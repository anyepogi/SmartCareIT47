import 'dart:async';

import 'package:flutter/material.dart';
import '../data/location_schedule.dart';
import '../services/geofence/geofence_service.dart';
import '../services/geofence/location_tracker.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

class SecretaryGeofenceScreen extends StatefulWidget {
  const SecretaryGeofenceScreen({super.key});

  @override
  State<SecretaryGeofenceScreen> createState() =>
      _SecretaryGeofenceScreenState();
}

class _SecretaryGeofenceScreenState extends State<SecretaryGeofenceScreen> {
  // Geofencing tracks the DOCTOR's presence, not the secretary's. Only the
  // doctor can start or stop tracking (from his own phone). Here the
  // secretary can only edit the clinic coordinates, see if the doctor's
  // tracking is on (polled from the backend in [_pollTrackingStatus]),
  // and use Manual Check-in.
  final _tracker = LocationTracker.instance;

  late final Map<String, TextEditingController> _latControllers;
  late final Map<String, TextEditingController> _lonControllers;

  // The last value confirmed as saved (either the seed default, or
  // whatever the server last returned) — compared against the live
  // controller text to detect real, unsaved edits. Kept separate from the
  // controllers themselves so a programmatic refresh from the server can
  // update both together without _CoordinateField mistaking it for a
  // change the secretary typed.
  late final Map<String, String> _confirmedLat;
  late final Map<String, String> _confirmedLon;

  String? _doctorName;
  int? _doctorUserId;
  Timer? _statusPollTimer;

  // What patients currently see for each clinic, for the Manual Check-in
  // card. Null until the first load.
  Map<String, ClinicAvailability>? _clinicStatus;
  String? _savingPresenceFor;

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
    _loadDoctorName();
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pollTrackingStatus(),
    );
  }

  Future<void> _loadDoctorName() async {
    try {
      final doctor = await GeofenceService.getDoctorAccount();
      if (!mounted) return;
      setState(() {
        _doctorName = doctor.name;
        _doctorUserId = doctor.userId;
      });
      _pollTrackingStatus();
    } catch (_) {
      // Leave it null — the tracker controls still work, just without
      // the doctor's name in the description text.
    }
  }

  /// Refreshes [LocationTracker.serverIsTracking] — picks up tracking
  /// started/stopped from the doctor's own device, so this screen's
  /// Active/Inactive status stays in sync even though his tracking doesn't
  /// run on this device.
  void _pollTrackingStatus() {
    _loadClinicStatus();
    final doctorUserId = _doctorUserId;
    if (doctorUserId == null) return;
    _tracker.refreshServerTrackingStatus(doctorUserId);
  }

  Future<void> _loadClinicStatus() async {
    try {
      final status = await GeofenceService.getStatus();
      if (!mounted) return;
      setState(() => _clinicStatus = status.clinics);
    } catch (_) {
      // Keep the last known status; the next poll tries again.
    }
  }

  /* Manual Check-in: lets the secretary mark the doctor as inside a
  clinic (or gone from it) when his geofence isn't working. Asks first,
  because arriving also notifies the patients booked there today. */
  Future<void> _setManualPresence(String location, bool isInside) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isInside ? 'Mark as Arrived?' : 'Mark as Left?'),
        content: Text(
          isInside
              ? 'Patients will see the doctor as "In Clinic" at $location, '
                    'and those booked there today will be notified that he '
                    'has arrived.'
              : 'Patients will no longer see the doctor as "In Clinic" at '
                    '$location.',
        ),
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
    if (confirmed != true || !mounted) return;

    setState(() => _savingPresenceFor = location);
    try {
      final message = await GeofenceService.setManualPresence(
        location: location,
        isInside: isInside,
      );
      await _loadClinicStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingPresenceFor = null);
    }
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
    // backend) even after this screen is disposed, e.g. when the
    // secretary navigates to another tab via the bottom nav.
    for (final controller in _latControllers.values) {
      controller.dispose();
    }
    for (final controller in _lonControllers.values) {
      controller.dispose();
    }
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tracker.serverIsTracking,
      builder: (context, _) {
        // The doctor's tracking status, read from the backend.
        final isTracking = _tracker.serverIsTracking.value;
        final tablet = _isTablet(context);
        final sectionTitleStyle = TextStyle(
          color: const Color(0xFF1B6F2A),
          fontSize: tablet ? 22 : 16,
          fontWeight: FontWeight.bold,
        );

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
                      "Track the doctor's clinic area and get alerts when they arrive or leave.",
                ),
                Padding(
                  padding: tablet
                      ? const EdgeInsets.fromLTRB(24, 20, 24, 16)
                      : const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: tablet ? 1080 : double.infinity,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Geofencing Status Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFD5E4D5),
                                ),
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
                                          borderRadius: BorderRadius.circular(
                                            21,
                                          ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Geofencing Status',
                                          style: TextStyle(
                                            color: const Color(0xFF0F6B2F),
                                            fontSize: tablet ? 22 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Active/Inactive Status with Icon
                                        Row(
                                          children: [
                                            Icon(
                                              isTracking
                                                  ? Icons.check_circle
                                                  : Icons.pause_circle_filled,
                                              color: isTracking
                                                  ? const Color(0xFF0F6B2F)
                                                  : const Color(0xFFFF9800),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isTracking
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                color: isTracking
                                                    ? const Color(0xFF0F6B2F)
                                                    : const Color(0xFFFF9800),
                                                fontSize: tablet ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Description Text
                                        Text(
                                          _doctorName == null
                                              ? 'Confirm when the doctor arrives at the clinic on his behalf, so patients can see his real-time availability.'
                                              : 'Confirm when $_doctorName arrives at the clinic on his behalf, so patients can see his real-time availability.',
                                          style: TextStyle(
                                            color: const Color(0xFF506D54),
                                            fontSize: tablet ? 14 : 12,
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
                            Text('Geofence Tracker', style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            _buildTrackerStatus(isTracking),
                            const SizedBox(height: 24),
                            Text('Manual Check-in', style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            _buildManualCheckIn(),
                            const SizedBox(height: 24),
                            Text('Clinic Locations', style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            for (final location in clinicLocations) ...[
                              tablet
                                  ? _buildTabletClinicCard(location, isTracking)
                                  : _buildClinicInfoCard(location, isTracking),
                              if (location != clinicLocations.last)
                                const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Read-only. Only the doctor can start or stop tracking.
  Widget _buildTrackerStatus(bool isTracking) {
    final tablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: tablet ? const EdgeInsets.all(20) : const EdgeInsets.all(16),
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
                ? 'The doctor is tracking all clinic locations from his phone.'
                : 'Tracking is off. Only the doctor can start tracking from his own phone.',
            style: TextStyle(
              color: const Color(0xFF506D54),
              fontSize: tablet ? 14 : 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCheckIn() {
    final tablet = _isTablet(context);
    final status = _clinicStatus;

    return Container(
      width: double.infinity,
      padding: tablet ? const EdgeInsets.all(20) : const EdgeInsets.all(16),
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
            "If the doctor's geofence isn't working, mark him as arrived or "
            'left here. Patients will see this right away.',
            style: TextStyle(
              color: const Color(0xFF506D54),
              fontSize: tablet ? 14 : 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          for (final location in clinicLocations)
            _buildManualCheckInRow(location, status?[location]),
        ],
      ),
    );
  }

  Widget _buildManualCheckInRow(String location, ClinicAvailability? clinic) {
    final presence = clinic?.presence;
    final isInClinic = presence == ClinicPresence.inClinic;
    final isSaving = _savingPresenceFor == location;
    final (label, color, background) = switch (presence) {
      ClinicPresence.inClinic => (
        'In Clinic',
        const Color(0xFF0F6B2F),
        const Color(0xFFE3F8E3),
      ),
      ClinicPresence.onTheWay => (
        'On the way',
        const Color(0xFF1565C0),
        const Color(0xFFE3EEFB),
      ),
      ClinicPresence.notInClinic => (
        'Not in clinic',
        const Color(0xFFB45309),
        const Color(0xFFFFF1DE),
      ),
      null => ('Loading...', const Color(0xFF999999), const Color(0xFFF2F2F2)),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    color: Color(0xFF1B6F2A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 132,
            height: 38,
            child: isInClinic
                ? OutlinedButton.icon(
                    onPressed: _savingPresenceFor != null
                        ? null
                        : () => _setManualPresence(location, false),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Mark Left'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC41E3A),
                      side: const BorderSide(color: Color(0xFFC41E3A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: presence == null || _savingPresenceFor != null
                        ? null
                        : () => _setManualPresence(location, true),
                    icon: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.how_to_reg, size: 16),
                    label: const Text('Mark Arrived'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6B2F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD5E4D5),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Tablet clinic card: latitude and longitude side by side.
  Widget _buildTabletClinicCard(String clinicName, bool isTracking) {
    final latController = _latControllers[clinicName]!;
    final lonController = _lonControllers[clinicName]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F8E3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF0F6B2F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  clinicName,
                  style: const TextStyle(
                    color: Color(0xFF1B6F2A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CoordinateField(
                  label: 'Target Latitude',
                  controller: latController,
                  confirmedValue: _confirmedLat[clinicName]!,
                  enabled: !isTracking,
                  large: true,
                  onConfirmed: (value) {
                    _confirmedLat[clinicName] = value;
                    _tracker.updateTargetLatitude(clinicName, value);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _CoordinateField(
                  label: 'Target Longitude',
                  controller: lonController,
                  confirmedValue: _confirmedLon[clinicName]!,
                  enabled: !isTracking,
                  large: true,
                  onConfirmed: (value) {
                    _confirmedLon[clinicName] = value;
                    _tracker.updateTargetLongitude(clinicName, value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoCard(String clinicName, bool isTracking) {
    final latController = _latControllers[clinicName]!;
    final lonController = _lonControllers[clinicName]!;

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
        ],
      ),
    );
  }
}

/// Tablet/desktop layouts (wider than 800px) get a centered 1080 container,
/// larger text and the redesigned clinic cards; phones keep their layout.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

class _CoordinateField extends StatefulWidget {
  const _CoordinateField({
    required this.label,
    required this.controller,
    required this.confirmedValue,
    required this.enabled,
    required this.onConfirmed,
    this.large = false,
  });

  final String label;
  final TextEditingController controller;

  /// Bigger label and value text for tablet layouts.
  final bool large;

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
          style: TextStyle(
            color: const Color(0xFF506D54),
            fontSize: widget.large ? 13 : 11,
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
          style: TextStyle(
            color: const Color(0xFF1A3320),
            fontSize: widget.large ? 16 : 13,
          ),
        ),
      ],
    );
  }
}
