class WorkOrder {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String equipmentId;
  final String createdBy;
  final String? assignedTo;
  final String? resolutionNotes;
  final String? completedAt;
  final String createdAt;

  WorkOrder({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.equipmentId,
    required this.createdBy,
    this.assignedTo,
    this.resolutionNotes,
    this.completedAt,
    required this.createdAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      equipmentId: json['equipment_id'],
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      resolutionNotes: json['resolution_notes'],
      completedAt: json['completed_at'],
      createdAt: json['created_at'],
    );
  }

  String get priorityText {
    switch (priority) {
      case 'critical': return 'Kritik';
      case 'high': return 'Yuksek';
      case 'normal': return 'Normal';
      case 'low': return 'Dusuk';
      default: return priority;
    }
  }

  String get statusText {
    switch (status) {
      case 'open': return 'Acik';
      case 'in_progress': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandi';
      case 'cancelled': return 'Iptal';
      default: return status;
    }
  }
}
