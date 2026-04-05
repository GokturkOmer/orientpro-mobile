import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/micro_learning.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class MicroLearningState {
  final TodayData? todayData;
  final MicroProgress? progress;
  final MicroQuizResult? lastQuizResult;
  final bool isLoading;
  final String? error;

  MicroLearningState({
    this.todayData,
    this.progress,
    this.lastQuizResult,
    this.isLoading = false,
    this.error,
  });

  MicroLearningState copyWith({
    TodayData? todayData,
    MicroProgress? progress,
    MicroQuizResult? lastQuizResult,
    bool? isLoading,
    String? error,
  }) => MicroLearningState(
    todayData: todayData ?? this.todayData,
    progress: progress ?? this.progress,
    lastQuizResult: lastQuizResult ?? this.lastQuizResult,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class MicroLearningNotifier extends Notifier<MicroLearningState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  MicroLearningState build() => MicroLearningState();

  /// Bugunku mikro-öğrenme kartlarini yükle
  Future<void> loadToday(String userId, {String? mode}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = mode != null ? '?mode=$mode' : '';
      final resp = await _dio.get('/micro-learning/today/$userId$queryParams');
      final data = TodayData.fromJson(resp.data);
      state = state.copyWith(todayData: data, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getMessage(e),
      );
    }
  }

  /// Karti okundu olarak isaretle
  Future<void> markCardRead(String cardId) async {
    try {
      await _dio.post('/micro-learning/card/$cardId/read');
      // Kartlari güncelle
      if (state.todayData != null) {
        final updatedCards = state.todayData!.cards.map((c) {
          if (c.id == cardId) {
            return DripCard(
              id: c.id, moduleId: c.moduleId, cardType: c.cardType,
              dayNumber: c.dayNumber, slot: c.slot, contentAngle: c.contentAngle,
              title: c.title, body: c.body, mediaUrl: c.mediaUrl,
              isRead: true,
            );
          }
          return c;
        }).toList();
        final readCount = updatedCards.where((c) => c.isRead).length;
        state = state.copyWith(
          todayData: TodayData(
            assignment: state.todayData!.assignment,
            cards: updatedCards,
            quizAvailable: readCount >= updatedCards.length && updatedCards.isNotEmpty,
            quizId: state.todayData!.quizId,
            cardsRead: readCount,
            cardsTotal: updatedCards.length,
            encouragement: state.todayData!.encouragement,
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint('Card read error: ${e.message}');
    }
  }

  /// Mikro-öğrenme quizi coz
  Future<MicroQuizResult?> submitQuiz(String assignmentId, Map<String, String> answers) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.post(
        '/micro-learning/quiz/$assignmentId/submit',
        data: {'answers': answers},
      );
      final result = MicroQuizResult.fromJson(resp.data);
      state = state.copyWith(lastQuizResult: result, isLoading: false);
      return result;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getMessage(e),
      );
      return null;
    }
  }

  /// Ilerleme yükle
  Future<void> loadProgress(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/micro-learning/progress/$userId');
      final data = MicroProgress.fromJson(resp.data);
      state = state.copyWith(progress: data, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getMessage(e),
      );
    }
  }

  // ── Yönetici Metodlari ──

  /// Calisanlara modul ata
  Future<bool> assignModules({
    required List<String> moduleIds,
    List<String>? userIds,
    String? departmentCode,
    String? routeId,
    String shiftType = 'A',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/micro-learning/assign', data: {
        'module_ids': moduleIds,
        'shift_type': shiftType,
        'user_ids': ?userIds,
        'department_code': ?departmentCode,
        'route_id': ?routeId,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getMessage(e),
      );
      return false;
    }
  }

  /// Atamayi iptal et
  Future<bool> cancelAssignment(String assignmentId) async {
    try {
      await _dio.delete('/micro-learning/assignments/$assignmentId');
      return true;
    } on DioException catch (e) {
      debugPrint('Cancel assignment error: ${e.message}');
      return false;
    }
  }

  /// Quiz sonuçunu temizle (ekran gecislerinde)
  void clearQuizResult() {
    state = state.copyWith(lastQuizResult: null);
  }
}

final microLearningProvider =
    NotifierProvider<MicroLearningNotifier, MicroLearningState>(
  MicroLearningNotifier.new,
);
