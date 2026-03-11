import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../models/notification_model.dart';

final notificationListProvider = FutureProvider<List<AppNotification>>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
  final res = await dio.get('/notifications/', queryParameters: {'limit': 50});
  return (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
  final res = await dio.get('/notifications/count');
  return res.data['unread'] ?? 0;
});

class NotificationService {
  static final _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));

  static Future<void> markAsRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  static Future<void> markAllRead() async {
    await _dio.put('/notifications/read-all');
  }
}
