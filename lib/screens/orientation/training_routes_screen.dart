import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../core/utils/turkish_string.dart';

class TrainingRoutesScreen extends ConsumerStatefulWidget {
  const TrainingRoutesScreen({super.key});

  @override
  ConsumerState<TrainingRoutesScreen> createState() => _TrainingRoutesScreenState();
}

class _TrainingRoutesScreenState extends ConsumerState<TrainingRoutesScreen> {
  String? _selectedDeptId;
  String? _selectedDeptName;
  String? _selectedTeknikTag; // elektrik, mekanik, tesisat, genel, null=tümü
  bool _loaded = false;
  String _searchQuery = '';

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
      _selectedTeknikTag = null; // dept degisince tag sifirla
    });
    ref.read(trainingProvider.notifier).loadRoutes(departmentId: deptId);
  }

  void _selectTeknikTag(String? tag) {
    setState(() => _selectedTeknikTag = tag);
  }

  /// Secili departmanin teknik olup olmadigini kontrol eder
  bool _isTeknikDeptSelected(List<dynamic> departments) {
    if (_selectedDeptId == null) return false;
    return departments.any((d) => d.id == _selectedDeptId && d.code == 'teknik');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);
    final isLoading = training.isLoading && training.routes.isEmpty;
    final userRole = auth.user?.role;
    final userDept = auth.user?.department;
    final visibleDepts = RoleHelper.visibleDepartments(userRole, userDept);

    // Departman filtreleme
    final filteredDepts = visibleDepts == null
        ? training.departments
        : training.departments.where((d) => visibleDepts.contains(d.code)).toList();

    // Rota filtreleme
    final allowedDeptIds = filteredDepts.map((d) => d.id).toSet();
    var filteredRoutes = visibleDepts == null
        ? training.routes
        : training.routes.where((r) => allowedDeptIds.contains(r.departmentId)).toList();

    // Teknik dept icerisinde tag filtreleme (RBAC)
    final teknikTags = RoleHelper.visibleTeknikTags(userRole);
    if (teknikTags != null && teknikTags.isNotEmpty) {
      final teknikDeptIds = training.departments.where((d) => d.code == 'teknik').map((d) => d.id).toSet();
      filteredRoutes = filteredRoutes.where((r) {
        if (!teknikDeptIds.contains(r.departmentId)) return true;
        return RoleHelper.canSeeTeknikRoute(userRole, r.tags);
      }).toList();
    }

    // Teknik alt-dal secimi yapildiysa ek filtre
    final isTeknikSelected = _isTeknikDeptSelected(training.departments);
    if (isTeknikSelected && _selectedTeknikTag != null) {
      filteredRoutes = filteredRoutes.where((r) {
        final tags = r.tags;
        if (_selectedTeknikTag == 'genel') {
          return tags == null || tags.isEmpty || tags.contains('genel');
        }
        return tags != null && tags.contains(_selectedTeknikTag);
      }).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filteredRoutes = filteredRoutes.where((r) =>
        r.title.toTurkishLowerCase().contains(_searchQuery) ||
        (r.description?.toTurkishLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }

    // Teknik dept seciliyken gorulebilir alt-dal tag listesi
    final visibleTagChips = <String>[];
    if (isTeknikSelected) {
      final allowedTags = RoleHelper.visibleTeknikTags(userRole);
      if (allowedTags == null) {
        // admin / teknik_mudur: tum tag'leri gor
        visibleTagChips.addAll(['genel', 'elektrik', 'mekanik', 'tesisat']);
      } else {
        visibleTagChips.addAll(allowedTags);
      }
    }

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedDeptName ?? 'Eğitim Rotalari',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
        ),
      ),
      body: Column(children: [
        // Arama
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rota ara...',
              hintStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: context.scada.textDim, size: 20),
              filled: true,
              fillColor: context.scada.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
            onChanged: (v) => setState(() => _searchQuery = v.toTurkishLowerCase()),
          ),
        ),
        // Department filter chips
        if (filteredDepts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (visibleDepts == null) _buildDeptChip('Tümü', null, null),
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

        // Teknik alt-dal tag chips
        if (isTeknikSelected && visibleTagChips.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(children: [
              _buildTagChip('Tümü', null, ScadaColors.cyan),
              ...visibleTagChips.map((tag) => _buildTagChip(
                _teknikTagLabel(tag),
                tag,
                _teknikTagColor(tag),
              )),
            ]),
          ),

        // Routes list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
              : filteredRoutes.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.route, size: 48, color: context.scada.textDim),
                        const SizedBox(height: 12),
                        Text('Henuz eğitim rotasi bulunmuyor', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) => _buildRouteCard(filteredRoutes[index]),
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
          color: isSelected ? context.scada.bg : chipColor,
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

  Widget _buildTagChip(String label, String? tag, Color color) {
    final isSelected = _selectedTeknikTag == tag;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 10,
          color: isSelected ? context.scada.bg : color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        )),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        onSelected: (_) => _selectTeknikTag(tag),
      ),
    );
  }

  String _teknikTagLabel(String tag) {
    const labels = {
      'genel': 'Genel Teknik',
      'elektrik': 'Elektrik',
      'mekanik': 'Mekanik',
      'tesisat': 'Tesisat',
    };
    return labels[tag] ?? tag;
  }

  Color _teknikTagColor(String tag) {
    switch (tag) {
      case 'elektrik': return ScadaColors.amber;
      case 'mekanik': return ScadaColors.green;
      case 'tesisat': return ScadaColors.purple;
      default: return ScadaColors.cyan;
    }
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
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, '/route-detail', arguments: route.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(route.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
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
              Text(route.description!, style: TextStyle(fontSize: 11, color: context.scada.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
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
              Icon(Icons.timer_outlined, size: 12, color: context.scada.textDim),
              const SizedBox(width: 3),
              Text('${route.estimatedMinutes} dk', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.check_circle_outline, size: 12, color: context.scada.textDim),
              const SizedBox(width: 3),
              Text('Gecme: %${route.passingScore}', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 12, color: context.scada.textDim),
            ]),
          ]),
        ),
      ),
    );
  }
}
