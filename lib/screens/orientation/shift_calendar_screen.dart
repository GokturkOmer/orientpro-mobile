import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift.dart' as sm;
import '../../core/theme/app_theme.dart';
import '../../core/utils/status_helper.dart';

class ShiftCalendarScreen extends ConsumerStatefulWidget {
  const ShiftCalendarScreen({super.key});

  @override
  ConsumerState<ShiftCalendarScreen> createState() => _ShiftCalendarScreenState();
}

class _ShiftCalendarScreenState extends ConsumerState<ShiftCalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _taskFilter = 'all'; // all, pending, in_progress, completed
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        // Bu haftanin vardiyalarini yukle
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        ref.read(shiftProvider.notifier).loadShifts(
          auth.user!.id,
          startDate: '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
          endDate: '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}',
        );
        ref.read(shiftProvider.notifier).loadTasks(auth.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.calendar_month, color: ScadaColors.amber, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Vardiya & Gorevler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: ScadaColors.cyan,
          labelColor: ScadaColors.cyan,
          unselectedLabelColor: context.scada.textDim,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Vardiyalar (${shiftState.shifts.length})'),
            Tab(text: 'Gorevler (${shiftState.tasks.length})'),
          ],
        ),
      ),
      body: shiftState.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildShiftsTab(shiftState),
                _buildTasksTab(shiftState),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ScadaColors.amber,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vardiya/gorev olusturma yaklasimda'),
              backgroundColor: ScadaColors.amber,
            ),
          );
        },
        child: Icon(Icons.add, color: context.scada.bg),
      ),
    );
  }

  // ===== SHIFTS TAB =====
  Widget _buildShiftsTab(ShiftState shiftState) {
    if (shiftState.shifts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 48, color: context.scada.textDim),
          const SizedBox(height: 8),
          Text('Bu hafta vardiya bulunamadi', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
        ]),
      );
    }

    // Gune gore grupla
    final grouped = <String, List<sm.Shift>>{};
    for (final s in shiftState.shifts) {
      grouped.putIfAbsent(s.shiftDate, () => []).add(s);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final shifts = grouped[day]!;
        return _buildDayCard(day, shifts);
      },
    );
  }

  Widget _buildDayCard(String dateStr, List<sm.Shift> shifts) {
    final dayNames = ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
    String dayLabel = dateStr;
    try {
      final dt = DateTime.parse(dateStr);
      dayLabel = '${dayNames[dt.weekday - 1]} ${dt.day}.${dt.month.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('_buildDayCard hata: $e');
    }

    final isToday = dateStr == _todayStr();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isToday ? ScadaColors.cyan.withValues(alpha: 0.5) : context.scada.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Day header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isToday ? ScadaColors.cyan.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            Text(dayLabel, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isToday ? ScadaColors.cyan : context.scada.textPrimary,
            )),
            if (isToday) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: ScadaColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('BUGUN', style: TextStyle(fontSize: 8, color: ScadaColors.cyan, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ),
        // Shifts
        ...shifts.map((s) => _buildShiftRow(s)),
      ]),
    );
  }

  Widget _buildShiftRow(sm.Shift shift) {
    final color = _getShiftColor(shift.shiftType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        Container(
          width: 4, height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(shift.shiftTypeText, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        if (shift.timeRange.isNotEmpty)
          Text(shift.timeRange, style: TextStyle(fontSize: 11, color: context.scada.textPrimary)),
        const Spacer(),
        if (shift.department != null)
          Text(shift.department!, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
      ]),
    );
  }

  Color _getShiftColor(String type) {
    switch (type) {
      case 'sabah': return ScadaColors.amber;
      case 'aksam': return ScadaColors.purple;
      case 'gece': return ScadaColors.cyan;
      case 'izin': return ScadaColors.green;
      case 'rapor': return ScadaColors.red;
      default: return context.scada.textSecondary;
    }
  }

  // ===== TASKS TAB =====
  Widget _buildTasksTab(ShiftState shiftState) {
    return Column(children: [
      // Arama
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Gorev ara...',
            hintStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: context.scada.textDim, size: 20),
            filled: true,
            fillColor: context.scada.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
      ),
      // Filter chips
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTaskFilter('Tumu', 'all'),
              _buildTaskFilter('Bekliyor', 'pending'),
              _buildTaskFilter('Devam', 'in_progress'),
              _buildTaskFilter('Tamam', 'completed'),
            ],
          ),
        ),
      ),
      Expanded(
        child: Builder(builder: (_) {
          var tasks = _taskFilter == 'all'
              ? shiftState.tasks
              : shiftState.tasks.where((t) => t.status == _taskFilter).toList();
          if (_searchQuery.isNotEmpty) {
            tasks = tasks.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();
          }

          if (tasks.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.task_alt, size: 48, color: context.scada.textDim),
                const SizedBox(height: 8),
                Text('Gorev bulunamadi', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
          );
        }),
      ),
    ]);
  }

  Widget _buildTaskFilter(String label, String value) {
    final isSelected = _taskFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 11,
          color: isSelected ? context.scada.bg : context.scada.textSecondary,
        )),
        selected: isSelected,
        selectedColor: ScadaColors.cyan,
        backgroundColor: context.scada.card,
        side: BorderSide(color: isSelected ? ScadaColors.cyan : context.scada.border),
        onSelected: (_) => setState(() => _taskFilter = value),
      ),
    );
  }

  Widget _buildTaskCard(sm.Task task) {
    final priorityColor = StatusHelper.priorityColor(task.priority);
    final statusColor = StatusHelper.taskStatusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: task.isOverdue ? ScadaColors.red.withValues(alpha: 0.5) : context.scada.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            task.status == 'completed' ? Icons.check_circle : Icons.task_alt,
            color: statusColor, size: 20,
          ),
        ),
        title: Row(children: [
          Expanded(child: Text(task.title, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: context.scada.textPrimary,
            decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
          ))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(task.priorityText, style: TextStyle(fontSize: 8, color: priorityColor, fontWeight: FontWeight.w600)),
          ),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (task.description != null)
            Text(task.description!, style: TextStyle(fontSize: 10, color: context.scada.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(task.statusText, style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w600)),
            ),
            if (task.dueDate != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.schedule, size: 10, color: task.isOverdue ? ScadaColors.red : context.scada.textDim),
              const SizedBox(width: 2),
              Text(task.dueDate!, style: TextStyle(fontSize: 9, color: task.isOverdue ? ScadaColors.red : context.scada.textDim)),
            ],
            if (task.category != null) ...[
              const SizedBox(width: 6),
              Text(task.category!, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
            ],
          ]),
        ]),
        trailing: task.status != 'completed' && task.status != 'cancelled'
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: context.scada.textDim),
                color: context.scada.surface,
                onSelected: (val) => _updateTaskStatus(task.id, val),
                itemBuilder: (_) => [
                  if (task.status == 'pending')
                    const PopupMenuItem(value: 'in_progress', child: Text('Baslat', style: TextStyle(fontSize: 12))),
                  if (task.status == 'in_progress')
                    const PopupMenuItem(value: 'completed', child: Text('Tamamla', style: TextStyle(fontSize: 12))),
                  const PopupMenuItem(value: 'cancelled', child: Text('Iptal Et', style: TextStyle(fontSize: 12))),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    final ok = await ref.read(shiftProvider.notifier).updateTaskStatus(taskId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? (status == 'completed' ? 'Gorev tamamlandi' : status == 'in_progress' ? 'Gorev basladi' : 'Gorev iptal edildi')
              : 'Islem basarisiz'),
          backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
        ),
      );
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
