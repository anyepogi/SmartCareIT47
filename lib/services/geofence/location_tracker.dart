import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/location_schedule.dart';
import '../../state/app_session.dart';
import 'geofence_service.dart';

/// A doctor is considered "inside" a clinic once their device is within
/// this many meters of the clinic's target coordinates.
const double geofenceRadiusMeters = 200;

/// How often the doctor's position is sent to the backend so the ETA
/// patients see stays up to date.
const Duration etaReportInterval = Duration(minutes: 2);

/* The GPS settings for the doctor's tracking (this file and
travel_tracker.dart). On Android they start a foreground service: a
notification that stays while tracking, which tells Android not to put
the app to sleep. Without it, Android stops the GPS and the 1 minute
reports a few minutes after the doctor minimizes the app (for example to
open Waze), and patients lose the ETA. The notification goes away when
tracking stops. Both trackers must use these same settings, because on
Android the plugin shares one GPS stream, and whichever tracker starts
first decides its settings. */
LocationSettings doctorTrackingLocationSettings() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 30),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'SmartCare',
        notificationText:
            "Location tracking is on so patients can see the doctor's ETA.",
        notificationChannelName: 'Doctor location tracking',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  }
  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
}

/* This class watches the doctor's live GPS position and compares it to
each clinic's location, to know if the doctor is physically inside a
clinic or not. There is only ever one of this class in the whole app
(this is called a singleton), instead of one per screen. This matters
because in this app, moving from one tab to another using the bottom
navigation bar actually destroys the old screen completely. If this
tracker lived inside a screen instead, GPS tracking would stop the
moment the doctor switched tabs. By keeping it separate from any
screen, tracking keeps running in the background no matter what screen
the doctor is looking at. */
class LocationTracker {
  LocationTracker._();
  static final LocationTracker instance = LocationTracker._();

  final ValueNotifier<bool> isTracking = ValueNotifier(false);

  /// Whether tracking is active according to the backend — which may have
  /// been started from a DIFFERENT device (the doctor's own, or the
  /// secretary's operating on his behalf), since [isTracking] only ever
  /// reflects this device's own local GPS stream. Screens should show
  /// "Active" when either this or [isTracking] is true. Refreshed via
  /// [refreshServerTrackingStatus]; kept in sync automatically whenever
  /// this device's own [start]/[stop] succeed.
  final ValueNotifier<bool> serverIsTracking = ValueNotifier(false);

  final ValueNotifier<String?> locationError = ValueNotifier(null);
  final ValueNotifier<Map<String, double?>> distances = ValueNotifier({
    for (final location in clinicLocations) location: null,
  });

  /// Last distances reported by whichever device is actually driving GPS
  /// tracking (the doctor's own, or the secretary's on his behalf) — the
  /// counterpart to [distances], which is empty on this device when the
  /// OTHER one is the one physically tracking. Refreshed alongside
  /// [serverIsTracking] via [refreshServerTrackingStatus].
  final ValueNotifier<Map<String, double?>> serverDistances = ValueNotifier({});

  final ValueNotifier<Set<String>> insideLocations = ValueNotifier({});

  /// The doctor-editable target coordinates per clinic, kept here (not on
  /// the Geofencing screen's State) so edits survive the screen being
  /// disposed when the doctor navigates to another tab via the bottom nav.
  /// Seeded with sane defaults; [loadTargetCoordinates] refreshes these
  /// from the database, which is the durable source of truth.
  final Map<String, (String, String)> targetCoordinates = {
    'Sta. Rita': ('16.2449', '120.4590'),
    'Lubao': ('15.1322', '120.6843'),
    'Guagua': ('15.3175', '120.8152'),
  };

  /// Refreshes [targetCoordinates] from the database. Leaves the current
  /// (default or previously loaded) values in place if the fetch fails.
  Future<void> loadTargetCoordinates() async {
    try {
      final coordinates = await GeofenceService.getClinicCoordinates();
      for (final entry in coordinates.entries) {
        targetCoordinates[entry.key] = (
          entry.value.$1.toString(),
          entry.value.$2.toString(),
        );
      }
    } catch (_) {
      // Keep whatever values are already cached.
    }
  }

  Future<void> updateTargetLatitude(String location, String value) async {
    final current = targetCoordinates[location]!;
    targetCoordinates[location] = (value, current.$2);
    await _persistTarget(location);
  }

  Future<void> updateTargetLongitude(String location, String value) async {
    final current = targetCoordinates[location]!;
    targetCoordinates[location] = (current.$1, value);
    await _persistTarget(location);
  }

  Future<void> _persistTarget(String location) async {
    final coords = targetCoordinates[location]!;
    final lat = double.tryParse(coords.$1);
    final lon = double.tryParse(coords.$2);
    if (lat == null || lon == null) return;
    await GeofenceService.updateClinicCoordinates(
      location: location,
      latitude: lat,
      longitude: lon,
      actorUserId: SmartCareSession.currentUserId,
    );
  }

  StreamSubscription<Position>? _subscription;
  Map<String, (double, double)> _targets = {};
  int? _userId;

  /// Sends the latest position every [etaReportInterval] for the ETA.
  /// Uses a timer instead of the position stream because the stream only
  /// fires when the doctor moves, and the ETA should refresh even while
  /// he is stuck in traffic.
  Timer? _etaTimer;
  Position? _lastPosition;

  /* This turns on GPS tracking for the doctor. It first checks if the
  app has permission to use the phone's location, and asks for it if
  not. It also checks if location services (GPS) are turned on in the
  phone's settings at all. If either check fails, it saves an error
  message in locationError instead of crashing, so the screen can show
  a helpful message. If everything is fine, it starts listening to the
  phone's GPS and tells the backend that tracking is now active. Each
  time the phone's position updates, _handlePosition below gets called
  automatically. Calling this again while already tracking does
  nothing, so it is safe to press "Start" more than once. */
  Future<void> start({
    required int userId,
    required Map<String, (double, double)> targets,
  }) async {
    if (isTracking.value) return;

    locationError.value = null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      locationError.value =
          'Location permission is required to track geofence status.';
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      locationError.value =
          'Please turn on location services to start tracking.';
      return;
    }

    _userId = userId;
    _targets = targets;
    isTracking.value = true;
    serverIsTracking.value = true;
    try {
      await GeofenceService.setTrackingStatus(userId: userId, isTracking: true);
    } catch (_) {
      // Best-effort — local tracking still starts; other devices simply
      // won't see the "Active" status until the next successful report.
    }

    _subscription =
        Geolocator.getPositionStream(
          locationSettings: doctorTrackingLocationSettings(),
        ).listen(
          _handlePosition,
          onError: (Object error) {
            locationError.value = 'Location tracking error: $error';
          },
        );

    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(etaReportInterval, (_) => _reportPosition());
    unawaited(_reportPosition());
  }

  /* This asks the GPS for a fresh position, runs the geofence check with
  it, and sends it to the backend so it can refresh the ETA patients
  see. A fresh reading is needed here because the GPS stream only fires
  when the doctor moves: if its first reading was inaccurate (for
  example a rough Wi-Fi fix kilometers away) and the doctor then stood
  still inside the clinic, the geofence used to stay stuck on that old
  reading and never detected him inside. The last stream position is
  only used if the GPS can't give a fresh one. */
  Future<void> _reportPosition() async {
    final userId = _userId;
    if (userId == null || !isTracking.value) return;
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
        checkPosition(position);
      } catch (_) {
        position = _lastPosition;
      }
      if (position == null) return;
      await GeofenceService.updatePosition(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Best-effort — the next 2 minute tick will try again, and the
      // backend hides an ETA that has not been refreshed for a while.
    }
  }

  // Position updates can arrive faster than the backend round-trip for a
  // transition completes. Firing those calls without ordering them risks
  // an older "exit" landing on the server after a newer "enter" — the app
  // shows the correct live status, but the server (and therefore what
  // patients see) gets stuck on stale data. These two fields turn the
  // stream into a simple serial queue: only ever one update in flight,
  // and if more positions arrive while it's running, only the latest one
  // is processed next (superseded ones are dropped, not queued up).
  Position? _pendingPosition;
  bool _isApplyingPosition = false;

  /// Runs the geofence check with a position taken somewhere else (for
  /// example TravelTracker's fresh reading), so the geofence doesn't have
  /// to wait for the GPS stream to report movement. Does nothing if
  /// tracking is off.
  void checkPosition(Position position) {
    if (!isTracking.value || _userId == null) return;
    _handlePosition(position);
  }

  void _handlePosition(Position position) {
    _pendingPosition = position;
    unawaited(_drainPendingPosition());
  }

  Future<void> _drainPendingPosition() async {
    if (_isApplyingPosition) return;
    _isApplyingPosition = true;
    try {
      while (_pendingPosition != null) {
        final position = _pendingPosition!;
        _pendingPosition = null;
        await _applyPosition(position);
      }
    } finally {
      _isApplyingPosition = false;
    }
  }

  /* This is the main brain of the geofence feature. Every time a new GPS
  position comes in, this function measures the straight line distance
  from that position to each clinic's saved coordinates. If the
  distance is 200 meters or less, the doctor counts as "inside" that
  clinic. It compares this to whether they were inside before, and if
  something changed (just walked in, or just walked out), it tells the
  backend about that change one at a time, in order, so the server
  never receives an "exit" after a newer "enter" by mistake. This is
  also where the current distances get saved and sent to the backend so
  the other device (doctor's or secretary's) can see them too. */
  Future<void> _applyPosition(Position position) async {
    final userId = _userId;
    if (userId == null) return;
    _lastPosition = position;

    final newDistances = Map<String, double?>.from(distances.value);
    final newInside = Set<String>.from(insideLocations.value);
    final transitions = <String, bool>{};

    for (final entry in _targets.entries) {
      final location = entry.key;
      final (lat, lon) = entry.value;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lon,
      );
      final isInside = distance <= geofenceRadiusMeters;
      final wasInside = newInside.contains(location);

      newDistances[location] = distance;
      if (isInside != wasInside) transitions[location] = isInside;
    }

    distances.value = newDistances;
    try {
      await GeofenceService.setTrackingStatus(
        userId: userId,
        isTracking: true,
        distances: newDistances,
      );
    } catch (_) {
      // Best-effort — the other device just won't see this particular
      // distance update; the next position will retry.
    }

    // Awaited one at a time (not fired concurrently) so the server always
    // processes them in the same order they happened on the device.
    for (final transition in transitions.entries) {
      if (transition.value) {
        newInside.add(transition.key);
      } else {
        newInside.remove(transition.key);
      }
      insideLocations.value = Set<String>.from(newInside);
      try {
        await GeofenceService.updateLocationStatus(
          userId: userId,
          location: transition.key,
          isInside: transition.value,
        );
      } catch (error) {
        locationError.value = 'Failed to report location status: $error';
      }
    }
  }

  /* This turns off GPS tracking. Before it fully stops, it sends an
  "exit" event to the backend for any clinic the doctor was still
  marked inside of, so the doctor does not stay stuck showing as "in
  clinic" forever after tracking has actually stopped. It also waits
  for any position update that is still being processed to finish
  first, so an old "enter" message cannot arrive at the server after
  this "exit" message and undo it by mistake. */
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _pendingPosition = null;
    _etaTimer?.cancel();
    _etaTimer = null;
    _lastPosition = null;

    // Wait for any in-flight position update to finish reporting before
    // sending the exit calls below, so they can't race and get
    // overwritten by a stale "enter" that was still in flight.
    while (_isApplyingPosition) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final userId = _userId;
    if (userId != null) {
      for (final location in insideLocations.value) {
        try {
          await GeofenceService.updateLocationStatus(
            userId: userId,
            location: location,
            isInside: false,
          );
        } catch (_) {
          // Best-effort on stop; nothing more useful to do with the error.
        }
      }
      try {
        await GeofenceService.setTrackingStatus(
          userId: userId,
          isTracking: false,
        );
      } catch (_) {
        // Best-effort — other devices will self-correct on their next poll.
      }
    }

    insideLocations.value = {};
    distances.value = {for (final location in clinicLocations) location: null};
    isTracking.value = false;
    serverIsTracking.value = false;
  }

  /// Refreshes [serverIsTracking] and [serverDistances] from the backend —
  /// call this on screen load and periodically while a Geofencing screen
  /// is open, so tracking (and distances) started from the OTHER device
  /// (doctor's own, or the secretary's) is reflected here too, not just
  /// this device's own [isTracking]/[distances].
  Future<void> refreshServerTrackingStatus(int userId) async {
    try {
      final (tracking, reportedDistances) =
          await GeofenceService.getTrackingStatus(userId);

      serverIsTracking.value = tracking;
      serverDistances.value = reportedDistances;

      if (!tracking && isTracking.value) {
        await stop();
      }
    } catch (_) {
      // Keep the current cached state if the server cannot be reached.
    }
  }

  /// Forces a fresh position check against every target right now — a
  /// no-op if tracking isn't active. Toggling "Available" off then back on
  /// doesn't move the device, so the GPS stream (which only fires on
  /// movement) never emits a new reading; without this, a doctor who never
  /// physically left the clinic would stay stuck showing "not in clinic"
  /// server-side until they moved or manually stopped/restarted tracking.
  /// [insideLocations] is cleared first so the still-inside location is
  /// re-detected as a fresh "enter" and re-reported, even though this
  /// device's local state never thought it left.
  Future<void> resyncCurrentPosition() async {
    if (!isTracking.value) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      insideLocations.value = {};
      await _applyPosition(position);
      // Also refresh the ETA right away, so patients see "On the way"
      // as soon as the doctor turns Available on instead of waiting for
      // the next 2 minute tick.
      await _reportPosition();
    } catch (_) {
      // Best-effort — the position stream will eventually catch up too.
    }
  }

  Future<void> stopForUser(int userId) async {
    if (isTracking.value) {
      await stop();
      return;
    }

    await GeofenceService.stopTracking(userId);

    serverIsTracking.value = false;
    serverDistances.value = {};
  }
}
