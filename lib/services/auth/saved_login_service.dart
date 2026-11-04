import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the email and password from a "Remember me" sign-in so the
/// sign-in form can be filled in automatically next time.
class SavedLoginService {
  SavedLoginService._();

  static const _keyEmail = 'saved_login_email';
  static const _keyPassword = 'saved_login_password';

  /* The password is stored with FlutterSecureStorage instead of
  SharedPreferences. SharedPreferences is a plain text file, while secure
  storage is encrypted by the phone itself (Keystore on Android, Keychain
  on iOS), so the password can't simply be read off the device. */
  static const _storage = FlutterSecureStorage();

  static Future<void> save({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// Returns the saved email and password, or null if nothing is saved.
  static Future<({String email, String password})?> load() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email == null || password == null) {
        return null;
      }
      return (email: email, password: password);
    } catch (_) {
      // The encrypted data can become unreadable (e.g. after restoring a
      // backup to a new phone). Start fresh instead of crashing.
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }
}
