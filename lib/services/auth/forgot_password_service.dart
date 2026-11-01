import 'dart:convert';

import '../api_config.dart';
import 'resend_cooldown_exception.dart';

class ForgotPasswordService {
  ForgotPasswordService._();

  /// Emails a 4 digit reset code (also used for resend). Returns how many
  /// seconds the code is valid. Throws ResendCooldownException if the user
  /// has to wait before asking again.
  static Future<int> sendResetCode(String email) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/send_password_reset_code.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'email': email}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 429) {
      throw ResendCooldownException(
        body['message'] ?? 'Please wait before requesting another code.',
        (body['resend_wait_seconds'] as num?)?.toInt() ?? 120,
      );
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to send reset code.');
    }

    return (body['expires_in_seconds'] as num?)?.toInt() ?? 300;
  }

  /// Checks the emailed code and sets the new password if the code is
  /// correct and not expired. Throws if it's wrong or expired.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/reset_password.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to reset password.');
    }
  }
}
