import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ModuleSelectionScreen extends ConsumerWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ScadaColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing, color: ScadaColors.cyan, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OrientPro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ScadaColors.cyan, letterSpacing: 1)),
                        Text(
                          auth.user?.fullName ?? '',
                          style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
                        ),
                      ],
                    ),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: ScadaColors.textDim),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ],
              ),

              // Cards
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Modul Secimi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ModuleCard(
                                title: 'Oryantasyon',
                                subtitle: 'Egitim & Rehber',
                                description: 'Personel oryantasyon surecleri,\negitim rotalari ve takip',
                                icon: Icons.school,
                                color: ScadaColors.purple,
                                onTap: () => Navigator.pushNamed(context, '/orientation-dashboard'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ModuleCard(
                                title: 'Pro',
                                subtitle: 'Teknik Yonetim',
                                description: 'SCADA, ekipman, is emirleri,\nalarm ve izleme sistemleri',
                                icon: Icons.precision_manufacturing,
                                color: ScadaColors.cyan,
                                onTap: () => Navigator.pushNamed(context, '/dashboard'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: ScadaColors.green.withOpacity(0.6), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Sistem aktif', style: TextStyle(fontSize: 10, color: ScadaColors.textDim)),
                const SizedBox(width: 16),
                const Text('|', style: TextStyle(color: ScadaColors.textDim, fontSize: 10)),
                const SizedBox(width: 16),
                const Text('v2.0', style: TextStyle(fontSize: 10, color: ScadaColors.textDim)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withOpacity(0.08)
                : ScadaColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : ScadaColors.border,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 20)]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withOpacity(0.3)),
                ),
                child: Icon(widget.icon, size: 40, color: widget.color),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ScadaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: ScadaColors.textDim,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
