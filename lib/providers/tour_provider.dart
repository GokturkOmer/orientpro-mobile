import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour.dart';
import '../core/network/auth_dio.dart';

final tourRoutesProvider = FutureProvider<List<TourRoute>>((ref) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/tours/routes');
  return (res.data as List).map((e) => TourRoute.fromJson(e)).toList();
});

final tourRouteDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, routeId) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/tours/routes/$routeId');
  return res.data;
});

final activeSessionProvider = FutureProvider.family<TourSession?, String>((ref, userId) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/tours/sessions/active', queryParameters: {'user_id': userId});
  if (res.data == null) return null;
  return TourSession.fromJson(res.data);
});

final sessionDetailProvider = FutureProvider.family<TourSession, int>((ref, sessionId) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/tours/sessions/$sessionId');
  return TourSession.fromJson(res.data);
});

class TourService {
  final Ref _ref;
  TourService(this._ref);

  Future<TourSession> startSession(int routeId, String userId) async {
    final dio = _ref.read(authDioProvider);
    final res = await dio.post('/tours/sessions/start', queryParameters: {'route_id': routeId, 'user_id': userId});
    return TourSession.fromJson(res.data);
  }

  Future<ScanResult> scanCheckpoint(int sessionId, String qrCode, {String status = 'ok', String? notes}) async {
    final dio = _ref.read(authDioProvider);
    final res = await dio.post('/tours/sessions/$sessionId/scan', queryParameters: {
      'qr_code': qrCode, 'status': status, if (notes != null) 'notes': notes,
    });
    return ScanResult.fromJson(res.data);
  }

  Future<void> skipCheckpoint(int sessionId, int checkpointId, String reason) async {
    final dio = _ref.read(authDioProvider);
    await dio.post('/tours/sessions/$sessionId/skip', queryParameters: {
      'checkpoint_id': checkpointId, 'reason': reason,
    });
  }

  Future<Map<String, dynamic>> completeSession(int sessionId, {String? notes}) async {
    final dio = _ref.read(authDioProvider);
    final res = await dio.put('/tours/sessions/$sessionId/complete', queryParameters: {
      if (notes != null) 'notes': notes,
    });
    return res.data;
  }

  Future<void> cancelSession(int sessionId) async {
    final dio = _ref.read(authDioProvider);
    await dio.put('/tours/sessions/$sessionId/cancel');
  }
}

final tourServiceProvider = Provider<TourService>((ref) {
  return TourService(ref);
});
