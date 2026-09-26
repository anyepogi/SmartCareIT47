import 'package:flutter/material.dart';

class NotificationModel {
  final int? notificationId;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String type; // 'Alerts', 'Reminders', 'Announcements', 'System'
  final String? targetRoute; // route to open when tapped, if any
  final bool isRead;

  NotificationModel({
    this.notificationId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.type,
    this.targetRoute,
    this.isRead = true,
  });
}
