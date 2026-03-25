import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api_config.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';


class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loaded = false;

  Future<void> _loadData() async {
    await ref.read(adminProvider.notifier).loadAll();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loaded) {
        _loaded = true;
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final admin = ref.watch(adminProvider);

    final int departmentCount = admin.departments.length;
    final int routeCount = admin.routes.length;
    final int moduleCount = admin.routes.fold<int>(0, (sum, r) => sum + (r.modules?.length ?? 0));

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
            child: const Icon(Icons.admin_panel_settings, color: ScadaColors.amber, size: 20),
          ),
          SizedBox(width: 8),
          Text('Yonetim Paneli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          if (admin.error != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.error, color: ScadaColors.red, size: 20),
            ),
        ],
      ),
      body: admin.isLoading && admin.error == null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: ScadaColors.amber),
              SizedBox(height: 16),
              Text('Yukleniyor...', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Error banner (en uste)
                if (admin.error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ScadaColors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.red.withValues(alpha: 0.4)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.error_outline, color: ScadaColors.red, size: 16),
                        const SizedBox(width: 8),
                        const Text('Hata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.red)),
                        const Spacer(),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text('Tekrar Dene', style: TextStyle(fontSize: 11, color: ScadaColors.cyan)),
                        ),
                      ]),
                      Text(admin.error!, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Welcome section
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
                        color: ScadaColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: ScadaColors.amber, size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hosgeldin, ${auth.user?.fullName ?? ""}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                      Text('Icerik yonetimi ve egitim modulu duzenleme', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                    ])),
                  ]),
                ),

                const SizedBox(height: 16),

                // Stats Row
                Row(children: [
                  _buildStatCard('Departman sayisi', '$departmentCount', Icons.business, ScadaColors.cyan),
                  const SizedBox(width: 8),
                  _buildStatCard('Rota sayisi', '$routeCount', Icons.route, ScadaColors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('Modul sayisi', '$moduleCount', Icons.school, ScadaColors.amber),
                ]),

                const SizedBox(height: 20),

                // Charts section
                if (admin.routes.isNotEmpty) ...[
                  _buildChartsSection(admin),
                  const SizedBox(height: 20),
                ],

                // Quick Actions header
                Row(children: [
                  Icon(Icons.flash_on, size: 14, color: context.scada.textDim),
                  SizedBox(width: 6),
                  Text('HIZLI ISLEMLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),

                // Action cards
                _buildActionCard(
                  icon: Icons.folder_open,
                  title: 'Icerik Yonetimi',
                  onTap: () => Navigator.pushNamed(context, '/admin/content'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Yeni Rota Olustur',
                  onTap: () => Navigator.pushNamed(context, '/admin/route-editor'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.library_books,
                  title: 'Dokuman Havuzu',
                  onTap: () => Navigator.pushNamed(context, '/admin/documents'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.school,
                  title: 'Yeni Modul Olustur',
                  onTap: () {
                    // Rota secimi gerekiyor — icerik yonetimine yonlendir
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Modul olusturmak icin once bir rota secin'),
                        backgroundColor: ScadaColors.amber,
                      ),
                    );
                    Navigator.pushNamed(context, '/admin/content');
                  },
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.quiz,
                  title: 'Quiz Olustur',
                  onTap: () => Navigator.pushNamed(context, '/quizzes'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.people,
                  title: 'Uyelik Yonetimi',
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.campaign,
                  title: 'Duyuru Yonetimi',
                  onTap: () => Navigator.pushNamed(context, '/announcements'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.folder_open,
                  title: 'Icerik Kutuphanesi',
                  onTap: () => Navigator.pushNamed(context, '/library'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.analytics,
                  title: 'Kullanim Analitigi',
                  onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.table_chart,
                  title: 'Excel Export',
                  onTap: () => _exportExcel(context),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.category,
                  title: 'Sektor Sablonlari',
                  onTap: () => Navigator.pushNamed(context, '/admin/templates'),
                ),
                const SizedBox(height: 8),
                _buildActionCard(
                  icon: Icons.shield,
                  title: 'Rol Yonetimi',
                  onTap: () => Navigator.pushNamed(context, '/admin/roles'),
                ),

                const SizedBox(height: 16),
              ]),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: context.scada.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildChartsSection(AdminState admin) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.bar_chart, size: 14, color: context.scada.textDim),
        SizedBox(width: 6),
        Text('ISTATISTIKLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
      ]),
      const SizedBox(height: 12),

      // Departman bazli rota dagilimi — Bar Chart
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Departman Bazli Rota Dagilimi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _buildDepartmentBarChart(admin),
          ),
        ]),
      ),

      const SizedBox(height: 12),

      // Modul dagilimi — Pie Chart
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Icerik Dagilimi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(children: [
              Expanded(child: _buildContentPieChart(admin)),
              const SizedBox(width: 16),
              _buildPieLegend(admin),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildDepartmentBarChart(AdminState admin) {
    // Departman bazli rota sayisi
    final deptMap = <String, int>{};
    for (final route in admin.routes) {
      final dept = route.departmentName ?? 'Genel';
      deptMap[dept] = (deptMap[dept] ?? 0) + 1;
    }
    final depts = deptMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = depts.isEmpty ? 1.0 : depts.first.value.toDouble();

    const colors = [ScadaColors.cyan, ScadaColors.green, ScadaColors.amber, ScadaColors.purple, ScadaColors.orange, ScadaColors.red];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= depts.length) return const SizedBox.shrink();
                final label = depts[idx].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 8)}..' : label,
                    style: TextStyle(fontSize: 9, color: context.scada.textDim),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                return Text('${value.toInt()}', style: TextStyle(fontSize: 9, color: context.scada.textDim));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.scada.border.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(depts.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: depts[i].value.toDouble(),
                color: colors[i % colors.length],
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContentPieChart(AdminState admin) {
    final routeCount = admin.routes.length;
    final moduleCount = admin.routes.fold<int>(0, (sum, r) => sum + (r.modules?.length ?? 0));
    final quizCount = admin.routes.fold<int>(0, (sum, r) {
      return sum + (r.modules?.fold<int>(0, (s, m) => s + (m.quizzes?.length ?? 0)) ?? 0);
    });

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(
            value: routeCount.toDouble(),
            color: ScadaColors.cyan,
            title: '$routeCount',
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            radius: 40,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: moduleCount.toDouble(),
            color: ScadaColors.green,
            title: '$moduleCount',
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            radius: 40,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: quizCount > 0 ? quizCount.toDouble() : 0.5,
            color: ScadaColors.amber,
            title: '$quizCount',
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            radius: 40,
            titlePositionPercentageOffset: 0.55,
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegend(AdminState admin) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendItem(ScadaColors.cyan, 'Rotalar', admin.routes.length),
        const SizedBox(height: 8),
        _legendItem(ScadaColors.green, 'Moduller', admin.routes.fold<int>(0, (sum, r) => sum + (r.modules?.length ?? 0))),
        const SizedBox(height: 8),
        _legendItem(ScadaColors.amber, 'Quizler', admin.routes.fold<int>(0, (sum, r) => sum + (r.modules?.fold<int>(0, (s, m) => s + (m.quizzes?.length ?? 0)) ?? 0))),
      ],
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 6),
      Text('$label ($count)', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
    ]);
  }

  Future<void> _exportExcel(BuildContext context) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    final url = '${ApiConfig.webUrl}/training/export-excel?token=$token';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel indirilemedi'), backgroundColor: ScadaColors.red),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel indirme hatasi'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.scada.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ScadaColors.cyan, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: context.scada.textDim),
        ]),
      ),
    );
  }
}
