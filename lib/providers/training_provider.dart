import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/training.dart';
import '../core/config/api_config.dart';

// State
class TrainingState {
  final List<Department> departments;
  final List<TrainingRoute> routes;
  final TrainingRoute? selectedRoute;
  final TrainingModule? selectedModule;
  final List<QuizQuestion> quizQuestions;
  final List<UserProgress> progress;
  final TrainingStats? stats;
  final bool isLoading;
  final String? error;

  TrainingState({
    this.departments = const [],
    this.routes = const [],
    this.selectedRoute,
    this.selectedModule,
    this.quizQuestions = const [],
    this.progress = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  TrainingState copyWith({
    List<Department>? departments,
    List<TrainingRoute>? routes,
    TrainingRoute? selectedRoute,
    TrainingModule? selectedModule,
    List<QuizQuestion>? quizQuestions,
    List<UserProgress>? progress,
    TrainingStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return TrainingState(
      departments: departments ?? this.departments,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      selectedModule: selectedModule ?? this.selectedModule,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      progress: progress ?? this.progress,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class TrainingNotifier extends Notifier<TrainingState> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));

  @override
  TrainingState build() => TrainingState();

  Future<void> loadDepartments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/departments');
      final departments = (response.data as List).map((d) => Department.fromJson(d)).toList();
      state = state.copyWith(departments: departments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Departmanlar yuklenemedi: $e');
    }
  }

  Future<void> loadRoutes({String? departmentId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (departmentId != null) params['department_id'] = departmentId;
      final response = await _dio.get('/training/routes', queryParameters: params);
      final routes = (response.data as List).map((r) => TrainingRoute.fromJson(r)).toList();
      state = state.copyWith(routes: routes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Egitim rotalari yuklenemedi: $e');
    }
  }

  Future<void> loadRouteDetail(String routeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/routes/$routeId');
      final route = TrainingRoute.fromJson(response.data);
      state = state.copyWith(selectedRoute: route, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Rota detayi yuklenemedi: $e');
    }
  }

  Future<void> loadModuleDetail(String moduleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/modules/$moduleId');
      final module = TrainingModule.fromJson(response.data);
      state = state.copyWith(selectedModule: module, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Modul detayi yuklenemedi: $e');
    }
  }

  Future<void> loadQuizQuestions(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/quizzes/$quizId/questions');
      final questions = (response.data as List).map((q) => QuizQuestion.fromJson(q)).toList();
      state = state.copyWith(quizQuestions: questions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Quiz sorulari yuklenemedi: $e');
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
    } catch (e) {
      state = state.copyWith(error: 'Quiz gonderilemedi: $e');
      return false;
    }
  }

  Future<void> startModule(String userId, String moduleId) async {
    try {
      await _dio.post('/training/progress', data: {
        'user_id': userId,
        'module_id': moduleId,
      });
    } catch (_) {}
  }
}

// Provider
final trainingProvider = NotifierProvider<TrainingNotifier, TrainingState>(() => TrainingNotifier());
