import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'resend_cooldown_exception.dart';

class ForgotPasswordService {
  ForgotPasswordService._();

  /* This sends a 4 digit code to the given email so the user can reset
  their password. It is also used to send the code again if the user
  did not get it. If the backend says to wait before sending again (this
  happens if the user asks too many times too fast), it throws a
  ResendCooldownException that tells the screen how many seconds are
  left to wait. If no account uses that email, it throws a normal error.
  When it works, it returns how many seconds the code will stay valid
  for, so the screen can show a countdown. */
  static Future<int> sendResetCode(String email) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/send_password_reset_code.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

  /* This checks if the code the user typed matches the code that was
  emailed to them, and that it has not expired yet (codes expire after a
  few minutes). If the code is correct and still valid, the backend
  changes the account's password to newPassword. If the code is wrong,
  expired, or was never sent, this throws an error explaining why. */
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/reset_password.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
