import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';

class TrainingRoutesScreen extends ConsumerStatefulWidget {
  const TrainingRoutesScreen({super.key});

  @override
  ConsumerState<TrainingRoutesScreen> createState() => _TrainingRoutesScreenState();
}

class _TrainingRoutesScreenState extends ConsumerState<TrainingRoutesScreen> {
  String? _selectedDeptId;
  String? _selectedDeptName;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _selectedDeptId = args?['departmentId'];
      _selectedDeptName = args?['departmentName'];
      Future.microtask(() {
        ref.read(trainingProvider.notifier).loadDepartments();
        ref.read(trainingProvider.notifier).loadRoutes(departmentId: _selectedDeptId);
      });
      _loaded = true;
    }
  }

  void _selectDepartment(String? deptId, String? deptName) {
    setState(() {
      _selectedDeptId = deptId;
      _selectedDeptName = deptName;
    });
    ref.read(trainingProvider.notifier).loadRoutes(departmentId: deptId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);
    final isLoading = training.isLoading && training.routes.isEmpty;
    final userRole = auth.user?.role;
    final userDept = auth.user?.department;
    final canSeeAll = RoleHelper.isAdmin(userRole);

    // Departman filtreleme: admin tum dept gorur, diger sadece kendi + GEN
    final filteredDepts = canSeeAll
        ? training.departments
        : training.departments.where((d) => d.code == 'GEN' || d.code == userDept).toList();

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedDeptName ?? 'Egitim Rotalari',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      body: Column(children: [
        // Department filter chips
        if (filteredDepts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (canSeeAll) _buildDeptChip('Tumu', null, null),
              ...filteredDepts.map((dept) {
                Color chipColor;
                try {
                  chipColor = dept.color != null
                      ? Color(int.parse('0xFF${dept.color!.replaceAll('#', '')}'))
                      : ScadaColors.purple;
                } catch (_) {
                  chipColor = ScadaColors.purple;
                }
                return _buildDeptChip(dept.name, dept.id, chipColor);
              }),
            ]),
          ),

        // Routes list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
              : training.routes.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.route, size: 48, color: ScadaColors.textDim),
                        const SizedBox(height: 12),
                        const Text('Henuz egitim rotasi bulunmuyor', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: training.routes.length,
                      itemBuilder: (context, index) => _buildRouteCard(training.routes[index]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildDeptChip(String label, String? deptId, Color? color) {
    final isSelected = _selectedDeptId == deptId;
    final chipColor = color ?? ScadaColors.cyan;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 11,
          color: isSelected ? ScadaColors.bg : chipColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        )),
        selected: isSelected,
        selectedColor: chipColor,
        backgroundColor: chipColor.withValues(alpha: 0.1),
        side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
        onSelected: (_) {
          _selectDepartment(deptId, deptId != null ? label : null);
        },
      ),
    );
  }

  Widget _buildRouteCard(dynamic route) {
    final difficultyColor = route.difficulty == 'beginner'
        ? ScadaColors.green
        : route.difficulty == 'intermediate'
            ? ScadaColors.amber
            : ScadaColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, '/route-detail', arguments: route.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(route.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
              ),
              if (route.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ScadaColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Zorunlu', style: TextStyle(fontSize: 9, color: ScadaColors.red, fontWeight: FontWeight.w600)),
                ),
            ]),
            if (route.description != null) ...[
              const SizedBox(height: 6),
              Text(route.description!, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(route.difficultyText, style: TextStyle(fontSize: 9, color: difficultyColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.timer_outlined, size: 12, color: ScadaColors.textDim),
              const SizedBox(width: 3),
              Text('${route.estimatedMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_outline, size: 12, color: ScadaColors.textDim),
              const SizedBox(width: 3),
              Text('Gecme: %${route.passingScore}', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 12, color: ScadaColors.textDim),
            ]),
          ]),
        ),
      ),
    );
  }
}
