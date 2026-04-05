import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'super_admin_orgs_screen.dart';
import 'super_admin_create_org_screen.dart';
import 'super_admin_dashboard_screen.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SuperAdminDashboardScreen(),
    SuperAdminOrgsScreen(),
    SuperAdminCreateOrgScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.scada.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFE53935), size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'Platform Yönetimi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
          ),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
            ),
            child: const Text(
              'SUPER ADMIN',
              style: TextStyle(fontSize: 9, color: Color(0xFFE53935), fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.scada.surface,
        indicatorColor: const Color(0xFFE53935).withValues(alpha: 0.15),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFE53935)),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: Color(0xFFE53935)),
            label: 'Musteriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_business_outlined),
            selectedIcon: Icon(Icons.add_business, color: Color(0xFFE53935)),
            label: 'Yeni Musteri',
          ),
        ],
      ),
    );
  }
}
