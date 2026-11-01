import 'dart:async';

import 'package:flutter/material.dart';
import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/geofence/geofence_service.dart';
import '../services/geofence/location_tracker.dart';
import '../services/geofence/travel_tracker.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/queue/queue_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../widgets/smartcare_bottom_nav.dart';
import 'serving.dart';

/// "Good morning, Dr. Juan" (or afternoon/evening, by the time of day)
/// when the logged-in doctor's first name is known, falling back to
/// "Good morning, Doctor" otherwise.
String _greetingTitle({required String prefix, required String roleLabel}) {
  final firstName = SmartCareSession.currentUserFirstName;
  final greeting = timeOfDayGreeting();
  return (firstName != null && firstName.isNotEmpty)
      ? "$greeting, $prefix $firstName"
      : "$greeting, $roleLabel";
}

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isInClinic = false;
  String? _currentGeofenceLocation;
  bool _showAllConsultations = false;
  List<Map<String, dynamic>> _queue = [];
  bool _isLoadingQueue = true;
  int _totalBookedCount = 0;

  /// Refreshes the queue every 15 seconds, so a patient the secretary
  /// just sent in shows up without the doctor having to reopen the tab.
  Timer? _queueRefreshTimer;

  /* Today's Consultations only lists the patients the secretary has sent
  to the doctor, plus the one the doctor is seeing now, so the doctor
  sees who is actually ready for them instead of everyone booked today.
  The stat cards above still count the whole day. */
  List<Map<String, dynamic>> get _consultations => _queue
      .where((p) => p['status'] == 'sent_to_doctor' || p['status'] == 'serving')
      .toList();

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(UserRole.doctor);
    _loadQueue();
    _queueRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadQueue(showSpinner: false),
    );
    _loadTotalBooked();
    _loadAvailability();
    final userId = SmartCareSession.currentUserId;
    if (userId != null) {
      AppointmentReminderService.syncAndShowNewNotifications(userId);
      // The ETA keeps reporting in TravelTracker even while this screen is
      // closed; this only restores it after an app restart and refreshes
      // the ETA right away when the doctor comes back to this tab.
      unawaited(TravelTracker.instance.restore(userId));
    }
  }

  Future<void> _loadAvailability() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      final (isAvailable, currentLocation) =
          await GeofenceService.getMyAvailability(userId);
      if (!mounted) return;
      setState(() {
        _isInClinic = isAvailable;
        _currentGeofenceLocation = currentLocation;
      });
    } catch (_) {
      // Leave the toggle at its default (off) if the fetch fails.
    }
  }

  @override
  void dispose() {
    _queueRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoadingQueue = true);
    try {
      final queue = await QueueService.getTodayQueue();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _isLoadingQueue = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingQueue = false);
    }
  }

  /// Every 'booked' appointment regardless of date, not just today's.
  Future<void> _loadTotalBooked() async {
    try {
      final appointments = await AppointmentService.getAllAppointments();
      if (!mounted) return;
      setState(() {
        _totalBookedCount = appointments
            .where((a) => a['status'] == 'booked')
            .length;
      });
    } catch (_) {
      // Leave the count at its last known value.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleClinicStatus() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;

    final nextValue = !_isInClinic;
    setState(() {
      _isInClinic = nextValue;
      // Toggling off clears geofence presence server-side too — turning
      // it back on doesn't mean the doctor is already inside a clinic.
      if (!nextValue) _currentGeofenceLocation = null;
    });

    try {
      await GeofenceService.toggleAvailability(
        userId: userId,
        isAvailable: nextValue,
      );
      // Turning availability back on doesn't move the device, so the GPS
      // stream (which only fires on movement) may never send a fresh
      // reading — without this, a doctor who never left the clinic would
      // stay stuck showing "not in clinic" until they physically moved.
      if (nextValue) {
        unawaited(LocationTracker.instance.resyncCurrentPosition());
      }
      if (!mounted) return;
      _showMessage(
        nextValue
            ? "You're now marked as available."
            : "You're now marked as unavailable.",
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInClinic = !nextValue);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Opens the "Choose Your Destination" sheet and keeps the clinic the
  /// doctor picked.
  Future<void> _chooseTravelDestination() async {
    final current = TravelTracker.instance.destination.value;
    if (current != null) {
      final confirmed = await _confirmTravelAction(
        context,
        title: "Change clinic?",
        message:
            "You're currently heading to $current Clinic. "
            "Do you want to choose a different clinic?",
        confirmLabel: "Change",
      );
      if (!confirmed || !mounted) return;
    }

    // Tablets get a centered dialog; phones keep the bottom sheet.
    final picked = _isTablet(context)
        ? await showDialog<String>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: const Color(0xFFF4FAF2),
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _ChooseDestinationSheet(
                  selected: current,
                  asDialog: true,
                ),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _ChooseDestinationSheet(selected: current),
          );
    if (picked == null || !mounted) return;

    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      await TravelTracker.instance.setDestination(userId, picked);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    _showMessage("Heading to $picked Clinic.");
  }

  Future<void> _clearTravelDestination() async {
    final confirmed = await _confirmTravelAction(
      context,
      title: "Clear destination?",
      message:
          "You will no longer be marked as heading to "
          "${TravelTracker.instance.destination.value} Clinic.",
      confirmLabel: "Clear",
    );
    if (!confirmed || !mounted) return;

    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      await TravelTracker.instance.clear(userId);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    _showMessage("Destination cleared.");
  }

  void _toggleShowAllConsultations() {
    setState(() {
      _showAllConsultations = !_showAllConsultations;
    });
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return "P";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// The queue number being served, out of how many queue numbers that
  /// clinic has given out today, like SO2/5.
  String get _nowServingValue {
    final serving = _queue.where((p) => p['status'] == 'serving');
    if (serving.isEmpty) return "--";
    return nowServingLabel(
      serving.first,
      (serving.first['session_total'] as num?)?.toInt(),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent_to_doctor':
        return 'Sent to Doctor';
      case 'serving':
        return 'With Doctor';
      case 'completed':
        return 'Completed';
      case 'no_show':
        return 'No-Show';
      default:
        return 'Waiting';
    }
  }

  void _openNowServing(BuildContext context) {
    final serving = _queue.where((p) => p['status'] == 'serving');
    if (serving.isEmpty) {
      _showMessage("No patient is currently being served.");
      return;
    }
    _openConsultation(context, serving.first);
  }

  void _openConsultation(BuildContext context, Map<String, dynamic> patient) {
    final waitingList = waitingInLine(_queue, patient)
        .map(
          (p) => {
            'initials': _initialsFor(p['patient_name'] as String),
            'name': p['patient_name'] as String,
            'time': appointmentQueueLabel(p),
          },
        )
        .toList();

    Navigator.of(context)
        .push(
          smartCareRoute(
            transition: SmartCareTransition.subPage,
            builder: (context) => ServingScreen(
              appointmentId: patient['appointment_id'] as int,
              patientUserId: patient['user_id'] as int?,
              patientName: patient['patient_name'] as String,
              referenceNo: patient['reference_no'] as String? ?? '',
              queueLabel: appointmentQueueLabel(patient),
              location: patient['location'] as String,
              status: patient['status'] as String,
              scheduleDate: patient['schedule_date'] as String?,
              waitingPatients: waitingList,
            ),
          ),
        )
        .then((changed) {
          if (changed == true) _loadQueue();
        });
  }

  /// Wraps the Geofencing Status + Doctor Status cards so they rebuild
  /// live off [LocationTracker.instance] whenever tracking is active on
  /// this device — rather than only ever reflecting whatever the backend
  /// happened to return once, at the moment the dashboard first loaded.
  Widget _buildGeofencingSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        LocationTracker.instance.isTracking,
        LocationTracker.instance.insideLocations,
        LocationTracker.instance.distances,
        TravelTracker.instance.destination,
        TravelTracker.instance.eta,
        TravelTracker.instance.isLoadingEta,
        TravelTracker.instance.arrivedAt,
      ]),
      builder: (context, _) {
        final liveTracking = LocationTracker.instance.isTracking.value;
        final liveInside = LocationTracker.instance.insideLocations.value;

        // Live tracking keeps distances fresh on its own; otherwise fall
        // back to the reading TravelTracker took on its last report.
        final destination = TravelTracker.instance.destination.value;
        final eta = TravelTracker.instance.eta.value;
        final travelDistance = destination == null
            ? null
            : liveTracking
            ? LocationTracker.instance.distances.value[destination]
            : eta.localDistanceMeters;
        final hasArrived =
            destination != null &&
            liveTracking &&
            liveInside.contains(destination);

        final currentLocation = liveTracking
            ? (liveInside.isEmpty ? null : liveInside.first)
            : _currentGeofenceLocation;
        final isActuallyInClinic = _isInClinic && currentLocation != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GeofencingStatusCard(
              isActuallyInClinic: isActuallyInClinic,
              currentLocation: currentLocation,
            ),
            const SizedBox(height: 24),
            const _SectionTitle("Doctor Status"),
            const SizedBox(height: 8),
            _DoctorStatusBanner(
              isAvailable: _isInClinic,
              isActuallyInClinic: isActuallyInClinic,
              onToggle: _toggleClinicStatus,
            ),
            const SizedBox(height: 24),
            const _SectionTitle("Doctor Travel"),
            const SizedBox(height: 8),
            _DoctorTravelCard(
              destination: destination,
              distanceMeters: travelDistance,
              serverEtaMinutes: eta.etaMinutes,
              serverDistanceMeters: eta.distanceMeters,
              hasArrived: hasArrived,
              arrivedAt: TravelTracker.instance.arrivedAt.value,
              isLoadingEta: TravelTracker.instance.isLoadingEta.value,
              onRefreshEta: TravelTracker.instance.refresh,
              onChoose: _chooseTravelDestination,
              onClear: _clearTravelDestination,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardBackGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F2E4),
        bottomNavigationBar: const SmartCareBottomNav(
          currentItem: SmartCareBottomItem.home,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Tablets/desktop get a wider 1080 container with 24px side
              // margins; phones keep their original padding and 760 cap.
              final isWide = MediaQuery.sizeOf(context).width > 800;
              final horizontalPadding = isWide
                  ? 24.0
                  : constraints.maxWidth < 380
                  ? 12.0
                  : 16.0;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DashboardHeader(
                    title: _greetingTitle(prefix: "Dr.", roleLabel: "Doctor"),
                    subtitle: "Here's your overview for today.",
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 1080 : 760,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatGrid(
                              stats: [
                                _DashboardStat(
                                  icon: Icons.groups,
                                  value: _queue.length.toString(),
                                  label: "Patients Today",
                                  detail: "Total patients scheduled",
                                  onTap: () {
                                    smartCareGoTo(context, '/doctor-view');
                                  },
                                ),
                                _DashboardStat(
                                  icon: Icons.groups,
                                  value: _queue
                                      .where((p) => p['status'] == 'booked')
                                      .length
                                      .toString(),
                                  label: "In Queue",
                                  detail: "Waiting for consultation",
                                  onTap: () {
                                    smartCareGoTo(context, '/queue');
                                  },
                                ),
                                _DashboardStat(
                                  icon: Icons.medical_services,
                                  value: _nowServingValue,
                                  label: "Now Serving",
                                  detail: "Currently in consultation",
                                  onTap: () => _openNowServing(context),
                                ),
                                _DashboardStat(
                                  icon: Icons.event_available,
                                  value: "$_totalBookedCount",
                                  label: "Total Booked",
                                  detail: "All booked appointments",
                                  onTap: () {
                                    smartCareGoTo(
                                      context,
                                      '/admin-appointments',
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildGeofencingSection(),
                            const SizedBox(height: 20),
                            _SectionHeader(
                              title: "Today's Consultations",
                              actionLabel: _showAllConsultations
                                  ? "View less"
                                  : "View all",
                              onTap: _toggleShowAllConsultations,
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingQueue)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF16751F),
                                  ),
                                ),
                              )
                            else if (_consultations.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD5E4D5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "No patients sent to you yet.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF506D54)),
                                ),
                              )
                            else
                              _ConsultationsCard(
                                children:
                                    (_showAllConsultations
                                            ? _consultations
                                            : _consultations.take(3).toList())
                                        .map((consultation) {
                                          final name =
                                              consultation['patient_name']
                                                  as String;
                                          return _PatientTile(
                                            initials: _initialsFor(name),
                                            name: name,
                                            detail:
                                                "${appointmentQueueLabel(consultation)} • "
                                                "${_statusLabel(consultation['status'] as String)}",
                                            isActive:
                                                consultation['status'] ==
                                                'serving',
                                            onTap: () => _openConsultation(
                                              context,
                                              consultation,
                                            ),
                                            onButtonPressed: () =>
                                                _openConsultation(
                                                  context,
                                                  consultation,
                                                ),
                                          );
                                        })
                                        .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tablet/desktop layouts (wider than 800px) get larger text and roomier
/// cards; phones keep their original sizes.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardHeader(title: title, subtitle: subtitle);
  }
}

class _DoctorStatusBanner extends StatelessWidget {
  const _DoctorStatusBanner({
    required this.isAvailable,
    required this.isActuallyInClinic,
    required this.onToggle,
  });

  /// The doctor's own manual toggle — controls the switch.
  final bool isAvailable;

  /// True only when [isAvailable] AND the doctor's device is currently
  /// detected inside a clinic's geofence — the same condition patients see.
  final bool isActuallyInClinic;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final doctorName = SmartCareSession.currentUserFirstName;
    final displayName = (doctorName != null && doctorName.isNotEmpty)
        ? "Dr. $doctorName"
        : "Doctor";
    final tablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDDF6DD),
                child: Icon(Icons.person, color: Color(0xFF16751F), size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: const Color(0xFF1A3320),
                        fontWeight: FontWeight.bold,
                        fontSize: tablet ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !isAvailable
                          ? "Unavailable"
                          : isActuallyInClinic
                          ? "In Clinic - ready for patients"
                          : "Available - not yet at a clinic",
                      style: TextStyle(
                        color: const Color(0xFF16751F),
                        fontSize: tablet ? 14 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE3EFE1)),
          const SizedBox(height: 8),
          // Availability and status controls
          Row(
            children: [
              _AvailabilityPill(isAvailable: isAvailable),
              const Spacer(),
              Transform.scale(
                scale: 0.86,
                child: Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: const Color(0xFF16751F),
                  activeTrackColor: const Color(0xFFA4D98D),
                  inactiveThumbColor: const Color(0xFF8FA193),
                  inactiveTrackColor: const Color(0xFFDDE8DF),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Short address shown under each clinic name in the destination sheet.
const Map<String, String> _clinicAddresses = {
  'Sta. Rita': '100 C Mariano, San Vicente',
  'Guagua': 'RMC Medical Arts Annex 1, Room 102',
  'Lubao': 'J.P. Rizal St., Sta. Cruz',
};

/// Asks the doctor to confirm a Doctor Travel action.
/// Returns true only when they tap the confirm button.
Future<bool> _confirmTravelAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006B2D),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/* GPS only gives the straight-line distance to the clinic, but roads are
never perfectly straight, so the distance is multiplied by 1.3 to roughly
match the actual road distance. The travel time then assumes an average
speed of 40 km/h on Pampanga roads. This is only an estimate, which is
why the card shows "~" before the time. */
const double _roadDistanceFactor = 1.3;
const double _averageSpeedKmh = 40;

String _formatEta(double straightLineMeters) {
  final roadKm = straightLineMeters * _roadDistanceFactor / 1000;
  final minutes = (roadKm / _averageSpeedKmh * 60).round();
  if (minutes < 1) return "less than 1 min";
  if (minutes < 60) return "$minutes min";
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return remaining == 0 ? "$hours hr" : "$hours hr $remaining min";
}

String _formatDistance(double meters) {
  return meters < 1000
      ? "${meters.round()} m"
      : "${(meters / 1000).toStringAsFixed(1)} km";
}

class _DoctorTravelCard extends StatelessWidget {
  const _DoctorTravelCard({
    required this.destination,
    required this.distanceMeters,
    required this.serverEtaMinutes,
    required this.serverDistanceMeters,
    required this.hasArrived,
    required this.arrivedAt,
    required this.isLoadingEta,
    required this.onRefreshEta,
    required this.onChoose,
    required this.onClear,
  });

  final String? destination;
  final double? distanceMeters;

  /// The backend's driving ETA, the same one patients see. Preferred over
  /// the local guess from [distanceMeters] whenever it is available.
  final int? serverEtaMinutes;
  final int? serverDistanceMeters;
  final bool hasArrived;

  /// The clinic the doctor just arrived at after his destination was
  /// cleared, shown in place of "Select your destination clinic".
  final String? arrivedAt;
  final bool isLoadingEta;
  final VoidCallback? onRefreshEta;
  final VoidCallback onChoose;
  final VoidCallback onClear;

  Widget _buildEtaRow(bool tablet) {
    final String text;
    if (hasArrived) {
      text = "You've arrived";
    } else if (isLoadingEta) {
      text = "Calculating ETA...";
    } else if (serverEtaMinutes != null && serverDistanceMeters != null) {
      final minutes = serverEtaMinutes!;
      final eta = minutes < 60
          ? "$minutes min"
          : minutes % 60 == 0
          ? "${minutes ~/ 60} hr"
          : "${minutes ~/ 60} hr ${minutes % 60} min";
      text =
          "ETA: ~$eta "
          "(${_formatDistance(serverDistanceMeters!.toDouble())} away)";
    } else if (distanceMeters == null) {
      text = "ETA unavailable - turn on location";
    } else {
      text =
          "ETA: ~${_formatEta(distanceMeters!)} "
          "(${_formatDistance(distanceMeters!)} away)";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasArrived ? Icons.check_circle : Icons.schedule,
            color: const Color(0xFF16751F),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF16751F),
                fontSize: tablet ? 14 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onRefreshEta != null && !isLoadingEta && !hasArrived)
            InkWell(
              onTap: onRefreshEta,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.refresh, color: Color(0xFF16751F), size: 18),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDestination = destination != null;
    final justArrived = !hasDestination && arrivedAt != null;
    final tablet = _isTablet(context);
    final chooseButton = ElevatedButton.icon(
      onPressed: onChoose,
      icon: Icon(Icons.location_on, size: tablet ? 20 : 18),
      label: Text(hasDestination ? "Change Clinic" : "Choose Clinic"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16751F),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: tablet ? const EdgeInsets.symmetric(horizontal: 24) : null,
        textStyle: TextStyle(
          fontSize: tablet ? 15 : 13,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tablet ? 22 : 20),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDDF6DD),
                child: Icon(
                  justArrived ? Icons.check_circle : Icons.directions_car,
                  color: const Color(0xFF16751F),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDestination
                          ? "Heading to $destination Clinic"
                          : justArrived
                          ? "You've arrived at $arrivedAt Clinic"
                          : "Select your destination clinic",
                      style: TextStyle(
                        color: const Color(0xFF1A3320),
                        fontWeight: FontWeight.bold,
                        fontSize: tablet ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasDestination
                          ? _clinicAddresses[destination] ?? ''
                          : justArrived
                          ? "Patients with appointments here today were notified."
                          : "Let us know which clinic you're going to today.",
                      style: TextStyle(
                        color: const Color(0xFF506D54),
                        fontSize: tablet ? 14 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDestination)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF879188),
                    size: 20,
                  ),
                  tooltip: "Clear destination",
                ),
              if (tablet) ...[
                const SizedBox(width: 16),
                SizedBox(height: 44, child: chooseButton),
              ],
            ],
          ),
          if (hasDestination) ...[
            const SizedBox(height: 10),
            _buildEtaRow(tablet),
          ],
          // Phones keep the full-width button under a divider; on tablets
          // the button sits at the right end of the row above.
          if (!tablet) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE3EFE1)),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 40, child: chooseButton),
          ],
        ],
      ),
    );
  }
}

/// Lists every clinic as a tappable card. Shown as a bottom sheet on phones
/// and as a centered dialog on tablets. Pops with the chosen clinic's name.
class _ChooseDestinationSheet extends StatelessWidget {
  const _ChooseDestinationSheet({
    required this.selected,
    this.asDialog = false,
  });

  final String? selected;
  final bool asDialog;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!asDialog) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC9DCC8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose Your Destination",
                    style: TextStyle(
                      color: const Color(0xFF16751F),
                      fontSize: asDialog ? 20 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Where are you going today?",
                    style: TextStyle(
                      color: const Color(0xFF506D54),
                      fontSize: asDialog ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            if (asDialog)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF6E8D73)),
                tooltip: "Close",
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        SizedBox(height: asDialog ? 20 : 14),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final clinic in clinicLocations)
                  _DestinationTile(
                    clinic: clinic,
                    address: _clinicAddresses[clinic] ?? '',
                    isSelected: clinic == selected,
                    onTap: () async {
                      final confirmed = await _confirmTravelAction(
                        context,
                        title: "Go to $clinic Clinic?",
                        message:
                            "You will be marked as heading to $clinic "
                            "Clinic (${_clinicAddresses[clinic] ?? ''}).",
                        confirmLabel: "Confirm",
                      );
                      if (!confirmed || !context.mounted) return;
                      Navigator.of(context).pop(clinic);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (asDialog) {
      return Padding(padding: const EdgeInsets.all(24), child: content);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4FAF2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        4 + MediaQuery.paddingOf(context).bottom,
      ),
      child: content,
    );
  }
}

/// A clinic card; the whole card is the button.
class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.clinic,
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final String clinic;
  final String address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isSelected ? const Color(0xFF16751F) : const Color(0xFFDCE9DB),
        width: isSelected ? 1.5 : 1,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF16751F).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF16751F).withValues(alpha: 0.04),
          hoverColor: const Color(0xFF16751F).withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5F4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF16751F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$clinic Clinic",
                        style: const TextStyle(
                          color: Color(0xFF0B4A23),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF16751F),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8FA893),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeofencingStatusCard extends StatelessWidget {
  const _GeofencingStatusCard({
    required this.isActuallyInClinic,
    required this.currentLocation,
  });

  final bool isActuallyInClinic;
  final String? currentLocation;

  @override
  Widget build(BuildContext context) {
    final statusColor = isActuallyInClinic
        ? const Color(0xFF0E8A2C)
        : const Color(0xFF999999);
    final tablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5E4D5)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF16751F), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Geofencing Status",
                      style: TextStyle(
                        color: const Color(0xFF16751F),
                        fontSize: tablet ? 18 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActuallyInClinic
                          ? "You are inside the $currentLocation area"
                          : "You are not inside a clinic area",
                      style: TextStyle(
                        color: const Color(0xFF506D54),
                        fontSize: tablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F8E3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: statusColor, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          isActuallyInClinic ? "Inside" : "Outside",
                          style: TextStyle(
                            color: statusColor,
                            fontSize: tablet ? 14 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoftSquareIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF5F6F63), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF16751F),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFCFEFCD) : const Color(0xFFE8ECE7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF0E8A2C)
                  : const Color(0xFF879188),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isAvailable ? "Available" : "Away",
            style: TextStyle(
              color: isAvailable
                  ? const Color(0xFF16751F)
                  : const Color(0xFF58655B),
              fontSize: _isTablet(context) ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5E4D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF16751F),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, this.size = 58});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE5F4E6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF16751F), size: size * 0.48),
    );
  }
}

class _SoftSquareIcon extends StatelessWidget {
  const _SoftSquareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF16751F), size: 24),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  }) : leadingIcon = null;

  final String title;
  final String actionLabel;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(child: _SectionTitle(title)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF16751F),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(fontSize: _isTablet(context) ? 14 : 12),
          ),
          child: Text("$actionLabel >"),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF1B6F2A),
        fontSize: _isTablet(context) ? 22 : 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<_DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final tablet = _isTablet(context);

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: tablet ? 1.6 : (columns == 4 ? 1.22 : 1.6),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: stats,
        );
      },
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFF1A3320),
        fontSize: tablet ? 18 : 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final detailText = Text(
      detail,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFF6E8D73),
        fontSize: tablet ? 13 : 9,
      ),
    );

    return Container(
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
          : const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE0F4E1),
            child: Icon(icon, color: const Color(0xFF16751F), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shrinks long values like "SO12/30" to fit instead of
                // cutting them off.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF16751F),
                      fontSize: tablet ? 34 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // On narrower tablets the bigger text shrinks to fit rather
                // than being cut off.
                if (tablet)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: labelText,
                  )
                else
                  labelText,
                if (tablet)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: detailText,
                  )
                else
                  detailText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationsCard extends StatelessWidget {
  const _ConsultationsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5E4D5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6B2F).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE3EFE1)),
          ],
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.initials,
    required this.name,
    required this.detail,
    required this.onTap,
    required this.onButtonPressed,
    this.isActive = false,
  });

  final String initials;
  final String name;
  final String detail;
  final VoidCallback onTap;
  final VoidCallback onButtonPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: tablet
              ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF16751F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  initials.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A3320),
                          fontSize: tablet ? 18 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF506D54),
                        fontSize: tablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final spacing = columns == 4 ? 12.0 : 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              height: 82,
              child: _QuickActionTile(action: action),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: action.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.iconColor, size: 28),
              const SizedBox(height: 7),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A3320),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentQueueCard extends StatelessWidget {
  const _CurrentQueueCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _QueueMiniRow(number: "#9", name: "Juan Dela Cruz"),
          const SizedBox(height: 8),
          const _QueueMiniRow(number: "#10", name: "Maria Santos"),
          const SizedBox(height: 8),
          const _QueueMiniRow(number: "#11", name: "Pedro Reyes"),
        ],
      ),
    );
  }
}

class _AppointmentRequestsCard extends StatelessWidget {
  const _AppointmentRequestsCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const _SoftIcon(icon: Icons.event_available, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "3",
                  style: TextStyle(
                    color: Color(0xFF16751F),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Pending Requests",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF263A2B), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMiniRow extends StatelessWidget {
  const _QueueMiniRow({required this.number, required this.name});

  final String number;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3EA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF5F6F63),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF263A2B), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _SolidActionButton extends StatelessWidget {
  const _SolidActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16751F),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: filled ? 156 : 136,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF16751F) : Colors.white,
          foregroundColor: const Color(0xFF16751F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: filled ? const Color(0xFF16751F) : const Color(0xFF6CB978),
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFF16751F),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : backgroundColor = Colors.white,
       iconColor = const Color(0xFF16751F);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
}
