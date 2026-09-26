import 'package:flutter/material.dart';
import '../services/notifications/notification_service.dart';
import '../state/app_session.dart';
import '../state/notification_center.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../state/notifications.dart';

IconData _iconForNotification(String title, String type) {
  if (title.contains('Cancelled')) return Icons.event_busy;
  if (title.contains('Completed')) return Icons.check_circle;
  if (title.contains('Rescheduled')) return Icons.calendar_month;
  if (title.contains('Booked')) return Icons.event_available;
  if (title.contains('Being Called')) return Icons.campaign;
  if (title.contains('hour') || title.contains('minutes')) {
    return Icons.access_time;
  }

  switch (type) {
    case 'Reminders':
      return Icons.access_time;
    case 'Announcements':
      return Icons.campaign;
    case 'System':
      return Icons.info;
    default:
      return Icons.notifications_active;
  }
}

Color _colorForNotification(String title, String type) {
  if (title.contains('Cancelled')) return const Color(0xFFE83232);
  if (title.contains('Completed')) return const Color(0xFF0DA94C);
  if (title.contains('Rescheduled')) return const Color(0xFFFFA500);
  if (title.contains('Booked')) return const Color(0xFF16751F);
  if (title.contains('Being Called')) return const Color(0xFF1F5AA2);
  if (title.contains('hour') || title.contains('minutes')) {
    return Colors.orange;
  }

  switch (type) {
    case 'Reminders':
      return Colors.orange;
    case 'Announcements':
      return const Color(0xFF5C28D6);
    case 'System':
      return const Color(0xFF0DA94C);
    default:
      return const Color(0xFFE83232);
  }
}

String _formatNotificationTime(String createdAt) {
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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _showAllNotifications = false;
  List<NotificationModel> _realNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadRealNotifications();
  }

  Future<void> _loadRealNotifications() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      final notifications = await NotificationService.getForUser(userId);
      if (!mounted) return;
      NotificationCenter.updateFromList(notifications);
      setState(() {
        _realNotifications = notifications
            .map(
              (n) => NotificationModel(
                notificationId: n['notification_id'] as int,
                title: n['title'] as String,
                subtitle: n['message'] as String,
                time: _formatNotificationTime(n['created_at'] as String),
                icon: _iconForNotification(
                  n['title'] as String,
                  n['type'] as String,
                ),
                iconColor: _colorForNotification(
                  n['title'] as String,
                  n['type'] as String,
                ),
                type: n['type'] as String,
                targetRoute: n['target_route'] as String?,
                isRead: (n['is_read'] as int? ?? 0) != 0,
              ),
            )
            .toList();
      });
    } catch (_) {
      // Keep showing the local list if the fetch fails.
    }
  }

  void _markRead(NotificationModel notification) {
    final id = notification.notificationId;
    if (id == null || notification.isRead) return;
    NotificationCenter.markRead(id);
    setState(() {
      final index = _realNotifications.indexWhere(
        (n) => n.notificationId == id,
      );
      if (index != -1) {
        final n = _realNotifications[index];
        _realNotifications[index] = NotificationModel(
          notificationId: n.notificationId,
          title: n.title,
          subtitle: n.subtitle,
          time: n.time,
          icon: n.icon,
          iconColor: n.iconColor,
          type: n.type,
          targetRoute: n.targetRoute,
          isRead: true,
        );
      }
    });
  }

  List<NotificationModel> _visibleNotifications() {
    final combined = _realNotifications;
    if (_showAllNotifications) return combined;
    return combined.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDECD9),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.menu,
      ),

      body: SafeArea(
        child: ListView(
          children: [
            const SmartCareDashboardHeader(
              title: "Notifications",
              subtitle:
                  "Stay updated with important announcements, reminders, and alerts.",
            ),

            // ================= BODY =================
            Container(
              width: double.infinity,
              color: const Color(0xFFDDECD9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

              child: Column(
                children: [
                  // ================= NOTIFICATIONS LIST =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          color: Color(0xFF1B6F2A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllNotifications = !_showAllNotifications;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF16751F),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: Text(
                          _showAllNotifications ? "View Less >" : "View All >",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._visibleNotifications().asMap().entries.map((entry) {
                    int index = entry.key;
                    NotificationModel notification = entry.value;
                    return Column(
                      children: [
                        _NotificationListItem(
                          title: notification.title,
                          subtitle: notification.subtitle,
                          time: notification.time,
                          icon: notification.icon,
                          iconColor: notification.iconColor,
                          isUnread: !notification.isRead,
                          onTap: () {
                            _markRead(notification);
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text(notification.title),
                                content: Text(notification.subtitle),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (index < _visibleNotifications().length - 1)
                          const SizedBox(height: 14),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  const _NotificationListItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isUnread = false,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isUnread ? const Color(0xFFF0FAF0) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUnread) ...[
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
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF146F1B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A9B76),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFFA2C989),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
