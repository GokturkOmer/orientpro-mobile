class RoleHelper {
  static const _adminRoles = ['admin', 'facility_manager'];
  static const _supervisorRoles = ['admin', 'facility_manager', 'chief_technician', 'hk_supervisor'];
  static const _proRoles = ['admin', 'facility_manager', 'chief_technician', 'technician', 'electrician', 'mechanic'];

  static bool isAdmin(String? role) => _adminRoles.contains(role);
  static bool isSupervisor(String? role) => _supervisorRoles.contains(role);
  static bool canAccessPro(String? role) => _proRoles.contains(role);
}
