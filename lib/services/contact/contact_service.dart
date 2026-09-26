import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class ContactService {
  ContactService._();

  /* This sends the Contact Us form (name, email, and the message or
  concern) to the backend, which then emails it to the clinic's support
  address using PHPMailer. If actorUserId is given, it means a logged in
  user sent this, so the backend can record who sent it in the audit
  log. If no one is logged in, it is sent as a guest message using the
  name and email typed in the form. */
  static Future<void> sendMessage({
    required String name,
    required String email,
    required String concern,
    int? actorUserId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/contact/send_message.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
