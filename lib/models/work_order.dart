class WorkOrder {
  final String id;
  final String? woNumber;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? faultType;
  final String? sourceDepartment;
  final String? roomNumber;
  final int? slaMinutes;
  final bool? slaBreached;
  final int? resolutionMinutes;
  final bool? isRecurring;
  final String? resolutionNotes;
  final String? equipmentId;
  final String? assignedTo;
  final String createdBy;
  final String createdAt;
  final String? startedAt;
  final String? completedAt;
  WorkOrder({required this.id, this.woNumber, required this.title, this.description, required this.priority, required this.status, this.faultType, this.sourceDepartment, this.roomNumber, this.slaMinutes, this.slaBreached, this.resolutionMinutes, this.isRecurring, this.resolutionNotes, this.equipmentId, this.assignedTo, required this.createdBy, required this.createdAt, this.startedAt, this.completedAt});
  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(id: json['id'], woNumber: json['wo_number'], title: json['title'], description: json['description'], priority: json['priority'], status: json['status'], faultType: json['fault_type'], sourceDepartment: json['source_department'], roomNumber: json['room_number'], slaMinutes: json['sla_minutes'], slaBreached: json['sla_breached'], resolutionMinutes: json['resolution_minutes'], isRecurring: json['is_recurring'], resolutionNotes: json['resolution_notes'], equipmentId: json['equipment_id'], assignedTo: json['assigned_to'], createdBy: json['created_by'], createdAt: json['created_at'], startedAt: json['started_at'], completedAt: json['completed_at']);
  }
  String get priorityText { switch (priority) { case 'critical': return 'Kritik'; case 'high': return 'Yuksek'; case 'normal': return 'Normal'; case 'low': return 'Dusuk'; default: return priority; } }
  String get statusText { switch (status) { case 'open': return 'Acik'; case 'assigned': return 'Atandi'; case 'in_progress': return 'Devam Ediyor'; case 'completed': return 'Tamamlandi'; case 'cancelled': return 'Iptal'; default: return status; } }
  String get faultTypeText { const map = {'calismiyor': 'Calismiyor', 'sogutmuyor': 'Sogutmuyor', 'ses_gurultu': 'Ses/Gurultu', 'tikaniklik': 'Tikaniklik', 'su_kacagi': 'Su Kacagi', 'kirik_hasarli': 'Kirik/Hasarli', 'kapanmiyor': 'Kapanmiyor', 'koku': 'Koku', 'yanmiyor': 'Yanmiyor', 'dusuk_basinc': 'Dusuk Basinc', 'diger': 'Diger'}; return map[faultType] ?? faultType ?? '-'; }
  String get slaText { if (slaMinutes == null) return '-'; if (slaMinutes! < 60) return ' dk'; return ' saat'; }
}
