import 'package:flutter/material.dart';

import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_dashboard_header.dart';
import 'confirm.dart';

const List<String> _monthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

String _formatDateTime(String isoDate, String timeSlot) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return "$isoDate at $timeSlot";
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year} at $timeSlot";
}

class AllUpcomingAppointmentsScreen extends StatefulWidget {
  const AllUpcomingAppointmentsScreen({super.key});

  @override
  State<AllUpcomingAppointmentsScreen> createState() =>
      _AllUpcomingAppointmentsScreenState();
}

class _AllUpcomingAppointmentsScreenState
    extends State<AllUpcomingAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  int? _cancellingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final appointments = await AppointmentService.getAllUpcoming(userId);
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
      for (final appt in appointments) {
        AppointmentReminderService.scheduleForAppointment(appt);
        AppointmentReminderService.checkAndNotifyIfDue(
          userId: userId,
          appointment: appt,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['appointment_id'] as int;
    setState(() => _cancellingId = appointmentId);
    try {
      await AppointmentService.cancel(appointmentId);
      await AppointmentReminderService.cancelForAppointment(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Appointment cancelled.")));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SmartCareDashboardHeader(
                title: "Upcoming Appointments",
                subtitle: "All of your booked appointments, soonest first.",
                onBack: () => Navigator.of(context).pop(),
              ),
              Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF006B2D)),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "You don't have any upcoming appointments.",
            style: TextStyle(color: Color(0xFF506D54)),
          ),
        ),
      );
    }

    return Column(
      children: _appointments.map((appt) {
        final isCancelling = _cancellingId == appt['appointment_id'];
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB7D7B8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFDDF6DD),
                    child: Icon(
                      Icons.event_available,
                      color: Color(0xFF16751F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(
                            appt['schedule_date'] as String,
                            appt['time_slot'] as String,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1A3320),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appt['location'] as String,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          smartCareRoute(
                            transition: SmartCareTransition.subPage,
                            builder: (_) => AppointmentConfirmScreen(
                              dateTime: _formatDateTime(
                                appt['schedule_date'] as String,
                                appt['time_slot'] as String,
                              ),
                              appointmentId:
                                  appt['reference_no'] as String? ?? '',
                              location: appt['location'] as String,
                              isExistingView: true,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006B2D),
                        side: const BorderSide(color: Color(0xFF006B2D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("View Details"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCancelling ? null : () => _cancel(appt),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isCancelling ? "Cancelling..." : "Cancel"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
