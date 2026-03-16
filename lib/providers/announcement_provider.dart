import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/announcement.dart';
import '../core/network/auth_dio.dart';

// State
class AnnouncementState {
  final List<Announcement> announcements;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  AnnouncementState({this.announcements = const [], this.unreadCount = 0, this.isLoading = false, this.error});

  AnnouncementState copyWith({List<Announcement>? announcements, int? unreadCount, bool? isLoading, String? error}) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
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

  Future<void> loadAnnouncements(String userId, {String? department}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{'user_id': userId};
      if (department != null) params['department'] = department;
      final resp = await _dio.get('/announcements/', queryParameters: params);
      final items = (resp.data as List).map((j) => Announcement.fromJson(j)).toList();
      state = state.copyWith(announcements: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider
final announcementProvider = NotifierProvider<AnnouncementNotifier, AnnouncementState>(AnnouncementNotifier.new);
