import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../widgets/notif_bell.dart';

class ModuleSelectionScreen extends ConsumerWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
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
                        color: ScadaColors.cyan.withValues(alpha: 0.15),
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
                          style: TextStyle(fontSize: 11, color: context.scada.textSecondary),
                        ),
                      ],
                    ),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const NotifBell(),
                    IconButton(
                      icon: Icon(
                        ref.watch(themeProvider).themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        size: 20,
                        color: context.scada.textDim,
                      ),
                      onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                      tooltip: 'Tema Degistir',
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, size: 20, color: context.scada.textDim),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ]),
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
                        Text(
                          'Modul Secimi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1),
                        ),
                        const SizedBox(height: 20),

                        // Ust: Oryantasyon (buyuk, tek)
                        SizedBox(
                          width: double.infinity,
                          child: _ModuleCard(
                            title: 'Oryantasyon',
                            subtitle: 'Egitim & Rehber',
                            description: 'Personel oryantasyon surecleri,\negitim rotalari ve takip',
                            icon: Icons.school,
                            color: ScadaColors.purple,
                            onTap: () => Navigator.pushNamed(context, '/orientation-dashboard'),
                          ),
                        ),

                        // Super Admin Paneli - sadece platform sahibi
                        if (auth.user != null && auth.user!.isSuperAdmin) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _SmallModuleCard(
                              title: 'Platform',
                              subtitle: 'Super Admin',
                              icon: Icons.shield_outlined,
                              color: const Color(0xFFE53935),
                              onTap: () => Navigator.pushNamed(context, '/super-admin'),
                            ),
                          ),
                        ],

                        // Alt kartlar
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Admin Paneli - sadece admin
                            if (auth.user != null && RoleHelper.isAdmin(auth.user!.role)) ...[
                              Expanded(
                                child: _SmallModuleCard(
                                  title: 'Yonetim',
                                  subtitle: 'Admin Paneli',
                                  icon: Icons.admin_panel_settings,
                                  color: ScadaColors.amber,
                                  onTap: () => Navigator.pushNamed(context, '/admin'),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            // Icerik Yonetimi - mudur/sef (admin haric, zaten admin panelinden ulasir)
                            if (auth.user != null && !RoleHelper.isAdmin(auth.user!.role) && RoleHelper.canEditContent(auth.user!.role)) ...[
                              Expanded(
                                child: _SmallModuleCard(
                                  title: 'Icerik',
                                  subtitle: 'Icerik Yonetimi',
                                  icon: Icons.edit_note,
                                  color: ScadaColors.amber,
                                  onTap: () => Navigator.pushNamed(context, '/admin/content'),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            // Pro - sadece teknik roller
                            if (auth.user != null && RoleHelper.canAccessPro(auth.user!.role))
                              Expanded(
                                child: _SmallModuleCard(
                                  title: 'Pro',
                                  subtitle: 'Teknik Yonetim',
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
                Container(width: 6, height: 6, decoration: BoxDecoration(color: ScadaColors.green.withValues(alpha: 0.6), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Sistem aktif', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
                const SizedBox(width: 16),
                Text('|', style: TextStyle(color: context.scada.textDim, fontSize: 10)),
                const SizedBox(width: 16),
                Text('v2.0', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
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
                ? widget.color.withValues(alpha: 0.08)
                : context.scada.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.5)
                  : context.scada.border,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.1), blurRadius: 20)]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: 0.3)),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.scada.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: context.scada.textDim,
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

class _SmallModuleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SmallModuleCard> createState() => _SmallModuleCardState();
}

class _SmallModuleCardState extends State<_SmallModuleCard> {
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.08)
                : context.scada.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.5)
                  : context.scada.border,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.icon, size: 22, color: widget.color),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.scada.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
