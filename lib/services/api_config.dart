import 'package:http/http.dart' as http;

class ApiConfig {
  ApiConfig._();

  /// Optional override, e.g. to test against local XAMPP from the emulator:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2/smartcare.1
  static const String _buildBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Backend URL. Uses API_BASE_URL if it was set, otherwise Hostinger.
  static String get baseUrl {
    if (_buildBaseUrl.isNotEmpty) return _buildBaseUrl;

    return 'https://smartcare-ccs.com';

    ///return 'http://10.0.2.2/smartcare.1';
  }

  /// Login token from sign in, sent as X-Auth-Token on every request.
  /// Set and cleared by SmartCareSession.
  static String? authToken;

  /// Runs when the backend rejects the token (expired, logged out, or
  /// password changed). Set in main.dart to go back to sign in.
  static void Function()? onUnauthorized;

  /// POST with a JSON body and the login token. A 401 on a request that had
  /// a token means the session expired. A 401 without a token (like a wrong
  /// password on sign in) is left for the caller to handle.
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = authToken;
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
        'X-Auth-Token': ?token,
      },
      body: body,
    );
    if (response.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
    return response;
  }
}
