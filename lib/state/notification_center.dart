import 'package:flutter/foundation.dart';

import '../services/notifications/notification_service.dart';

/// Tracks the current user's unread notification count so the bell icon
/// badge (in [SmartCareDashboardHeader]) can reflect it live from anywhere
/// in the app, without every screen re-fetching the full notification list.
class NotificationCenter {
  NotificationCenter._();

  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Recomputes the unread count from an already-fetched notification list
  /// (each entry expected to have an `is_read` field of 0 or 1). Called
  /// wherever the full list is already being fetched, so this never
  /// triggers an extra network request on its own.
  static void updateFromList(List<Map<String, dynamic>> notifications) {
    unreadCount.value = notifications
        .where((n) => (n['is_read'] as int? ?? 0) == 0)
        .length;
  }

  /// Marks a single notification as read on the backend and optimistically
  /// decrements the badge immediately, rather than waiting for a refetch.
  static Future<void> markRead(int notificationId) async {
    if (unreadCount.value > 0) unreadCount.value -= 1;
    try {
      await NotificationService.markRead(notificationId);
    } catch (_) {
      // Best-effort — the badge already updated locally; the next full
      // list refresh will self-correct if this particular call failed.
    }
  }

  /// Resets the badge — call this on logout so the next login starts clean
  /// before that user's notifications have been fetched.
  static void reset() {
    unreadCount.value = 0;
  }
}
