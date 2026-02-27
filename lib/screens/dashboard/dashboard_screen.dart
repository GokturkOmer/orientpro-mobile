import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/api_config.dart';

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
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
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
      appBar: AppBar(title: const Text('OrientPro v2'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () { ref.read(authProvider.notifier).logout(); Navigator.pushReplacementNamed(context, '/'); }),
      ]),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Hosgeldiniz, ${auth.user?.fullName ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('${auth.user?.roleText ?? ""} - ${auth.user?.departmentText ?? ""}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          const Text('Is Emirleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [_statCard('Acik', '${woStats["open"] ?? 0}', Icons.error_outline, Colors.orange, onTap: () => Navigator.pushNamed(context, '/work-orders')), const SizedBox(width: 8), _statCard('Devam', '${woStats["in_progress"] ?? 0}', Icons.engineering, Colors.blue, onTap: () => Navigator.pushNamed(context, '/work-orders')), const SizedBox(width: 8), _statCard('Bitti', '${woStats["completed"] ?? 0}', Icons.check_circle, Colors.green, onTap: () => Navigator.pushNamed(context, '/work-orders'))]),
          const SizedBox(height: 8),
          Row(children: [_statCard('Kritik', '${woStats["critical_count"] ?? 0}', Icons.warning, Colors.red, onTap: () => Navigator.pushNamed(context, '/work-orders')), const SizedBox(width: 8), _statCard('SLA Asim', '${woStats["sla_breached"] ?? 0}', Icons.timer_off, Colors.deepOrange, onTap: () => Navigator.pushNamed(context, '/work-orders')), const SizedBox(width: 8), _statCard('Ort. Sure', '${woStats["avg_resolution_minutes"] ?? "-"} dk', Icons.schedule, Colors.teal)]),
          const SizedBox(height: 20),
          const Text('Ekipman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [_statCard('Toplam', '${eqStats["total"] ?? 0}', Icons.build, const Color(0xFF1B5E20), onTap: () => Navigator.pushNamed(context, '/equipment')), const SizedBox(width: 8), _statCard('Aktif', '${eqStats["active"] ?? 0}', Icons.power, Colors.green, onTap: () => Navigator.pushNamed(context, '/equipment')), const SizedBox(width: 8), _statCard('Bakimda', '${eqStats["maintenance"] ?? 0}', Icons.handyman, Colors.orange, onTap: () => Navigator.pushNamed(context, '/equipment'))]),
          const SizedBox(height: 24),
          _menuBtn('Ekipmanlar', Icons.inventory, '/equipment'),
          const SizedBox(height: 8),
          _menuBtn('Is Emirleri', Icons.assignment, '/work-orders'),
          const SizedBox(height: 8),
          _menuBtn('Kontrol Turlari', Icons.checklist, '/inspections'),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) { if (i == 1) Navigator.pushNamed(context, '/equipment'); if (i == 2) Navigator.pushNamed(context, '/work-orders'); if (i == 3) Navigator.pushNamed(context, '/inspections'); },
        selectedItemColor: const Color(0xFF1B5E20), unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed,
        items: const [BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'), BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Ekipman'), BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Is Emri'), BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Kontrol')],
      ),
    );
  }
  Widget _statCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Column(children: [Icon(icon, size: 24, color: color), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)), Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)])))));
  }
  Widget _menuBtn(String title, IconData icon, String route) {
    return Card(child: ListTile(leading: Icon(icon, color: const Color(0xFF1B5E20)), title: Text(title), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => Navigator.pushNamed(context, route)));
  }
}
