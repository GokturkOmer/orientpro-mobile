import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/training.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

// Module info for progress lookup
class ModuleInfo {
  final String id;
  final String title;
  final String routeId;
  final String departmentId;
  final String moduleType;
  final int estimatedMinutes;

  ModuleInfo({required this.id, required this.title, required this.routeId, required this.departmentId, required this.moduleType, required this.estimatedMinutes});
}

// State
class TrainingState {
  final List<Department> departments;
  final List<TrainingRoute> routes;
  final TrainingRoute? selectedRoute;
  final TrainingModule? selectedModule;
  final List<QuizQuestion> quizQuestions;
  final List<QuizListItem> quizList;
  final List<QuizResult> quizResults;
  final List<UserProgress> progress;
  final TrainingStats? stats;
  final bool isLoading;
  final String? error;

  // Progress screen state
  final Map<String, ModuleInfo> moduleMap;
  final List<TeamMemberProgress> teamProgress;
  final DashboardSummary? dashboardSummary;
  final List<TrainingReminder> reminders;
  final int reviewCount;

  TrainingState({
    this.departments = const [],
    this.routes = const [],
    this.selectedRoute,
    this.selectedModule,
    this.quizQuestions = const [],
    this.quizList = const [],
    this.quizResults = const [],
    this.progress = const [],
    this.stats,
    this.isLoading = false,
    this.error,
    this.moduleMap = const {},
    this.teamProgress = const [],
    this.dashboardSummary,
    this.reminders = const [],
    this.reviewCount = 0,
  });

  TrainingState copyWith({
    List<Department>? departments,
    List<TrainingRoute>? routes,
    TrainingRoute? selectedRoute,
    TrainingModule? selectedModule,
    List<QuizQuestion>? quizQuestions,
    List<QuizListItem>? quizList,
    List<QuizResult>? quizResults,
    List<UserProgress>? progress,
    TrainingStats? stats,
    bool? isLoading,
    String? error,
    Map<String, ModuleInfo>? moduleMap,
    List<TeamMemberProgress>? teamProgress,
    DashboardSummary? dashboardSummary,
    List<TrainingReminder>? reminders,
    int? reviewCount,
  }) {
    return TrainingState(
      departments: departments ?? this.departments,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      selectedModule: selectedModule ?? this.selectedModule,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      quizList: quizList ?? this.quizList,
      quizResults: quizResults ?? this.quizResults,
      progress: progress ?? this.progress,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      moduleMap: moduleMap ?? this.moduleMap,
      teamProgress: teamProgress ?? this.teamProgress,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      reminders: reminders ?? this.reminders,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

// Notifier
class TrainingNotifier extends Notifier<TrainingState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  TrainingState build() => TrainingState();

  Future<void> loadDepartments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/departments');
      final departments = (response.data as List).map((d) => Department.fromJson(d)).toList();
      state = state.copyWith(departments: departments, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadRoutes({String? departmentId, int? limit, int? offset}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (departmentId != null) params['department_id'] = departmentId;
      if (limit != null) params['limit'] = limit;
      if (offset != null) params['offset'] = offset;
      final response = await _dio.get('/training/routes', queryParameters: params);
      final routes = (response.data as List).map((r) => TrainingRoute.fromJson(r)).toList();
      state = state.copyWith(routes: routes, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadRouteDetail(String routeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/routes/$routeId');
      final route = TrainingRoute.fromJson(response.data);
      state = state.copyWith(selectedRoute: route, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadModuleDetail(String moduleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/modules/$moduleId');
      final module = TrainingModule.fromJson(response.data);
      state = state.copyWith(selectedModule: module, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadQuizzes({String? departmentId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (departmentId != null) params['department_id'] = departmentId;
      final response = await _dio.get('/training/quizzes', queryParameters: params);
      final quizzes = (response.data as List).map((q) => QuizListItem.fromJson(q)).toList();
      state = state.copyWith(quizList: quizzes, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadQuizQuestions(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/quizzes/$quizId/questions');
      final questions = (response.data as List).map((q) => QuizQuestion.fromJson(q)).toList();
      state = state.copyWith(quizQuestions: questions, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadStats(String userId) async {
    try {
      final response = await _dio.get('/training/stats/$userId');
      final stats = TrainingStats.fromJson(response.data);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats yuklenmezse sessizce devam et
    }
  }

  Future<void> loadProgress(String userId) async {
    try {
      final response = await _dio.get('/training/progress/$userId');
      final progress = (response.data as List).map((p) => UserProgress.fromJson(p)).toList();
      state = state.copyWith(progress: progress);
    } catch (e) {
      // Progress yuklenmezse sessizce devam et
    }
  }

  Future<bool> submitQuiz(String quizId, String userId, double score, double maxScore, Map<String, dynamic> answers) async {
    try {
      final response = await _dio.post('/training/quiz-results', data: {
        'user_id': userId,
        'quiz_id': quizId,
        'score': score,
        'max_score': maxScore,
        'answers': answers,
      });
      return response.data['passed'] == true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<void> loadUserQuizResults(String userId) async {
    try {
      final response = await _dio.get('/training/quiz-results/$userId');
      final results = (response.data as List).map((r) => QuizResult.fromJson(r)).toList();
      state = state.copyWith(quizResults: results);
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> startModule(String userId, String moduleId) async {
    try {
      await _dio.post('/training/progress', data: {
        'user_id': userId,
        'module_id': moduleId,
      });
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  // ===== MODULES (for progress lookup) =====

  Future<void> loadModules() async {
    try {
      final response = await _dio.get('/training/modules');
      final modules = response.data as List;
      final Map<String, ModuleInfo> map = {};
      for (final m in modules) {
        final routeId = m['route_id'] as String;
        final route = state.routes.where((r) => r.id == routeId).toList();
        map[m['id']] = ModuleInfo(
          id: m['id'],
          title: m['title'] ?? 'Bilinmeyen Modul',
          routeId: routeId,
          departmentId: route.isNotEmpty ? route.first.departmentId : '',
          moduleType: m['module_type'] ?? 'lesson',
          estimatedMinutes: m['estimated_minutes'] ?? 15,
        );
      }
      state = state.copyWith(moduleMap: map);
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    }
  }

  // ===== PROGRESS DATA (all-in-one for progress screen) =====

  Future<void> loadProgressData(String userId, {String? department, bool isSupervisor = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Paralel: departments, routes
      await Future.wait([
        loadDepartments(),
        loadRoutes(),
      ]).timeout(const Duration(seconds: 15), onTimeout: () => []);
      await loadModules(); // routes gerekli
      // Stats ve progress paralel
      await Future.wait([
        loadStats(userId),
        loadProgress(userId),
      ]).timeout(const Duration(seconds: 15), onTimeout: () => []);

      if (isSupervisor && department != null) {
        final team = await loadTeamProgress(department);
        state = state.copyWith(teamProgress: team, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ilerleme verisi yuklenemedi');
    }
  }

  // ===== DASHBOARD DATA (all-in-one for dashboard screen) =====

  Future<void> loadDashboardData(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        loadDepartments(),
        loadRoutes(),
        loadStats(userId),
      ]);
      final summary = await loadDashboardSummary(userId);
      await generateReminders(userId);
      final reminderList = await loadReminders(userId);
      final reviews = await loadPendingReviews(userId);
      state = state.copyWith(
        dashboardSummary: summary,
        reminders: reminderList,
        reviewCount: reviews.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Veri yuklenemedi');
    }
  }

  // ===== ACKNOWLEDGMENT =====

  Future<bool> submitAcknowledgment(String userId, String moduleId, String routeId, String text) async {
    try {
      await _dio.post('/training/acknowledgments', data: {
        'user_id': userId,
        'module_id': moduleId,
        'route_id': routeId,
        'acknowledgment_text': text,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<TrainingAcknowledgment?> checkModuleAcknowledgment(String userId, String moduleId) async {
    try {
      final response = await _dio.get('/training/acknowledgments/$userId/$moduleId');
      if (response.data != null) {
        return TrainingAcknowledgment.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  // ===== DASHBOARD SUMMARY =====

  Future<DashboardSummary?> loadDashboardSummary(String userId) async {
    try {
      final response = await _dio.get('/training/dashboard/$userId');
      return DashboardSummary.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  // ===== SPACED REPETITION =====

  Future<List<SpacedReview>> loadPendingReviews(String userId) async {
    try {
      final response = await _dio.get('/training/reviews/$userId');
      return (response.data as List).map((r) => SpacedReview.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> completeReview(String scheduleId) async {
    try {
      await _dio.post('/training/reviews/$scheduleId/complete');
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  // ===== REMINDERS =====

  Future<List<TrainingReminder>> loadReminders(String userId) async {
    try {
      final response = await _dio.get('/training/reminders/$userId');
      return (response.data as List).map((r) => TrainingReminder.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> generateReminders(String userId) async {
    try {
      await _dio.post('/training/reminders/generate/$userId');
    } catch (_) {}
  }

  Future<void> markReminderRead(String reminderId) async {
    try {
      await _dio.put('/training/reminders/$reminderId/read');
    } catch (_) {}
  }

  void dismissReminder(String reminderId) {
    markReminderRead(reminderId);
    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != reminderId).toList(),
    );
  }

  // ===== TEAM PROGRESS =====

  Future<List<TeamMemberProgress>> loadTeamProgress(String department) async {
    try {
      final response = await _dio.get('/training/team-progress/$department');
      return (response.data as List).map((t) => TeamMemberProgress.fromJson(t)).toList();
    } catch (_) {
      return [];
    }
  }
}

// Provider
final trainingProvider = NotifierProvider<TrainingNotifier, TrainingState>(() => TrainingNotifier());
