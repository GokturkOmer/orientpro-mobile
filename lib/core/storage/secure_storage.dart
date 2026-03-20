import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sifrelenmis kalici depolama (JWT token, kullanici bilgileri)
/// Android: EncryptedSharedPreferences
/// iOS: Keychain
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyUserJson = 'user_json';

  // --- Token ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyAccessToken);
  }

  // --- User JSON (oturum geri yukleme icin) ---
  static Future<void> saveUserJson(String json) async {
    await _storage.write(key: _keyUserJson, value: json);
  }

  static Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }

  // --- Temizle ---
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
