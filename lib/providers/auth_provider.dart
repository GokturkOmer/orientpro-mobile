import 'dart:convert';
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

  /// Login islemi — basarili olursa token ve kullanici bilgisi kalici olarak saklanir
  /// Birden fazla organizasyona uyeyse org secim ekrani gosterilir
  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true, autoLoginChecked: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
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
        return true; // login basarili ama org secimi bekliyor
      }

      // Tek org veya org yok — direkt giris
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

  /// Token ve kullanici bilgisini kaydet
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
        // Access token gecersiz — refresh token ile yenilemeyi dene
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Yeni token ile kullanici bilgisini al
          try {
            final response = await _dio.get('/auth/me',
                options: Options(headers: {'Authorization': 'Bearer ${state.token}'}));
            final freshUser = User.fromJson(response.data);
            await SecureStorage.saveUserJson(jsonEncode(freshUser.toJson()));
            state = AuthState(user: freshUser, token: state.token, autoLoginChecked: true);
            return true;
          } catch (_) {}
        }
        // Refresh de basarisiz — temizle ve login ekranina yonlendir
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
