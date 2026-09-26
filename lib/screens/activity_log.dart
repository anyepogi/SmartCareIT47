import 'package:flutter/material.dart';
import '../widgets/smartcare_dashboard_header.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD5E4D5)),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF0F6B2F),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Activity Log',
                    style: TextStyle(
                      color: Color(0xFF1B6F2A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Activity Log Entries
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
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
                  children: [
                    _ActivityLogItem(
                      icon: Icons.login,
                      iconColor: const Color(0xFF0F6B2F),
                      title: 'You entered the clinic area',
                      time: 'Today, 7:58 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.groups,
                      iconColor: const Color(0xFFA4D98D),
                      title: 'Patient Juan Dela Rosa entered the clinic area',
                      time: 'Today, 8:05 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.logout,
                      iconColor: const Color(0xFFFF9800),
                      title: 'Patient Maria Santos exited the clinic area',
                      time: 'Today, 10:12 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.login,
                      iconColor: const Color(0xFF0F6B2F),
                      title: 'You entered the clinic area',
                      time: 'Today, 10:45 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.logout,
                      iconColor: const Color(0xFFFF9800),
                      title: 'Patient Ana Garcia exited the clinic area',
                      time: 'Yesterday, 4:30 PM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.login,
                      iconColor: const Color(0xFF0F6B2F),
                      title: 'You entered the clinic area',
                      time: 'Yesterday, 7:30 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.groups,
                      iconColor: const Color(0xFFA4D98D),
                      title: 'Patient Carlos Lopez entered the clinic area',
                      time: 'Yesterday, 8:15 AM',
                      radius: '200m radius',
                    ),
                    const SizedBox(height: 12),
                    _ActivityLogItem(
                      icon: Icons.logout,
                      iconColor: const Color(0xFFFF9800),
                      title: 'Patient Rosa Santos exited the clinic area',
                      time: 'Yesterday, 2:20 PM',
                      radius: '200m radius',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  const _ActivityLogItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.radius,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String radius;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A3320),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Color(0xFF6E8D73), fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          radius,
          style: const TextStyle(color: Color(0xFF6E8D73), fontSize: 11),
        ),
      ],
    );
  }
}
