class Department {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String? icon;
  final String? color;
  final bool isActive;
  final int sortOrder;

  Department({required this.id, required this.name, required this.code, this.description, this.icon, this.color, this.isActive = true, this.sortOrder = 0});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'], name: json['name'], code: json['code'], description: json['description'], icon: json['icon'], color: json['color'], isActive: json['is_active'] ?? true, sortOrder: json['sort_order'] ?? 0);
  }
}

class TrainingRoute {
  final String id;
  final String departmentId;
  final String title;
  final String? description;
  final String difficulty;
  final int estimatedMinutes;
  final bool isMandatory;
  final bool isActive;
  final int sortOrder;
  final int passingScore;
  final bool certificateEnabled;
  final List<dynamic>? tags;
  final String? departmentName;
  final List<TrainingModule>? modules;

  TrainingRoute({required this.id, required this.departmentId, required this.title, this.description, this.difficulty = 'beginner', this.estimatedMinutes = 60, this.isMandatory = true, this.isActive = true, this.sortOrder = 0, this.passingScore = 70, this.certificateEnabled = false, this.tags, this.departmentName, this.modules});

  factory TrainingRoute.fromJson(Map<String, dynamic> json) {
    return TrainingRoute(
      id: json['id'], departmentId: json['department_id'], title: json['title'], description: json['description'], difficulty: json['difficulty'] ?? 'beginner', estimatedMinutes: json['estimated_minutes'] ?? 60, isMandatory: json['is_mandatory'] ?? true, isActive: json['is_active'] ?? true, sortOrder: json['sort_order'] ?? 0, passingScore: json['passing_score'] ?? 70, certificateEnabled: json['certificate_enabled'] ?? false, tags: json['tags'], departmentName: json['department_name'],
      modules: json['modules'] != null ? (json['modules'] as List).map((m) => TrainingModule.fromJson(m)).toList() : null,
    );
  }

  String get difficultyText {
    switch (difficulty) {
      case 'beginner': return 'Baslangic';
      case 'intermediate': return 'Orta';
      case 'advanced': return 'Ileri';
      default: return difficulty;
    }
  }
}

class TrainingModule {
  final String id;
  final String routeId;
  final String title;
  final String? description;
  final String moduleType;
  final int estimatedMinutes;
  final int sortOrder;
  final bool isActive;
  final List<ModuleContent>? contents;
  final List<Quiz>? quizzes;

  TrainingModule({required this.id, required this.routeId, required this.title, this.description, this.moduleType = 'lesson', this.estimatedMinutes = 15, this.sortOrder = 0, this.isActive = true, this.contents, this.quizzes});

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id'], routeId: json['route_id'], title: json['title'], description: json['description'], moduleType: json['module_type'] ?? 'lesson', estimatedMinutes: json['estimated_minutes'] ?? 15, sortOrder: json['sort_order'] ?? 0, isActive: json['is_active'] ?? true,
      contents: json['contents'] != null ? (json['contents'] as List).map((c) => ModuleContent.fromJson(c)).toList() : null,
      quizzes: json['quizzes'] != null ? (json['quizzes'] as List).map((q) => Quiz.fromJson(q)).toList() : null,
    );
  }

  String get typeText {
    switch (moduleType) {
      case 'lesson': return 'Ders';
      case 'video': return 'Video';
      case 'practice': return 'Uygulama';
      case 'assessment': return 'Degerlendirme';
      default: return moduleType;
    }
  }
}

class ModuleContent {
  final String id;
  final String moduleId;
  final String contentType;
  final String title;
  final String? body;
  final String? mediaUrl;
  final Map<String, dynamic>? metadataJson;
  final int sortOrder;

  ModuleContent({required this.id, required this.moduleId, required this.contentType, required this.title, this.body, this.mediaUrl, this.metadataJson, this.sortOrder = 0});

  factory ModuleContent.fromJson(Map<String, dynamic> json) {
    return ModuleContent(id: json['id'], moduleId: json['module_id'], contentType: json['content_type'], title: json['title'], body: json['body'], mediaUrl: json['media_url'], metadataJson: json['metadata_json'], sortOrder: json['sort_order'] ?? 0);
  }
}

class Quiz {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final int maxAttempts;
  final int passingScore;
  final bool isActive;

  Quiz({required this.id, required this.moduleId, required this.title, this.description, this.timeLimitMinutes, this.maxAttempts = 3, this.passingScore = 70, this.isActive = true});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(id: json['id'], moduleId: json['module_id'], title: json['title'], description: json['description'], timeLimitMinutes: json['time_limit_minutes'], maxAttempts: json['max_attempts'] ?? 3, passingScore: json['passing_score'] ?? 70, isActive: json['is_active'] ?? true);
  }
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType;
  final List<dynamic>? options;
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int sortOrder;

  QuizQuestion({required this.id, required this.quizId, required this.questionText, this.questionType = 'multiple_choice', this.options, required this.correctAnswer, this.explanation, this.points = 10, this.sortOrder = 0});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(id: json['id'], quizId: json['quiz_id'], questionText: json['question_text'], questionType: json['question_type'] ?? 'multiple_choice', options: json['options'], correctAnswer: json['correct_answer'], explanation: json['explanation'], points: json['points'] ?? 10, sortOrder: json['sort_order'] ?? 0);
  }
}

class UserProgress {
  final String id;
  final String userId;
  final String moduleId;
  final String status;
  final double progressPercent;
  final int timeSpentMinutes;
  final String? startedAt;
  final String? completedAt;

  UserProgress({required this.id, required this.userId, required this.moduleId, this.status = 'not_started', this.progressPercent = 0.0, this.timeSpentMinutes = 0, this.startedAt, this.completedAt});

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(id: json['id'], userId: json['user_id'], moduleId: json['module_id'], status: json['status'] ?? 'not_started', progressPercent: (json['progress_percent'] ?? 0.0).toDouble(), timeSpentMinutes: json['time_spent_minutes'] ?? 0, startedAt: json['started_at'], completedAt: json['completed_at']);
  }

  String get statusText {
    switch (status) {
      case 'not_started': return 'Baslanmadi';
      case 'in_progress': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandi';
      default: return status;
    }
  }
}

class TrainingStats {
  final int totalModules;
  final int completedModules;
  final int inProgressModules;
  final int totalTimeMinutes;
  final int quizzesPassed;

  TrainingStats({this.totalModules = 0, this.completedModules = 0, this.inProgressModules = 0, this.totalTimeMinutes = 0, this.quizzesPassed = 0});

  factory TrainingStats.fromJson(Map<String, dynamic> json) {
    return TrainingStats(totalModules: json['total_modules'] ?? 0, completedModules: json['completed_modules'] ?? 0, inProgressModules: json['in_progress_modules'] ?? 0, totalTimeMinutes: json['total_time_minutes'] ?? 0, quizzesPassed: json['quizzes_passed'] ?? 0);
  }

  double get completionPercent => totalModules > 0 ? (completedModules / totalModules * 100) : 0.0;
}
