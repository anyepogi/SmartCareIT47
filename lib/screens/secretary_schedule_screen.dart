import 'package:flutter/material.dart';
import '../services/queue/queue_service.dart';
import '../services/navigation_transitions.dart';
import '../widgets/manage_slots_panel.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';
import 'serving.dart';

String _scheduleStatusLabel(String status) {
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

Color _scheduleStatusColor(String status) {
  switch (status) {
    case 'sent_to_doctor':
      return const Color(0xFF7C3AED);
    case 'serving':
      return const Color(0xFF1F5AA2);
    case 'completed':
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFF6B7280);
  }
}

class SecretaryScheduleScreen extends StatefulWidget {
  const SecretaryScheduleScreen({super.key});

  @override
  State<SecretaryScheduleScreen> createState() =>
      _SecretaryScheduleScreenState();
}

class _SecretaryScheduleScreenState extends State<SecretaryScheduleScreen> {
  late DateTime _selectedDate;
  bool _showAllSchedule = false;
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;

  String get _dateKey =>
      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final queue = await QueueService.getTodayQueue(date: _dateKey);
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadQueue();
    }
  }

  void _toggleShowAllSchedule() {
    setState(() {
      _showAllSchedule = !_showAllSchedule;
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    for (final part in parts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  void _openPatientDetails(BuildContext context, Map<String, dynamic> item) {
    final waitingList = _queue
        .where((p) => p['appointment_id'] != item['appointment_id'])
        .map(
          (p) => {
            'initials': _getInitials(p['patient_name'] as String),
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
              appointmentId: item['appointment_id'] as int,
              patientUserId: item['user_id'] as int,
              patientName: item['patient_name'] as String,
              referenceNo: item['reference_no'] as String? ?? '',
              timeSlot: item['time_slot'] as String,
              location: item['location'] as String,
              status: item['status'] as String,
              waitingPatients: waitingList,
            ),
          ),
        )
        .then((changed) {
          if (changed == true) _loadQueue();
        });
  }

  List<Widget> _buildScheduleList() {
    final displayed = _showAllSchedule ? _queue : _queue.take(4).toList();
    final children = <Widget>[];

    for (var i = 0; i < displayed.length; i++) {
      final item = displayed[i];
      children.add(
        _AppointmentCard(
          time: item['time_slot'] as String,
          patient: item['patient_name'] as String,
          status: item['status'] as String,
          onTap: () => _openPatientDetails(context, item),
        ),
      );
      if (i < displayed.length - 1) {
        children.add(
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3EFE1)),
        );
      }
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _queue
        .where((p) => p['status'] == 'completed')
        .length;
    final servingCount = _queue.where((p) => p['status'] == 'serving').length;
    final waitingCount = _queue
        .where(
          (p) => p['status'] == 'booked' || p['status'] == 'sent_to_doctor',
        )
        .length;
    final stillInQueueCount = servingCount + waitingCount;
    final total = _queue.length;
    final completedFraction = total == 0 ? 0.0 : completedCount / total;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.schedule,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const SmartCareDashboardHeader(
                  title: "Schedule",
                  subtitle: "View and manage your daily schedule.",
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          _SummaryCard(
                            icon: Icons.calendar_today,
                            value: "$total",
                            label: "Appointments",
                            detail: "Total scheduled",
                          ),
                          _SummaryCard(
                            icon: Icons.check_circle,
                            value: "$completedCount",
                            label: "Completed",
                            detail: "Finished",
                          ),
                          _SummaryCard(
                            icon: Icons.access_time,
                            value: "$servingCount",
                            label: "With Doctor",
                            detail: "In consultation",
                          ),
                          _SummaryCard(
                            icon: Icons.schedule,
                            value: "$waitingCount",
                            label: "Waiting",
                            detail: "Still in queue",
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD2E7D1),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _selectDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Date",
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                          style: const TextStyle(
                                            color: Color(0xFF1A3320),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.green.shade700,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const ManageSlotsPanel(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Schedule",
                            style: TextStyle(
                              color: Color(0xFF1B6F2A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleShowAllSchedule,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF16751F),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(
                              _showAllSchedule ? "View Less >" : "View All >",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
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
                            border: Border.all(color: const Color(0xFFD5E4D5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "No appointments for this date.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF506D54)),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD5E4D5)),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F6B2F,
                                ).withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(children: _buildScheduleList()),
                        ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Schedule Overview",
                          style: TextStyle(
                            color: Color(0xFF1B6F2A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD5E4D5)),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F6B2F,
                              ).withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: total == 0 ? 0 : completedFraction,
                                      strokeWidth: 14,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF16A34A),
                                      ),
                                      backgroundColor: const Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "$total",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16751F),
                                        ),
                                      ),
                                      const Text(
                                        "Total",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _legendRow(
                                    "Completed",
                                    "$completedCount",
                                    const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(height: 12),
                                  _legendRow(
                                    "Still in Queue",
                                    "$stillInQueueCount",
                                    const Color(0xFFD1D5DB),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3320),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String detail;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.detail,
  });

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
            backgroundColor: const Color(0xFFE8F2E4),
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

class _AppointmentCard extends StatelessWidget {
  final String time;
  final String patient;
  final String status;
  final VoidCallback? onTap;

  const _AppointmentCard({
    required this.time,
    required this.patient,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _scheduleStatusColor(status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                patient.isEmpty ? "?" : patient.substring(0, 1),
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
                  Text(
                    patient,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3320),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _scheduleStatusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
