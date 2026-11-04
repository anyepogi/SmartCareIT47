import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geofence_service.dart';
import 'location_tracker.dart';

/// How often the doctor's position is reported while heading to a clinic.
/// Keep this a little longer than ETA_REFRESH_SECONDS in eta_helper.php so
/// every report gets a freshly computed ETA from the server.
const Duration travelReportInterval = Duration(minutes: 1);

/// The latest ETA for the Doctor Travel card.
/// [etaMinutes] / [distanceMeters] come from the server (the same numbers
/// patients see); [localDistanceMeters] is a straight-line backup measured
/// on the phone, used only when the server could not be reached.
typedef TravelEta = ({
  int? etaMinutes,
  int? distanceMeters,
  double? localDistanceMeters,
});

const TravelEta _noEta = (
  etaMinutes: null,
  distanceMeters: null,
  localDistanceMeters: null,
);

/* This class keeps the doctor's "Doctor Travel" ETA going while he is
heading to a clinic. Like LocationTracker, there is only ever one of it
in the whole app (a singleton) instead of one per screen. That matters
because moving between tabs with the bottom navigation bar destroys the
old screen completely, so a timer living inside the doctor dashboard
used to stop the moment the doctor opened another tab, and patients
stopped getting a fresh ETA. Living here, it keeps reporting the
doctor's position every minute no matter which screen is open, and the
dashboard just listens to the values below to show them. */
class TravelTracker {
  TravelTracker._();
  static final TravelTracker instance = TravelTracker._();

  /// The clinic the doctor is heading to, or null if none is picked.
  final ValueNotifier<String?> destination = ValueNotifier(null);
  final ValueNotifier<TravelEta> eta = ValueNotifier(_noEta);
  final ValueNotifier<bool> isLoadingEta = ValueNotifier(false);

  /// The clinic the doctor just arrived at, so the card can say "You've
  /// arrived" after the destination is cleared. Null until he arrives,
  /// and reset when he picks a new destination or logs out.
  final ValueNotifier<String?> arrivedAt = ValueNotifier(null);

  Timer? _reportTimer;
  int? _userId;
  bool _restored = false;
  bool _listeningToGeofence = false;

  /// Watches the GPS between the 1 minute reports, only to catch the
  /// moment the doctor reaches (or leaves) the clinic, see _onPosition.
  StreamSubscription<Position>? _positionSub;
  bool _isRefreshing = false;

  /// Same as GEOFENCE_EXIT_METERS in arrival_helper.php.
  static const double _leaveRadiusMeters = 300;

  /* The 1 minute report is enough for the ETA, but waiting up to a minute
  to report an arrival made patients think the app was stuck. So while
  heading to a clinic (or sitting in one), this also listens to the GPS
  and reports right away the moment the doctor crosses into the clinic's
  geofence, or far enough out of it. The backend still makes the final
  call; this only makes the report happen sooner. */
  void _watchPosition() {
    if (_positionSub != null) return;
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: doctorTrackingLocationSettings(),
        ).listen(
          _onPosition,
          onError: (Object _) {
            // No permission or GPS off; the 1 minute reports still run.
            _positionSub?.cancel();
            _positionSub = null;
          },
        );
  }

  void _stopWatchingPosition() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  double? _distanceTo(String clinic, Position position) {
    final target = LocationTracker.instance.targetCoordinates[clinic];
    final lat = double.tryParse(target?.$1 ?? '');
    final lon = double.tryParse(target?.$2 ?? '');
    if (lat == null || lon == null) return null;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lon,
    );
  }

  void _onPosition(Position position) {
    final heading = destination.value;
    final inClinic = arrivedAt.value;
    if (heading != null) {
      final distance = _distanceTo(heading, position);
      if (distance != null && distance <= geofenceRadiusMeters) {
        unawaited(refresh(showSpinner: false));
      }
    } else if (inClinic != null) {
      final distance = _distanceTo(inClinic, position);
      if (distance != null && distance > _leaveRadiusMeters) {
        unawaited(refresh(showSpinner: false));
      }
    }
  }

  /* The phone's geofence can detect the doctor walking into the clinic
  before the next travel report does. When that happens the backend has
  already cleared his destination (update_location.php), so this clears
  it here too instead of leaving "Heading to" on the card. */
  void _listenToGeofence() {
    if (_listeningToGeofence) return;
    _listeningToGeofence = true;
    LocationTracker.instance.insideLocations.addListener(() {
      final clinic = destination.value;
      if (clinic != null &&
          LocationTracker.instance.insideLocations.value.contains(clinic)) {
        _markArrived(clinic);
      }
    });
  }

  /* Reporting keeps going after the doctor arrives (it only switches from
  "heading to" to "in clinic"). With geofence tracking off, these reports
  are the only way the backend can tell he has driven away again, and
  without them he would stay "In Clinic" for patients long after leaving. */
  void _markArrived(String clinic) {
    destination.value = null;
    eta.value = _noEta;
    isLoadingEta.value = false;
    arrivedAt.value = clinic;
    _ensureReportTimer();
    _watchPosition();
  }

  /// Called once the backend says the doctor is no longer inside the
  /// clinic he arrived at.
  void _markLeft() {
    arrivedAt.value = null;
    if (destination.value == null) {
      _reportTimer?.cancel();
      _reportTimer = null;
      _stopWatchingPosition();
    }
  }

  void _ensureReportTimer() {
    _reportTimer ??= Timer.periodic(
      travelReportInterval,
      (_) => refresh(showSpinner: false),
    );
  }

  /// Loads the clinic picked before (for example before the app was
  /// closed) and starts reporting again. Only asks the server once per
  /// login; later calls just refresh the ETA right away.
  Future<void> restore(int userId) async {
    if (_restored && _userId == userId) {
      if (destination.value != null) unawaited(refresh());
      return;
    }
    _userId = userId;
    _restored = true;
    try {
      final saved = await GeofenceService.getMyTravelDestination(userId);
      if (_userId != userId) return;
      if (saved != null) {
        destination.value = saved;
        _startReporting();
        return;
      }
      // No destination, but the app may have closed while the doctor was
      // "In Clinic" from an earlier trip. Keep checking whether he has
      // left, unless the geofence is already watching that itself.
      final (_, currentLocation) = await GeofenceService.getMyAvailability(
        userId,
      );
      if (currentLocation != null &&
          _userId == userId &&
          !LocationTracker.instance.isTracking.value) {
        _listenToGeofence();
        _markArrived(currentLocation);
        unawaited(refresh(showSpinner: false));
      }
    } catch (_) {
      // Leave the card empty if the fetch fails; try again next login.
      _restored = false;
    }
  }

  /// Saves [clinic] on the server first (so patients see the same clinic),
  /// then starts reporting. Throws if the server rejects it.
  Future<void> setDestination(int userId, String clinic) async {
    await GeofenceService.setTravelDestination(
      userId: userId,
      destination: clinic,
    );
    _userId = userId;
    _restored = true;
    arrivedAt.value = null;
    destination.value = clinic;
    eta.value = _noEta;
    _startReporting();
  }

  /// Clears the destination on the server and stops reporting. Throws if
  /// the server rejects it, leaving everything as it was.
  Future<void> clear(int userId) async {
    await GeofenceService.setTravelDestination(
      userId: userId,
      destination: null,
    );
    _stopReporting();
  }

  /// Forgets everything without telling the server, used on logout so
  /// the next account to sign in on this phone starts clean.
  void reset() {
    _stopReporting();
    arrivedAt.value = null;
    _userId = null;
    _restored = false;
  }

  void _startReporting() {
    _listenToGeofence();
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      travelReportInterval,
      (_) => refresh(showSpinner: false),
    );
    _watchPosition();
    unawaited(refresh());
  }

  void _stopReporting() {
    _reportTimer?.cancel();
    _reportTimer = null;
    _stopWatchingPosition();
    destination.value = null;
    eta.value = _noEta;
    isLoadingEta.value = false;
    arrivedAt.value = null;
  }

  /* This gets the phone's current GPS position, measures how far it is
  from the chosen clinic, and sends it to the backend. The backend then
  computes the real driving ETA (the same one patients see) and sends it
  back. The local straight-line distance is kept as a backup in case the
  backend can't be reached. */
  Future<void> refresh({bool showSpinner = true}) async {
    // The GPS watcher, the timer, and the refresh button can all ask at
    // once; one report at a time is enough.
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await _refresh(showSpinner: showSpinner);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _refresh({required bool showSpinner}) async {
    final clinic = destination.value;
    final userId = _userId;
    if (userId == null) return;
    if (clinic == null) {
      if (arrivedAt.value != null) await _checkStillInClinic(userId);
      return;
    }

    if (showSpinner) isLoadingEta.value = true;
    double? localDistance;
    int? serverEta;
    int? serverDistance;
    String? serverArrivedAt;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever &&
          await Geolocator.isLocationServiceEnabled()) {
        await LocationTracker.instance.loadTargetCoordinates();
        final target = LocationTracker.instance.targetCoordinates[clinic];
        final lat = double.tryParse(target?.$1 ?? '');
        final lon = double.tryParse(target?.$2 ?? '');
        final position = await Geolocator.getCurrentPosition();
        // Share this fresh reading with the geofence so it doesn't stay
        // stuck on an old one while the doctor is standing still.
        LocationTracker.instance.checkPosition(position);
        if (lat != null && lon != null) {
          localDistance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat,
            lon,
          );
        }
        try {
          final result = await GeofenceService.reportTravelPosition(
            userId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          serverEta = result.etaMinutes;
          serverDistance = result.distanceMeters;
          serverArrivedAt = result.arrivedAt;
        } catch (_) {
          // Backend unreachable; the card falls back to the local guess.
        }
      }
    } catch (_) {
      // Leave the distance empty; the card shows "ETA unavailable".
    }

    // Ignore the result if the destination changed or was cleared while
    // the GPS reading was still loading.
    if (destination.value != clinic || _userId != userId) return;
    if (serverArrivedAt == clinic) {
      _markArrived(clinic);
      return;
    }
    eta.value = (
      etaMinutes: serverEta,
      distanceMeters: serverDistance,
      localDistanceMeters: localDistance,
    );
    isLoadingEta.value = false;
  }

  /* While the doctor is "In Clinic" with no new destination, this sends
  his position so the backend can tell whether he is still there. Once
  the backend no longer has him inside the clinic (he drove away), the
  card stops saying "You've arrived" and patients stop seeing "In Clinic". */
  Future<void> _checkStillInClinic(int userId) async {
    final clinic = arrivedAt.value;
    if (clinic == null) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      LocationTracker.instance.checkPosition(position);
      final result = await GeofenceService.reportTravelPosition(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (arrivedAt.value != clinic || _userId != userId) return;
      if (result.currentLocation != clinic) _markLeft();
    } catch (_) {
      // No GPS or backend right now; the next tick will try again.
    }
  }
}
