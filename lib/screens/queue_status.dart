import 'package:flutter/material.dart';

import '../services/appointment/appointment_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

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

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage> {
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;

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
      final appt = await AppointmentService.getUpcoming(userId);
      if (!mounted) return;
      setState(() {
        _appointment = appt;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String get _queueNumber {
    final ref = _appointment?['reference_no'] as String?;
    if (ref == null || ref.length < 2) return "--";
    return ref.substring(ref.length - 2);
  }

  String get _dateTimeLabel {
    final date = _appointment?['schedule_date'] as String?;
    final slot = _appointment?['time_slot'] as String?;
    if (date == null || slot == null) return "";
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return "$date at $slot";
    return "${_monthNames[parsed.month - 1]} ${parsed.day}, ${parsed.year} at $slot";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDECD9),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.queue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SmartCareDashboardHeader(
                title: "Queue Status",
                subtitle:
                    "Track queue updates and monitor appointment status in real time.",
              ),

              // BODY
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF006B2D),
                          ),
                        ),
                      )
                    : _appointment == null
                    ? _buildNoAppointment()
                    : _buildQueueCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAppointment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3DEC4), width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy, color: Color(0xFF14731D), size: 40),
          SizedBox(height: 12),
          Text(
            "You don't have any upcoming appointment.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF146F1B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard() {
    final appointment = _appointment!;
    final total = appointment['total_in_queue']?.toString() ?? "1";

    return Column(
      children: [
        // QUEUE CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC3DEC4), width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // QUEUE NUMBER CIRCLE
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFF14731D),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _queueNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 0),
                        const Text(
                          "Your Queue #",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 0.9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // APPOINTMENT INFO COLUMN
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Your Appointment",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF146F1B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateTimeLabel,
                          style: const TextStyle(
                            color: Color(0xFF146F1B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment['location'] as String,
                          style: const TextStyle(
                            color: Color(0xFF146F1B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // NOTIFICATION BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC3DEC4), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Color(0xFF146F1B),
                      size: 16,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please arrive at least 10 minutes before your scheduled time.",
                        style: TextStyle(
                          color: Color(0xFF146F1B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // INFO GRID
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC3DEC4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _CompactInfoTile(
                  label: "Your Location",
                  value: appointment['location'] as String,
                  icon: Icons.location_on,
                ),
              ),
              Container(height: 60, width: 1, color: const Color(0xFFD0D0D0)),
              Expanded(
                child: _CompactInfoTile(
                  label: "Total in Queue",
                  value: total,
                  icon: Icons.people_outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoTile extends StatelessWidget {
  const _CompactInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  }) : subtitle = null;

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF146F1B), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7A9B76),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF146F1B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A9B76),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}
