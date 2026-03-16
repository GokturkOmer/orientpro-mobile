import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_dio.dart';
import '../models/notification_model.dart';

final notificationListProvider = FutureProvider<List<AppNotification>>((ref) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/notifications/', queryParameters: {'limit': 50});
  return (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/notifications/count');
  return res.data['unread'] ?? 0;
});

class NotificationService {
  final Ref _ref;
  NotificationService(this._ref);

  Future<void> markAsRead(int id) async {
    final dio = _ref.read(authDioProvider);
    await dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    final dio = _ref.read(authDioProvider);
    await dio.put('/notifications/read-all');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
