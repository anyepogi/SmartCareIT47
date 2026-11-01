import 'dart:async';

import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/geofence/geofence_service.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/queue/queue_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/walk_in_dialog.dart';
import 'serving.dart';

/// "Good morning, Sec. Juana" (or afternoon/evening, by the time of day)
/// when the logged-in secretary's first name is known, falling back to
/// "Good morning, Secretary" otherwise.
String _greetingTitle({required String prefix, required String roleLabel}) {
  final firstName = SmartCareSession.currentUserFirstName;
  final greeting = timeOfDayGreeting();
  return (firstName != null && firstName.isNotEmpty)
      ? "$greeting, $prefix $firstName"
      : "$greeting, $roleLabel";
}

class SecretaryDashboardScreen extends StatefulWidget {
  const SecretaryDashboardScreen({super.key});

  @override
  State<SecretaryDashboardScreen> createState() =>
      _SecretaryDashboardScreenState();
}

class _SecretaryDashboardScreenState extends State<SecretaryDashboardScreen> {
  bool _showAllConsultations = false;
  List<Map<String, dynamic>> _queue = [];
  bool _isLoadingQueue = true;
  int _totalBookedCount = 0;

  bool _doctorIsActuallyInClinic = false;
  String? _doctorCurrentLocation;

  /// The clinic the doctor is on the way to, with his ETA and distance,
  /// or null when he isn't travelling to one.
  ClinicAvailability? _doctorOnTheWay;

  /// Reloads the doctor's status every minute, the same rate his phone
  /// reports its position, so the ETA and "Inside" status stay current.
  Timer? _doctorStatusTimer;

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(UserRole.secretary);
    _loadQueue();
    _loadTotalBooked();
    _loadDoctorGeofenceStatus();
    _doctorStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadDoctorGeofenceStatus(),
    );
    final userId = SmartCareSession.currentUserId;
    if (userId != null) {
      AppointmentReminderService.syncAndShowNewNotifications(userId);
    }
  }

  @override
  void dispose() {
    _doctorStatusTimer?.cancel();
    super.dispose();
  }

  /// Whether the clinic's doctor is currently detected inside a clinic
  /// geofence — the same condition patients see. Read from the server so
  /// it's accurate regardless of which device (the doctor's or the
  /// secretary's) is actually driving the tracking.
  Future<void> _loadDoctorGeofenceStatus() async {
    try {
      final doctor = await GeofenceService.getDoctorAccount();
      final (isAvailable, currentLocation) =
          await GeofenceService.getMyAvailability(doctor.userId);
      if (!mounted) return;
      setState(() {
        _doctorIsActuallyInClinic = isAvailable && currentLocation != null;
        _doctorCurrentLocation = currentLocation;
      });
    } catch (_) {
      // Leave the card showing "not in clinic" if this fails.
    }

    // Uses the same status patients see, so the secretary's ETA always
    // matches theirs (she also gets the distance, which patients don't).
    try {
      final status = await GeofenceService.getStatus();
      final onTheWay = status.clinics.values
          .where((c) => c.presence == ClinicPresence.onTheWay)
          .firstOrNull;
      if (!mounted) return;
      setState(() => _doctorOnTheWay = onTheWay);
    } catch (_) {
      // Keep the last ETA shown; the next minute's reload will retry.
    }
  }

  /// Records a walk-in patient, then reloads today's list so a walk-in for
  /// today shows up right away.
  Future<void> _addWalkIn() async {
    final booking = await showWalkInDialog(context);
    if (booking == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Walk-in recorded. Queue number ${booking.queueCode} "
          "(${booking.code}).",
        ),
      ),
    );
    _loadQueue();
    _loadTotalBooked();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoadingQueue = true);
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
<<<<<<< HEAD
              // Tablets/desktop get a wider 1080 container with 24px side
              // margins; phones keep their original padding and 760 cap.
              final isWide = MediaQuery.sizeOf(context).width > 800;
              final horizontalPadding = isWide
                  ? 24.0
                  : constraints.maxWidth < 380
=======
              final horizontalPadding = constraints.maxWidth < 380
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                  ? 12.0
                  : 16.0;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DashboardHeader(
                    title: _greetingTitle(
                      prefix: "Sec.",
                      roleLabel: "Secretary",
                    ),
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
<<<<<<< HEAD
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 1080 : 760,
                        ),
=======
                        constraints: const BoxConstraints(maxWidth: 760),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                            const SizedBox(height: 24),
=======
                            const SizedBox(height: 16),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            _GeofencingStatusCard(
                              isActuallyInClinic: _doctorIsActuallyInClinic,
                              currentLocation: _doctorCurrentLocation,
                              onTheWay: _doctorIsActuallyInClinic
                                  ? null
                                  : _doctorOnTheWay,
                            ),
<<<<<<< HEAD
                            const SizedBox(height: 24),
                            // Full width on phones; a compact right-aligned
                            // button with larger text on tablets.
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: isWide ? 280 : double.infinity,
                                height: isWide ? 50 : 44,
                                child: ElevatedButton.icon(
                                  onPressed: _addWalkIn,
                                  icon: Icon(
                                    Icons.person_add,
                                    size: isWide ? 22 : 18,
                                  ),
                                  label: const Text("Add Walk-in Patient"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16751F),
                                    foregroundColor: Colors.white,
                                    textStyle: isWide
                                        ? const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isWide ? 14 : 10,
                                      ),
                                    ),
=======
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _addWalkIn,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text("Add Walk-in Patient"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16751F),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                                  ),
                                ),
                              ),
                            ),
<<<<<<< HEAD
                            const SizedBox(height: 20),
=======
                            const SizedBox(height: 16),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            _SectionHeader(
                              title: "Today's Consultations",
                              actionLabel: _showAllConsultations
                                  ? "View less"
                                  : "View all",
                              onTap: _toggleShowAllConsultations,
                            ),
<<<<<<< HEAD
                            const SizedBox(height: 4),
=======
                            const SizedBox(height: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            if (_isLoadingQueue)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF16751F),
                                  ),
                                ),
                              )
                            else if (_queue.isEmpty)
                              Container(
                                width: double.infinity,
<<<<<<< HEAD
                                padding: isWide
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 28,
                                      )
                                    : const EdgeInsets.all(20),
=======
                                padding: const EdgeInsets.all(20),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD5E4D5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
<<<<<<< HEAD
                                child: Text(
                                  "No patients scheduled today.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF506D54),
                                    fontSize: isWide ? 15 : null,
                                  ),
=======
                                child: const Text(
                                  "No patients scheduled today.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF506D54)),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                                ),
                              )
                            else
                              _ConsultationsCard(
                                children:
                                    (_showAllConsultations
                                            ? _queue
                                            : _queue.take(3).toList())
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

<<<<<<< HEAD
/// Tablet/desktop layouts (wider than 800px) get larger text and roomier
/// cards; phones keep their original sizes.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardHeader(title: title, subtitle: subtitle);
  }
}

class _GeofencingStatusCard extends StatelessWidget {
  const _GeofencingStatusCard({
    required this.isActuallyInClinic,
    required this.currentLocation,
    this.onTheWay,
  });

  final bool isActuallyInClinic;
  final String? currentLocation;

  /// Set while the doctor is travelling to a clinic, to show his ETA.
  final ClinicAvailability? onTheWay;

  String _etaText(ClinicAvailability clinic) {
    final minutes = clinic.etaMinutes;
    final String eta;
    if (minutes == null) {
      eta = "ETA unavailable";
    } else if (minutes < 60) {
      eta = "ETA: ~$minutes min";
    } else {
      final rest = minutes % 60;
      eta = rest == 0
          ? "ETA: ~${minutes ~/ 60} hr"
          : "ETA: ~${minutes ~/ 60} hr $rest min";
    }
    final km = clinic.distanceKm;
    return km == null ? eta : "$eta ($km km away)";
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = isActuallyInClinic
        ? const Color(0xFF0E8A2C)
        : const Color(0xFF999999);
<<<<<<< HEAD
    final tablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          : const EdgeInsets.all(16),
=======

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                    Text(
                      "Geofencing Status",
                      style: TextStyle(
                        color: const Color(0xFF16751F),
                        fontSize: tablet ? 18 : 15,
=======
                    const Text(
                      "Geofencing Status",
                      style: TextStyle(
                        color: Color(0xFF16751F),
                        fontSize: 15,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActuallyInClinic
                          ? "The doctor is inside the $currentLocation area"
                          : "The doctor is not inside a clinic area",
<<<<<<< HEAD
                      style: TextStyle(
                        color: const Color(0xFF506D54),
                        fontSize: tablet ? 14 : 12,
=======
                      style: const TextStyle(
                        color: Color(0xFF506D54),
                        fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                            fontSize: tablet ? 14 : 11,
=======
                            fontSize: 11,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
          if (onTheWay != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Color(0xFF16751F),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "On the way to ${onTheWay!.location} Clinic",
<<<<<<< HEAD
                          style: TextStyle(
                            color: const Color(0xFF1A3320),
                            fontSize: tablet ? 15 : 12,
=======
                          style: const TextStyle(
                            color: Color(0xFF1A3320),
                            fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _etaText(onTheWay!),
<<<<<<< HEAD
                          style: TextStyle(
                            color: const Color(0xFF16751F),
                            fontSize: tablet ? 14 : 12,
=======
                          style: const TextStyle(
                            color: Color(0xFF16751F),
                            fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
<<<<<<< HEAD
              fontSize: _isTablet(context) ? 14 : 12,
=======
              fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF16751F),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
<<<<<<< HEAD
            textStyle: TextStyle(fontSize: _isTablet(context) ? 14 : 12),
=======
            textStyle: const TextStyle(fontSize: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
      style: TextStyle(
        color: const Color(0xFF1B6F2A),
        fontSize: _isTablet(context) ? 22 : 16,
=======
      style: const TextStyle(
        color: Color(0xFF1B6F2A),
        fontSize: 16,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
        final tablet = _isTablet(context);
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
<<<<<<< HEAD
          childAspectRatio: tablet ? 1.6 : (columns == 4 ? 1.22 : 1.6),
=======
          childAspectRatio: columns == 4 ? 1.22 : 1.6,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
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
=======
    return Container(
      padding: const EdgeInsets.all(10),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                    style: TextStyle(
                      color: const Color(0xFF16751F),
                      fontSize: tablet ? 34 : 20,
=======
                    style: const TextStyle(
                      color: Color(0xFF16751F),
                      fontSize: 20,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
<<<<<<< HEAD
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
=======
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A3320),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF6E8D73), fontSize: 9),
                ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
    final tablet = _isTablet(context);

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
<<<<<<< HEAD
          padding: tablet
              ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
=======
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
                  initials.length > 1
                      ? initials.substring(0, 2)
                      : initials.substring(0, 1),
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
<<<<<<< HEAD
                        style: TextStyle(
                          color: const Color(0xFF1A3320),
                          fontSize: tablet ? 18 : 14,
=======
                        style: const TextStyle(
                          color: Color(0xFF1A3320),
                          fontSize: 14,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
<<<<<<< HEAD
                      style: TextStyle(
                        color: const Color(0xFF506D54),
                        fontSize: tablet ? 14 : 12,
=======
                      style: const TextStyle(
                        color: Color(0xFF506D54),
                        fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
