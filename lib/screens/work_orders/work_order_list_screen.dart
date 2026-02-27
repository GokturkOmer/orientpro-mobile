import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../models/work_order.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  List<WorkOrder> items = [];
  bool isLoading = true;
  String? statusFilter;
  final Map<String, String> statuses = {'open': 'Acik', 'assigned': 'Atandi', 'in_progress': 'Devam', 'completed': 'Bitti'};
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
      String url = '/work-orders/?limit=100';
      if (statusFilter != null) url += '&status=$statusFilter';
      final res = await dio.get(url);
      setState(() { items = (res.data as List).map((e) => WorkOrder.fromJson(e)).toList(); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }
  Color _prioColor(String p) { switch (p) { case 'critical': return Colors.red; case 'high': return Colors.orange; case 'normal': return Colors.blue; case 'low': return Colors.grey; default: return Colors.grey; } }
  IconData _statusIcon(String s) { switch (s) { case 'open': return Icons.error_outline; case 'assigned': return Icons.person_add; case 'in_progress': return Icons.engineering; case 'completed': return Icons.check_circle; default: return Icons.help_outline; } }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Is Emirleri')),
      body: Column(children: [
        SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), children: [
          Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: const Text('Tumu'), selected: statusFilter == null, onSelected: (_) { statusFilter = null; _load(); }, selectedColor: const Color(0xFF1B5E20).withValues(alpha: 0.2))),
          ...statuses.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(e.value), selected: statusFilter == e.key, onSelected: (_) { statusFilter = statusFilter == e.key ? null : e.key; _load(); }, selectedColor: const Color(0xFF1B5E20).withValues(alpha: 0.2)))),
        ])),
        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : items.isEmpty ? const Center(child: Text('Is emri bulunamadi')) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: items.length, itemBuilder: (ctx, i) {
          final wo = items[i];
          return Card(child: ListTile(
            leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_statusIcon(wo.status), color: _prioColor(wo.priority), size: 28), if (wo.slaBreached == true) const Icon(Icons.timer_off, color: Colors.red, size: 14)]),
            title: Text(wo.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: _prioColor(wo.priority).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(wo.priorityText, style: TextStyle(fontSize: 10, color: _prioColor(wo.priority), fontWeight: FontWeight.bold))), const SizedBox(width: 4), Text(wo.statusText, style: const TextStyle(fontSize: 12)), if (wo.roomNumber != null) ...[const SizedBox(width: 4), Text('Oda ', style: TextStyle(fontSize: 11, color: Colors.blue.shade700))]]),
              Row(children: [Text(wo.faultTypeText, style: const TextStyle(fontSize: 11, color: Colors.grey)), const Spacer(), Text(wo.createdAt.substring(0, 10), style: const TextStyle(fontSize: 11, color: Colors.grey))]),
            ]),
            isThreeLine: true,
          ));
        }))),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pushNamed(context, '/equipment'), backgroundColor: const Color(0xFF1B5E20), child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
