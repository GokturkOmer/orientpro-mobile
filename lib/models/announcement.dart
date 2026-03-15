class Announcement {
  final String id;
  final String title;
  final String body;
  final String priority; // "normal", "high", "critical"
  final bool isPinned;
  final String? targetDepartment;
  final List<dynamic> attachments;
  final String createdBy;
  final bool isActive;
  final String publishedAt;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;
  final bool? isRead;
  final int? readCount;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.priority = 'normal',
    this.isPinned = false,
    this.targetDepartment,
    this.attachments = const [],
    required this.createdBy,
    this.isActive = true,
    required this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.isRead,
    this.readCount,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      priority: json['priority'] ?? 'normal',
      isPinned: json['is_pinned'] ?? false,
      targetDepartment: json['target_department'],
      attachments: json['attachments'] ?? [],
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      publishedAt: json['published_at'] ?? '',
      expiresAt: json['expires_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isRead: json['is_read'],
      readCount: json['read_count'],
    );
  }

  String get priorityText {
    switch (priority) {
      case 'critical': return 'Kritik';
      case 'high': return 'Yuksek';
      default: return 'Normal';
    }
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(publishedAt);
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk once';
      if (diff.inHours < 24) return '${diff.inHours} saat once';
      if (diff.inDays < 7) return '${diff.inDays} gun once';
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
