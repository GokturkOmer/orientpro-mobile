import 'dart:io' show File, Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../models/training.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';
import '../../core/utils/file_saver.dart' as file_saver;
import '../../core/utils/status_helper.dart';
import '../../core/utils/department_filter.dart';
import '../../widgets/section_header.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  bool _isSupervisor = false;
  TabController? _tabController;
  List<SpacedReview> _pendingReviews = [];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _isSupervisor = RoleHelper.isSupervisor(auth.user?.role);
    if (_isSupervisor) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;
    await ref.read(trainingProvider.notifier).loadProgressData(
      auth.user!.id,
      department: auth.user!.department,
      isSupervisor: _isSupervisor,
    );
    // Tekrar gereken konulari yukle
    final reviews = await ref.read(trainingProvider.notifier).loadPendingReviews(auth.user!.id);
    if (mounted) setState(() => _pendingReviews = reviews);
  }

  Future<void> _downloadReport() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.get(
        '/training/stats/${auth.user!.id}',
        queryParameters: {'format': 'pdf'},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as List<int>;
      final fileName = 'ilerleme_raporu_${DateTime.now().toIso8601String().split('T').first}.pdf';

      if (kIsWeb) {
        await file_saver.saveFileWeb(bytes, fileName);
      } else {
        String dirPath;
        if (Platform.isAndroid) {
          final dir = await getExternalStorageDirectory();
          dirPath = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
        } else {
          dirPath = (await getApplicationDocumentsDirectory()).path;
        }
        final file = File('$dirPath/$fileName');
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor indirildi: $fileName'), backgroundColor: ScadaColors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor indirme hatasi'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  // RBAC filtrelenmiş departmanlar
  List<Department> _getFilteredDepartments(TrainingState training) {
    final auth = ref.read(authProvider);
    return DepartmentFilter.filterDepartments(
      departments: training.departments,
      userRole: auth.user?.role,
      userDepartment: auth.user?.department,
    );
  }

  // RBAC filtrelenmiş rotalar
  List<TrainingRoute> _getFilteredRoutes(TrainingState training) {
    final auth = ref.read(authProvider);
    return DepartmentFilter.filterRoutes(
      routes: training.routes,
      departments: training.departments,
      userRole: auth.user?.role,
      userDepartment: auth.user?.department,
    );
  }

  // Departman bazlı ilerleme hesapla
  double _calcDeptProgress(String departmentId, TrainingState training) {
    final deptModuleIds = training.moduleMap.entries
        .where((e) => e.value.departmentId == departmentId)
        .map((e) => e.key)
        .toSet();
    if (deptModuleIds.isEmpty) return 0;
    final deptProgress = training.progress.where((p) => deptModuleIds.contains(p.moduleId)).toList();
    if (deptProgress.isEmpty) return 0;
    final completed = deptProgress.where((p) => p.status == 'completed').length;
    return completed / deptModuleIds.length;
  }

  // Departmandaki başlanan modül sayısı
  int _deptStartedCount(String departmentId, TrainingState training) {
    final deptModuleIds = training.moduleMap.entries
        .where((e) => e.value.departmentId == departmentId)
        .map((e) => e.key)
        .toSet();
    return training.progress.where((p) => deptModuleIds.contains(p.moduleId)).length;
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
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
          Text('Ilerleme Takibi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: ScadaColors.cyan, size: 20),
            tooltip: 'Rapor Indir',
            onPressed: _downloadReport,
          ),
        ],
        bottom: _isSupervisor ? TabBar(
          controller: _tabController,
          indicatorColor: ScadaColors.amber,
          labelColor: ScadaColors.amber,
          unselectedLabelColor: context.scada.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Benim Ilerlemem'),
            Tab(text: 'Ekip Takibi'),
          ],
        ) : null,
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : training.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(training.error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadData, child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.amber))),
                  ]),
                )
              : _isSupervisor
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyProgressTab(training),
                        _buildTeamProgressTab(training),
                      ],
                    )
                  : _buildMyProgressTab(training),
    );
  }

  Widget _buildMyProgressTab(TrainingState training) {
    final departments = _getFilteredDepartments(training);
    final routes = _getFilteredRoutes(training);
    return RefreshIndicator(
      color: ScadaColors.amber,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          if (training.stats != null) _buildOverallProgressCard(training.stats!),

          // Tekrar gereken konular
          if (_pendingReviews.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(icon: Icons.replay, title: 'TEKRAR GEREKEN KONULAR'),
            const SizedBox(height: 12),
            ..._pendingReviews.map((review) => _buildReviewCard(review, training)),
          ],

          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.business, title: 'DEPARTMAN BAZLI ILERLEME'),
          const SizedBox(height: 12),
          ...departments.map((dept) {
            final deptRoutes = routes.where((r) => r.departmentId == dept.id).toList();
            if (deptRoutes.isEmpty) return const SizedBox.shrink();
            return _buildDepartmentProgressCard(dept, deptRoutes, training);
          }),
          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.list_alt, title: 'MODUL DETAY'),
          const SizedBox(height: 12),
          if (training.progress.isEmpty)
            _buildEmptyState()
          else
            ...training.progress.map((p) => _buildModuleProgressItem(p, training)),
        ],
      ),
    );
  }

  Widget _buildTeamProgressTab(TrainingState training) {
    if (training.teamProgress.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.group_off, size: 48, color: context.scada.textDim),
        const SizedBox(height: 12),
        Text('Departmaninizda henuz personel yok', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: training.teamProgress.length,
      itemBuilder: (context, index) => _buildTeamMemberCard(training.teamProgress[index]),
    );
  }

  Widget _buildTeamMemberCard(TeamMemberProgress member) {
    final progressColor = member.completionPercent >= 80
        ? ScadaColors.green
        : member.completionPercent >= 40
            ? ScadaColors.amber
            : ScadaColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text(
              member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
            if (member.department != null)
              Text(member.department!, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('%${member.completionPercent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor)),
            Text('tamamlama', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
          ]),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: member.completionPercent / 100,
            minHeight: 6,
            backgroundColor: context.scada.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.verified_user, size: 12, color: context.scada.textDim),
          const SizedBox(width: 4),
          Text('${member.acknowledgedCount}/${member.totalRequired} onay', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
          const Spacer(),
          if (member.lastActivity != null) ...[
            Icon(Icons.access_time, size: 12, color: context.scada.textDim),
            const SizedBox(width: 4),
            Text('Son: ${_formatDate(member.lastActivity!)}', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          ],
        ]),
      ]),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildOverallProgressCard(TrainingStats stats) {
    final percent = stats.completionPercent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Genel Ilerleme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
            const Spacer(),
            Text('${stats.totalModules} modul', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
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
                      backgroundColor: context.scada.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent >= 80 ? ScadaColors.green : percent >= 40 ? ScadaColors.amber : ScadaColors.red,
                      ),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('%${percent.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                    Text('Tamamlandi', style: TextStyle(fontSize: 9, color: context.scada.textSecondary)),
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
        Text(label, style: TextStyle(fontSize: 8, color: context.scada.textSecondary)),
      ]),
    );
  }

  Widget _buildDepartmentProgressCard(Department dept, List<TrainingRoute> routes, TrainingState training) {
    final deptColor = dept.color != null
        ? Color(int.parse('0xFF${dept.color!.replaceAll('#', '')}'))
        : ScadaColors.purple;

    final totalRoutes = routes.length;
    final mandatoryRoutes = routes.where((r) => r.isMandatory).length;
    final totalMinutes = routes.fold<int>(0, (sum, r) => sum + r.estimatedMinutes);
    final progress = _calcDeptProgress(dept.id, training);
    final startedCount = _deptStartedCount(dept.id, training);
    final totalModulesInDept = training.moduleMap.entries.where((e) => e.value.departmentId == dept.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scada.card,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.scada.border,
              valueColor: AlwaysStoppedAnimation<Color>(deptColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text(
              startedCount > 0 ? '$startedCount/$totalModulesInDept modul baslandi' : 'Henuz baslanmadi',
              style: TextStyle(fontSize: 9, color: startedCount > 0 ? deptColor : context.scada.textDim),
            ),
            const Spacer(),
            Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: deptColor)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _buildChip(Icons.flag, '$mandatoryRoutes zorunlu', ScadaColors.red),
            const SizedBox(width: 8),
            _buildChip(Icons.timer, '$totalMinutes dk', context.scada.textSecondary),
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

  Widget _buildModuleProgressItem(UserProgress p, TrainingState training) {
    final statusColor = StatusHelper.trainingStatusColor(p.status);
    final statusIcon = StatusHelper.trainingStatusIcon(p.status);

    final info = training.moduleMap[p.moduleId];
    final moduleName = info?.title ?? 'Modul #${p.moduleId.length > 8 ? p.moduleId.substring(0, 8) : p.moduleId}';
    final moduleType = info?.moduleType ?? 'lesson';
    final typeIcon = StatusHelper.moduleTypeIcon(moduleType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(statusIcon, color: statusColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(moduleName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.scada.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(p.statusText, style: TextStyle(fontSize: 9, color: statusColor)),
              ),
              const SizedBox(width: 6),
              Icon(typeIcon, size: 10, color: context.scada.textDim),
              const SizedBox(width: 2),
              Text(_moduleTypeText(moduleType), style: TextStyle(fontSize: 9, color: context.scada.textDim)),
              if (p.timeSpentMinutes > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.timer, size: 10, color: context.scada.textDim),
                const SizedBox(width: 2),
                Text('${p.timeSpentMinutes} dk', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
              ],
            ]),
          ]),
        ),
        if (p.progressPercent > 0)
          SizedBox(
            width: 36, height: 36,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: p.progressPercent / 100, strokeWidth: 3, backgroundColor: context.scada.border, valueColor: AlwaysStoppedAnimation<Color>(statusColor)),
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

  Widget _buildReviewCard(SpacedReview review, TrainingState training) {
    final info = training.moduleMap[review.moduleId];
    final moduleName = info?.title ?? 'Modul';
    final weakCount = review.weakQuestionIds?.length ?? 0;
    final reasonText = review.reason == 'quiz_fail' ? 'Quiz basarisiz' : 'Dusuk puan';
    final intervalText = '${review.intervalDays} gun araliklarla tekrar';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ScadaColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.replay, color: ScadaColors.orange, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(moduleName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: ScadaColors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(reasonText, style: const TextStyle(fontSize: 9, color: ScadaColors.orange)),
              ),
              const SizedBox(width: 6),
              Text('$weakCount zayif soru', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
            ]),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.schedule, size: 12, color: context.scada.textDim),
          const SizedBox(width: 4),
          Text(intervalText, style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          const Spacer(),
          SizedBox(
            height: 30,
            child: ElevatedButton.icon(
              onPressed: () => _startReview(review),
              icon: const Icon(Icons.play_arrow, size: 14),
              label: const Text('Tekrar Et', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _startReview(SpacedReview review) async {
    // Tamamla ve quiz ekranina yonlendir
    final success = await ref.read(trainingProvider.notifier).completeReview(review.id);
    if (success && mounted) {
      Navigator.pushNamed(context, '/quiz', arguments: {'quizId': review.quizId});
      // Listeyi guncelle
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        final reviews = await ref.read(trainingProvider.notifier).loadPendingReviews(auth.user!.id);
        if (mounted) setState(() => _pendingReviews = reviews);
      }
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(Icons.school_outlined, size: 48, color: context.scada.textDim.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text('Henuz bir egitim modulu baslatmadiniz', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
        const SizedBox(height: 4),
        Text('Egitim Rotalari\'ndan bir modul secin', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
      ]),
    );
  }

}
