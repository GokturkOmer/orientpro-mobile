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

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    setState(() => isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
      final res = await dio.get('/work-orders/');
      setState(() {
        items = (res.data as List).map((e) => WorkOrder.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'normal': return Colors.blue;
      case 'low': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'open': return Icons.error_outline;
      case 'in_progress': return Icons.engineering;
      case 'completed': return Icons.check_circle;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Is Emirleri')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Henuz is emri yok'))
              : RefreshIndicator(
                  onRefresh: _loadWorkOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final wo = items[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(_statusIcon(wo.status), color: _priorityColor(wo.priority), size: 32),
                          title: Text(wo.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(' - '),
                          trailing: Text(wo.createdAt.substring(0, 10), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
