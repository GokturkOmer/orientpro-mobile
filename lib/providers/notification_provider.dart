import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_dio.dart';
import '../models/notification_model.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) => NotificationState(
    notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount,
    isLoading: isLoading ?? this.isLoading,
  );
}

class NotificationNotifier extends Notifier<NotificationState> {
  Timer? _refreshTimer;

  @override
  NotificationState build() {
    // Auto-refresh: her 60 saniyede unread count güncelle
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => refreshUnreadCount());

    ref.onDispose(() => _refreshTimer?.cancel());

    // Ilk yükleme
    Future.microtask(() => refreshUnreadCount());
    return const NotificationState();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(authDioProvider);
      final res = await dio.get('/notifications/', queryParameters: {'limit': 50});
      final list = (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final dio = ref.read(authDioProvider);
      final res = await dio.get('/notifications/count');
      state = state.copyWith(unreadCount: res.data['unread'] ?? 0);
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.put('/notifications/$id/read');
      // Lokal güncelle
      final updated = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return AppNotification(
            id: n.id, title: n.title, message: n.message,
            category: n.category, severity: n.severity, source: n.source,
            isRead: true, createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.put('/notifications/read-all');
      final updated = state.notifications.map((n) => AppNotification(
        id: n.id, title: n.title, message: n.message,
        category: n.category, severity: n.severity, source: n.source,
        isRead: true, createdAt: n.createdAt,
      )).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

// Geriye uyumluluk: eski FutureProvider'lari kullanan widget'lar icin
final unreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final count = ref.watch(notificationProvider.select((s) => s.unreadCount));
  return AsyncValue.data(count);
});
