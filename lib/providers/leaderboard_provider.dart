import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? department;
  final double completionPercent;
  final int completedModules;
  final int totalModules;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.department,
    required this.completionPercent,
    required this.completedModules,
    required this.totalModules,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Bilinmeyen',
      department: json['department'],
      completionPercent: (json['completion_percent'] ?? json['completionPercent'] ?? 0).toDouble(),
      completedModules: json['completed_modules'] ?? json['completedModules'] ?? 0,
      totalModules: json['total_modules'] ?? json['totalModules'] ?? 0,
    );
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;

  LeaderboardState({this.entries = const [], this.isLoading = false, this.error});

  LeaderboardState copyWith({List<LeaderboardEntry>? entries, bool? isLoading, String? error}) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  LeaderboardState build() => LeaderboardState();

  Future<void> loadLeaderboard(String department) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/team-progress/$department');
      final data = response.data as List;
      final entries = data.map((d) => LeaderboardEntry.fromJson(d)).toList();
      entries.sort((a, b) => b.completionPercent.compareTo(a.completionPercent));
      state = state.copyWith(entries: entries.take(10).toList(), isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Siralama yüklenemedi');
    }
  }
}

final leaderboardProvider = NotifierProvider<LeaderboardNotifier, LeaderboardState>(() => LeaderboardNotifier());
