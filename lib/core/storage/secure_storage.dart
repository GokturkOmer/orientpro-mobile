import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Şifrelenmis kalici depolama (JWT token, kullanıcı bilgileri)
/// Android: EncryptedSharedPreferences
/// iOS: Keychain
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserJson = 'user_json';
  static const _keyOnboardingSeen = 'onboarding_seen';

  // --- Access Token ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyAccessToken);
  }

  // --- Refresh Token ---
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // --- User JSON (oturum geri yükleme icin) ---
  static Future<void> saveUserJson(String json) async {
    await _storage.write(key: _keyUserJson, value: json);
  }

  static Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }

  // --- Onboarding ---
  static Future<void> markOnboardingSeen() async {
    await _storage.write(key: _keyOnboardingSeen, value: 'true');
  }

  static Future<bool> isOnboardingSeen() async {
    final val = await _storage.read(key: _keyOnboardingSeen);
    return val == 'true';
  }

  // --- Temizle (onboarding flag korunur) ---
  static Future<void> clearAll() async {
    final onboardingSeen = await isOnboardingSeen();
    await _storage.deleteAll();
    if (onboardingSeen) await markOnboardingSeen();
  }
}
