import 'package:shared_preferences/shared_preferences.dart';

/// Saves the logged in user on the device so they stay logged in after
/// the app is reopened.
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyEmail = 'session_email';
  static const _keyFirstName = 'session_first_name';
  static const _keyLastName = 'session_last_name';
  static const _keyRole = 'session_role';
  static const _keyToken = 'session_token';

  /// Saves the session in SharedPreferences.
  static Future<void> save({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyToken, token);
  }

  /// The saved session, or null if logged out. Sessions saved by older
  /// versions have no token, so those count as logged out.
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    final token = prefs.getString(_keyToken);
    if (userId == null || token == null || token.isEmpty) {
      return null;
    }

    return {
      'token': token,
      'user_id': userId,
      'email': prefs.getString(_keyEmail) ?? '',
      'first_name': prefs.getString(_keyFirstName) ?? '',
      'last_name': prefs.getString(_keyLastName) ?? '',
      'role': prefs.getString(_keyRole) ?? 'patient',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyToken);
  }
}
