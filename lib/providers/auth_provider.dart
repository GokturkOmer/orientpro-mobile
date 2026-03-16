import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_helper.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null && token != null;
}

class AuthNotifier extends Notifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));

  @override
  AuthState build() => AuthState();

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response.data['user']);
      final token = response.data['access_token'];
      state = AuthState(user: user, token: token);
      return true;
    } on DioException catch (e) {
      state = AuthState(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }

  Future<bool> validateToken() async {
    final currentToken = state.token;
    if (currentToken == null) return false;
    try {
      final response = await _dio.get('/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $currentToken'}));
      final user = User.fromJson(response.data);
      state = AuthState(user: user, token: currentToken);
      return true;
    } catch (_) {
      state = AuthState();
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
