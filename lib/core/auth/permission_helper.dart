/// DB tabanli izin kontrolu — RoleHelper'in hardcoded mantigi yerine
/// backend'den gelen permissions listesini kullanir.
/// Permissions bossa false doner (fallback icin RoleHelper kullanilir).
class PermissionHelper {
  final List<Map<String, dynamic>> permissions;

  const PermissionHelper(this.permissions);

  bool get hasPermissions => permissions.isNotEmpty;

  bool hasPermission(String resource, String action) {
    return permissions.any((p) => p['resource'] == resource && p['action'] == action);
  }

  bool hasAnyPermission(String resource) {
    return permissions.any((p) => p['resource'] == resource);
  }

  // Yetki kontrolleri — RoleHelper metodlariyla eslesen
  bool get canAccessAdmin => hasPermission('settings', 'view') || hasPermission('settings', 'edit');
  bool get canEditContent => hasPermission('content', 'edit') || hasPermission('content', 'create');
  bool get canApproveContent => hasPermission('content', 'approve');
  bool get canManageUsers => hasPermission('users', 'create') || hasPermission('users', 'edit');
  bool get canViewReports => hasPermission('reports', 'view');
  bool get canManageTraining => hasPermission('training', 'create') || hasPermission('training', 'edit');
}
