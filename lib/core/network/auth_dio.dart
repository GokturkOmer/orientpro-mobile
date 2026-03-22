import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../../providers/auth_provider.dart';

/// Merkezi authenticated Dio provider.
/// Tum provider'lar bu instance'i kullanarak otomatik olarak
/// Authorization header gonderir ve 401 durumunda once token
/// yenilemeyi dener, basarisiz olursa logout yapar.
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
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Refresh endpoint'ine giden istek zaten 401 aldiysa dongu olmasin
        if (error.requestOptions.path.contains('/auth/refresh')) {
          ref.read(authProvider.notifier).logout();
          handler.next(error);
          return;
        }

        // Token yenilemeyi dene
        final success = await ref.read(authProvider.notifier).refreshAccessToken();
        if (success) {
          // Yeni token ile orijinal istegi tekrarla
          final newToken = ref.read(authProvider).token;
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          try {
            final response = await dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (retryError) {
            if (retryError is DioException) {
              handler.next(retryError);
              return;
            }
          }
        }

        // Refresh basarisiz — logout
        ref.read(authProvider.notifier).logout();
      }
      handler.next(error);
    },
  ));

  return dio;
});
