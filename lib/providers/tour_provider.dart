import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour.dart';
import '../core/network/auth_dio.dart';

final tourRoutesProvider = FutureProvider<List<TourRoute>>((ref) async {
  try {
    final dio = ref.read(authDioProvider);
    final res = await dio.get('/tours/routes');
    return (res.data as List).map((e) => TourRoute.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final tourRouteDetailProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, routeId) async {
  try {
    final dio = ref.read(authDioProvider);
    final res = await dio.get('/tours/routes/$routeId');
    return res.data;
  } catch (e) {
    return null;
  }
});

final sessionDetailProvider = FutureProvider.family<TourSession?, int>((ref, sessionId) async {
  try {
    final dio = ref.read(authDioProvider);
    final res = await dio.get('/tours/sessions/$sessionId');
    return TourSession.fromJson(res.data);
  } catch (e) {
    return null;
  }
});

class TourService {
  final Ref _ref;
  TourService(this._ref);

  Future<TourSession?> startSession(int routeId, String userId) async {
    try {
      final dio = _ref.read(authDioProvider);
      final res = await dio.post('/tours/sessions/start', queryParameters: {'route_id': routeId, 'user_id': userId});
      return TourSession.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  Future<ScanResult?> scanCheckpoint(int sessionId, String qrCode, {String status = 'ok', String? notes}) async {
    try {
      final dio = _ref.read(authDioProvider);
      final res = await dio.post('/tours/sessions/$sessionId/scan', queryParameters: {
        'qr_code': qrCode, 'status': status, if (notes != null) 'notes': notes,
      });
      return ScanResult.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> skipCheckpoint(int sessionId, int checkpointId, String reason) async {
    try {
      final dio = _ref.read(authDioProvider);
      await dio.post('/tours/sessions/$sessionId/skip', queryParameters: {
        'checkpoint_id': checkpointId, 'reason': reason,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> completeSession(int sessionId, {String? notes}) async {
    try {
      final dio = _ref.read(authDioProvider);
      final res = await dio.put('/tours/sessions/$sessionId/complete', queryParameters: {
        if (notes != null) 'notes': notes,
      });
      return res.data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelSession(int sessionId) async {
    try {
      final dio = _ref.read(authDioProvider);
      await dio.put('/tours/sessions/$sessionId/cancel');
      return true;
    } catch (e) {
      return false;
    }
  }
}

final tourServiceProvider = Provider<TourService>((ref) {
  return TourService(ref);
});
