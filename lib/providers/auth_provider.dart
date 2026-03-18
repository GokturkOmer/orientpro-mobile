import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_helper.dart';
import '../core/storage/secure_storage.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool autoLoginChecked;

  AuthState({this.user, this.token, this.isLoading = false, this.error, this.autoLoginChecked = false});

  bool get isLoggedIn => user != null && token != null;
}

class AuthNotifier extends Notifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));

  @override
  AuthState build() => AuthState();

  /// Login islemi — basarili olursa token ve kullanici bilgisi kalici olarak saklanir
  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true, autoLoginChecked: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response.data['user']);
      final token = response.data['access_token'];

      // Token ve kullanici bilgisini sifrelenmis depolamaya kaydet
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserJson(jsonEncode(user.toJson()));

      state = AuthState(user: user, token: token, autoLoginChecked: true);
      return true;
    } on DioException catch (e) {
      state = AuthState(error: ErrorHelper.getMessage(e), autoLoginChecked: true);
      return false;
    }
  }

  /// Uygulama basladiginda veya arka plandan donuldugunde oturumu geri yukle
  Future<bool> tryAutoLogin() async {
    try {
      final savedToken = await SecureStorage.getToken();
      if (savedToken == null) {
        state = AuthState(autoLoginChecked: true);
        return false;
      }

      // Oncelikle kaydedilmis kullanici bilgisiyle hemen oturumu ac
      final userJson = await SecureStorage.getUserJson();
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, token: savedToken, autoLoginChecked: true);
      }

      // Arka planda token'i sunucudan dogrula
      try {
        final response = await _dio.get('/auth/me',
            options: Options(headers: {'Authorization': 'Bearer $savedToken'}));
        final freshUser = User.fromJson(response.data);
        await SecureStorage.saveUserJson(jsonEncode(freshUser.toJson()));
        state = AuthState(user: freshUser, token: savedToken, autoLoginChecked: true);
        return true;
      } on DioException catch (_) {
        // Token gecersiz — temizle ve login ekranina yonlendir
        await SecureStorage.clearAll();
        state = AuthState(autoLoginChecked: true);
        return false;
      }
    } catch (_) {
      state = AuthState(autoLoginChecked: true);
      return false;
    }
  }

  /// Cikis yap — token ve kullanici bilgisini sil
  Future<void> logout() async {
    final currentToken = state.token;
    // Sunucuya logout bildirimi (basarisiz olursa sorun degil)
    if (currentToken != null) {
      try {
        await _dio.post('/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $currentToken'}));
      } catch (_) {}
    }
    await SecureStorage.clearAll();
    state = AuthState(autoLoginChecked: true);
  }

  Future<bool> validateToken() async {
    final currentToken = state.token;
    if (currentToken == null) return false;
    try {
      final response = await _dio.get('/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $currentToken'}));
      final user = User.fromJson(response.data);
      state = AuthState(user: user, token: currentToken, autoLoginChecked: true);
      return true;
    } catch (_) {
      await SecureStorage.clearAll();
      state = AuthState(autoLoginChecked: true);
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
