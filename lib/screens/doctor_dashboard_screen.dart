import 'dart:async';

import 'package:flutter/material.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/geofence/geofence_service.dart';
import '../services/geofence/location_tracker.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/queue/queue_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../widgets/smartcare_bottom_nav.dart';
import 'serving.dart';

/// "Good morning, Dr. Juan" when the logged-in doctor's first name is known,
/// falling back to "Good morning, Doctor" otherwise.
String _greetingTitle({required String prefix, required String roleLabel}) {
  final firstName = SmartCareSession.currentUserFirstName;
  return (firstName != null && firstName.isNotEmpty)
      ? "Good morning, $prefix $firstName"
      : "Good morning, $roleLabel";
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

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(UserRole.doctor);
    _loadQueue();
    _loadTotalBooked();
    _loadAvailability();
    final userId = SmartCareSession.currentUserId;
    if (userId != null) {
      AppointmentReminderService.syncAndShowNewNotifications(userId);
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

  String get _nowServingValue {
    final serving = _queue.where((p) => p['status'] == 'serving');
    if (serving.isEmpty) return "--";
    final ref = serving.first['reference_no'] as String? ?? '';
    if (ref.length < 2) return "--";
    return "#${ref.substring(ref.length - 2)}";
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent_to_doctor':
        return 'Sent to Doctor';
      case 'serving':
        return 'With Doctor';
      case 'completed':
        return 'Completed';
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
    final waitingList = _queue
        .where((p) => p['appointment_id'] != patient['appointment_id'])
        .map(
          (p) => {
            'initials': _initialsFor(p['patient_name'] as String),
            'name': p['patient_name'] as String,
            'time': p['time_slot'] as String,
          },
        )
        .toList();

    Navigator.of(context)
        .push(
          smartCareRoute(
            transition: SmartCareTransition.subPage,
            builder: (context) => ServingScreen(
              appointmentId: patient['appointment_id'] as int,
              patientUserId: patient['user_id'] as int,
              patientName: patient['patient_name'] as String,
              referenceNo: patient['reference_no'] as String? ?? '',
              timeSlot: patient['time_slot'] as String,
              location: patient['location'] as String,
              status: patient['status'] as String,
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
      ]),
      builder: (context, _) {
        final liveTracking = LocationTracker.instance.isTracking.value;
        final liveInside = LocationTracker.instance.insideLocations.value;

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
            const SizedBox(height: 16),
            const _SectionTitle("Doctor Status"),
            const SizedBox(height: 12),
            _DoctorStatusBanner(
              isAvailable: _isInClinic,
              isActuallyInClinic: isActuallyInClinic,
              onToggle: _toggleClinicStatus,
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
              final horizontalPadding = constraints.maxWidth < 380
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
                        constraints: const BoxConstraints(maxWidth: 760),
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
                            const SizedBox(height: 16),
                            _buildGeofencingSection(),
                            const SizedBox(height: 16),
                            _SectionHeader(
                              title: "Today's Consultations",
                              actionLabel: _showAllConsultations
                                  ? "View less"
                                  : "View all",
                              onTap: _toggleShowAllConsultations,
                            ),
                            const SizedBox(height: 12),
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
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD5E4D5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "No patients scheduled today.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF506D54)),
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
                                                "${consultation['time_slot']} • "
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
                      style: const TextStyle(
                        color: Color(0xFF1A3320),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !isAvailable
                          ? "Unavailable"
                          : isActuallyInClinic
                          ? "In Clinic - ready for patients"
                          : "Available - not yet at a clinic",
                      style: const TextStyle(
                        color: Color(0xFF16751F),
                        fontSize: 11,
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
                    const Text(
                      "Geofencing Status",
                      style: TextStyle(
                        color: Color(0xFF16751F),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActuallyInClinic
                          ? "You are inside the $currentLocation area"
                          : "You are not inside a clinic area",
                      style: const TextStyle(
                        color: Color(0xFF506D54),
                        fontSize: 12,
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
                            fontSize: 11,
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
              fontSize: 12,
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
            textStyle: const TextStyle(fontSize: 12),
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
      style: const TextStyle(
        color: Color(0xFF1B6F2A),
        fontSize: 16,
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

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: columns == 4 ? 1.22 : 1.6,
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
    return Container(
      padding: const EdgeInsets.all(10),
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
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF16751F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        style: const TextStyle(
                          color: Color(0xFF1A3320),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF506D54),
                        fontSize: 12,
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
