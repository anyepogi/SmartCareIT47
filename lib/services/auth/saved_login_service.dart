import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Saves the email and password for "Remember me" so the sign in form
/// is filled in next time.
class SavedLoginService {
  SavedLoginService._();

  static const _keyEmail = 'saved_login_email';
  static const _keyPassword = 'saved_login_password';

  // Secure storage instead of SharedPreferences so the password is
  // encrypted (Keystore on Android, Keychain on iOS), not plain text.
  static const _storage = FlutterSecureStorage();

  static Future<void> save({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// The saved email and password, or null if nothing is saved.
  static Future<({String email, String password})?> load() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email == null || password == null) {
        return null;
      }
      return (email: email, password: password);
    } catch (_) {
      // Can't be decrypted anymore (e.g. a backup restored on a new phone),
      // so just clear it.
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }
}
