import 'package:flutter/material.dart';
import '../services/notifications/notification_service.dart';
import '../state/app_session.dart';
import '../state/notification_center.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

String _formatActivityTime(String createdAt) {
  final dt = DateTime.tryParse(createdAt);
  if (dt == null) return createdAt;
  final now = DateTime.now();
  final isToday =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final timeStr = "$hour12:$minute $ampm";
  return isToday ? "Today • $timeStr" : "${dt.month}/${dt.day} • $timeStr";
}

IconData _iconForActivityTitle(String title) {
  if (title.contains('Rescheduled')) return Icons.calendar_month;
  if (title.contains('Cancelled')) return Icons.event_busy;
  if (title.contains('Booked')) return Icons.event_available;
  return Icons.event_note;
}

Color _colorForActivityTitle(String title) {
  if (title.contains('Rescheduled')) return const Color(0xFFFFA500);
  if (title.contains('Cancelled')) return const Color(0xFFFF304B);
  if (title.contains('Booked')) return const Color(0xFF146F1B);
  return const Color(0xFF7C3AED);
}

class ActivityLog {
  final int notificationId;
  final String name;
  final String action;
  final String actionType;
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final String role;
  final bool isRead;

  ActivityLog({
    required this.notificationId,
    required this.name,
    required this.action,
    required this.actionType,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.role,
    required this.isRead,
  });
}

class NotificationDoctorNursePage extends StatefulWidget {
  const NotificationDoctorNursePage({super.key});

  @override
  State<NotificationDoctorNursePage> createState() =>
      _NotificationDoctorNursePageState();
}

class _NotificationDoctorNursePageState
    extends State<NotificationDoctorNursePage> {
  String sortBy = 'Newest First';
  List<ActivityLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getForUser(userId);
      if (!mounted) return;
      NotificationCenter.updateFromList(notifications);
      setState(() {
        _logs = notifications.map((n) {
          final title = n['title'] as String;
          return ActivityLog(
            notificationId: n['notification_id'] as int,
            name: 'SmartCare System',
            action: n['message'] as String,
            actionType: 'Appointment',
            timestamp: _formatActivityTime(n['created_at'] as String),
            icon: _iconForActivityTitle(title),
            iconColor: _colorForActivityTitle(title),
            role: SmartCareSession.currentRole.label,
            isRead: (n['is_read'] as int? ?? 0) != 0,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<ActivityLog> getSortedLogs() {
    if (sortBy == 'Oldest First') {
      return _logs.reversed.toList();
    }
    return _logs;
  }

  void _markRead(ActivityLog log) {
    if (log.isRead) return;
    NotificationCenter.markRead(log.notificationId);
    setState(() {
      final index = _logs.indexWhere(
        (l) => l.notificationId == log.notificationId,
      );
      if (index != -1) {
        _logs[index] = ActivityLog(
          notificationId: log.notificationId,
          name: log.name,
          action: log.action,
          actionType: log.actionType,
          timestamp: log.timestamp,
          icon: log.icon,
          iconColor: log.iconColor,
          role: log.role,
          isRead: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.menu,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SmartCareDashboardHeader(
              title: 'Notifications',
              subtitle: 'Stay updated on appointments and clinic activity',
            ),
            // ================= HEADER WITH SORT AND EXPORT =================
            Container(
              width: double.infinity,
              color: const Color(0xFFE8F2E4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFD2E7D1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sort by: ',
                          style: TextStyle(
                            color: Color(0xFF6E8D73),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        PopupMenuButton<String>(
                          initialValue: sortBy,
                          onSelected: (value) {
                            setState(() {
                              sortBy = value;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'Newest First',
                                child: Text('Newest First'),
                              ),
                              const PopupMenuItem(
                                value: 'Oldest First',
                                child: Text('Oldest First'),
                              ),
                            ];
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sortBy,
                                style: const TextStyle(
                                  color: Color(0xFF1A3320),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF1A3320),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ================= ACTIVITY LOG ENTRIES =================
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF16751F)),
                ),
              )
            else if (_logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    "No notifications yet.",
                    style: TextStyle(color: Color(0xFF6E8D73)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final log in getSortedLogs())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityLogCard(
                          log: log,
                          onOpened: () => _markRead(log),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log, required this.onOpened});

  final ActivityLog log;
  final VoidCallback onOpened;

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'Patient Record':
        return const Color(0xFFECF1EE);
      case 'Appointment':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFFFF8E1);
    }
  }

  Color _getActionTypeBadgeColor(String actionType) {
    switch (actionType) {
      case 'Patient Record':
        return const Color(0xFF146F1B);
      case 'Appointment':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFFFA500);
    }
  }

  void _showFullMessage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(log.actionType),
        content: Text(log.action),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: log.isRead ? Colors.white : const Color(0xFFF0FAF0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onOpened();
          _showFullMessage(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: log.isRead ? Colors.white : const Color(0xFFF0FAF0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3EFE1), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A000000),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: log.iconColor.withOpacity(0.15),
                ),
                child: Center(
                  child: Icon(log.icon, color: log.iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and timestamp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!log.isRead) ...[
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF304B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    log.name,
                                    style: const TextStyle(
                                      color: Color(0xFF1A3320),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.action,
                                style: const TextStyle(
                                  color: Color(0xFF6E8D73),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.timestamp,
                          style: const TextStyle(
                            color: Color(0xFF9CB0A0),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getActionTypeColor(log.actionType),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.actionType,
                        style: TextStyle(
                          color: _getActionTypeBadgeColor(log.actionType),
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
      ),
    );
  }
}
