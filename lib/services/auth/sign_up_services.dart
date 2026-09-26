import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'resend_cooldown_exception.dart';

class SignUpService {
  SignUpService._();

  /* This is the first step of signing up. It sends all the form info
  (name, birthday, gender, email, password, phone) to the backend, and
  the backend emails a 4 digit code to that address. The backend does
  not create the account yet, it just saves the form info for a few
  minutes while it waits for the code to be typed back in. This same
  function is also used to resend the code if the user did not get it.
  If they ask for a new code too fast, it throws a ResendCooldownException
  so the screen can show how long to wait. */
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

  /* This is the second and last step of signing up. It sends the code
  the user typed back to the backend. If it matches the code that was
  emailed and it has not expired, the backend now actually creates the
  account using the form info it saved earlier, and returns the new
  account's info. If the code is wrong or expired, it throws an error
  and no account gets created. */
  static Future<Map<String, dynamic>> verifyAndRegister({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/register.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create account.');
    }

    return body['user'] as Map<String, dynamic>;
  }
}
