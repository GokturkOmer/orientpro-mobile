import '../../models/training.dart';
import '../auth/role_helper.dart';

/// RBAC bazli departman ve rota filtreleme.
/// progress_screen, training_routes gibi ekranlarda tekrarlayan
/// filtreleme mantigi burada merkezlestirilir.
class DepartmentFilter {
  DepartmentFilter._();

  /// Kullanicinin gorebilecegi departmanlari filtreler.
  static List<Department> filterDepartments({
    required List<Department> departments,
    required String? userRole,
    required String? userDepartment,
  }) {
    final allowed = RoleHelper.visibleDepartments(userRole, userDepartment);
    if (allowed == null) return departments; // admin — hepsini gor
    return departments.where((d) => allowed.contains(d.code)).toList();
  }

  /// Kullanicinin gorebilecegi rotalari filtreler.
  /// Teknik departman icindeki tag filtrelemesini de yapar.
  static List<TrainingRoute> filterRoutes({
    required List<TrainingRoute> routes,
    required List<Department> departments,
    required String? userRole,
    required String? userDepartment,
  }) {
    final allowed = RoleHelper.visibleDepartments(userRole, userDepartment);
    var filtered = routes;

    // Departman filtreleme
    if (allowed != null) {
      final allowedDeptIds = departments
          .where((d) => allowed.contains(d.code))
          .map((d) => d.id)
          .toSet();
      filtered = filtered.where((r) => allowedDeptIds.contains(r.departmentId)).toList();
    }

    // Teknik tag filtreleme
    final teknikTags = RoleHelper.visibleTeknikTags(userRole);
    if (teknikTags != null && teknikTags.isNotEmpty) {
      final teknikDeptIds = departments
          .where((d) => d.code == 'teknik')
          .map((d) => d.id)
          .toSet();
      filtered = filtered.where((r) {
        if (!teknikDeptIds.contains(r.departmentId)) return true;
        return RoleHelper.canSeeTeknikRoute(userRole, r.tags);
      }).toList();
    }

    return filtered;
  }
}
