class UserProfile {
  final String id;
  final String userId;
  final String? birthDate;
  final String? bloodType;
  final String? nationalId;
  final String? address;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;
  final String? hireDate;
  final String? positionTitle;
  final String? shiftType;
  final List<dynamic> skills;
  final List<dynamic> certifications;
  final String? bio;
  final String createdAt;
  final String updatedAt;
  // User join fields
  final String? fullName;
  final String? email;
  final String? role;
  final String? department;
  final String? phone;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.userId,
    this.birthDate,
    this.bloodType,
    this.nationalId,
    this.address,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
    this.hireDate,
    this.positionTitle,
    this.shiftType,
    this.skills = const [],
    this.certifications = const [],
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.email,
    this.role,
    this.department,
    this.phone,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      birthDate: json['birth_date'],
      bloodType: json['blood_type'],
      nationalId: json['national_id'],
      address: json['address'],
      emergencyName: json['emergency_name'],
      emergencyPhone: json['emergency_phone'],
      emergencyRelation: json['emergency_relation'],
      hireDate: json['hire_date'],
      positionTitle: json['position_title'],
      shiftType: json['shift_type'],
      skills: json['skills'] ?? [],
      certifications: json['certifications'] ?? [],
      bio: json['bio'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      phone: json['phone'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (birthDate != null) map['birth_date'] = birthDate;
    if (bloodType != null) map['blood_type'] = bloodType;
    if (nationalId != null) map['national_id'] = nationalId;
    if (address != null) map['address'] = address;
    if (emergencyName != null) map['emergency_name'] = emergencyName;
    if (emergencyPhone != null) map['emergency_phone'] = emergencyPhone;
    if (emergencyRelation != null) map['emergency_relation'] = emergencyRelation;
    if (hireDate != null) map['hire_date'] = hireDate;
    if (positionTitle != null) map['position_title'] = positionTitle;
    if (shiftType != null) map['shift_type'] = shiftType;
    if (bio != null) map['bio'] = bio;
    return map;
  }

  String get roleText {
    switch (role) {
      case 'admin': return 'Yönetici';
      case 'facility_manager': return 'Tesis Muduru';
      case 'chief_technician': return 'Sef Teknisyen';
      case 'technician': return 'Teknisyen';
      case 'hk_supervisor': return 'HK Supervisor';
      case 'housekeeper': return 'Kat Görevlisi';
      default: return role ?? '';
    }
  }

  String get shiftTypeText {
    switch (shiftType) {
      case 'sabah': return 'Sabah (07:00-15:00)';
      case 'aksam': return 'Aksam (15:00-23:00)';
      case 'gece': return 'Gece (23:00-07:00)';
      default: return shiftType ?? 'Belirtilmemis';
    }
  }
}

class ProfileSummary {
  final String userId;
  final int completedTrainings;
  final int documentCount;
  final int formCount;

  ProfileSummary({
    required this.userId,
    this.completedTrainings = 0,
    this.documentCount = 0,
    this.formCount = 0,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      userId: json['user_id'],
      completedTrainings: json['completed_trainings'] ?? 0,
      documentCount: json['document_count'] ?? 0,
      formCount: json['form_count'] ?? 0,
    );
  }
}
