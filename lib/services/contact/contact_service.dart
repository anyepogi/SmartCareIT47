import 'dart:convert';

import '../api_config.dart';

class ContactService {
  ContactService._();

  /// Sends the Contact Us form; the backend emails it to the clinic.
  /// actorUserId is set when logged in so it's recorded in the audit log.
  static Future<void> sendMessage({
    required String name,
    required String email,
    required String concern,
    int? actorUserId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/contact/send_message.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'name': name,
        'email': email,
        'concern': concern,
        'actor_user_id': actorUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to send your message.');
    }
  }
}
