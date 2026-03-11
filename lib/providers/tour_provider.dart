import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/tour.dart';
import '../core/config/api_config.dart';

final _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl, connectTimeout: const Duration(seconds: 5)));

final tourRoutesProvider = FutureProvider<List<TourRoute>>((ref) async {
  final res = await _dio.get('/tours/routes');
  return (res.data as List).map((e) => TourRoute.fromJson(e)).toList();
});

final tourRouteDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, routeId) async {
  final res = await _dio.get('/tours/routes/$routeId');
  return res.data;
});

final activeSessionProvider = FutureProvider.family<TourSession?, String>((ref, userId) async {
  final res = await _dio.get('/tours/sessions/active', queryParameters: {'user_id': userId});
  if (res.data == null) return null;
  return TourSession.fromJson(res.data);
});

final sessionDetailProvider = FutureProvider.family<TourSession, int>((ref, sessionId) async {
  final res = await _dio.get('/tours/sessions/$sessionId');
  return TourSession.fromJson(res.data);
});

class TourService {
  static Future<TourSession> startSession(int routeId, String userId) async {
    final res = await _dio.post('/tours/sessions/start', queryParameters: {'route_id': routeId, 'user_id': userId});
    return TourSession.fromJson(res.data);
  }

  static Future<ScanResult> scanCheckpoint(int sessionId, String qrCode, {String status = 'ok', String? notes}) async {
    final res = await _dio.post('/tours/sessions/$sessionId/scan', queryParameters: {
      'qr_code': qrCode, 'status': status, if (notes != null) 'notes': notes,
    });
    return ScanResult.fromJson(res.data);
  }

  static Future<void> skipCheckpoint(int sessionId, int checkpointId, String reason) async {
    await _dio.post('/tours/sessions/$sessionId/skip', queryParameters: {
      'checkpoint_id': checkpointId, 'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> completeSession(int sessionId, {String? notes}) async {
    final res = await _dio.put('/tours/sessions/$sessionId/complete', queryParameters: {
      if (notes != null) 'notes': notes,
    });
    return res.data;
  }

  static Future<void> cancelSession(int sessionId) async {
    await _dio.put('/tours/sessions/$sessionId/cancel');
  }
}
