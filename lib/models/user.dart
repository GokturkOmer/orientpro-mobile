class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? department;
  final String? phone;
  final String? specialization;
  final String? photoUrl;
  final bool isActive;
  final int sharedUploadLimit;
  final String? organizationId;
  final String? organizationName;
  final List<Map<String, dynamic>> permissions;
  final bool isSuperAdmin;
  User({required this.id, required this.email, required this.fullName, required this.role, this.department, this.phone, this.specialization, this.photoUrl, required this.isActive, this.sharedUploadLimit = 5, this.organizationId, this.organizationName, this.permissions = const [], this.isSuperAdmin = false});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], email: json['email'], fullName: json['full_name'], role: json['role'], department: json['department'], phone: json['phone'], specialization: json['specialization'], photoUrl: json['photo_url'], isActive: json['is_active'] ?? true, sharedUploadLimit: json['shared_upload_limit'] ?? 5, organizationId: json['organization_id'], organizationName: json['organization']?['name'],
      permissions: (json['permissions'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const [],
      isSuperAdmin: json['is_super_admin'] ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'full_name': fullName, 'role': role,
    'department': department, 'phone': phone, 'specialization': specialization,
    'photo_url': photoUrl, 'is_active': isActive, 'shared_upload_limit': sharedUploadLimit,
    'organization_id': organizationId, 'permissions': permissions,
    'is_super_admin': isSuperAdmin,
  };
  String get roleText {
    const map = {
      'admin': 'Admin',
      'teknik_mudur': 'Teknik Mudur',
      'resepsiyon_mudur': 'Resepsiyon Muduru',
      'hk_mudur': 'HK Muduru',
      'guvenlik_mudur': 'Guvenlik Muduru',
      'mutfak_mudur': 'Mutfak Muduru',
      'fb_mudur': 'Yiyecek Icecek Muduru',
      'spa_mudur': 'SPA Muduru',
      'elektrik_sefi': 'Elektrik Sefi',
      'mekanik_sefi': 'Mekanik Sefi',
      'tesisat_sefi': 'Tesisat Sefi',
      'elektrikci': 'Elektrikci',
      'mekanikci': 'Mekanikci',
      'tesisatci': 'Tesisatci',
      'teknik_staff': 'Teknik Personel',
      'hk_staff': 'HK Personeli',
      'resepsiyon_staff': 'Resepsiyon Personeli',
      'guvenlik_staff': 'Guvenlik Personeli',
      'mutfak_staff': 'Mutfak Personeli',
      'fb_staff': 'Yiyecek Icecek Personeli',
      'spa_staff': 'SPA Personeli',
    };
    return map[role] ?? role;
  }
  String get departmentText {
    const map = {
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'yonetim': 'Yonetim',
      'on_buro': 'Resepsiyon',
      'guvenlik': 'Guvenlik',
      'mutfak': 'Mutfak',
      'fb': 'Yiyecek & Icecek',
      'spa': 'SPA & Wellness',
    };
    return map[department] ?? department ?? '';
  }
}
