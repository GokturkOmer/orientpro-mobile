import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic> eqStats = {};
  Map<String, dynamic> woStats = {};
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    final dio = ref.read(authDioProvider);
    try {
      final eqRes = await dio.get('/equipment/stats');
      final woRes = await dio.get('/work-orders/stats');
      setState(() { eqStats = eqRes.data; woStats = woRes.data; isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.precision_manufacturing, color: ScadaColors.cyan, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('OrientPro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ScadaColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: ScadaColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('ONLINE', style: TextStyle(fontSize: 9, color: ScadaColors.green, fontWeight: FontWeight.w700)),
            ]),
          ),
          _buildNotifBell(ref),
          IconButton(
            icon: const Icon(Icons.home, size: 20, color: ScadaColors.textDim),
            tooltip: 'Modul Secimi',
            onPressed: () => Navigator.pushReplacementNamed(context, '/module-selection'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: ScadaColors.textDim),
            onPressed: () { ref.read(authProvider.notifier).logout(); Navigator.pushReplacementNamed(context, '/'); },
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
        : RefreshIndicator(
            color: ScadaColors.cyan,
            backgroundColor: ScadaColors.surface,
            onRefresh: _loadStats,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              // User greeting
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
                      color: ScadaColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: ScadaColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(auth.user?.fullName ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                    Text('${auth.user?.roleText ?? ""} • ${auth.user?.departmentText ?? ""}', style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),

              // Quick access cards - top row
              Row(children: [
                Expanded(child: _scadaQuickCard('SCADA\nMonitor', Icons.monitor_heart, ScadaColors.cyan, '/scada')),
                const SizedBox(width: 10),
                Expanded(child: _scadaQuickCard('Dijital\nIkiz', Icons.account_tree, ScadaColors.purple, '/digital-twin')),
                const SizedBox(width: 10),
                Expanded(child: _scadaQuickCard('QR Tur\nSistemi', Icons.qr_code_scanner, ScadaColors.green, '/tours')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _scadaQuickCard('AI Ariza\nTahmini', Icons.psychology, ScadaColors.amber, '/ai-predictions')),
                const SizedBox(width: 10),
                Expanded(child: _scadaQuickCard('Bildirimler', Icons.notifications, ScadaColors.amber, '/notifications')),
                const SizedBox(width: 8),
                Expanded(child: _scadaQuickCard('AI Asistan', Icons.smart_toy, ScadaColors.cyan, '/chatbot')),
                Expanded(child: _scadaQuickCard('Alarmlar', Icons.warning_amber, ScadaColors.red, '/alarms')),
              ]),
              const SizedBox(height: 20),

              // Section: İş Emirleri
              _sectionHeader('IS EMIRLERI', Icons.assignment),
              const SizedBox(height: 8),
              Row(children: [
                _statCard('Acik', '${woStats["open"] ?? 0}', ScadaColors.amber, '/work-orders'),
                const SizedBox(width: 8),
                _statCard('Devam', '${woStats["in_progress"] ?? 0}', ScadaColors.cyan, '/work-orders'),
                const SizedBox(width: 8),
                _statCard('Bitti', '${woStats["completed"] ?? 0}', ScadaColors.green, '/work-orders'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _statCard('Kritik', '${woStats["critical_count"] ?? 0}', ScadaColors.red, '/work-orders'),
                const SizedBox(width: 8),
                _statCard('SLA', '${woStats["sla_breached"] ?? 0}', ScadaColors.orange, '/work-orders'),
                const SizedBox(width: 8),
                _statCard('Ort.', '${woStats["avg_resolution_minutes"] ?? "-"} dk', ScadaColors.cyanDim, null),
              ]),
              const SizedBox(height: 20),

              // Section: Ekipman
              _sectionHeader('EKIPMAN', Icons.build),
              const SizedBox(height: 8),
              Row(children: [
                _statCard('Toplam', '${eqStats["total"] ?? 0}', ScadaColors.cyan, '/equipment'),
                const SizedBox(width: 8),
                _statCard('Aktif', '${eqStats["active"] ?? 0}', ScadaColors.green, '/equipment'),
                const SizedBox(width: 8),
                _statCard('Bakim', '${eqStats["maintenance"] ?? 0}', ScadaColors.amber, '/equipment'),
              ]),
              const SizedBox(height: 20),

              // Navigation menu
              _sectionHeader('MODULLER', Icons.apps),
              const SizedBox(height: 8),
              _menuItem('SCADA Monitor', Icons.monitor_heart, ScadaColors.cyan, '/scada'),
              _menuItem('AI Ariza Tahmini', Icons.psychology, ScadaColors.purple, '/ai-predictions'),
              _menuItem('Dijital Ikiz', Icons.account_tree, ScadaColors.purple, '/digital-twin'),
              _menuItem('QR Tur Sistemi', Icons.qr_code_scanner, ScadaColors.green, '/tours'),
              _menuItem('AI Asistan', Icons.smart_toy, ScadaColors.cyan, '/chatbot'),
              _menuItem('Ekipmanlar', Icons.inventory, ScadaColors.cyanDim, '/equipment'),
              _menuItem('Is Emirleri', Icons.assignment, ScadaColors.amber, '/work-orders'),
              _menuItem('Kontrol Turlari', Icons.checklist, ScadaColors.orange, '/inspections'),
              const SizedBox(height: 80),
            ]),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ScadaColors.surface,
          border: Border(top: BorderSide(color: ScadaColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (i) {
            if (i == 1) Navigator.pushNamed(context, '/scada');
            if (i == 2) Navigator.pushNamed(context, '/digital-twin');
            if (i == 3) Navigator.pushNamed(context, '/work-orders');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: ScadaColors.cyan,
          unselectedItemColor: ScadaColors.textDim,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'SCADA'),
            BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Ikiz'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Is Emri'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifBell(WidgetRef ref) {
    final countAsync = ref.watch(unreadCountProvider);
    final unread = countAsync.whenOrNull(data: (d) => d) ?? 0;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22, color: ScadaColors.amber),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (unread > 0)
          Positioned(right: 6, top: 6, child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ScadaColors.red, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: ScadaColors.red.withValues(alpha: 0.5), blurRadius: 4)]),
            child: Text('$unread', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
          )),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: ScadaColors.textDim),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
    ]);
  }

  Widget _scadaQuickCard(String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1.3), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, String? route) {
    return Expanded(child: GestureDetector(
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ScadaColors.border),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
        ]),
      ),
    ));
  }

  Widget _menuItem(String title, IconData icon, Color color, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ScadaColors.textPrimary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: ScadaColors.textDim),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
