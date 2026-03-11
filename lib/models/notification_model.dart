class AppNotification {
  final int id;
  final String title;
  final String message;
  final String category;
  final String severity;
  final String? source;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    this.source,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: json['category'] ?? 'info',
      severity: json['severity'] ?? 'info',
      source: json['source'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
