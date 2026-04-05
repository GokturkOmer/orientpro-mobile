import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_helper.dart';
import '../core/storage/secure_storage.dart';

class OrgInfo {
  final String id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String role;

  OrgInfo({required this.id, required this.name, this.slug, this.logoUrl, required this.role});

  factory OrgInfo.fromJson(Map<String, dynamic> json) => OrgInfo(
    id: json['id'],
    name: json['name'],
    slug: json['slug'],
    logoUrl: json['logo_url'],
    role: json['role'] ?? 'staff',
  );
}

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool autoLoginChecked;
  // Multi-org secimi icin
  final bool requiresOrgSelection;
  final String? tempToken;
  final List<OrgInfo> organizations;

  AuthState({
    this.user, this.token, this.isLoading = false, this.error,
    this.autoLoginChecked = false, this.requiresOrgSelection = false,
    this.tempToken, this.organizations = const [],
  });

  bool get isLoggedIn => user != null && token != null;
}

class AuthNotifier extends Notifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
  bool _isRefreshing = false;

  @override
  AuthState build() => AuthState();

  /// Public kayıt işlemi — başarılı olursa e-posta doğrulama ekranina yonlendirilir
  Future<Map<String, dynamic>> register(String email, String fullName, String password) async {
    state = AuthState(isLoading: true, autoLoginChecked: state.autoLoginChecked);
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': 'staff',
        'department': 'genel',
      });
      state = AuthState(autoLoginChecked: state.autoLoginChecked);
      return {'success': true};
    } on DioException catch (e) {
      final msg = ErrorHelper.getMessage(e);
      state = AuthState(error: msg, autoLoginChecked: state.autoLoginChecked);
      return {'success': false, 'error': msg};
    }
  }

  /// Kurum kaydı — organizasyon + admin kullanıcı oluşturur
  Future<Map<String, dynamic>> registerOrganization(String email, String fullName, String password, String orgName, {String sector = 'hotel'}) async {
    state = AuthState(isLoading: true, autoLoginChecked: state.autoLoginChecked);
    try {
      await _dio.post('/auth/register-organization', data: {
        'email': email,
        'full_name': fullName,
        'password': password,
        'organization_name': orgName,
        'sector': sector,
      });
      state = AuthState(autoLoginChecked: state.autoLoginChecked);
      return {'success': true};
    } on DioException catch (e) {
      final msg = ErrorHelper.getMessage(e);
      state = AuthState(error: msg, autoLoginChecked: state.autoLoginChecked);
      return {'success': false, 'error': msg};
    }
  }

  /// Login işlemi — başarılı olursa token ve kullanıcı bilgisi kalici olarak saklanir
  /// Birden fazla organizasyona uyeyse org secim ekrani gösterilir
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    state = AuthState(isLoading: true, autoLoginChecked: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
      });

      // Multi-org secimi gerekiyorsa
      if (response.data['requires_org_selection'] == true) {
        final orgs = (response.data['organizations'] as List)
            .map((o) => OrgInfo.fromJson(o))
            .toList();
        state = AuthState(
          autoLoginChecked: true,
          requiresOrgSelection: true,
          tempToken: response.data['temp_token'],
          organizations: orgs,
        );
        return true; // login başarılı ama org secimi bekliyor
      }

      // Tek org veya org yok — direkt giriş
      return _handleLoginSuccess(response.data);
    } on DioException catch (e) {
      state = AuthState(error: ErrorHelper.getMessage(e), autoLoginChecked: true);
      return false;
    }
  }

  /// Multi-org seciminden sonra cagrilir
  Future<bool> selectOrganization(String organizationId) async {
    final tempToken = state.tempToken;
    if (tempToken == null) return false;

    state = AuthState(isLoading: true, autoLoginChecked: true);
    try {
      final response = await _dio.post('/auth/select-organization', data: {
        'temp_token': tempToken,
        'organization_id': organizationId,
      });
      return _handleLoginSuccess(response.data);
    } on DioException catch (e) {
      state = AuthState(error: ErrorHelper.getMessage(e), autoLoginChecked: true);
      return false;
    }
  }

  /// Token ve kullanıcı bilgisini kaydet
  Future<bool> _handleLoginSuccess(Map<String, dynamic> data) async {
    final user = User.fromJson(data['user']);
    final token = data['access_token'];
    final refreshToken = data['refresh_token'] as String?;

    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveUserJson(jsonEncode(user.toJson()));

    state = AuthState(user: user, token: token, autoLoginChecked: true);
    return true;
  }

  /// Access token suresi doldugunda refresh token ile yeni token al
  Future<bool> refreshAccessToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String?;

      await SecureStorage.saveToken(newAccessToken);
      if (newRefreshToken != null) {
        await SecureStorage.saveRefreshToken(newRefreshToken);
      }

      state = AuthState(
        user: state.user,
        token: newAccessToken,
        autoLoginChecked: true,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Uygulama basladiginda veya arka plandan donuldugunde oturumu geri yükle
  Future<bool> tryAutoLogin() async {
    try {
      final savedToken = await SecureStorage.getToken();
      if (savedToken == null) {
        state = AuthState(autoLoginChecked: true);
        return false;
      }

      // Oncelikle kaydedilmis kullanıcı bilgisiyle hemen oturumu ac
      final userJson = await SecureStorage.getUserJson();
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, token: savedToken, autoLoginChecked: true);
      }

      // Arka planda token'i sunucudan doğrula
      try {
        final response = await _dio.get('/auth/me',
            options: Options(headers: {'Authorization': 'Bearer $savedToken'}));
        final freshUser = User.fromJson(response.data);
        await SecureStorage.saveUserJson(jsonEncode(freshUser.toJson()));
        state = AuthState(user: freshUser, token: savedToken, autoLoginChecked: true);
        return true;
      } on DioException catch (_) {
        // Access token gecersiz — refresh token ile yenilemeyi dene
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Yeni token ile kullanıcı bilgisini al
          try {
            final response = await _dio.get('/auth/me',
                options: Options(headers: {'Authorization': 'Bearer ${state.token}'}));
            final freshUser = User.fromJson(response.data);
            await SecureStorage.saveUserJson(jsonEncode(freshUser.toJson()));
            state = AuthState(user: freshUser, token: state.token, autoLoginChecked: true);
            return true;
          } catch (e) {
            debugPrint('tryAutoLogin hata: $e');
          }
        }
        // Refresh de başarısız — temizle ve login ekranina yonlendir
        await SecureStorage.clearAll();
        state = AuthState(autoLoginChecked: true);
        return false;
      }
    } catch (_) {
      state = AuthState(autoLoginChecked: true);
      return false;
    }
  }

  /// Çıkış yap — token ve kullanıcı bilgisini sil
  Future<void> logout() async {
    final currentToken = state.token;
    // Sunucuya logout bildirimi (başarısız olursa sorun degil)
    if (currentToken != null) {
      try {
        await _dio.post('/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $currentToken'}));
      } catch (e) {
        debugPrint('logout hata: $e');
      }
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
      // Token gecersiz — refresh dene
      final refreshed = await refreshAccessToken();
      if (refreshed) return true;
      await SecureStorage.clearAll();
      state = AuthState(autoLoginChecked: true);
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
