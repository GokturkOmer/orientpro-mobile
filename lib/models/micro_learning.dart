// OrientPro — Mikro-Öğrenme Modelleri
// DripCard, MicroAssignment, MicroProgress

class DripCard {
  final String id;
  final String moduleId;
  final String cardType; // content, quiz
  final int dayNumber;
  final String slot; // morning, noon, evening
  final int contentAngle;
  final String title;
  final String? body;
  final String? mediaUrl;
  final bool isRead;

  DripCard({
    required this.id,
    required this.moduleId,
    required this.cardType,
    required this.dayNumber,
    required this.slot,
    required this.contentAngle,
    required this.title,
    this.body,
    this.mediaUrl,
    this.isRead = false,
  });

  factory DripCard.fromJson(Map<String, dynamic> json) => DripCard(
    id: json['id'],
    moduleId: json['module_id'],
    cardType: json['card_type'] ?? 'content',
    dayNumber: json['day_number'] ?? 1,
    slot: json['slot'] ?? 'morning',
    contentAngle: json['content_angle'] ?? 1,
    title: json['title'] ?? '',
    body: json['body'],
    mediaUrl: json['media_url'],
    isRead: json['is_read'] ?? false,
  );

  String get slotText {
    switch (slot) {
      case 'morning': return 'Sabah';
      case 'noon': return 'Ogle';
      case 'evening': return 'Aksam';
      default: return slot;
    }
  }

  String get slotIcon {
    switch (slot) {
      case 'morning': return '🌅';
      case 'noon': return '☀️';
      case 'evening': return '🌙';
      default: return '📖';
    }
  }
}

class MicroAssignment {
  final String id;
  final String userId;
  final String moduleId;
  final String? moduleTitle;
  final String? routeId;
  final String? routeTitle;
  final String status; // active, completed, failed_retry
  final int learningDay;
  final int contentAngle;
  final bool quizPassed;
  final int quizAttempts;
  final String shiftType; // A, B, C
  final String mode; // onboarding, manager
  final String startedDate;
  final String? completedDate;
  final String assignedBy;

  MicroAssignment({
    required this.id,
    required this.userId,
    required this.moduleId,
    this.moduleTitle,
    this.routeId,
    this.routeTitle,
    required this.status,
    required this.learningDay,
    required this.contentAngle,
    required this.quizPassed,
    required this.quizAttempts,
    this.shiftType = 'A',
    this.mode = 'manager',
    required this.startedDate,
    this.completedDate,
    required this.assignedBy,
  });

  factory MicroAssignment.fromJson(Map<String, dynamic> json) => MicroAssignment(
    id: json['id'],
    userId: json['user_id'],
    moduleId: json['module_id'],
    moduleTitle: json['module_title'],
    routeId: json['route_id'],
    routeTitle: json['route_title'],
    status: json['status'] ?? 'active',
    learningDay: json['learning_day'] ?? 1,
    contentAngle: json['content_angle'] ?? 1,
    quizPassed: json['quiz_passed'] ?? false,
    quizAttempts: json['quiz_attempts'] ?? 0,
    shiftType: json['shift_type'] ?? 'A',
    mode: json['mode'] ?? 'manager',
    startedDate: json['started_date'] ?? '',
    completedDate: json['completed_date'],
    assignedBy: json['assigned_by'] ?? '',
  );

  bool get isActive => status == 'active' || status == 'failed_retry';
  bool get isCompleted => status == 'completed';
  bool get isRetry => status == 'failed_retry';
  bool get isOnboarding => mode == 'onboarding';
  bool get isManager => mode == 'manager';
}

class TodayData {
  final MicroAssignment? assignment;
  final List<DripCard> cards;
  final bool quizAvailable;
  final String? quizId;
  final int cardsRead;
  final int cardsTotal;
  final String encouragement;
  final int dailyAttemptsLeft;
  final int dailyAttemptsMax;
  final String mode;

  TodayData({
    this.assignment,
    this.cards = const [],
    this.quizAvailable = false,
    this.quizId,
    this.cardsRead = 0,
    this.cardsTotal = 0,
    this.encouragement = '',
    this.dailyAttemptsLeft = 3,
    this.dailyAttemptsMax = 3,
    this.mode = 'manager',
  });

  factory TodayData.fromJson(Map<String, dynamic> json) => TodayData(
    assignment: json['assignment'] != null
        ? MicroAssignment.fromJson(json['assignment'])
        : null,
    cards: (json['cards'] as List? ?? [])
        .map((c) => DripCard.fromJson(c))
        .toList(),
    quizAvailable: json['quiz_available'] ?? false,
    quizId: json['quiz_id'],
    cardsRead: json['cards_read'] ?? 0,
    cardsTotal: json['cards_total'] ?? 0,
    encouragement: json['encouragement'] ?? '',
    dailyAttemptsLeft: json['daily_attempts_left'] ?? 3,
    dailyAttemptsMax: json['daily_attempts_max'] ?? 3,
    mode: json['mode'] ?? 'manager',
  );

  bool get hasAssignment => assignment != null;
  bool get hasAttemptsLeft => dailyAttemptsLeft > 0;
  bool get isOnboarding => mode == 'onboarding';
  bool get isManager => mode == 'manager';
}

class MicroQuizResult {
  final bool passed;
  final double score;
  final double maxScore;
  final int correctCount;
  final int totalQuestions;
  final String? nextModuleTitle;
  final bool routeCompleted;
  final String mode;
  final String encouragement;

  MicroQuizResult({
    required this.passed,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.totalQuestions,
    this.nextModuleTitle,
    this.routeCompleted = false,
    this.mode = 'manager',
    this.encouragement = '',
  });

  factory MicroQuizResult.fromJson(Map<String, dynamic> json) => MicroQuizResult(
    passed: json['passed'] ?? false,
    score: (json['score'] ?? 0).toDouble(),
    maxScore: (json['max_score'] ?? 100).toDouble(),
    correctCount: json['correct_count'] ?? 0,
    totalQuestions: json['total_questions'] ?? 0,
    nextModuleTitle: json['next_module_title'],
    routeCompleted: json['route_completed'] ?? false,
    mode: json['mode'] ?? 'manager',
    encouragement: json['encouragement'] ?? '',
  );

  double get percent => maxScore > 0 ? (score / maxScore * 100) : 0;
}

class MicroProgress {
  final List<MicroAssignment> assignments;
  final int completedCount;
  final int activeCount;
  final int totalCount;

  MicroProgress({
    this.assignments = const [],
    this.completedCount = 0,
    this.activeCount = 0,
    this.totalCount = 0,
  });

  factory MicroProgress.fromJson(Map<String, dynamic> json) => MicroProgress(
    assignments: (json['assignments'] as List? ?? [])
        .map((a) => MicroAssignment.fromJson(a))
        .toList(),
    completedCount: json['completed_count'] ?? 0,
    activeCount: json['active_count'] ?? 0,
    totalCount: json['total_count'] ?? 0,
  );
}
