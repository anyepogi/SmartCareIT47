import 'dart:convert';

import '../api_config.dart';
import 'resend_cooldown_exception.dart';

class SignUpService {
  SignUpService._();

  /// Sign up step 1: sends the form and emails a 4 digit code. The account
  /// isn't created yet. Also used for resend. Returns how many seconds the
  /// code is valid; throws ResendCooldownException if asked again too soon.
  static Future<int> sendVerificationCode({
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
    required String email,
    required String password,
    required String phone,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/send_verification_code.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 429) {
      throw ResendCooldownException(
        body['message'] ?? 'Please wait before requesting another code.',
        (body['resend_wait_seconds'] as num?)?.toInt() ?? 120,
      );
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to send verification code.');
    }

    return (body['expires_in_seconds'] as num?)?.toInt() ?? 300;
  }

  /// Sign up step 2: checks the code and creates the account. Returns the
  /// new account's info, or throws if the code is wrong or expired.
  static Future<Map<String, dynamic>> verifyAndRegister({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/register.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'email': email, 'code': code}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create account.');
    }

    return body['user'] as Map<String, dynamic>;
  }
}
