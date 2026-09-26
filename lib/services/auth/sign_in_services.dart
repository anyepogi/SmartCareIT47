import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class SignInService {
  SignInService._();

  /* This sends the email and password the user typed to the backend to
  check if they are correct. The backend checks the password against
  the encrypted one saved in the database. If they match, it sends back
  the user's account info (id, name, role, and so on) so the app can log
  them in. If they do not match, it throws an error with a message like
  "Invalid email or password." */
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Invalid email or password.');
    }

    return body['user'] as Map<String, dynamic>;
  }
}
