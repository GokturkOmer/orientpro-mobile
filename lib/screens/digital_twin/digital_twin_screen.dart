import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sensor.dart';
import '../../providers/sensor_provider.dart';

class DigitalTwinScreen extends ConsumerWidget {
  const DigitalTwinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(sensorLatestProvider);
    final defsAsync = ref.watch(sensorListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Dijital Ikiz'),
        backgroundColor: const Color(0xFF16213e),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _PulsingDot(color: Colors.greenAccent),
              const SizedBox(width: 6),
              const Text('CANLI', style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: latestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 8),
          Text('Baglanti hatasi', style: TextStyle(color: Colors.red.shade300)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(sensorLatestProvider), child: const Text('Tekrar Dene')),
        ])),
        data: (sensors) {
          final defs = defsAsync.whenOrNull(data: (d) => d) ?? [];
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(sensorLatestProvider); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildStatusBar(sensors),
                const SizedBox(height: 16),
                _buildFacilityMap(context, sensors, defs),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(List<SensorLatestValue> sensors) {
    final normal = sensors.where((s) => s.alarmStatus == 'normal').length;
    final warning = sensors.where((s) => s.alarmStatus == 'warning').length;
    final alarm = sensors.where((s) => s.alarmStatus == 'alarm').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statusBadge('Normal', normal, Colors.greenAccent),
        Container(width: 1, height: 30, color: Colors.white12),
        _statusBadge('Uyari', warning, Colors.orangeAccent),
        Container(width: 1, height: 30, color: Colors.white12),
        _statusBadge('Alarm', alarm, Colors.redAccent),
        Container(width: 1, height: 30, color: Colors.white12),
        _statusBadge('Toplam', sensors.length, Colors.blueAccent),
      ]),
    );
  }

  Widget _statusBadge(String label, int count, Color color) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
    ]);
  }

  Widget _buildFacilityMap(BuildContext context, List<SensorLatestValue> sensors, List<SensorDefinition> defs) {
    final grouped = <int, List<_SensorWithDef>>{};
    for (final s in sensors) {
      final def = defs.where((d) => d.id == s.sensorId).firstOrNull;
      final unitId = def?.unitId ?? 0;
      grouped.putIfAbsent(unitId, () => []).add(_SensorWithDef(s, def));
    }

    final zones = [
      _ZoneConfig(1, 'KAZAN DAIRESI', Icons.local_fire_department, const Color(0xFFe74c3c), 'B Blok - Zemin Kat'),
      _ZoneConfig(2, 'CHILLER', Icons.ac_unit, const Color(0xFF3498db), 'A Blok - Bodrum'),
      _ZoneConfig(3, 'AHU SISTEMI', Icons.air, const Color(0xFF2ecc71), 'A Blok - Cati'),
      _ZoneConfig(4, 'POMPA GRUBU', Icons.water_drop, const Color(0xFF9b59b6), 'B Blok - Bodrum'),
      _ZoneConfig(5, 'ENERJI ANALIZORU', Icons.bolt, const Color(0xFFf39c12), 'Ana Pano'),
    ];

    return Column(children: [
      Row(children: [
        Icon(Icons.apartment, color: Colors.white.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 8),
        Text('TESIS PLANI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 2)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildZone(context, zones[0], grouped[1] ?? [])),
        const SizedBox(width: 10),
        Expanded(child: _buildZone(context, zones[1], grouped[2] ?? [])),
      ]),
      const SizedBox(height: 10),
      _buildPipeConnection('Sicak Su', 'Soguk Su', Colors.redAccent, Colors.blueAccent),
      const SizedBox(height: 10),
      _buildZone(context, zones[2], grouped[3] ?? []),
      const SizedBox(height: 10),
      _buildPipeConnection('Hava', 'Elektrik', Colors.greenAccent, Colors.orangeAccent),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _buildZone(context, zones[3], grouped[4] ?? [])),
        const SizedBox(width: 10),
        Expanded(child: _buildZone(context, zones[4], grouped[5] ?? [])),
      ]),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Sensore dokunarak detay ve trend grafigine ulasabilirsiniz',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildPipeConnection(String left, String right, Color leftColor, Color rightColor) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text(left, style: TextStyle(fontSize: 8, color: leftColor.withValues(alpha: 0.6))),
        const SizedBox(width: 6),
        Expanded(child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [leftColor.withValues(alpha: 0.5), rightColor.withValues(alpha: 0.5)]),
            borderRadius: BorderRadius.circular(1),
          ),
        )),
        const SizedBox(width: 6),
        Text(right, style: TextStyle(fontSize: 8, color: rightColor.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _buildZone(BuildContext context, _ZoneConfig zone, List<_SensorWithDef> sensors) {
    final hasAlarm = sensors.any((s) => s.sensor.alarmStatus == 'alarm');
    final hasWarning = sensors.any((s) => s.sensor.alarmStatus == 'warning');
    final borderColor = hasAlarm ? Colors.redAccent : hasWarning ? Colors.orangeAccent : zone.color.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: hasAlarm ? 2 : 1),
        boxShadow: hasAlarm ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 12)] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: zone.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Icon(zone.icon, size: 16, color: zone.color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: zone.color, letterSpacing: 1)),
            Text(zone.location, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.3))),
          ])),
          if (hasAlarm) _PulsingDot(color: Colors.redAccent, size: 8),
          if (hasWarning && !hasAlarm) _PulsingDot(color: Colors.orangeAccent, size: 8),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sensors.map((s) => _sensorChip(context, s)).toList(),
        ),
      ]),
    );
  }

  Widget _sensorChip(BuildContext context, _SensorWithDef sw) {
    final sensor = sw.sensor;
    Color statusColor;
    switch (sensor.alarmStatus) {
      case 'alarm': statusColor = Colors.redAccent; break;
      case 'warning': statusColor = Colors.orangeAccent; break;
      default: statusColor = Colors.greenAccent;
    }

    final shortName = sensor.sensorName
        .replaceAll(RegExp(r'^(Kazan|Chiller|AHU|Pompa|Enerji)\s*'), '')
        .replaceAll('Sirkuelasyon ', '');

    final isDurum = shortName.toLowerCase().contains('durum');
    String valueText;
    if (isDurum) {
      valueText = sensor.value >= 1 ? 'ON' : 'OFF';
    } else {
      valueText = _fmt(sensor.value);
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/sensor-detail', arguments: sensor.sensorId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4)]),
          ),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(shortName, style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.5))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(valueText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor)),
              if (!isDurum) ...[
                const SizedBox(width: 2),
                Text(sensor.unit, style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.4))),
              ],
            ]),
          ]),
        ]),
      ),
    );
  }

  String _fmt(double val) {
    if (val == val.roundToDouble()) return val.toStringAsFixed(0);
    if (val >= 100) return val.toStringAsFixed(1);
    return val.toStringAsFixed(2);
  }
}

class _ZoneConfig {
  final int unitId;
  final String name;
  final IconData icon;
  final Color color;
  final String location;
  const _ZoneConfig(this.unitId, this.name, this.icon, this.color, this.location);
}

class _SensorWithDef {
  final SensorLatestValue sensor;
  final SensorDefinition? def;
  const _SensorWithDef(this.sensor, this.def);
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 6});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.5 + _ctrl.value * 0.5),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: _ctrl.value * 0.6), blurRadius: widget.size * 2)],
        ),
      ),
    );
  }
}
