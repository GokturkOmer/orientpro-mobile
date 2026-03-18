import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../models/work_order.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/status_helper.dart';

class WorkOrderListScreen extends ConsumerStatefulWidget {
  const WorkOrderListScreen({super.key});
  @override
  ConsumerState<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends ConsumerState<WorkOrderListScreen> {
  List<WorkOrder> items = [];
  bool isLoading = true;
  String? statusFilter;
  final Map<String, String> statuses = {'open': 'Acik', 'assigned': 'Atandi', 'in_progress': 'Devam', 'completed': 'Bitti'};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final dio = ref.read(authDioProvider);
      String url = '/work-orders/?limit=100';
      if (statusFilter != null) url += '&status=$statusFilter';
      final res = await dio.get(url);
      setState(() { items = (res.data as List).map((e) => WorkOrder.fromJson(e)).toList(); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: ScadaColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.assignment, color: ScadaColors.amber, size: 18)),
          const SizedBox(width: 8),
          const Text('Is Emirleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      body: Column(children: [
        SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), children: [
          Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
            label: const Text('Tumu', style: TextStyle(fontSize: 11, color: ScadaColors.textPrimary)),
            selected: statusFilter == null,
            onSelected: (_) { statusFilter = null; _load(); },
            selectedColor: ScadaColors.cyan.withValues(alpha: 0.15),
            backgroundColor: ScadaColors.card,
            side: BorderSide(color: statusFilter == null ? ScadaColors.cyan.withValues(alpha: 0.5) : ScadaColors.border),
          )),
          ...statuses.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
            label: Text(e.value, style: TextStyle(fontSize: 11, color: statusFilter == e.key ? ScadaColors.cyan : ScadaColors.textSecondary)),
            selected: statusFilter == e.key,
            onSelected: (_) { statusFilter = statusFilter == e.key ? null : e.key; _load(); },
            selectedColor: ScadaColors.cyan.withValues(alpha: 0.15),
            backgroundColor: ScadaColors.card,
            side: BorderSide(color: statusFilter == e.key ? ScadaColors.cyan.withValues(alpha: 0.5) : ScadaColors.border),
          ))),
        ])),
        Expanded(child: isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : items.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.assignment_outlined, size: 64, color: ScadaColors.textDim),
                const SizedBox(height: 12),
                const Text('Is emri bulunamadi', style: TextStyle(color: ScadaColors.textDim)),
              ]))
            : RefreshIndicator(color: ScadaColors.cyan, backgroundColor: ScadaColors.surface, onRefresh: _load,
              child: ListView.builder(padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), itemCount: items.length, itemBuilder: (ctx, i) {
                final wo = items[i];
                final pColor = StatusHelper.priorityColor(wo.priority);
                final sColor = StatusHelper.workOrderStatusColor(wo.status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: ScadaColors.card, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: wo.slaBreached == true ? ScadaColors.red.withValues(alpha: 0.5) : ScadaColors.border, width: wo.slaBreached == true ? 1.5 : 1),
                  ),
                  child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(StatusHelper.workOrderStatusIcon(wo.status), color: sColor, size: 18),
                        if (wo.slaBreached == true) const Icon(Icons.timer_off, color: ScadaColors.red, size: 10),
                      ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(wo.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: pColor.withValues(alpha: 0.3))),
                          child: Text(wo.priorityText, style: TextStyle(fontSize: 8, color: pColor, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(wo.statusText, style: TextStyle(fontSize: 8, color: sColor, fontWeight: FontWeight.w600))),
                        if (wo.roomNumber != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.room, size: 10, color: ScadaColors.textDim),
                          Text('${wo.roomNumber}', style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(wo.faultTypeText, style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
                        const Spacer(),
                        Icon(Icons.access_time, size: 10, color: ScadaColors.textDim),
                        const SizedBox(width: 3),
                        Text(wo.createdAt.substring(0, 10), style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
                      ]),
                    ])),
                  ])),
                );
              }),
            ),
        ),
      ]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'chatbot',
            onPressed: () => Navigator.pushNamed(context, '/chatbot'),
            backgroundColor: Colors.cyanAccent,
            child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a), size: 20),
            tooltip: 'AI Asistan',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.pushNamed(context, '/equipment'),
            backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
            foregroundColor: ScadaColors.cyan,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
