import 'dart:convert';

import '../api_config.dart';

class ChangePasswordService {
  ChangePasswordService._();

  /// Changes the logged in user's password. The account comes from the
  /// login token. Other devices on the account get signed out, this one
  /// stays in. Throws the backend's message (e.g. wrong current password).
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
