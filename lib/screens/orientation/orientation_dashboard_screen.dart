import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../core/utils/department_filter.dart';
import '../../widgets/notif_bell.dart';

class OrientationDashboardScreen extends ConsumerStatefulWidget {
  const OrientationDashboardScreen({super.key});

  @override
  ConsumerState<OrientationDashboardScreen> createState() => _OrientationDashboardScreenState();
}

class _OrientationDashboardScreenState extends ConsumerState<OrientationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(trainingProvider.notifier).loadDashboardData(auth.user!.id);
        ref.read(announcementProvider.notifier).loadUnreadCount(auth.user!.id, department: auth.user!.department);
        ref.read(announcementProvider.notifier).loadAnnouncements(auth.user!.id, department: auth.user!.department);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
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
          Text('Oryantasyon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          const NotifBell(),
          IconButton(
            icon: Icon(Icons.logout, size: 20, color: context.scada.textDim),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.purple))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Welcome card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.scada.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.scada.border),
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
                      Text('Hosgeldiniz, ${auth.user?.fullName ?? ""}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                      Text('Oryantasyon ve egitim modulune hosgeldiniz', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                    ])),
                  ]),
                ),

                // Bugunku Egitimim karti
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.pushNamed(context, '/today'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        ScadaColors.cyan.withValues(alpha: 0.15),
                        ScadaColors.purple.withValues(alpha: 0.1),
                      ]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: ScadaColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_stories, color: ScadaColors.cyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bugunku Egitimim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                        Text('Mikro-ogrenme kartlarini goruntule', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                      ])),
                      Icon(Icons.chevron_right, color: ScadaColors.cyan, size: 22),
                    ]),
                  ),
                ),

                // Stats cards
                if (training.stats != null) ...[
                  const SizedBox(height: 12),
                  // Genel ilerleme bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.scada.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.scada.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Genel Ilerleme', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                        const Spacer(),
                        Text('%${training.stats!.completionPercent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.amber)),
                        Text(' (${training.stats!.completedModules}/${training.stats!.totalModules})', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: training.stats!.completionPercent / 100,
                          minHeight: 6,
                          backgroundColor: context.scada.border,
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
                if (training.dashboardSummary != null && (training.dashboardSummary!.pendingAcknowledgments > 0 || training.reviewCount > 0)) ...[
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
                      if (training.dashboardSummary!.pendingAcknowledgments > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: context.scada.textSecondary),
                            const SizedBox(width: 6),
                            Text('${training.dashboardSummary!.pendingAcknowledgments} modul onay bekliyor', style: TextStyle(fontSize: 12, color: context.scada.textPrimary)),
                          ]),
                        ),
                      if (training.reviewCount > 0)
                        Row(children: [
                          Icon(Icons.replay, size: 14, color: context.scada.textSecondary),
                          const SizedBox(width: 6),
                          Text('${training.reviewCount} tekrar gerektiren konu', style: TextStyle(fontSize: 12, color: context.scada.textPrimary)),
                        ]),
                    ]),
                  ),
                ],

                // Tamamlanmamis Zorunlu Egitimler (departman filtreleme)
                if (training.dashboardSummary != null && training.dashboardSummary!.upcomingDeadlines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.schedule, size: 14, color: context.scada.textDim),
                    const SizedBox(width: 6),
                    Text('TAMAMLANMAMIS ZORUNLU EGITIMLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final userRole = auth.user?.role;
                    final userDept = auth.user?.department;
                    final visibleDepts = RoleHelper.visibleDepartments(userRole, userDept);
                    final filtered = visibleDepts == null
                        ? training.dashboardSummary!.upcomingDeadlines
                        : training.dashboardSummary!.upcomingDeadlines.where((d) =>
                            visibleDepts.contains(d['department_code'])).toList();
                    return Column(children: _buildGroupedDeadlines(filtered));
                  }),
                ],

                // Haftalik Ozet
                if (training.dashboardSummary != null && (training.dashboardSummary!.weeklyCompleted > 0 || training.dashboardSummary!.totalAcknowledgments > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.scada.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.scada.border),
                    ),
                    child: Row(children: [
                      _buildMiniStat('Bu Hafta', '${training.dashboardSummary!.weeklyCompleted}', 'modul', ScadaColors.cyan),
                      Container(width: 1, height: 24, color: context.scada.border),
                      _buildMiniStat('Sure', '${training.dashboardSummary!.weeklyTimeMinutes}', 'dk', ScadaColors.amber),
                      Container(width: 1, height: 24, color: context.scada.border),
                      _buildMiniStat('Onay', '${training.dashboardSummary!.totalAcknowledgments}', 'modul', ScadaColors.green),
                    ]),
                  ),
                ],

                // Duyurular onizleme
                Builder(builder: (context) {
                  final annState = ref.watch(announcementProvider);
                  final previewItems = annState.announcements.take(3).toList();
                  if (previewItems.isEmpty && annState.unreadCount == 0) return const SizedBox.shrink();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.scada.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ScadaColors.amber.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.campaign, size: 14, color: ScadaColors.amber),
                          const SizedBox(width: 6),
                          const Text('DUYURULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.amber, letterSpacing: 1)),
                          if (annState.unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: ScadaColors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text('${annState.unreadCount} yeni', style: const TextStyle(fontSize: 9, color: ScadaColors.red, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ]),
                        if (previewItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...previewItems.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(top: 4, right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: a.isRead == true ? context.scada.textDim : ScadaColors.amber,
                                ),
                              ),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.scada.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(a.body, style: TextStyle(fontSize: 10, color: context.scada.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              const SizedBox(width: 6),
                              Text(a.timeAgo, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
                            ]),
                          )),
                        ],
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                            onPressed: () => Navigator.pushNamed(context, '/announcements'),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('Tumunu Gor', style: TextStyle(fontSize: 11, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 10, color: ScadaColors.amber),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]);
                }),

                const SizedBox(height: 20),

                // Section: Moduller
                Row(children: [
                  Icon(Icons.apps, size: 14, color: context.scada.textDim),
                  const SizedBox(width: 6),
                  Text('MODULLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),

                Builder(builder: (context) {
                  final annState = ref.watch(announcementProvider);
                  final filteredRoutes = DepartmentFilter.filterRoutes(
                    routes: training.routes,
                    departments: training.departments,
                    userRole: auth.user?.role,
                    userDepartment: auth.user?.department,
                  );

                  final modules = [
                    _ModuleCardConfig(icon: Icons.route, title: 'Egitim Rotalari', description: 'Departman bazli egitim rotalari ve icerikler', color: ScadaColors.cyan, route: '/training-routes', badge: '${filteredRoutes.length}'),
                    _ModuleCardConfig(icon: Icons.quiz, title: 'Quiz & Sinavlar', description: 'Bilgi testleri ve degerlendirmeler', color: ScadaColors.green, route: '/quizzes'),
                    _ModuleCardConfig(icon: Icons.trending_up, title: 'Ilerleme Takibi', description: 'Egitim tamamlama durumu ve raporlar', color: ScadaColors.amber, route: '/progress'),
                    _ModuleCardConfig(icon: Icons.smart_toy, title: 'AI Asistan', description: 'Oryantasyon sureci icin yapay zeka destegi', color: ScadaColors.purple, route: '/ai-assistant'),
                    _ModuleCardConfig(icon: Icons.campaign, title: 'Duyuru Panosu', description: 'Sirket ve departman duyurulari', color: ScadaColors.amber, route: '/announcements', badge: annState.unreadCount > 0 ? '${annState.unreadCount}' : null),
                    _ModuleCardConfig(icon: Icons.folder_open, title: 'Icerik Kutuphanesi', description: 'Kisisel ve paylasilan belgeler', color: ScadaColors.purple, route: '/library'),
                    _ModuleCardConfig(icon: Icons.person, title: 'Profil Karti', description: 'Kisisel bilgiler, acil durum, sertifikalar', color: ScadaColors.orange, route: '/profile'),
                    _ModuleCardConfig(icon: Icons.calendar_month, title: 'Vardiya & Gorevler', description: 'Haftalik vardiya plani ve gorev takibi', color: ScadaColors.amber, route: '/shifts'),
                  ];

                  return Column(
                    children: modules.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildModuleCard(
                        icon: m.icon, title: m.title, description: m.description,
                        color: m.color, badge: m.badge,
                        onTap: () => Navigator.pushNamed(context, m.route),
                      ),
                    )).toList(),
                  );
                }),


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
          color: context.scada.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: context.scada.textSecondary)),
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
            Text(unit, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
          ]),
          Text(label, style: TextStyle(fontSize: 9, color: context.scada.textSecondary)),
        ]),
      ),
    );
  }

  List<Widget> _buildGroupedDeadlines(List<dynamic> deadlines) {
    final widgets = <Widget>[];
    final genItems = deadlines.where((d) => d['department_code'] == 'GEN').toList();

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


    return widgets;
  }

  Widget _buildDeadlineItem(dynamic d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.scada.border),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['title'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.scada.textPrimary)),
            Text('${d['completed_modules'] ?? 0}/${d['total_modules'] ?? 0} modul', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
          ])),
          Text('~${d['estimated_minutes'] ?? 0} dk', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
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
        color: context.scada.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.scada.border),
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
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        subtitle: Text(description, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: context.scada.textDim),
        onTap: onTap,
      ),
    );
  }
}

class _ModuleCardConfig {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;
  final String? badge;

  const _ModuleCardConfig({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
    this.badge,
  });
}
