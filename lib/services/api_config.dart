import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiConfig {
  ApiConfig._();

  /// The backend address picked at build time. Empty for a normal
  /// `flutter run`, which then talks to the local XAMPP server. A release
  /// build for real users points at Hostinger instead:
  ///   flutter build apk --dart-define=API_BASE_URL=https://smartcare-ccs.com
  static const String _buildBaseUrl = String.fromEnvironment('API_BASE_URL');

  /* This tells the app what web address to use when it talks to the PHP
  backend. If the build was given API_BASE_URL (see above), every
  platform uses that, which is how a release build reaches Hostinger
  without editing this file. Otherwise it uses the local XAMPP server:
  the Android emulator can't reach the computer as "localhost", so it
  uses 10.0.2.2, which is the emulator's address for the computer. */
  static String get baseUrl {
    if (_buildBaseUrl.isNotEmpty) return _buildBaseUrl;
    if (kIsWeb) return 'http://localhost/smartcare.1';
    if (Platform.isAndroid) return 'http://10.0.2.2/smartcare.1';
    return 'http://localhost/smartcare.1';
  }

  /// The login token the backend gave at sign in. Sent as the
  /// X-Auth-Token header on every request so the backend knows who is
  /// calling. Set and cleared by SmartCareSession.
  static String? authToken;

  /// Called when the backend rejects the saved token (expired, signed out
  /// elsewhere, or password changed), so the app can send the user back
  /// to the sign in screen. Set in main.dart.
  static void Function()? onUnauthorized;

  /* Every service uses this instead of http.post directly. It always
  sends JSON and the current login token, and if the backend answers
  401 for a request that carried a token, it reports the session as
  expired. Requests without a token (like signing in with a wrong
  password, which is also a 401) are left alone. */
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
