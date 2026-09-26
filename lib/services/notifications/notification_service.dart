import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class NotificationService {
  NotificationService._();

  /* This saves a new notification for a specific user in the database.
  It does not push anything to the user's phone right away, it only
  creates a row that will show up in their in app Notifications list
  and, if their app happens to check for new notifications while it is
  open, a small system notification popup too. */
  static Future<void> create({
    required int userId,
    required String title,
    required String message,
    String type = 'Alerts',
    String? targetRoute,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/create.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

  /* This tells the backend that the user has opened and seen a specific
  notification, so it changes that notification's is_read value to
  true. This is what makes the red unread count badge go down when a
  notification is tapped. */
  static Future<void> markRead(int notificationId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/notifications/mark_read.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notification_id': notificationId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to mark notification read.');
    }
  }

  static Future<List<Map<String, dynamic>>> getForUser(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/get.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load notifications.');
    }

    return List<Map<String, dynamic>>.from(body['notifications'] as List);
  }
}
