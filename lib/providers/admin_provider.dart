import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/training.dart';
import '../models/user.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

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
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  // ===== USERS =====

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/auth/users');
      final users = (response.data as List).map((u) => User.fromJson(u)).toList();
      state = state.copyWith(users: users, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Kullanici başarıyla oluşturuldu');
      await loadUsers();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> toggleUserActive(String userId) async {
    try {
      await _dio.patch('/auth/users/$userId', data: {});
      await loadUsers();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> updateUserLimit(String userId, int limit) async {
    try {
      await _dio.patch('/auth/users/$userId', data: {'shared_upload_limit': limit});
      await loadUsers();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  // ===== DEPARTMENTS =====

  Future<void> loadDepartments() async {
    try {
      final response = await _dio.get('/training/departments');
      final departments = (response.data as List).map((d) => Department.fromJson(d)).toList();
      state = state.copyWith(departments: departments);
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> createDepartment({required String name, required String code, String? description, String? color}) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post('/training/departments', data: {
        'name': name,
        'code': code,
        'description': ?description,
        'color': ?color,
      });
      state = state.copyWith(isSaving: false, successMessage: 'Departman oluşturuldu');
      await loadDepartments();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  // ===== ROUTES =====

  Future<void> loadRoutes({String? departmentId}) async {
    try {
      final params = <String, dynamic>{};
      if (departmentId != null) params['department_id'] = departmentId;
      final response = await _dio.get('/training/routes',
        queryParameters: params);
      final newRoutes = (response.data as List).map((r) => TrainingRoute.fromJson(r)).toList();
      if (departmentId != null) {
        // Merge: mevcut rotalari koru, sadece bu departmanin rotalarini güncelle
        final existing = state.routes.where((r) => r.departmentId != departmentId).toList();
        state = state.copyWith(routes: [...existing, ...newRoutes]);
      } else {
        state = state.copyWith(routes: newRoutes);
      }
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
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

  Future<bool> createRoute(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/routes',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Rota başarıyla oluşturuldu');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Rota başarıyla güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/routes/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Rota başarıyla silindi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteDepartment(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete('/training/departments/$id');
      state = state.copyWith(isSaving: false, successMessage: 'Departman başarıyla silindi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> createModule(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.post(
        '/training/modules',
        data: data,

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul başarıyla oluşturuldu');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Modul başarıyla güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteModule(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/modules/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Modul başarıyla silindi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Modul sirasi güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'İçerik başarıyla oluşturuldu');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'İçerik başarıyla güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteContent(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/contents/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'İçerik başarıyla silindi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
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
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return null;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Quiz başarıyla oluşturuldu');
      return response.data['id'] as String?;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Quiz başarıyla oluşturuldu');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Quiz başarıyla güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
      return [];
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Soru başarıyla oluşturuldu');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Soru başarıyla güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    }
  }

  Future<bool> deleteQuestion(String id) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _dio.delete(
        '/training/quizzes/questions/$id',

      );
      state = state.copyWith(isSaving: false, successMessage: 'Soru başarıyla silindi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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
    String? department,
    bool enrichContents = false,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null, uploadProgress: 0.0);
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'module_id': ?moduleId,
        'title': ?title,
        'department': ?department,
        'enrich_contents': enrichContents ? 'true' : 'false',
      });

      final response = await _dio.post(
        '/training/upload-content',
        data: formData,
        options: Options(
          receiveTimeout: Duration(seconds: enrichContents ? 600 : 120), // AI işlemleri uzun surebilir
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
        successMessage: 'PDF başarıyla yüklendi ve AI tarafindan siniflandirildi',
      );
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: ErrorHelper.getMessage(e));
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: ErrorHelper.getMessage(e));
      return null;
    }
  }

  /// Doküman Havuzu'ndaki mevcut PDF'den modul icerigi oluştur (tekrar yüklemeden)
  Future<Map<String, dynamic>?> generateModuleFromDocument({
    required String contentId,
    required String moduleId,
    bool clearExisting = false,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final response = await _dio.post(
        '/training/generate-from-document',
        data: {'content_id': contentId, 'module_id': moduleId, 'clear_existing': clearExisting},
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(isSaving: false, successMessage: '${data['generated_count']} bolum oluşturuldu (taslak)');
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return null;
    }
  }

  /// Doküman Havuzu'ndaki PDF'den mikro-öğrenme drip kartlari + quiz oluştur
  Future<Map<String, dynamic>?> generateDripCardsFromDocument({
    required String contentId,
    required String moduleId,
    int dayCount = 5,
    bool generateQuiz = true,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final response = await _dio.post(
        '/training/generate-drip-cards',
        data: {
          'content_id': contentId, 'module_id': moduleId,
          'day_count': dayCount, 'generate_quiz': generateQuiz,
        },
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(isSaving: false, successMessage: '${data['cards_generated']} kart oluşturuldu');
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return null;
    }
  }

  /// PDF yükleyerek modulun içerik bolumlerini AI ile otomatik oluşturur
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
        'title': ?title,
        'clear_existing': clearExisting ? 'true' : 'false',
      });

      final response = await _dio.post(
        '/training/generate-module-content',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 600), // 10dk - 6MB+ PDF AI işlemi
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
        successMessage: '${data['generated_count']} içerik bolumu otomatik oluşturuldu',
      );
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: ErrorHelper.getMessage(e));
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, uploadProgress: null, error: ErrorHelper.getMessage(e));
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
      state = state.copyWith(isSaving: false, successMessage: 'Siniflandirma güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: ErrorHelper.getMessage(e));
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

  // ========== AI QUIZ OLUSTURMA ==========

  /// Departmana gore indexlenmis dokümanlari getir
  Future<List<Map<String, dynamic>>> loadDocumentsByDepartment(String departmentCode) async {
    try {
      final response = await _dio.get(
        '/training/documents-by-department',
        queryParameters: {'department': departmentCode},
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Tum indexlenmis dokümanlari getir
  Future<List<Map<String, dynamic>>> loadAllIndexedDocuments() async {
    try {
      final response = await _dio.get('/training/documents');
      final docs = (response.data as List).cast<Map<String, dynamic>>();
      // Sadece indexlenmis olanlari filtrele
      return docs.where((d) => d['rag_status'] == 'indexed').toList();
    } catch (e) {
      return [];
    }
  }

  /// AI ile quiz oluştur
  Future<Map<String, dynamic>?> generateQuizFromDocs({
    required List<String> docIds,
    required int questionCount,
    required String difficulty,
    required String departmentCode,
    required String title,
    int passingScore = 70,
    int? timeLimitMinutes,
    int maxAttempts = 3,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await _dio.post(
        '/training/generate-quiz',
        data: {
          'doc_ids': docIds,
          'question_count': questionCount,
          'difficulty': difficulty,
          'department_code': departmentCode,
          'title': title,
          'passing_score': passingScore,
          'time_limit_minutes': timeLimitMinutes,
          'max_attempts': maxAttempts,
        },
      );
      state = state.copyWith(isSaving: false, successMessage: 'Quiz başarıyla oluşturuldu');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      final msg = e is DioException ? ErrorHelper.getMessage(e) : 'Quiz oluşturulamadı';
      state = state.copyWith(isSaving: false, error: msg);
      return null;
    }
  }

  /// Quiz'i tamamen sil (sorular + RAG dahil)
  Future<bool> deleteQuizFull(String quizId) async {
    try {
      await _dio.delete('/training/quizzes/$quizId/full');
      state = state.copyWith(successMessage: 'Quiz silindi');
      return true;
    } catch (e) {
      final msg = e is DioException ? ErrorHelper.getMessage(e) : 'Quiz silinemedi';
      state = state.copyWith(error: msg);
      return false;
    }
  }
}

// Provider
final adminProvider = NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
