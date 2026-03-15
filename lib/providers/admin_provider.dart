import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/training.dart';
import '../models/user.dart';
import '../core/network/auth_dio.dart';

// State
class AdminState {
  final List<Department> departments;
  final List<TrainingRoute> routes;
  final List<User> users;
  final TrainingRoute? selectedRoute;
  final TrainingModule? selectedModule;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final double? uploadProgress;
  final Map<String, dynamic>? lastClassification;

  AdminState({
    this.departments = const [],
    this.routes = const [],
    this.users = const [],
    this.selectedRoute,
    this.selectedModule,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.uploadProgress,
    this.lastClassification,
  });

  AdminState copyWith({
    List<Department>? departments,
    List<TrainingRoute>? routes,
    List<User>? users,
    TrainingRoute? selectedRoute,
    TrainingModule? selectedModule,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    double? uploadProgress,
    Map<String, dynamic>? lastClassification,
  }) {
    return AdminState(
      departments: departments ?? this.departments,
      routes: routes ?? this.routes,
      users: users ?? this.users,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      selectedModule: selectedModule ?? this.selectedModule,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
      uploadProgress: uploadProgress,
      lastClassification: lastClassification,
    );
  }
}

// Notifier
class AdminNotifier extends Notifier<AdminState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  AdminState build() => AdminState();

  // ===== LOAD ALL (Dashboard icin) =====

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deptResp = await _dio.get('/training/departments');
      final departments = (deptResp.data as List).map((d) => Department.fromJson(d)).toList();

      final routeResp = await _dio.get('/training/routes');
      final routes = (routeResp.data as List).map((r) => TrainingRoute.fromJson(r)).toList();

      state = state.copyWith(departments: departments, routes: routes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Veri yuklenemedi: $e');
    }
  }

  // ===== USERS =====

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/auth/users');
      final users = (response.data as List).map((u) => User.fromJson(u)).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Kullanicilar yuklenemedi: $e');
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String department,
    String? phone,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        'department': department,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      state = state.copyWith(isSaving: false, successMessage: 'Kullanici basariyla olusturuldu');
      await loadUsers();
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Kullanici olusturulamadi';
      state = state.copyWith(isSaving: false, error: '$detail');
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Kullanici olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> toggleUserActive(String userId) async {
    try {
      await _dio.patch('/auth/users/$userId');
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Durum degistirilemedi: $e');
      return false;
    }
  }

  // ===== DEPARTMENTS =====

  Future<void> loadDepartments() async {
    try {
      final response = await _dio.get('/training/departments');
      final departments = (response.data as List).map((d) => Department.fromJson(d)).toList();
      state = state.copyWith(departments: departments);
    } catch (e) {
      state = state.copyWith(error: 'Departmanlar yuklenemedi: $e');
    }
  }

  // ===== ROUTES =====

  Future<void> loadRoutes({String? departmentId}) async {
    try {
      final params = <String, dynamic>{};
      if (departmentId != null) params['department_id'] = departmentId;
      final response = await _dio.get('/training/routes',
        queryParameters: params);
      final routes = (response.data as List).map((r) => TrainingRoute.fromJson(r)).toList();
      state = state.copyWith(routes: routes);
    } catch (e) {
      state = state.copyWith(error: 'Egitim rotalari yuklenemedi: $e');
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

  Future<bool> createRoute(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/routes',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Rota basariyla olusturuldu');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Rota olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> updateRoute(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.patch(
        '/training/routes/$id',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Rota basariyla guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Rota guncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/routes/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Rota basariyla silindi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Rota silinemedi: $e');
      return false;
    }
  }

  // ===== MODULES =====

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

  Future<bool> createModule(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/modules',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul basariyla olusturuldu');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Modul olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> updateModule(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.patch(
        '/training/modules/$id',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul basariyla guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Modul guncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteModule(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/modules/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul basariyla silindi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Modul silinemedi: $e');
      return false;
    }
  }

  Future<bool> reorderModules(List<String> moduleIds) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.put(
        '/training/modules/reorder',
        data: {'module_ids': moduleIds},

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul sirasi guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Modul sirasi guncellenemedi: $e');
      return false;
    }
  }

  // ===== CONTENTS =====

  Future<bool> createContent(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/contents',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Icerik basariyla olusturuldu');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Icerik olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> updateContent(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.patch(
        '/training/contents/$id',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Icerik basariyla guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Icerik guncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteContent(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/contents/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Icerik basariyla silindi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Icerik silinemedi: $e');
      return false;
    }
  }

  Future<bool> reorderContents(List<Map<String, String>> contentOrders) async {
    try {
      for (final item in contentOrders) {
        await _dio.patch(
          '/training/contents/${item['id']}',
          data: {'sort_order': int.parse(item['sort_order']!)},
  
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Icerik siralama basarisiz: $e');
      return false;
    }
  }

  // ===== QUIZZES =====

  Future<Quiz?> loadQuiz(String quizId) async {
    try {
      final response = await _dio.get(
        '/training/quizzes/$quizId',

      );
      return Quiz.fromJson(response.data);
    } catch (e) {
      state = state.copyWith(error: 'Quiz yuklenemedi: $e');
      return null;
    }
  }

  Future<String?> createQuizAndReturnId(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final response = await _dio.post(
        '/training/quizzes',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Quiz basariyla olusturuldu');
      return response.data['id'] as String?;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Quiz olusturulamadi: $e');
      return null;
    }
  }

  Future<bool> createQuiz(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/quizzes',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Quiz basariyla olusturuldu');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Quiz olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> updateQuiz(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.patch(
        '/training/quizzes/$id',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Quiz basariyla guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Quiz guncellenemedi: $e');
      return false;
    }
  }

  // ===== QUIZ QUESTIONS =====

  Future<List<QuizQuestion>> loadQuizQuestions(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/training/quizzes/$quizId/questions');
      final questions = (response.data as List).map((q) => QuizQuestion.fromJson(q)).toList();
      state = state.copyWith(isLoading: false);
      return questions;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Quiz sorulari yuklenemedi: $e');
      return [];
    }
  }

  Future<bool> createQuestion(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/quizzes/questions',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Soru basariyla olusturuldu');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Soru olusturulamadi: $e');
      return false;
    }
  }

  Future<bool> updateQuestion(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.patch(
        '/training/quizzes/questions/$id',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Soru basariyla guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Soru guncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/quizzes/questions/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Soru basariyla silindi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Soru silinemedi: $e');
      return false;
    }
  }
  // ===== PDF UPLOAD & AI =====

  Future<Map<String, dynamic>?> uploadPdfContent({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    String? moduleId,
    String? title,
    bool enrichContents = false,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null, uploadProgress: 0.0);
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        if (moduleId != null) 'module_id': moduleId,
        if (title != null) 'title': title,
        'enrich_contents': enrichContents ? 'true' : 'false',
      });

      final response = await _dio.post(
        '/training/upload-content',
        data: formData,
        options: Options(
          receiveTimeout: Duration(seconds: enrichContents ? 600 : 120), // AI islemleri uzun surebilir
          sendTimeout: const Duration(seconds: 120),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        isSaving: false,
        uploadProgress: null,
        lastClassification: data['classification'],
        successMessage: 'PDF basariyla yuklendi ve AI tarafindan siniflandirildi',
      );
      return data;
    } catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: 'PDF yuklenemedi: $e');
      return null;
    }
  }

  /// PDF yukleyerek modulun icerik bolumlerini AI ile otomatik olusturur
  Future<Map<String, dynamic>?> generateModuleFromPdf({
    required String fileName,
    required List<int> fileBytes,
    required String moduleId,
    String? title,
    bool clearExisting = false,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null, uploadProgress: 0.0);
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'module_id': moduleId,
        if (title != null) 'title': title,
        'clear_existing': clearExisting ? 'true' : 'false',
      });

      final response = await _dio.post(
        '/training/generate-module-content',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 600), // 10dk - 6MB+ PDF AI islemi
          sendTimeout: const Duration(seconds: 120), // büyük dosya yükleme
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        isSaving: false,
        uploadProgress: null,
        lastClassification: data['classification'],
        successMessage: '${data['generated_count']} icerik bolumu otomatik olusturuldu',
      );
      return data;
    } catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: 'Icerik olusturulamadi: $e');
      return null;
    }
  }

  Future<bool> updateClassification(String contentId, Map<String, dynamic> classification) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _dio.patch(
        '/training/contents/$contentId/classification',
        data: classification,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Siniflandirma guncellendi');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Siniflandirma guncellenemedi: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchTrainingContent(String query, {int limit = 5}) async {
    try {
      final response = await _dio.post(
        '/training/search-content',
        data: {'query': query, 'limit': limit},
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchDocumentChunks(String docId) async {
    try {
      final response = await _dio.get('/training/documents/$docId/chunks');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadTrainingDocuments({String? department}) async {
    try {
      final params = <String, dynamic>{'content_type': 'pdf'};
      if (department != null) params['department'] = department;
      final response = await _dio.get('/training/documents', queryParameters: params);
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}

// Provider
final adminProvider = NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
