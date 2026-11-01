import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/location_schedule.dart';
import '../../state/app_session.dart';
import 'geofence_service.dart';

/// Distance from a clinic (in meters) where the doctor counts as inside.
const double geofenceRadiusMeters = 200;

/// How often the position is sent for the patients' ETA.
const Duration etaReportInterval = Duration(minutes: 2);

/// GPS settings shared by LocationTracker and TravelTracker.
/// On Android this runs a foreground service (the tracking notification)
/// so the GPS keeps going when the app is minimized, like when the doctor
/// opens Waze. Both trackers need the same settings because they share
/// one GPS stream, and whichever starts first sets it.
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

/// Watches the doctor's GPS and checks if they're inside a clinic.
/// It's a singleton so tracking doesn't stop when the doctor changes tabs
/// (the bottom nav disposes the old screen).
class LocationTracker {
  LocationTracker._();
  static final LocationTracker instance = LocationTracker._();

  final ValueNotifier<bool> isTracking = ValueNotifier(false);

  /// Tracking status from the backend, which may come from the other phone
  /// (doctor's or secretary's). isTracking is only this phone's GPS, so
  /// show "Active" if either one is true.
  final ValueNotifier<bool> serverIsTracking = ValueNotifier(false);

  final ValueNotifier<String?> locationError = ValueNotifier(null);
  final ValueNotifier<Map<String, double?>> distances = ValueNotifier({
    for (final location in clinicLocations) location: null,
  });

  /// Distances from whichever phone is tracking. Use this when the other
  /// phone has the GPS on, since distances would be empty here.
  final ValueNotifier<Map<String, double?>> serverDistances = ValueNotifier({});

  final ValueNotifier<Set<String>> insideLocations = ValueNotifier({});

  /// Target coordinates per clinic. Kept here so edits aren't lost when the
  /// Geofencing screen is disposed. Uses defaults until
  /// loadTargetCoordinates gets the saved ones from the database.
  final Map<String, (String, String)> targetCoordinates = {
    'Sta. Rita': ('16.2449', '120.4590'),
    'Lubao': ('15.1322', '120.6843'),
    'Guagua': ('15.3175', '120.8152'),
  };

  /// Loads targetCoordinates from the database. Keeps the current values
  /// if it fails.
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
      // Keep the cached values.
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

  /// Sends the position every etaReportInterval. A timer is used because
  /// the GPS stream only fires when the doctor moves, and the ETA should
  /// still update while he's stuck in traffic.
  Timer? _etaTimer;
  Position? _lastPosition;

  /// Starts GPS tracking. Asks for location permission and checks that GPS
  /// is on; if either fails, the reason goes to locationError instead of
  /// throwing. Safe to call again while already tracking.
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
      // Tracking still runs on this phone; the other phone just won't see
      // "Active" until the next report goes through.
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

  /// Gets a fresh GPS reading, runs the geofence check, and sends it for the
  /// ETA. The stream only fires on movement, so a bad first reading could
  /// stay stuck while the doctor stands still in the clinic. Falls back to
  /// the last stream position if there's no fresh one.
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
      // The next tick will retry, and the backend hides old ETAs anyway.
    }
  }

  // Positions can come in faster than the backend replies. So an old "exit"
  // can't land after a newer "enter", only one update runs at a time, and
  // only the latest waiting position is kept.
  Position? _pendingPosition;
  bool _isApplyingPosition = false;

  /// Runs the geofence check with a position from somewhere else (like
  /// TravelTracker) instead of waiting for the stream. Does nothing if
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

  /// The main geofence check. Measures the distance to each clinic, and
  /// anything within geofenceRadiusMeters counts as inside. Enter/exit
  /// changes are sent to the backend in order, together with the latest
  /// distances for the other phone.
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
      // Not a big deal, the next position sends it again.
    }

    // One at a time so the server gets them in the order they happened.
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

  /// Stops tracking. Sends "exit" for any clinic the doctor is still marked
  /// inside so he doesn't stay "In Clinic". Waits for any running update
  /// first so an old "enter" can't arrive after the exit.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _pendingPosition = null;
    _etaTimer?.cancel();
    _etaTimer = null;
    _lastPosition = null;

    // Let the running update finish first so it can't overwrite the exits.
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
          // Nothing else to do here.
        }
      }
      try {
        await GeofenceService.setTrackingStatus(
          userId: userId,
          isTracking: false,
        );
      } catch (_) {
        // The other phone catches up on its next poll.
      }
    }

    insideLocations.value = {};
    distances.value = {for (final location in clinicLocations) location: null};
    isTracking.value = false;
    serverIsTracking.value = false;
  }

  /// Updates serverIsTracking and serverDistances from the backend. Call it
  /// on load and every few seconds on the Geofencing screen so tracking
  /// from the other phone shows up here too.
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
      // Keep the cached values if the server can't be reached.
    }
  }

  /// Checks the current position again right away (only while tracking).
  /// Needed after turning Available off and on, since the phone didn't move
  /// and the stream won't fire. insideLocations is cleared first so the
  /// clinic gets reported as a fresh "enter".
  Future<void> resyncCurrentPosition() async {
    if (!isTracking.value) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      insideLocations.value = {};
      await _applyPosition(position);
      // Update the ETA now too, so patients see "On the way" as soon as the
      // doctor turns Available on.
      await _reportPosition();
    } catch (_) {
      // The stream will catch up later.
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
