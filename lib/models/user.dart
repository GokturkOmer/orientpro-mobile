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
  User({required this.id, required this.email, required this.fullName, required this.role, this.department, this.phone, this.specialization, this.photoUrl, required this.isActive});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], email: json['email'], fullName: json['full_name'], role: json['role'], department: json['department'], phone: json['phone'], specialization: json['specialization'], photoUrl: json['photo_url'], isActive: json['is_active']);
  }
  String get roleText { const map = {'admin': 'Admin', 'facility_manager': 'Tesis Muduru', 'chief_technician': 'Teknik Sef', 'technician': 'Teknisyen', 'electrician': 'Elektrikci', 'mechanic': 'Mekanik', 'hk_supervisor': 'HK Amiri', 'hk_staff': 'HK Personeli', 'ordertaker': 'Ordertaker', 'readonly': 'Izleme'}; return map[role] ?? role; }
  String get departmentText { const map = {'teknik': 'Teknik', 'hk': 'Housekeeping', 'yonetim': 'Yonetim', 'on_buro': 'On Buro', 'spa': 'SPA', 'fb': 'F&B'}; return map[department] ?? department ?? ''; }
}
