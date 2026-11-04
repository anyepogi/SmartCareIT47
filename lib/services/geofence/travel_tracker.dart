import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geofence_service.dart';
import 'location_tracker.dart';

/// How often the position is reported while heading to a clinic. Keep it
/// a bit longer than ETA_REFRESH_SECONDS in eta_helper.php so each report
/// gets a new ETA.
const Duration travelReportInterval = Duration(minutes: 1);

/// ETA for the Doctor Travel card. etaMinutes and distanceMeters come
/// from the server (same as what patients see). localDistanceMeters is a
/// straight-line distance from the phone, used if the server is down.
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

/// Keeps the Doctor Travel ETA updated while the doctor is heading to a
/// clinic. A singleton like LocationTracker, so it keeps running when the
/// doctor changes tabs. The dashboard just listens to the notifiers.
class TravelTracker {
  TravelTracker._();
  static final TravelTracker instance = TravelTracker._();

  /// The clinic the doctor is heading to, or null if none is picked.
  final ValueNotifier<String?> destination = ValueNotifier(null);
  final ValueNotifier<TravelEta> eta = ValueNotifier(_noEta);
  final ValueNotifier<bool> isLoadingEta = ValueNotifier(false);

  /// The clinic the doctor arrived at, so the card can say "You've arrived".
  /// Reset when a new destination is picked or on logout.
  final ValueNotifier<String?> arrivedAt = ValueNotifier(null);

  Timer? _reportTimer;
  int? _userId;
  bool _restored = false;
  bool _listeningToGeofence = false;

  /// Watches the GPS between reports to catch arriving or leaving sooner.
  StreamSubscription<Position>? _positionSub;
  bool _isRefreshing = false;

  /// Same as GEOFENCE_EXIT_METERS in arrival_helper.php.
  static const double _leaveRadiusMeters = 300;

  /// Reports right away when the doctor enters the clinic or goes far
  /// enough away, instead of waiting for the next 1 minute report. The
  /// backend still decides if he really arrived.
  void _watchPosition() {
    if (_positionSub != null) return;
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: doctorTrackingLocationSettings(),
        ).listen(
          _onPosition,
          onError: (Object _) {
            // No permission or GPS is off; the timer still runs.
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

  /// If the geofence sees the doctor inside the destination first, the
  /// backend has already cleared it, so clear it here too.
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

  /// Keeps reporting after arriving. With geofence tracking off, these
  /// reports are the only way the backend knows the doctor has left.
  void _markArrived(String clinic) {
    destination.value = null;
    eta.value = _noEta;
    isLoadingEta.value = false;
    arrivedAt.value = clinic;
    _ensureReportTimer();
    _watchPosition();
  }

  /// Called when the backend says the doctor has left the clinic.
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

  /// Brings back the picked clinic (e.g. after the app was closed) and
  /// starts reporting. Only fetches once per login; after that it just
  /// refreshes.
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
      // No destination, but the doctor may still be "In Clinic" from before.
      // Keep checking if he left, unless the geofence already does that.
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
      // Try again on the next login.
      _restored = false;
    }
  }

  /// Saves the clinic on the server, then starts reporting. Throws if the
  /// server rejects it.
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

  /// Clears the destination on the server and stops reporting. If that
  /// fails it throws and nothing changes.
  Future<void> clear(int userId) async {
    await GeofenceService.setTravelDestination(
      userId: userId,
      destination: null,
    );
    _stopReporting();
  }

  /// Clears everything locally without calling the server. Used on logout.
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

  /// Gets the GPS position and sends it to the backend, which returns the
  /// driving ETA. The straight-line distance is kept as a backup in case
  /// the backend can't be reached.
  Future<void> refresh({bool showSpinner = true}) async {
    // The timer, the GPS watcher, and the refresh button can all call this
    // at the same time.
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
        // Give the geofence this fresh reading too.
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
          // Backend is down; the card uses the local distance.
        }
      }
    } catch (_) {
      // No GPS; the card shows "ETA unavailable".
    }

    // The destination changed while waiting for the GPS, so drop this result.
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

  /// While "In Clinic" with no new destination, sends the position so the
  /// backend can tell if the doctor left. If he did, the card and the
  /// patients' view stop showing "In Clinic".
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
      // Try again on the next tick.
    }
  }
}
