import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in user's session on-device so the app can restore
/// it on the next launch, without needing a backend call.
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyEmail = 'session_email';
  static const _keyFirstName = 'session_first_name';
  static const _keyLastName = 'session_last_name';
  static const _keyRole = 'session_role';

  /* This saves the logged in user's info on the phone itself, using
  SharedPreferences (a simple storage built into the phone, like a small
  file). This way, when the user closes and reopens the app, it can
  remember who was logged in without asking them to log in again. */
  static Future<void> save({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyRole, role);
  }

  /// Returns the saved session, or null if the user is not logged in.
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    if (userId == null) {
      return null;
    }

    return {
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
  }
}
