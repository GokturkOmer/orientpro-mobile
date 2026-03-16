import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/api_config.dart';

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
            child: const Icon(Icons.admin_panel_settings, color: ScadaColors.amber, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Yonetim Paneli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
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
              const SizedBox(height: 16),
              Text('Yukleniyor... (${ApiConfig.url})', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                      Text(admin.error!, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Welcome section
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
                        color: ScadaColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: ScadaColors.amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hosgeldin, ${auth.user?.fullName ?? ""}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                      const Text('Icerik yonetimi ve egitim modulu duzenleme', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
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

                // Quick Actions header
                Row(children: [
                  const Icon(Icons.flash_on, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 6),
                  const Text('HIZLI ISLEMLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quiz olusturmak icin once bir modul secin'),
                        backgroundColor: ScadaColors.amber,
                      ),
                    );
                    Navigator.pushNamed(context, '/admin/content');
                  },
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

                // Debug info
                const SizedBox(height: 16),
                Text('API: ${ApiConfig.url}', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
              ]),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
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
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ScadaColors.border),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: ScadaColors.textDim),
        ]),
      ),
    );
  }
}
