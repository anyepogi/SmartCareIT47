import 'package:flutter/material.dart';
import '../services/queue/queue_service.dart';
import '../services/navigation_transitions.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart'
    show SmartCareBottomNav, SmartCareBottomItem;
import '../widgets/smartcare_dashboard_header.dart';
import 'serving.dart';

String _queueStatusLabel(String status) {
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

Color _queueStatusColor(String status) {
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

class DoctorQueueScreen extends StatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  late DateTime _selectedDate;
  bool _showAllQueue = false;
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;

  String get _dateKey =>
      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(UserRole.doctor);
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
      setState(() => _selectedDate = picked);
      _loadQueue();
    }
  }

  void _toggleShowAllQueue() {
    setState(() => _showAllQueue = !_showAllQueue);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    var initials = '';
    for (final part in parts) {
      if (part.isNotEmpty) initials += part[0].toUpperCase();
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  void _openPatientDetails(Map<String, dynamic> item) {
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

  List<Widget> _buildQueueList() {
    final displayed = _showAllQueue ? _queue : _queue.take(4).toList();
    final children = <Widget>[];

    for (var i = 0; i < displayed.length; i++) {
      final item = displayed[i];
      children.add(
        _QueuePatientRow(
          name: item['patient_name'] as String,
          time: item['time_slot'] as String,
          status: item['status'] as String,
          onTap: () => _openPatientDetails(item),
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
    final pendingCount = _queue.where((p) => p['status'] != 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.queue,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const SmartCareDashboardHeader(
                  title: "Queue Management",
                  subtitle: "Monitor queue and manage appointment flow",
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard(
                            number: "$pendingCount",
                            label: "Not Yet Done",
                            icon: Icons.hourglass_top,
                          ),
                          _StatCard(
                            number: "$completedCount",
                            label: "Completed",
                            icon: Icons.check_circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      // Queue List Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Queue List",
                            style: TextStyle(
                              color: Color(0xFF1B6F2A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleShowAllQueue,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF16751F),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(
                              _showAllQueue ? "View Less >" : "View All >",
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
                          child: Column(children: _buildQueueList()),
                        ),
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
}

class _QueuePatientRow extends StatelessWidget {
  const _QueuePatientRow({
    required this.name,
    required this.time,
    required this.status,
    required this.onTap,
  });

  final String name;
  final String time;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _queueStatusColor(status);
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
                name.isEmpty ? "?" : name.substring(0, 1).toUpperCase(),
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
                    name,
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
                _queueStatusLabel(status),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
  });

  final String number;
  final String label;
  final IconData icon;

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
                  number,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
