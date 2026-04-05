class FormField {
  final String name;
  final String label;
  final String type; // text, textarea, number, date, select, checkbox
  final bool required;
  final List<String>? options;

  FormField({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
  });

  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }
}

class FormTemplate {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? department;
  final bool isMandatory;
  final List<FormField> fields;
  final String createdBy;
  final bool isActive;
  final int sortOrder;
  final String createdAt;
  final int? submissionCount;
  final bool? userSubmitted;

  FormTemplate({
    required this.id,
    required this.title,
    this.description,
    this.category = 'onboarding',
    this.department,
    this.isMandatory = false,
    this.fields = const [],
    required this.createdBy,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    this.submissionCount,
    this.userSubmitted,
  });

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'] ?? 'onboarding',
      department: json['department'],
      isMandatory: json['is_mandatory'] ?? false,
      fields: json['fields'] != null
          ? (json['fields'] as List).map((f) => FormField.fromJson(f)).toList()
          : [],
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      submissionCount: json['submission_count'],
      userSubmitted: json['user_submitted'],
    );
  }

  String get categoryText {
    switch (category) {
      case 'onboarding': return 'Ise Giriş';
      case 'health': return 'Saglik';
      case 'asset': return 'Zimmet';
      case 'evaluation': return 'Degerlendirme';
      case 'checklist': return 'Checklist';
      default: return 'Diger';
    }
  }
}

class FormSubmission {
  final String id;
  final String templateId;
  final String userId;
  final Map<String, dynamic> data;
  final String status; // draft, submitted, approved, rejected
  final String? reviewedBy;
  final String? reviewNotes;
  final String? reviewedAt;
  final String submittedAt;
  final String createdAt;
  final String? templateTitle;

  FormSubmission({
    required this.id,
    required this.templateId,
    required this.userId,
    this.data = const {},
    this.status = 'submitted',
    this.reviewedBy,
    this.reviewNotes,
    this.reviewedAt,
    required this.submittedAt,
    required this.createdAt,
    this.templateTitle,
  });

  factory FormSubmission.fromJson(Map<String, dynamic> json) {
    return FormSubmission(
      id: json['id'],
      templateId: json['template_id'],
      userId: json['user_id'],
      data: json['data'] ?? {},
      status: json['status'] ?? 'submitted',
      reviewedBy: json['reviewed_by'],
      reviewNotes: json['review_notes'],
      reviewedAt: json['reviewed_at'],
      submittedAt: json['submitted_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      templateTitle: json['template_title'],
    );
  }

  String get statusText {
    switch (status) {
      case 'draft': return 'Taslak';
      case 'submitted': return 'Gonderildi';
      case 'approved': return 'Onaylandi';
      case 'rejected': return 'Reddedildi';
      default: return status;
    }
  }
}
