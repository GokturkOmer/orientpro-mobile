class LibraryDocument {
  final String id;
  final String title;
  final String? description;
  final String category; // "personal" / "shared"
  final String docType; // "certificate", "sop", "health_report", "id_copy", "emergency_plan", "other"
  final String? department;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final String uploadedBy;
  final bool isActive;
  final Map<String, dynamic>? tags;
  final String createdAt;
  final String updatedAt;
  final String? downloadUrl;

  LibraryDocument({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.docType,
    this.department,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    required this.uploadedBy,
    this.isActive = true,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.downloadUrl,
  });

  factory LibraryDocument.fromJson(Map<String, dynamic> json) {
    return LibraryDocument(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'] ?? 'personal',
      docType: json['doc_type'] ?? 'other',
      department: json['department'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'] ?? 0,
      mimeType: json['mime_type'],
      uploadedBy: json['uploaded_by'],
      isActive: json['is_active'] ?? true,
      tags: json['tags'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      downloadUrl: json['download_url'],
    );
  }

  String get docTypeText {
    switch (docType) {
      case 'certificate': return 'Sertifika';
      case 'sop': return 'SOP';
      case 'health_report': return 'Saglik Raporu';
      case 'id_copy': return 'Kimlik Fotokopisi';
      case 'emergency_plan': return 'Acil Durum Plani';
      default: return 'Diger';
    }
  }

  String get fileSizeText {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
