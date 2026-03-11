class TourRoute {
  final int id;
  final String name;
  final String? description;
  final String? department;
  final int estimatedMinutes;
  final int checkpointCount;

  TourRoute({required this.id, required this.name, this.description, this.department, required this.estimatedMinutes, required this.checkpointCount});

  factory TourRoute.fromJson(Map<String, dynamic> json) => TourRoute(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'],
    department: json['department'],
    estimatedMinutes: json['estimated_minutes'] ?? 30,
    checkpointCount: json['checkpoint_count'] ?? 0,
  );
}

class TourCheckpoint {
  final int id;
  final int orderIndex;
  final String qrCode;
  final String name;
  final String? location;
  final String? instructions;
  final List<String> checkItems;
  final bool photoRequired;
  final bool noteRequired;
  final bool scanned;
  final String scanStatus;
  final String? scanTime;
  final String? scanNotes;

  TourCheckpoint({
    required this.id, required this.orderIndex, required this.qrCode, required this.name,
    this.location, this.instructions, required this.checkItems,
    this.photoRequired = false, this.noteRequired = false,
    this.scanned = false, this.scanStatus = 'pending', this.scanTime, this.scanNotes,
  });

  factory TourCheckpoint.fromJson(Map<String, dynamic> json) => TourCheckpoint(
    id: json['id'],
    orderIndex: json['order_index'] ?? 0,
    qrCode: json['qr_code'] ?? '',
    name: json['name'] ?? '',
    location: json['location'],
    instructions: json['instructions'],
    checkItems: (json['check_items'] as List?)?.map((e) => e.toString()).toList() ?? [],
    photoRequired: json['photo_required'] ?? false,
    noteRequired: json['note_required'] ?? false,
    scanned: json['scanned'] ?? false,
    scanStatus: json['scan_status'] ?? 'pending',
    scanTime: json['scan_time'],
    scanNotes: json['scan_notes'],
  );
}

class TourSession {
  final int id;
  final int routeId;
  final String routeName;
  final String status;
  final String startedAt;
  final String? completedAt;
  final int? elapsedMinutes;
  final int totalCheckpoints;
  final int scannedCheckpoints;
  final int skippedCheckpoints;
  final int completionRate;
  final List<TourCheckpoint> checkpoints;

  TourSession({
    required this.id, required this.routeId, required this.routeName, required this.status,
    required this.startedAt, this.completedAt, this.elapsedMinutes,
    required this.totalCheckpoints, required this.scannedCheckpoints,
    required this.skippedCheckpoints, required this.completionRate,
    required this.checkpoints,
  });

  factory TourSession.fromJson(Map<String, dynamic> json) => TourSession(
    id: json['id'],
    routeId: json['route_id'] ?? 0,
    routeName: json['route_name'] ?? '',
    status: json['status'] ?? 'active',
    startedAt: json['started_at'] ?? '',
    completedAt: json['completed_at'],
    elapsedMinutes: json['elapsed_minutes'],
    totalCheckpoints: json['total_checkpoints'] ?? 0,
    scannedCheckpoints: json['scanned_checkpoints'] ?? 0,
    skippedCheckpoints: json['skipped_checkpoints'] ?? 0,
    completionRate: json['completion_rate'] ?? 0,
    checkpoints: (json['checkpoints'] as List?)?.map((e) => TourCheckpoint.fromJson(e)).toList() ?? [],
  );
}

class ScanResult {
  final bool success;
  final String checkpointName;
  final int checkpointOrder;
  final String? location;
  final String? instructions;
  final List<String> checkItems;
  final int scanned;
  final int total;
  final int remaining;
  final String? orderWarning;
  final bool autoCompleted;
  final bool photoRequired;
  final bool noteRequired;

  ScanResult({
    required this.success, required this.checkpointName, required this.checkpointOrder,
    this.location, this.instructions, required this.checkItems,
    required this.scanned, required this.total, required this.remaining,
    this.orderWarning, this.autoCompleted = false,
    this.photoRequired = false, this.noteRequired = false,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    success: json['success'] ?? false,
    checkpointName: json['checkpoint_name'] ?? '',
    checkpointOrder: json['checkpoint_order'] ?? 0,
    location: json['location'],
    instructions: json['instructions'],
    checkItems: (json['check_items'] as List?)?.map((e) => e.toString()).toList() ?? [],
    scanned: json['scanned'] ?? 0,
    total: json['total'] ?? 0,
    remaining: json['remaining'] ?? 0,
    orderWarning: json['order_warning'],
    autoCompleted: json['auto_completed'] ?? false,
    photoRequired: json['photo_required'] ?? false,
    noteRequired: json['note_required'] ?? false,
  );
}
