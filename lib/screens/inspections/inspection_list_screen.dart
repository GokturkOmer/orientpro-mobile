import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';

class InspectionListScreen extends ConsumerStatefulWidget {
  const InspectionListScreen({super.key});

  @override
  ConsumerState<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends ConsumerState<InspectionListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> templates = [];
  List<dynamic> inspections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final dio = ref.read(authDioProvider);
      final tRes = await dio.get('/inspections/templates');
      final iRes = await dio.get('/inspections/');
      setState(() {
        templates = tRes.data;
        inspections = iRes.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _freqText(String freq) {
    switch (freq) {
      case 'daily': return 'Gunluk';
      case 'weekly': return 'Haftalik';
      case 'monthly': return 'Aylik';
      case 'quarterly': return '3 Aylik';
      default: return freq;
    }
  }

  IconData _freqIcon(String freq) {
    switch (freq) {
      case 'daily': return Icons.today;
      case 'weekly': return Icons.date_range;
      case 'monthly': return Icons.calendar_month;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrol Turlari'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.list_alt), text: 'Sablonlar'),
          Tab(icon: Icon(Icons.history), text: 'Gecmis'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: ScadaColors.cyan,
        tooltip: 'AI Asistan',
        child: Icon(Icons.smart_toy, color: context.scada.bg),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabController, children: [
              RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  itemCount: templates.length,
                  itemBuilder: (ctx, i) {
                    final t = templates[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ScadaColors.green.withValues(alpha: 0.1),
                          child: Icon(_freqIcon(t['frequency']), color: ScadaColors.green),
                        ),
                        title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: ScadaColors.cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(_freqText(t['frequency']), style: const TextStyle(fontSize: 11, color: ScadaColors.cyan)),
                          ),
                          const SizedBox(width: 6),
                          Text(t['target_system'] ?? t['target_zone'] ?? '', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
                        ]),
                        trailing: const Icon(Icons.play_circle, color: ScadaColors.green, size: 32),
                      ),
                    );
                  },
                ),
              ),
              RefreshIndicator(
                onRefresh: _load,
                child: inspections.isEmpty
                    ? const Center(child: Text('Henuz kontrol turu yapilmamis'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                        itemCount: inspections.length,
                        itemBuilder: (ctx, i) {
                          final ins = inspections[i];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                ins['status'] == 'completed' ? Icons.check_circle : Icons.pending,
                                color: ins['status'] == 'completed' ? ScadaColors.green : ScadaColors.amber,
                                size: 32,
                              ),
                              title: Text('Kontrol #'),
                              subtitle: Text(ins['inspection_date'] ?? ''),
                              trailing: Text('/',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
