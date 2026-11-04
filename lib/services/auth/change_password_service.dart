import 'dart:convert';

import '../api_config.dart';

class ChangePasswordService {
  ChangePasswordService._();

  /* This changes the logged in user's own password from Settings. The
  backend checks currentPassword first, and the account is taken from
  the login token, so no user id is sent. Other phones signed in to the
  same account are signed out; this one stays signed in. Throws with the
  backend's reason, for example when the current password is wrong. */
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/change_password.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to change password.');
    }
  }
}
