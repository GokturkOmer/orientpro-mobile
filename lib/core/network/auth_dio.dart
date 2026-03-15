import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../../providers/auth_provider.dart';

/// Merkezi authenticated Dio provider.
/// Tum provider'lar bu instance'i kullanarak otomatik olarak
/// Authorization header gonderir ve 401 durumunda logout yapar.
final authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.webUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        ref.read(authProvider.notifier).logout();
      }
      handler.next(error);
    },
  ));

  return dio;
});
