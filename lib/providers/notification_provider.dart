import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_dio.dart';
import '../models/notification_model.dart';

final notificationListProvider = FutureProvider<List<AppNotification>>((ref) async {
  try {
    final dio = ref.read(authDioProvider);
    final res = await dio.get('/notifications/', queryParameters: {'limit': 50});
    return (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final dio = ref.read(authDioProvider);
    final res = await dio.get('/notifications/count');
    return res.data['unread'] ?? 0;
  } catch (e) {
    return 0;
  }
});

class NotificationService {
  final Ref _ref;
  NotificationService(this._ref);

  Future<bool> markAsRead(int id) async {
    try {
      final dio = _ref.read(authDioProvider);
      await dio.put('/notifications/$id/read');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      final dio = _ref.read(authDioProvider);
      await dio.put('/notifications/read-all');
      return true;
    } catch (e) {
      return false;
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
