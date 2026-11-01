import 'dart:convert';

import '../api_config.dart';

class NotificationService {
  NotificationService._();

  /// Saves a notification for a user. It shows in their Notifications list,
  /// and as a phone notification the next time their app syncs.
  static Future<void> create({
    required int userId,
    required String title,
    required String message,
    String type = 'Alerts',
    String? targetRoute,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/create.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'target_route': targetRoute,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create notification.');
    }
  }

  /// Marks a notification as read, which lowers the unread badge.
  static Future<void> markRead(int notificationId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/notifications/mark_read.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'notification_id': notificationId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to mark notification read.');
    }
  }

  static Future<List<Map<String, dynamic>>> getForUser(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/get.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load notifications.');
    }

    return List<Map<String, dynamic>>.from(body['notifications'] as List);
  }
}
