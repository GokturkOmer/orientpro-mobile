import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/announcement.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

// State
class AnnouncementState {
  final List<Announcement> announcements;
  final int unreadCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  AnnouncementState({
    this.announcements = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  AnnouncementState copyWith({
    List<Announcement>? announcements,
    int? unreadCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Notifier
class AnnouncementNotifier extends Notifier<AnnouncementState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  AnnouncementState build() {
    return AnnouncementState();
  }

  static const _pageSize = 20;

  Future<void> loadAnnouncements(String userId, {String? department}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{'user_id': userId, 'limit': _pageSize, 'offset': 0};
      if (department != null) params['department'] = department;
      final resp = await _dio.get('/announcements/', queryParameters: params);
      final items = (resp.data as List).map((j) => Announcement.fromJson(j)).toList();
      state = state.copyWith(announcements: items, isLoading: false, hasMore: items.length >= _pageSize);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadMoreAnnouncements(String userId, {String? department}) async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final params = <String, dynamic>{
        'user_id': userId,
        'limit': _pageSize,
        'offset': state.announcements.length,
      };
      if (department != null) params['department'] = department;
      final resp = await _dio.get('/announcements/', queryParameters: params);
      final newItems = (resp.data as List).map((j) => Announcement.fromJson(j)).toList();
      state = state.copyWith(
        announcements: [...state.announcements, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length >= _pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> loadUnreadCount(String userId, {String? department}) async {
    try {
      final params = <String, dynamic>{};
      if (department != null) params['department'] = department;
      final resp = await _dio.get('/announcements/unread-count/$userId', queryParameters: params);
      state = state.copyWith(unreadCount: resp.data['unread_count'] ?? 0);
    } catch (_) {}
  }

  Future<bool> markAsRead(String announcementId, String userId) async {
    try {
      await _dio.post('/announcements/$announcementId/read?user_id=$userId');
      // Listeyi guncelle
      final updated = state.announcements.map((a) {
        if (a.id == announcementId) {
          return Announcement.fromJson({
            ...{
              'id': a.id, 'title': a.title, 'body': a.body,
              'priority': a.priority, 'is_pinned': a.isPinned,
              'target_department': a.targetDepartment,
              'attachments': a.attachments, 'created_by': a.createdBy,
              'is_active': a.isActive, 'published_at': a.publishedAt,
              'expires_at': a.expiresAt, 'created_at': a.createdAt,
              'updated_at': a.updatedAt,
              'is_read': true,
              'read_count': (a.readCount ?? 0) + 1,
            },
          });
        }
        return a;
      }).toList();
      state = state.copyWith(
        announcements: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String body,
    required String createdBy,
    String priority = 'normal',
    bool isPinned = false,
    String? targetDepartment,
  }) async {
    try {
      await _dio.post('/announcements/', data: {
        'title': title,
        'body': body,
        'priority': priority,
        'is_pinned': isPinned,
        'target_department': targetDepartment,
        'created_by': createdBy,
      });
      await loadAnnouncements(createdBy);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> updateAnnouncement(String announcementId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/announcements/$announcementId', data: data);
      // Listeyi yenile
      final currentUser = state.announcements.isNotEmpty ? state.announcements.first.createdBy : '';
      if (currentUser.isNotEmpty) await loadAnnouncements(currentUser);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      await _dio.delete('/announcements/$announcementId');
      state = state.copyWith(
        announcements: state.announcements.where((a) => a.id != announcementId).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }
}

// Provider
final announcementProvider = NotifierProvider<AnnouncementNotifier, AnnouncementState>(AnnouncementNotifier.new);
