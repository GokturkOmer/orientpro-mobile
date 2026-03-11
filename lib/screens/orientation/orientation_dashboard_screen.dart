import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';

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
      ref.read(trainingProvider.notifier).loadDepartments();
      ref.read(trainingProvider.notifier).loadRoutes();
      if (auth.user != null) {
        ref.read(trainingProvider.notifier).loadStats(auth.user!.id);
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
              color: ScadaColors.purple.withOpacity(0.15),
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
                        color: ScadaColors.purple.withOpacity(0.15),
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
                  const SizedBox(height: 16),
                  Row(children: [
                    _buildStatCard('Tamamlanan', '${training.stats!.completedModules}', ScadaColors.green),
                    const SizedBox(width: 8),
                    _buildStatCard('Devam Eden', '${training.stats!.inProgressModules}', ScadaColors.amber),
                    const SizedBox(width: 8),
                    _buildStatCard('Quiz Basari', '${training.stats!.quizzesPassed}', ScadaColors.cyan),
                  ]),
                ],

                const SizedBox(height: 20),

                // Section: Departmanlar
                Row(children: [
                  const Icon(Icons.business, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 6),
                  const Text('DEPARTMANLAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),

                // Department chips
                if (training.departments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: training.departments.map((dept) {
                      final deptColor = dept.color != null
                          ? Color(int.parse('0xFF${dept.color!.replaceAll('#', '')}'))
                          : ScadaColors.purple;
                      return ActionChip(
                        label: Text(dept.name, style: TextStyle(fontSize: 12, color: deptColor)),
                        backgroundColor: deptColor.withOpacity(0.1),
                        side: BorderSide(color: deptColor.withOpacity(0.3)),
                        onPressed: () {
                          Navigator.pushNamed(context, '/training-routes', arguments: {'departmentId': dept.id, 'departmentName': dept.name});
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // Section: Moduller
                Row(children: [
                  const Icon(Icons.apps, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 6),
                  const Text('MODULLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),

                _buildModuleCard(
                  icon: Icons.route,
                  title: 'Egitim Rotalari',
                  description: 'Departman bazli egitim rotalari ve icerikler',
                  color: ScadaColors.cyan,
                  badge: '${training.routes.length}',
                  onTap: () => Navigator.pushNamed(context, '/training-routes'),
                ),
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
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.smart_toy,
                  title: 'AI Asistan',
                  description: 'Oryantasyon sureci icin yapay zeka destegi',
                  color: ScadaColors.purple,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _buildModuleCard(
                  icon: Icons.verified,
                  title: 'Sertifikalar',
                  description: 'Egitim tamamlama sertifikalari ve onaylar',
                  color: ScadaColors.orange,
                  onTap: () {},
                ),

                // Error message
                if (training.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ScadaColors.red.withOpacity(0.1),
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
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
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
            color: color.withOpacity(0.12),
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
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
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
