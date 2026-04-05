class Shift {
  final String id;
  final String userId;
  final String shiftDate;
  final String shiftType; // sabah, aksam, gece, izin, rapor
  final String? startTime;
  final String? endTime;
  final String? department;
  final String? location;
  final String? notes;
  final String createdBy;
  final bool isActive;
  final String createdAt;
  final String? userName;

  Shift({
    required this.id,
    required this.userId,
    required this.shiftDate,
    required this.shiftType,
    this.startTime,
    this.endTime,
    this.department,
    this.location,
    this.notes,
    required this.createdBy,
    this.isActive = true,
    required this.createdAt,
    this.userName,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      userId: json['user_id'],
      shiftDate: json['shift_date'] ?? '',
      shiftType: json['shift_type'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      department: json['department'],
      location: json['location'],
      notes: json['notes'],
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'],
    );
  }

  String get shiftTypeText {
    switch (shiftType) {
      case 'sabah': return 'Sabah';
      case 'aksam': return 'Aksam';
      case 'gece': return 'Gece';
      case 'izin': return 'Izin';
      case 'rapor': return 'Rapor';
      default: return shiftType;
    }
  }

  String get timeRange {
    if (startTime != null && endTime != null) {
      final start = startTime!.length >= 5 ? startTime!.substring(0, 5) : startTime!;
      final end = endTime!.length >= 5 ? endTime!.substring(0, 5) : endTime!;
      return '$start - $end';
    }
    return '';
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final String assignedTo;
  final String createdBy;
  final String? dueDate;
  final String priority; // low, normal, high, urgent
  final String status; // pending, in_progress, completed, cancelled
  final String? category;
  final String? department;
  final String? completedAt;
  final String? completionNotes;
  final String createdAt;
  final String? assignedName;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.createdBy,
    this.dueDate,
    this.priority = 'normal',
    this.status = 'pending',
    this.category,
    this.department,
    this.completedAt,
    this.completionNotes,
    required this.createdAt,
    this.assignedName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      dueDate: json['due_date'],
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'pending',
      category: json['category'],
      department: json['department'],
      completedAt: json['completed_at'],
      completionNotes: json['completion_notes'],
      createdAt: json['created_at'] ?? '',
      assignedName: json['assigned_name'],
    );
  }

  String get priorityText {
    switch (priority) {
      case 'urgent': return 'Acil';
      case 'high': return 'Yuksek';
      case 'normal': return 'Normal';
      case 'low': return 'Dusuk';
      default: return priority;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'in_progress': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandi';
      case 'cancelled': return 'İptal';
      default: return status;
    }
  }

  bool get isOverdue {
    if (dueDate == null || status == 'completed' || status == 'cancelled') return false;
    try {
      return DateTime.parse(dueDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
