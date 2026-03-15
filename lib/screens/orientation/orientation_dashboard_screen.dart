import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../models/training.dart';

class OrientationDashboardScreen extends ConsumerStatefulWidget {
  const OrientationDashboardScreen({super.key});

  @override
  ConsumerState<OrientationDashboardScreen> createState() => _OrientationDashboardScreenState();
}

class _OrientationDashboardScreenState extends ConsumerState<OrientationDashboardScreen> {
  DashboardSummary? _summary;
  List<TrainingReminder> _reminders = [];
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = ref.read(authProvider);
      ref.read(trainingProvider.notifier).loadDepartments();
      ref.read(trainingProvider.notifier).loadRoutes();
      if (auth.user != null) {
        ref.read(trainingProvider.notifier).loadStats(auth.user!.id);
        // Dashboard summary ve reminders yukle
        final summary = await ref.read(trainingProvider.notifier).loadDashboardSummary(auth.user!.id);
        final reminders = await ref.read(trainingProvider.notifier).loadReminders(auth.user!.id);
        final reviews = await ref.read(trainingProvider.notifier).loadPendingReviews(auth.user!.id);
        // Ilk giris icin hatirlatma programi olustur
        ref.read(trainingProvider.notifier).generateReminders(auth.user!.id);
        // Okunmamis duyuru sayisini yukle
        ref.read(announcementProvider.notifier).loadUnreadCount(auth.user!.id, department: auth.user!.department);
        if (mounted) {
          setState(() {
            _summary = summary;
            _reminders = reminders;
            _reviewCount = reviews.length;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pushReplacementNamed(context, '/module-selection'),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.school, color: ScadaColors.purple, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Oryantasyon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: ScadaColors.textDim),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ScadaColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: ScadaColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: ScadaColors.purple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hosgeldiniz, ${auth.user?.fullName ?? ""}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                      const Text('Oryantasyon ve egitim modulune hosgeldiniz', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                    ])),
                  ]),
                ),

                // Stats cards
                if (training.stats != null) ...[
                  const SizedBox(height: 12),
                  // Genel ilerleme bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ScadaColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('Genel Ilerleme', style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                        const Spacer(),
                        Text('%${training.stats!.completionPercent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.amber)),
                        Text(' (${training.stats!.completedModules}/${training.stats!.totalModules})', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: training.stats!.completionPercent / 100,
                          minHeight: 6,
                          backgroundColor: ScadaColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            training.stats!.completionPercent >= 80 ? ScadaColors.green : training.stats!.completionPercent >= 40 ? ScadaColors.amber : ScadaColors.purple,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _buildStatCard('Tamamlanan', '${training.stats!.completedModules}', ScadaColors.green),
                    const SizedBox(width: 8),
                    _buildStatCard('Devam Eden', '${training.stats!.inProgressModules}', ScadaColors.amber),
                    const SizedBox(width: 8),
                    _buildStatCard('Quiz Basari', '${training.stats!.quizzesPassed}', ScadaColors.cyan),
                  ]),
                ],

                // Bekleyen Islemler + Tekrar Gerekli
                if (_summary != null && (_summary!.pendingAcknowledgments > 0 || _reviewCount > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ScadaColors.amber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ScadaColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.pending_actions, size: 14, color: ScadaColors.amber),
                        const SizedBox(width: 6),
                        const Text('BEKLEYEN ISLEMLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.amber, letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 8),
                      if (_summary!.pendingAcknowledgments > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            const Icon(Icons.verified_user_outlined, size: 14, color: ScadaColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('${_summary!.pendingAcknowledgments} modul onay bekliyor', style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary)),
                          ]),
                        ),
                      if (_reviewCount > 0)
                        Row(children: [
                          const Icon(Icons.replay, size: 14, color: ScadaColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('$_reviewCount tekrar gerektiren konu', style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary)),
                        ]),
                    ]),
                  ),
                ],

                // Tamamlanmamis Zorunlu Egitimler (departman filtreleme)
                if (_summary != null && _summary!.upcomingDeadlines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.schedule, size: 14, color: ScadaColors.textDim),
                    const SizedBox(width: 6),
                    const Text('TAMAMLANMAMIS ZORUNLU EGITIMLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final userRole = auth.user?.role;
                    final userDept = auth.user?.department;
                    final visibleDepts = RoleHelper.visibleDepartments(userRole, userDept);
                    final filtered = visibleDepts == null
                        ? _summary!.upcomingDeadlines
                        : _summary!.upcomingDeadlines.where((d) =>
                            visibleDepts.contains(d['department_code'])).toList();
                    return Column(children: _buildGroupedDeadlines(filtered));
                  }),
                ],

                // Haftalik Ozet
                if (_summary != null && (_summary!.weeklyCompleted > 0 || _summary!.totalAcknowledgments > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ScadaColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.border),
                    ),
                    child: Row(children: [
                      _buildMiniStat('Bu Hafta', '${_summary!.weeklyCompleted}', 'modul', ScadaColors.cyan),
                      Container(width: 1, height: 24, color: ScadaColors.border),
                      _buildMiniStat('Sure', '${_summary!.weeklyTimeMinutes}', 'dk', ScadaColors.amber),
                      Container(width: 1, height: 24, color: ScadaColors.border),
                      _buildMiniStat('Onay', '${_summary!.totalAcknowledgments}', 'modul', ScadaColors.green),
                    ]),
                  ),
                ],

                // Hatirlatmalar
                if (_reminders.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._reminders.take(2).map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ScadaColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.notifications_active, size: 16, color: ScadaColors.cyan),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                        Text(r.message, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      InkWell(
                        onTap: () => ref.read(trainingProvider.notifier).markReminderRead(r.id).then((_) {
                          setState(() => _reminders.removeWhere((rem) => rem.id == r.id));
                        }),
                        child: const Icon(Icons.close, size: 14, color: ScadaColors.textDim),
                      ),
                    ]),
                  )),
                ],

                const SizedBox(height: 20),

                // Section: Moduller
                Row(children: [
                  const Icon(Icons.apps, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 6),
                  const Text('MODULLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),

                Builder(builder: (context) {
                  final userRole = auth.user?.role;
                  final userDept = auth.user?.department;
                  final visibleDepts = RoleHelper.visibleDepartments(userRole, userDept);
                  final allowedDeptIds = visibleDepts == null
                      ? null
                      : training.departments.where((d) => visibleDepts.contains(d.code)).map((d) => d.id).toSet();
                  var filteredRoutes = allowedDeptIds == null
                      ? training.routes
                      : training.routes.where((r) => allowedDeptIds.contains(r.departmentId)).toList();
                  // Teknik dept icerisinde tag filtreleme
                  final teknikTags = RoleHelper.visibleTeknikTags(userRole);
                  if (teknikTags != null && teknikTags.isNotEmpty) {
                    final teknikDeptIds = training.departments.where((d) => d.code == 'teknik').map((d) => d.id).toSet();
                    filteredRoutes = filteredRoutes.where((r) {
                      if (!teknikDeptIds.contains(r.departmentId)) return true;
                      return RoleHelper.canSeeTeknikRoute(userRole, r.tags);
                    }).toList();
                  }
                  return _buildModuleCard(
                    icon: Icons.route,
                    title: 'Egitim Rotalari',
                    description: 'Departman bazli egitim rotalari ve icerikler',
                    color: ScadaColors.cyan,
                    badge: '${filteredRoutes.length}',
                    onTap: () => Navigator.pushNamed(context, '/training-routes'),
                  );
                }),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.quiz,
                  title: 'Quiz & Sinavlar',
                  description: 'Bilgi testleri ve degerlendirmeler',
                  color: ScadaColors.green,
                  onTap: () => Navigator.pushNamed(context, '/training-routes'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.trending_up,
                  title: 'Ilerleme Takibi',
                  description: 'Egitim tamamlama durumu ve raporlar',
                  color: ScadaColors.amber,
                  onTap: () => Navigator.pushNamed(context, '/progress'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.smart_toy,
                  title: 'AI Asistan',
                  description: 'Oryantasyon sureci icin yapay zeka destegi',
                  color: ScadaColors.purple,
                  onTap: () => Navigator.pushNamed(context, '/ai-assistant'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.verified,
                  title: 'Sertifikalar',
                  description: 'Egitim tamamlama sertifikalari ve onaylar',
                  color: ScadaColors.orange,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final annState = ref.watch(announcementProvider);
                  return _buildModuleCard(
                    icon: Icons.campaign,
                    title: 'Duyuru Panosu',
                    description: 'Sirket ve departman duyurulari',
                    color: ScadaColors.amber,
                    badge: annState.unreadCount > 0 ? '${annState.unreadCount}' : null,
                    onTap: () => Navigator.pushNamed(context, '/announcements'),
                  );
                }),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.folder_open,
                  title: 'Icerik Kutuphanesi',
                  description: 'Kisisel ve paylasilan belgeler',
                  color: ScadaColors.purple,
                  onTap: () => Navigator.pushNamed(context, '/library'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.assignment,
                  title: 'Form & Checklistler',
                  description: 'PDF formlar ve Excel checklistler — indir veya goruntule',
                  color: ScadaColors.green,
                  onTap: () => Navigator.pushNamed(context, '/forms'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.person,
                  title: 'Profil Karti',
                  description: 'Kisisel bilgiler, acil durum, sertifikalar',
                  color: ScadaColors.orange,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.calendar_month,
                  title: 'Vardiya & Gorevler',
                  description: 'Haftalik vardiya plani ve gorev takibi',
                  color: ScadaColors.amber,
                  onTap: () => Navigator.pushNamed(context, '/shifts'),
                ),

                // Yonetici: Ekip Egitim Takibi
                if (auth.user != null && RoleHelper.isSupervisor(auth.user!.role)) ...[
                  const SizedBox(height: 8),
                  _buildModuleCard(
                    icon: Icons.group,
                    title: 'Ekip Egitim Takibi',
                    description: 'Personel egitim tamamlama ve onay durumu',
                    color: ScadaColors.red,
                    onTap: () => Navigator.pushNamed(context, '/team-progress'),
                  ),
                ],

                // Error message
                if (training.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ScadaColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(training.error!, style: const TextStyle(fontSize: 11, color: ScadaColors.red)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
          ]),
          Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
        ]),
      ),
    );
  }

  List<Widget> _buildGroupedDeadlines(List<dynamic> deadlines) {
    final widgets = <Widget>[];
    final genItems = deadlines.where((d) => d['department_code'] == 'GEN').toList();
    final otherItems = deadlines.where((d) => d['department_code'] != 'GEN').toList();

    if (genItems.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Genel Oryantasyon', style: TextStyle(fontSize: 9, color: ScadaColors.cyan, fontWeight: FontWeight.w600)),
          ),
        ]),
      ));
      for (final d in genItems) {
        widgets.add(_buildDeadlineItem(d));
      }
    }

    if (otherItems.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Departman Egitimleri', style: TextStyle(fontSize: 9, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
          ),
        ]),
      ));
      for (final d in otherItems) {
        widgets.add(_buildDeadlineItem(d));
      }
    }

    return widgets;
  }

  Widget _buildDeadlineItem(dynamic d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ScadaColors.border),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ScadaColors.textPrimary)),
            Text('${d['completed_modules'] ?? 0}/${d['total_modules'] ?? 0} modul', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          ])),
          Text('~${d['estimated_minutes'] ?? 0} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
        ]),
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        subtitle: Text(description, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: ScadaColors.textDim),
        onTap: onTap,
      ),
    );
  }
}
