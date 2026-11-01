import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiConfig {
  ApiConfig._();

  /// Set only for release builds:
  ///   flutter build apk --dart-define=API_BASE_URL=https://smartcare-ccs.com
  /// Empty on a normal `flutter run`, so the app uses local XAMPP.
  static const String _buildBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Backend URL. Uses API_BASE_URL if it was set, otherwise local XAMPP.
  /// The Android emulator reaches the PC through 10.0.2.2, not localhost.
  static String get baseUrl {
    if (_buildBaseUrl.isNotEmpty) return _buildBaseUrl;
    if (kIsWeb) return 'http://localhost/smartcare.1';
    if (Platform.isAndroid) return 'http://10.0.2.2/smartcare.1';
    return 'http://localhost/smartcare.1';
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
