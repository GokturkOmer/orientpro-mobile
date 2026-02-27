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
  Map<String, dynamic> stats = {};
  Map<String, dynamic> woStats = {};
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
    try {
      final eqRes = await dio.get('/equipment/count');
      final woRes = await dio.get('/work-orders/stats');
      setState(() {
        stats = eqRes.data;
        woStats = woRes.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrientPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hosgeldiniz, ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatCard('Toplam\nEkipman', '', Icons.build, const Color(0xFF1B5E20)),
                      const SizedBox(width: 12),
                      _buildStatCard('Acik Is\nEmri', '', Icons.assignment_late, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard('Devam\nEden', '', Icons.engineering, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Tamamlanan', '', Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildMenuButton('Ekipman Listesi', Icons.inventory, '/equipment'),
                  const SizedBox(height: 8),
                  _buildMenuButton('Is Emirleri', Icons.assignment, '/work-orders'),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) Navigator.pushNamed(context, '/equipment');
          if (i == 2) Navigator.pushNamed(context, '/work-orders');
        },
        selectedItemColor: const Color(0xFF1B5E20),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Ekipman'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Is Emirleri'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1B5E20)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
