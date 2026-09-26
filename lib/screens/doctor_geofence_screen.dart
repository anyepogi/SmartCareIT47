import 'dart:async';

import 'package:flutter/material.dart';
import '../data/location_schedule.dart';
import '../services/geofence/location_tracker.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

class DoctorGeofenceScreen extends StatefulWidget {
  const DoctorGeofenceScreen({super.key});

  @override
  State<DoctorGeofenceScreen> createState() => _DoctorGeofenceScreenState();
}

class _DoctorGeofenceScreenState extends State<DoctorGeofenceScreen> {
  final _tracker = LocationTracker.instance;

  late final Map<String, TextEditingController> _latControllers;
  late final Map<String, TextEditingController> _lonControllers;

  // The last value confirmed as saved (either the seed default, or
  // whatever the server last returned) — compared against the live
  // controller text to detect real, unsaved edits. Kept separate from the
  // controllers themselves so a programmatic refresh from the server can
  // update both together without _CoordinateField mistaking it for a
  // change the doctor typed.
  late final Map<String, String> _confirmedLat;
  late final Map<String, String> _confirmedLon;

  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _latControllers = {
      for (final location in clinicLocations)
        location: TextEditingController(
          text: _tracker.targetCoordinates[location]!.$1,
        ),
    };
    _lonControllers = {
      for (final location in clinicLocations)
        location: TextEditingController(
          text: _tracker.targetCoordinates[location]!.$2,
        ),
    };
    _confirmedLat = {
      for (final location in clinicLocations)
        location: _tracker.targetCoordinates[location]!.$1,
    };
    _confirmedLon = {
      for (final location in clinicLocations)
        location: _tracker.targetCoordinates[location]!.$2,
    };
    _refreshCoordinatesFromServer();
    _pollTrackingStatus();
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pollTrackingStatus(),
    );
  }

  /// Refreshes [LocationTracker.serverIsTracking] — picks up tracking
  /// started/stopped from the secretary's device, so this screen's
  /// Active/Inactive status stays in sync even though her tracking
  /// doesn't run on this device.
  void _pollTrackingStatus() {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    _tracker.refreshServerTrackingStatus(userId);
  }

  /// Pulls the latest saved coordinates from the database — in case they
  /// were edited from another session — and syncs the input fields, unless
  /// tracking is active (fields are read-only then anyway).
  Future<void> _refreshCoordinatesFromServer() async {
    await _tracker.loadTargetCoordinates();
    if (!mounted || _tracker.isTracking.value) return;
    setState(() {
      for (final location in clinicLocations) {
        final coords = _tracker.targetCoordinates[location]!;
        _latControllers[location]!.text = coords.$1;
        _lonControllers[location]!.text = coords.$2;
        _confirmedLat[location] = coords.$1;
        _confirmedLon[location] = coords.$2;
      }
    });
  }

  @override
  void dispose() {
    // Deliberately NOT touching _tracker here — it's a process-wide
    // singleton that must keep running (and keep reporting to the
    // backend) even after this screen is disposed, e.g. when the doctor
    // navigates to another tab via the bottom nav.
    for (final controller in _latControllers.values) {
      controller.dispose();
    }
    for (final controller in _lonControllers.values) {
      controller.dispose();
    }
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;

    final targets = <String, (double, double)>{};
    for (final location in clinicLocations) {
      final lat = double.tryParse(_latControllers[location]!.text);
      final lon = double.tryParse(_lonControllers[location]!.text);
      if (lat != null && lon != null) targets[location] = (lat, lon);
    }

    await _tracker.start(userId: userId, targets: targets);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _tracker.isTracking,
        _tracker.serverIsTracking,
        _tracker.locationError,
        _tracker.distances,
        _tracker.serverDistances,
        _tracker.insideLocations,
      ]),
      builder: (context, _) {
        final isTracking = _tracker.isTracking.value;
        // "Active" also when tracking was started from the secretary's
        // device on the doctor's behalf — not just this device's own GPS
        // stream — so both screens agree on whether tracking is on.
        final displayIsTracking = isTracking || _tracker.serverIsTracking.value;
        final locationError = _tracker.locationError.value;

        return Scaffold(
          backgroundColor: const Color(0xFFE8F2E4),
          bottomNavigationBar: const SmartCareBottomNav(
            currentItem: SmartCareBottomItem.geofence,
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SmartCareDashboardHeader(
                  title: "Geofencing",
                  subtitle:
                      "Manage your clinic area and get alerts when you or patients enter or exit.",
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Geofencing Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD5E4D5)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F6B2F,
                              ).withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shield Icon Container
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F8F0),
                                borderRadius: BorderRadius.circular(29),
                              ),
                              child: Center(
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF0F6B2F),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(21),
                                  ),
                                  child: const Icon(
                                    Icons.shield,
                                    color: Color(0xFF0F6B2F),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Geofencing Status',
                                    style: TextStyle(
                                      color: Color(0xFF0F6B2F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Active/Inactive Status with Icon
                                  Row(
                                    children: [
                                      Icon(
                                        displayIsTracking
                                            ? Icons.check_circle
                                            : Icons.pause_circle_filled,
                                        color: displayIsTracking
                                            ? const Color(0xFF0F6B2F)
                                            : const Color(0xFFFF9800),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        displayIsTracking
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: displayIsTracking
                                              ? const Color(0xFF0F6B2F)
                                              : const Color(0xFFFF9800),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Description Text
                                  const Text(
                                    'Confirms when you\'ve arrived at the clinic, so patients can see your real-time availability.',
                                    style: TextStyle(
                                      color: Color(0xFF506D54),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Geofence Tracker
                      const Text(
                        'Geofence Tracker',
                        style: TextStyle(
                          color: Color(0xFF1B6F2A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTrackerControls(
                        isTracking,
                        displayIsTracking,
                        locationError,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Clinic Locations',
                        style: TextStyle(
                          color: Color(0xFF1B6F2A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final location in clinicLocations) ...[
                        _buildClinicInfoCard(location, isTracking),
                        if (location != clinicLocations.last)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackerControls(
    bool isTracking,
    bool displayIsTracking,
    String? locationError,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5E4D5)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTracking
                ? 'Tracking all clinic locations.'
                : displayIsTracking
                ? 'Tracking is active from the secretary\'s device.'
                : 'Start tracking to monitor all clinic locations at once.',
            style: const TextStyle(color: Color(0xFF506D54), fontSize: 12),
          ),
          if (locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              locationError,
              style: const TextStyle(color: Color(0xFFC41E3A), fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          // Start Tracking and Stop Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: displayIsTracking ? null : _startTracking,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6B2F),
                    disabledBackgroundColor: const Color(0xFFD5E4D5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF999999),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !displayIsTracking
                      ? null
                      : () {
                          final userId = SmartCareSession.currentUserId;
                          if (userId == null) return;
                          _tracker.stopForUser(userId);
                        },
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F6B2F),
                    disabledForegroundColor: const Color(0xFF999999),
                    side: const BorderSide(color: Color(0xFF0F6B2F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _distanceLabel(String clinicName) {
    // Falls back to the secretary's device's last-reported distance when
    // this device isn't the one actually driving GPS tracking.
    final distance =
        _tracker.distances.value[clinicName] ??
        _tracker.serverDistances.value[clinicName];
    if (distance == null) return 'Distance: —';
    return 'Distance: ${distance.toStringAsFixed(2)} meters';
  }

  String _statusLabel(String clinicName, bool isTracking) {
    if (!isTracking) return 'Status: Waiting...';
    return _tracker.insideLocations.value.contains(clinicName)
        ? 'Status: Inside'
        : 'Status: Outside';
  }

  Widget _buildClinicInfoCard(String clinicName, bool isTracking) {
    final latController = _latControllers[clinicName]!;
    final lonController = _lonControllers[clinicName]!;
    final isInside = _tracker.insideLocations.value.contains(clinicName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isInside ? const Color(0xFF0F6B2F) : const Color(0xFFD5E4D5),
          width: isInside ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F8E3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF0F6B2F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicName,
                      style: const TextStyle(
                        color: Color(0xFF1B6F2A),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CoordinateField(
                  label: 'Target Latitude',
                  controller: latController,
                  confirmedValue: _confirmedLat[clinicName]!,
                  enabled: !isTracking,
                  onConfirmed: (value) {
                    _confirmedLat[clinicName] = value;
                    _tracker.updateTargetLatitude(clinicName, value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CoordinateField(
                  label: 'Target Longitude',
                  controller: lonController,
                  confirmedValue: _confirmedLon[clinicName]!,
                  enabled: !isTracking,
                  onConfirmed: (value) {
                    _confirmedLon[clinicName] = value;
                    _tracker.updateTargetLongitude(clinicName, value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _distanceLabel(clinicName),
                style: const TextStyle(
                  color: Color(0xFF506D54),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _statusLabel(clinicName, isTracking),
                style: TextStyle(
                  color: isInside
                      ? const Color(0xFF0F6B2F)
                      : const Color(0xFFFF9800),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends StatefulWidget {
  const _CoordinateField({
    required this.label,
    required this.controller,
    required this.confirmedValue,
    required this.enabled,
    required this.onConfirmed,
  });

  final String label;
  final TextEditingController controller;

  /// The value last confirmed as saved. Compared against the live
  /// controller text to detect real edits; when the parent updates this
  /// (e.g. after refreshing from the server), [didUpdateWidget] re-syncs
  /// the internal baseline too, so that refresh isn't mistaken for an
  /// unsaved change the user just made.
  final String confirmedValue;
  final bool enabled;
  final ValueChanged<String> onConfirmed;

  @override
  State<_CoordinateField> createState() => _CoordinateFieldState();
}

class _CoordinateFieldState extends State<_CoordinateField> {
  final FocusNode _focusNode = FocusNode();
  late String _confirmedValue;

  @override
  void initState() {
    super.initState();
    _confirmedValue = widget.confirmedValue;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _CoordinateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.confirmedValue != oldWidget.confirmedValue) {
      _confirmedValue = widget.confirmedValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleFocusChange() async {
    if (_focusNode.hasFocus) return;
    final newValue = widget.controller.text;
    if (newValue == _confirmedValue) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Changes?'),
        content: Text('Update ${widget.label} to "$newValue"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6B2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      setState(() => _confirmedValue = newValue);
      widget.onConfirmed(newValue);
    } else {
      setState(() => widget.controller.text = _confirmedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF506D54),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            hintText: widget.label,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD5E4D5)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD5E4D5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0F6B2F), width: 2),
            ),
          ),
          style: const TextStyle(color: Color(0xFF1A3320), fontSize: 13),
        ),
      ],
    );
  }
}
