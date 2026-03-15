import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../models/training.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api_config.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _loading = true;
  List<Department> _departments = [];
  List<TrainingRoute> _routes = [];
  List<UserProgress> _progress = [];
  TrainingStats? _stats;
  String? _error;

  // Modul ID -> Modul bilgisi lookup
  Map<String, _ModuleInfo> _moduleMap = {};

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.webUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    try {
      // Paralel yukle: departmanlar, rotalar, moduller
      final results = await Future.wait([
        _dio.get('/training/departments'),
        _dio.get('/training/routes'),
        _dio.get('/training/modules'),
      ]);

      _departments = (results[0].data as List).map((d) => Department.fromJson(d)).toList();
      _routes = (results[1].data as List).map((r) => TrainingRoute.fromJson(r)).toList();

      // Modul lookup map olustur
      final modules = results[2].data as List;
      _moduleMap = {};
      for (final m in modules) {
        final routeId = m['route_id'] as String;
        // Route'un departmentId'sini bul
        final route = _routes.where((r) => r.id == routeId).toList();
        _moduleMap[m['id']] = _ModuleInfo(
          title: m['title'] ?? 'Bilinmeyen Modul',
          routeId: routeId,
          departmentId: route.isNotEmpty ? route.first.departmentId : '',
          moduleType: m['module_type'] ?? 'lesson',
          estimatedMinutes: m['estimated_minutes'] ?? 15,
        );
      }

      if (auth.user != null) {
        try {
          final statsRes = await _dio.get('/training/stats/${auth.user!.id}');
          _stats = TrainingStats.fromJson(statsRes.data);
        } catch (_) {}

        try {
          final progRes = await _dio.get('/training/progress/${auth.user!.id}');
          _progress = (progRes.data as List).map((p) => UserProgress.fromJson(p)).toList();
        } catch (_) {}
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Veri yuklenemedi'; });
    }
  }

  // Departman bazli ilerleme hesapla
  double _calcDeptProgress(String departmentId) {
    // Bu departmandaki tum modulleri bul
    final deptModuleIds = _moduleMap.entries
        .where((e) => e.value.departmentId == departmentId)
        .map((e) => e.key)
        .toSet();
    if (deptModuleIds.isEmpty) return 0;

    // Bu modullerdeki progress kayitlarini bul
    final deptProgress = _progress.where((p) => deptModuleIds.contains(p.moduleId)).toList();
    if (deptProgress.isEmpty) return 0;

    final completed = deptProgress.where((p) => p.status == 'completed').length;
    return completed / deptModuleIds.length;
  }

  // Departmandaki baslanan modul sayisi
  int _deptStartedCount(String departmentId) {
    final deptModuleIds = _moduleMap.entries
        .where((e) => e.value.departmentId == departmentId)
        .map((e) => e.key)
        .toSet();
    return _progress.where((p) => deptModuleIds.contains(p.moduleId)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.trending_up, color: ScadaColors.amber, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Ilerleme Takibi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadData(); }, child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.amber))),
                  ]),
                )
              : RefreshIndicator(
                  color: ScadaColors.amber,
                  onRefresh: () async { setState(() => _loading = true); await _loadData(); },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_stats != null) _buildOverallProgressCard(_stats!),

                      const SizedBox(height: 20),

                      _buildSectionHeader(Icons.business, 'DEPARTMAN BAZLI ILERLEME'),
                      const SizedBox(height: 12),

                      ..._departments.map((dept) {
                        final deptRoutes = _routes.where((r) => r.departmentId == dept.id).toList();
                        if (deptRoutes.isEmpty) return const SizedBox.shrink();
                        return _buildDepartmentProgressCard(dept, deptRoutes);
                      }),

                      const SizedBox(height: 20),

                      _buildSectionHeader(Icons.list_alt, 'MODUL DETAY'),
                      const SizedBox(height: 12),

                      if (_progress.isEmpty)
                        _buildEmptyState()
                      else
                        ..._progress.map((p) => _buildModuleProgressItem(p)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallProgressCard(TrainingStats stats) {
    final percent = stats.completionPercent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Genel Ilerleme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            const Spacer(),
            Text('${stats.totalModules} modul', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 10,
                      backgroundColor: ScadaColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent >= 80 ? ScadaColors.green : percent >= 40 ? ScadaColors.amber : ScadaColors.red,
                      ),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('%${percent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                    const Text('Tamamlandi', style: TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _buildMiniStat(Icons.check_circle, '${stats.completedModules}', 'Tamamlanan', ScadaColors.green),
            _buildMiniStat(Icons.play_circle, '${stats.inProgressModules}', 'Devam Eden', ScadaColors.amber),
            _buildMiniStat(Icons.quiz, '${stats.quizzesPassed}', 'Quiz Basari', ScadaColors.cyan),
            _buildMiniStat(Icons.timer, '${stats.totalTimeMinutes}dk', 'Toplam Sure', ScadaColors.purple),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: ScadaColors.textSecondary)),
      ]),
    );
  }

  Widget _buildDepartmentProgressCard(Department dept, List<TrainingRoute> routes) {
    final deptColor = dept.color != null
        ? Color(int.parse('0xFF${dept.color!.replaceAll('#', '')}'))
        : ScadaColors.purple;

    final totalRoutes = routes.length;
    final mandatoryRoutes = routes.where((r) => r.isMandatory).length;
    final totalMinutes = routes.fold<int>(0, (sum, r) => sum + r.estimatedMinutes);
    final progress = _calcDeptProgress(dept.id);
    final startedCount = _deptStartedCount(dept.id);
    final totalModulesInDept = _moduleMap.entries.where((e) => e.value.departmentId == dept.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: deptColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: deptColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(dept.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: deptColor))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: deptColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('$totalRoutes rota', style: TextStyle(fontSize: 9, color: deptColor)),
            ),
          ]),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: ScadaColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(deptColor),
            ),
          ),
          const SizedBox(height: 4),
          // Progress text
          Row(children: [
            Text(
              startedCount > 0 ? '$startedCount/$totalModulesInDept modul baslandi' : 'Henuz baslanmadi',
              style: TextStyle(fontSize: 9, color: startedCount > 0 ? deptColor : ScadaColors.textDim),
            ),
            const Spacer(),
            Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: deptColor)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _buildChip(Icons.flag, '$mandatoryRoutes zorunlu', ScadaColors.red),
            const SizedBox(width: 8),
            _buildChip(Icons.timer, '$totalMinutes dk', ScadaColors.textSecondary),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/training-routes', arguments: {'departmentId': dept.id, 'departmentName': dept.name}),
              child: Row(children: [
                Text('Detay', style: TextStyle(fontSize: 10, color: deptColor)),
                Icon(Icons.arrow_forward_ios, size: 10, color: deptColor),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, color: color)),
    ]);
  }

  Widget _buildModuleProgressItem(UserProgress p) {
    final statusColor = p.status == 'completed' ? ScadaColors.green : p.status == 'in_progress' ? ScadaColors.amber : ScadaColors.textDim;
    final statusIcon = p.status == 'completed' ? Icons.check_circle : p.status == 'in_progress' ? Icons.play_circle : Icons.radio_button_unchecked;

    // Modul bilgisini lookup'tan al
    final info = _moduleMap[p.moduleId];
    final moduleName = info?.title ?? 'Modul #${p.moduleId.length > 8 ? p.moduleId.substring(0, 8) : p.moduleId}';
    final moduleType = info?.moduleType ?? 'lesson';
    final typeIcon = moduleType == 'video' ? Icons.play_circle_outline : moduleType == 'practice' ? Icons.build : moduleType == 'assessment' ? Icons.quiz : Icons.menu_book;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(statusIcon, color: statusColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(moduleName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ScadaColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(p.statusText, style: TextStyle(fontSize: 9, color: statusColor)),
              ),
              const SizedBox(width: 6),
              Icon(typeIcon, size: 10, color: ScadaColors.textDim),
              const SizedBox(width: 2),
              Text(_moduleTypeText(moduleType), style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
              if (p.timeSpentMinutes > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.timer, size: 10, color: ScadaColors.textDim),
                const SizedBox(width: 2),
                Text('${p.timeSpentMinutes} dk', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
              ],
            ]),
          ]),
        ),
        if (p.progressPercent > 0)
          SizedBox(
            width: 36, height: 36,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: p.progressPercent / 100, strokeWidth: 3, backgroundColor: ScadaColors.border, valueColor: AlwaysStoppedAnimation<Color>(statusColor)),
              Text('%${p.progressPercent.toInt()}', style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  String _moduleTypeText(String type) {
    switch (type) {
      case 'video': return 'Video';
      case 'practice': return 'Uygulama';
      case 'assessment': return 'Degerlendirme';
      default: return 'Ders';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(Icons.school_outlined, size: 48, color: ScadaColors.textDim.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('Henuz bir egitim modulu baslatmadiniz', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Egitim Rotalari\'ndan bir modul secin', style: TextStyle(fontSize: 10, color: ScadaColors.textDim)),
      ]),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 14, color: ScadaColors.textDim),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
    ]);
  }
}

class _ModuleInfo {
  final String title;
  final String routeId;
  final String departmentId;
  final String moduleType;
  final int estimatedMinutes;

  _ModuleInfo({required this.title, required this.routeId, required this.departmentId, required this.moduleType, required this.estimatedMinutes});
}
