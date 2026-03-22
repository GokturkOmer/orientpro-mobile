import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sensor.dart';
import '../../providers/sensor_provider.dart';

class SensorDetailScreen extends ConsumerWidget {
  final int sensorId;
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(sensorLatestProvider);
    final readingsAsync = ref.watch(sensorReadingsProvider(sensorId));
    final sensorDefsAsync = ref.watch(sensorListProvider);

    final sensor = latestAsync.whenOrNull(
      data: (list) => list.where((s) => s.sensorId == sensorId).firstOrNull,
    );
    final sensorDef = sensorDefsAsync.whenOrNull(
      data: (list) => list.where((s) => s.id == sensorId).firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(sensor?.sensorName ?? 'Sensör #$sensorId'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        tooltip: 'AI Asistan',
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Current value card
          if (sensor != null) _buildCurrentValueCard(sensor),
          const SizedBox(height: 16),

          // Threshold info
          if (sensorDef != null) _buildThresholdCard(sensorDef),
          const SizedBox(height: 16),

          // Chart
          const Text('Son 1 Saat Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: readingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Veri yüklenemedi: $e')),
              data: (readings) {
                if (readings.isEmpty) {
                  return const Center(child: Text('Henüz veri yok'));
                }
                return _buildChart(readings, sensorDef);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Refresh button
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(sensorReadingsProvider(sensorId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentValueCard(SensorLatestValue sensor) {
    Color statusColor;
    String statusText;
    switch (sensor.alarmStatus) {
      case 'alarm':
        statusColor = Colors.red;
        statusText = '🚨 ALARM';
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusText = '⚠️ UYARI';
        break;
      default:
        statusColor = const Color(0xFF4CAF50);
        statusText = '✅ Normal';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(sensor.sensorName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(sensor.value),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: statusColor),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(' ${sensor.unit}', style: const TextStyle(fontSize: 20, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(
            'Son güncelleme: ${_formatTime(sensor.timestamp)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ]),
      ),
    );
  }

  Widget _buildThresholdCard(SensorDefinition def) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eşik Değerleri', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              if (def.alarmMin != null) _thresholdChip('Alt Alarm', def.alarmMin!, Colors.red),
              if (def.warningMin != null) _thresholdChip('Alt Uyarı', def.warningMin!, Colors.orange),
              if (def.warningMax != null) _thresholdChip('Üst Uyarı', def.warningMax!, Colors.orange),
              if (def.alarmMax != null) _thresholdChip('Üst Alarm', def.alarmMax!, Colors.red),
            ]),
            if (def.alarmMin == null && def.warningMin == null && def.warningMax == null && def.alarmMax == null)
              const Text('Eşik tanımlanmamış', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _thresholdChip(String label, double value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 9, color: color), textAlign: TextAlign.center),
          Text(value.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _buildChart(List<SensorReading> readings, SensorDefinition? def) {
    // Sort by time ascending
    final sorted = List<SensorReading>.from(readings)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.length < 2) return const Center(child: Text('Yetersiz veri'));

    final startTime = sorted.first.timestamp;
    final spots = sorted.map((r) {
      final x = r.timestamp.difference(startTime).inSeconds.toDouble();
      return FlSpot(x, r.value);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15;

    // Threshold lines
    final extraLines = <HorizontalLine>[];
    if (def?.alarmMax != null) {
      extraLines.add(HorizontalLine(y: def!.alarmMax!, color: Colors.red.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]));
    }
    if (def?.warningMax != null) {
      extraLines.add(HorizontalLine(y: def!.warningMax!, color: Colors.orange.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]));
    }
    if (def?.alarmMin != null) {
      extraLines.add(HorizontalLine(y: def!.alarmMin!, color: Colors.red.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]));
    }
    if (def?.warningMin != null) {
      extraLines.add(HorizontalLine(y: def!.warningMin!, color: Colors.orange.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]));
    }

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: spots.last.x / 4,
              getTitlesWidget: (v, meta) {
                final time = startTime.add(Duration(seconds: v.toInt()));
                return Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 9, color: Colors.grey));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: extraLines),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: const Color(0xFF1B5E20),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final time = startTime.add(Duration(seconds: spot.x.toInt()));
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)}\n${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatValue(double val) {
    if (val == val.roundToDouble()) return val.toStringAsFixed(0);
    if (val >= 100) return val.toStringAsFixed(1);
    return val.toStringAsFixed(2);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
