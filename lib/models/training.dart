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

  Map<String, dynamic> toJson() => {
    'department_id': departmentId, 'title': title, 'description': description,
    'difficulty': difficulty, 'estimated_minutes': estimatedMinutes,
    'is_mandatory': isMandatory, 'passing_score': passingScore,
    'certificate_enabled': certificateEnabled, 'tags': tags, 'sort_order': sortOrder,
  };

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

  Map<String, dynamic> toJson() => {
    'route_id': routeId, 'title': title, 'description': description,
    'module_type': moduleType, 'estimated_minutes': estimatedMinutes, 'sort_order': sortOrder,
  };

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
  final String? moduleId;
  final String contentType;
  final String title;
  final String? body;
  final String? mediaUrl;
  final Map<String, dynamic>? metadataJson;
  final int sortOrder;

  ModuleContent({required this.id, this.moduleId, required this.contentType, required this.title, this.body, this.mediaUrl, this.metadataJson, this.sortOrder = 0});

  factory ModuleContent.fromJson(Map<String, dynamic> json) {
    return ModuleContent(id: json['id'], moduleId: json['module_id'], contentType: json['content_type'], title: json['title'], body: json['body'], mediaUrl: json['media_url'], metadataJson: json['metadata_json'], sortOrder: json['sort_order'] ?? 0);
  }

  Map<String, dynamic> toJson() => {
    'module_id': moduleId, 'content_type': contentType, 'title': title,
    'body': body, 'media_url': mediaUrl, 'metadata_json': metadataJson, 'sort_order': sortOrder,
  };

  // PDF convenience getters
  bool get isPdf => contentType == 'pdf';
  Map<String, dynamic>? get classification => metadataJson?['classification'];
  String? get ragStatus => metadataJson?['rag_status'];
  String? get ragDocId => metadataJson?['rag_doc_id'];
  List<String> get tags => (classification?['tags'] as List?)?.cast<String>() ?? [];
  String? get summary => classification?['summary'];
  String? get fileName => metadataJson?['file_name'];
  int get fileSize => metadataJson?['file_size'] ?? 0;
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

  Map<String, dynamic> toJson() => {
    'module_id': moduleId, 'title': title, 'description': description,
    'time_limit_minutes': timeLimitMinutes, 'max_attempts': maxAttempts, 'passing_score': passingScore,
  };
}

class QuizListItem {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final int maxAttempts;
  final int passingScore;
  final bool isActive;
  final String? moduleTitle;
  final String? routeTitle;
  final String? routeId;
  final String? departmentId;
  final String? departmentName;
  final String? departmentCode;

  QuizListItem({required this.id, required this.moduleId, required this.title, this.description, this.timeLimitMinutes, this.maxAttempts = 3, this.passingScore = 70, this.isActive = true, this.moduleTitle, this.routeTitle, this.routeId, this.departmentId, this.departmentName, this.departmentCode});

  factory QuizListItem.fromJson(Map<String, dynamic> json) {
    return QuizListItem(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      description: json['description'],
      timeLimitMinutes: json['time_limit_minutes'],
      maxAttempts: json['max_attempts'] ?? 3,
      passingScore: json['passing_score'] ?? 70,
      isActive: json['is_active'] ?? true,
      moduleTitle: json['module_title'],
      routeTitle: json['route_title'],
      routeId: json['route_id'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      departmentCode: json['department_code'],
    );
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

  Map<String, dynamic> toJson() => {
    'quiz_id': quizId, 'question_text': questionText, 'question_type': questionType,
    'options': options, 'correct_answer': correctAnswer, 'explanation': explanation,
    'points': points, 'sort_order': sortOrder,
  };
}

class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final double score;
  final double maxScore;
  final bool passed;
  final int attemptNumber;
  final String createdAt;

  QuizResult({required this.id, required this.userId, required this.quizId, required this.score, required this.maxScore, required this.passed, this.attemptNumber = 1, required this.createdAt});

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(id: json['id'], userId: json['user_id'], quizId: json['quiz_id'], score: (json['score'] ?? 0).toDouble(), maxScore: (json['max_score'] ?? 0).toDouble(), passed: json['passed'] ?? false, attemptNumber: json['attempt_number'] ?? 1, createdAt: json['created_at'] ?? '');
  }

  double get percent => maxScore > 0 ? (score / maxScore * 100) : 0;
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


class TrainingAcknowledgment {
  final String id;
  final String userId;
  final String moduleId;
  final String routeId;
  final String acknowledgmentText;
  final String? supervisorId;
  final String? supervisorAcknowledgedAt;
  final String acknowledgedAt;

  TrainingAcknowledgment({required this.id, required this.userId, required this.moduleId, required this.routeId, required this.acknowledgmentText, this.supervisorId, this.supervisorAcknowledgedAt, required this.acknowledgedAt});

  factory TrainingAcknowledgment.fromJson(Map<String, dynamic> json) {
    return TrainingAcknowledgment(id: json['id'], userId: json['user_id'], moduleId: json['module_id'], routeId: json['route_id'], acknowledgmentText: json['acknowledgment_text'], supervisorId: json['supervisor_id'], supervisorAcknowledgedAt: json['supervisor_acknowledged_at'], acknowledgedAt: json['acknowledged_at']);
  }
}


class SpacedReview {
  final String id;
  final String userId;
  final String moduleId;
  final String? quizId;
  final List<dynamic>? weakQuestionIds;
  final String reason;
  final String scheduledAt;
  final String? completedAt;
  final int intervalDays;

  SpacedReview({required this.id, required this.userId, required this.moduleId, this.quizId, this.weakQuestionIds, required this.reason, required this.scheduledAt, this.completedAt, this.intervalDays = 1});

  factory SpacedReview.fromJson(Map<String, dynamic> json) {
    return SpacedReview(id: json['id'], userId: json['user_id'], moduleId: json['module_id'], quizId: json['quiz_id'], weakQuestionIds: json['weak_question_ids'], reason: json['reason'], scheduledAt: json['scheduled_at'], completedAt: json['completed_at'], intervalDays: json['interval_days'] ?? 1);
  }
}


class TrainingReminder {
  final String id;
  final String userId;
  final String reminderType;
  final String? routeId;
  final String? moduleId;
  final String title;
  final String message;
  final String scheduledAt;
  final String? readAt;

  TrainingReminder({required this.id, required this.userId, required this.reminderType, this.routeId, this.moduleId, required this.title, required this.message, required this.scheduledAt, this.readAt});

  factory TrainingReminder.fromJson(Map<String, dynamic> json) {
    return TrainingReminder(id: json['id'], userId: json['user_id'], reminderType: json['reminder_type'], routeId: json['route_id'], moduleId: json['module_id'], title: json['title'], message: json['message'], scheduledAt: json['scheduled_at'], readAt: json['read_at']);
  }
}


class DashboardSummary {
  final int pendingAcknowledgments;
  final List<dynamic> upcomingDeadlines;
  final int weeklyCompleted;
  final int weeklyTimeMinutes;
  final List<dynamic> overdueModules;
  final int spacedReviewsDue;
  final int totalAcknowledgments;

  DashboardSummary({this.pendingAcknowledgments = 0, this.upcomingDeadlines = const [], this.weeklyCompleted = 0, this.weeklyTimeMinutes = 0, this.overdueModules = const [], this.spacedReviewsDue = 0, this.totalAcknowledgments = 0});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(pendingAcknowledgments: json['pending_acknowledgments'] ?? 0, upcomingDeadlines: json['upcoming_deadlines'] ?? [], weeklyCompleted: json['weekly_completed'] ?? 0, weeklyTimeMinutes: json['weekly_time_minutes'] ?? 0, overdueModules: json['overdue_modules'] ?? [], spacedReviewsDue: json['spaced_reviews_due'] ?? 0, totalAcknowledgments: json['total_acknowledgments'] ?? 0);
  }
}


class TeamMemberProgress {
  final String userId;
  final String userName;
  final String? department;
  final double completionPercent;
  final int acknowledgedCount;
  final int totalRequired;
  final String? lastActivity;

  TeamMemberProgress({required this.userId, required this.userName, this.department, this.completionPercent = 0, this.acknowledgedCount = 0, this.totalRequired = 0, this.lastActivity});

  factory TeamMemberProgress.fromJson(Map<String, dynamic> json) {
    return TeamMemberProgress(userId: json['user_id'], userName: json['user_name'], department: json['department'], completionPercent: (json['completion_percent'] ?? 0).toDouble(), acknowledgedCount: json['acknowledged_count'] ?? 0, totalRequired: json['total_required'] ?? 0, lastActivity: json['last_activity']);
  }
}
