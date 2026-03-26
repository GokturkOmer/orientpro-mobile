import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/badge.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class BadgeState {
  final List<BadgeCatalogItem> catalog;
  final List<UserBadge> earnedBadges;
  final List<Map<String, dynamic>> newlyAwarded;
  final bool isLoading;
  final String? error;

  BadgeState({
    this.catalog = const [],
    this.earnedBadges = const [],
    this.newlyAwarded = const [],
    this.isLoading = false,
    this.error,
  });

  Set<String> get earnedCodes => earnedBadges.map((b) => b.badgeCode).toSet();

  BadgeState copyWith({
    List<BadgeCatalogItem>? catalog,
    List<UserBadge>? earnedBadges,
    List<Map<String, dynamic>>? newlyAwarded,
    bool? isLoading,
    String? error,
  }) {
    return BadgeState(
      catalog: catalog ?? this.catalog,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      newlyAwarded: newlyAwarded ?? this.newlyAwarded,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BadgeNotifier extends Notifier<BadgeState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  BadgeState build() => BadgeState();

  Future<void> loadBadges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dio.get('/badges/catalog'),
        _dio.get('/badges/my'),
      ]);

      final catalog = (results[0].data as List).map((d) => BadgeCatalogItem.fromJson(d)).toList();
      final earned = (results[1].data as List).map((d) => UserBadge.fromJson(d)).toList();

      state = state.copyWith(catalog: catalog, earnedBadges: earned, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Rozet verisi yuklenemedi');
    }
  }

  Future<BadgeCheckResult?> checkAndAward() async {
    try {
      final response = await _dio.post('/badges/check');
      final result = BadgeCheckResult.fromJson(response.data);

      if (result.newlyAwarded.isNotEmpty) {
        state = state.copyWith(newlyAwarded: result.newlyAwarded);
        // Yeniden yukle — yeni rozetler DB'ye kaydedildi
        await loadBadges();
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  void clearNewlyAwarded() {
    state = state.copyWith(newlyAwarded: const []);
  }
}

final badgeProvider = NotifierProvider<BadgeNotifier, BadgeState>(() => BadgeNotifier());
