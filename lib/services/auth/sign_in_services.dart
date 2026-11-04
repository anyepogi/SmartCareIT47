import 'dart:convert';

import '../api_config.dart';

class SignInService {
  SignInService._();

  /// Logs in with email and password. Returns the account info, or throws
  /// the backend's message (e.g. "Invalid email or password.").
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'email': email, 'password': password}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Invalid email or password.');
    }

    return body['user'] as Map<String, dynamic>;
  }

  /// Deletes this token on the backend. Errors are ignored since the app
  /// clears its own session anyway. The token is passed in because the
  /// session is usually already cleared when this runs.
  static Future<void> logout(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/logout.php');
    try {
      await ApiConfig.post(uri, headers: {'X-Auth-Token': token});
    } catch (_) {
      // The session is already cleared on this device.
    }
  }
}
