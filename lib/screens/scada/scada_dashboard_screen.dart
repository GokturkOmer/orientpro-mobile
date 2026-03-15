import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sensor.dart';
import '../../providers/sensor_provider.dart';
import '../../core/theme/app_theme.dart';

class ScadaDashboardScreen extends ConsumerWidget {
  const ScadaDashboardScreen({super.key});

  static const Map<int, _UnitInfo> unitInfo = {
    1: _UnitInfo('KAZAN DAIRESI', Icons.local_fire_department, Color(0xFFe74c3c)),
    2: _UnitInfo('CHILLER', Icons.ac_unit, Color(0xFF3498db)),
    3: _UnitInfo('AHU SISTEMI', Icons.air, Color(0xFF2ecc71)),
    4: _UnitInfo('POMPA GRUBU', Icons.water_drop, Color(0xFF9b59b6)),
    5: _UnitInfo('ENERJI ANALIZORU', Icons.bolt, Color(0xFFf39c12)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(sensorLatestProvider);
    final alarmAsync = ref.watch(alarmStatsProvider);
    final countAsync = ref.watch(readingCountProvider);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ScadaColors.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.monitor_heart, color: ScadaColors.cyan, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('SCADA Monitor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ScadaColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: ScadaColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('CANLI', style: TextStyle(fontSize: 9, color: ScadaColors.green, fontWeight: FontWeight.w700)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, size: 20, color: ScadaColors.amber),
            onPressed: () => Navigator.pushNamed(context, '/alarms'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: RefreshIndicator(
        color: ScadaColors.cyan,
        backgroundColor: ScadaColors.surface,
        onRefresh: () async {
          ref.read(sensorLatestProvider.notifier).fetch();
          ref.read(alarmStatsProvider.notifier).fetch();
          ref.invalidate(readingCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _buildStatsRow(alarmAsync, countAsync),
            const SizedBox(height: 12),
            latestAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: ScadaColors.cyan))),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ScadaColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScadaColors.red.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.wifi_off, color: ScadaColors.red),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('SCADA baglantisi kurulamadi', style: TextStyle(color: ScadaColors.red))),
                ]),
              ),
              data: (sensors) {
                if (sensors.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Henuz sensor verisi yok', style: TextStyle(color: ScadaColors.textDim))));
                final grouped = <int, List<SensorLatestValue>>{};
                final sensorDefs = ref.watch(sensorListProvider);
                for (final s in sensors) {
                  final unitId = sensorDefs.whenOrNull(data: (defs) {
                    final def = defs.where((d) => d.id == s.sensorId).firstOrNull;
                    return def?.unitId;
                  }) ?? 0;
                  grouped.putIfAbsent(unitId, () => []).add(s);
                }
                final sortedKeys = grouped.keys.toList()..sort();
                return Column(children: sortedKeys.map((uid) {
                  final info = unitInfo[uid] ?? _UnitInfo('Unit $uid', Icons.developer_board, ScadaColors.textDim);
                  return _buildUnitSection(context, uid, info, grouped[uid]!);
                }).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<AlarmStats> alarmAsync, AsyncValue<Map<String, dynamic>> countAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _miniStat(Icons.analytics, ScadaColors.cyan, countAsync.whenOrNull(data: (d) => '${d["total"] ?? 0}') ?? '-', 'Okuma'),
        Container(width: 1, height: 28, color: ScadaColors.border),
        _miniStat(Icons.warning_amber, ScadaColors.amber, alarmAsync.whenOrNull(data: (d) => '${d.totalActive}') ?? '0', 'Aktif Alarm'),
        Container(width: 1, height: 28, color: ScadaColors.border),
        _miniStat(Icons.error, ScadaColors.red, alarmAsync.whenOrNull(data: (d) => '${d.bySeverity["critical"] ?? 0}') ?? '0', 'Kritik'),
      ]),
    );
  }

  Widget _miniStat(IconData icon, Color color, String value, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
      ]),
    ]);
  }

  Widget _buildUnitSection(BuildContext context, int unitId, _UnitInfo info, List<SensorLatestValue> sensors) {
    final hasAlarm = sensors.any((s) => s.alarmStatus == 'alarm');
    final hasWarning = sensors.any((s) => s.alarmStatus == 'warning');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasAlarm ? ScadaColors.red.withValues(alpha: 0.5) : hasWarning ? ScadaColors.amber.withValues(alpha: 0.5) : ScadaColors.border,
          width: hasAlarm ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: info.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Icon(info.icon, size: 16, color: info.color),
          ),
          const SizedBox(width: 8),
          Text(info.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: info.color, letterSpacing: 1)),
          const Spacer(),
          if (hasAlarm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: ScadaColors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text('ALARM', style: TextStyle(fontSize: 8, color: ScadaColors.red, fontWeight: FontWeight.w700)),
            ),
          if (hasWarning && !hasAlarm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: ScadaColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text('UYARI', style: TextStyle(fontSize: 8, color: ScadaColors.amber, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: sensors.map((s) => _sensorCard(context, s)).toList()),
      ]),
    );
  }

  bool _isDurumSensor(String name) {
    final lower = name.toLowerCase();
    return lower.contains('durum') || lower.contains('status');
  }

  Widget _sensorCard(BuildContext context, SensorLatestValue sensor) {
    Color statusColor;
    switch (sensor.alarmStatus) {
      case 'alarm': statusColor = ScadaColors.red; break;
      case 'warning': statusColor = ScadaColors.amber; break;
      default: statusColor = ScadaColors.green;
    }
    final shortName = sensor.sensorName.replaceAll(RegExp(r'^(Kazan|Chiller|AHU|Pompa|Enerji)\s*'), '');
    final isDurum = _isDurumSensor(sensor.sensorName);

    String displayValue;
    Color valueColor;
    IconData? durumIcon;

    if (isDurum) {
      final isOn = sensor.value >= 1;
      displayValue = isOn ? 'ACIK' : 'KAPALI';
      valueColor = isOn ? ScadaColors.green : ScadaColors.red;
      durumIcon = isOn ? Icons.power : Icons.power_off;
    } else {
      displayValue = _fmt(sensor.value, sensor.unit);
      valueColor = sensor.alarmStatus != 'normal' ? statusColor : ScadaColors.cyan;
      durumIcon = null;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/sensor-detail', arguments: sensor.sensorId),
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(shortName, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 4),
          if (durumIcon != null) Icon(durumIcon, size: 18, color: valueColor),
          Text(displayValue, style: TextStyle(fontSize: isDurum ? 13 : 18, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          if (!isDurum)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4)])),
              const SizedBox(width: 3),
              Text(sensor.unit, style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
            ]),
          if (isDurum)
            Container(width: 5, height: 5, decoration: BoxDecoration(color: valueColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: valueColor.withValues(alpha: 0.5), blurRadius: 4)])),
        ]),
      ),
    );
  }

  String _fmt(double val, String unit) {
    if (unit == '' || val == val.roundToDouble()) return val.toStringAsFixed(0);
    if (val >= 100) return val.toStringAsFixed(1);
    return val.toStringAsFixed(2);
  }
}

class _UnitInfo {
  final String name;
  final IconData icon;
  final Color color;
  const _UnitInfo(this.name, this.icon, this.color);
}
