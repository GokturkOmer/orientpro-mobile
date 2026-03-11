import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/prediction_provider.dart';
import '../../core/theme/app_theme.dart';

class AIPredictionScreen extends ConsumerWidget {
  const AIPredictionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(predictionProvider);
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: ScadaColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.psychology, color: ScadaColors.purple, size: 18)),
          const SizedBox(width: 8),
          const Text('AI Ariza Tahmini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20, color: ScadaColors.cyan), onPressed: () => ref.invalidate(predictionProvider)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: dataAsync.when(
        loading: () => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: ScadaColors.cyan),
          SizedBox(height: 16),
          Text('AI analiz yapiliyor...', style: TextStyle(color: ScadaColors.textSecondary)),
        ])),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error, size: 48, color: ScadaColors.red),
          const SizedBox(height: 8),
          Text('Hata: $e', style: const TextStyle(color: ScadaColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(predictionProvider), child: const Text('Tekrar Dene')),
        ])),
        data: (data) {
          final summary = data['summary'] as Map<String, dynamic>;
          final units = (data['units'] as List).cast<Map<String, dynamic>>();
          final anomalies = (data['anomalies'] as List).cast<Map<String, dynamic>>();
          final predictions = (data['predictions'] as List).cast<Map<String, dynamic>>();

          return RefreshIndicator(
            color: ScadaColors.cyan, backgroundColor: ScadaColors.surface,
            onRefresh: () async => ref.invalidate(predictionProvider),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              // Summary bar
              _summaryBar(summary),
              const SizedBox(height: 14),

              // Health scores
              _sectionLabel('UNITE SAGLIK SKORLARI', Icons.favorite),
              const SizedBox(height: 8),
              ...units.map((u) => _healthCard(u)),
              const SizedBox(height: 14),

              // Anomalies
              if (anomalies.isNotEmpty) ...[
                _sectionLabel('ANOMALI TESPITI', Icons.bug_report),
                const SizedBox(height: 8),
                ...anomalies.map((a) => _anomalyCard(a)),
                const SizedBox(height: 14),
              ],

              // Predictions
              if (predictions.isNotEmpty) ...[
                _sectionLabel('ARIZA TAHMINLERI', Icons.trending_up),
                const SizedBox(height: 8),
                ...predictions.map((p) => _predictionCard(p)),
              ],

              // No issues
              if (anomalies.isEmpty && predictions.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ScadaColors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: ScadaColors.green.withOpacity(0.3))),
                  child: Column(children: [
                    const Icon(Icons.check_circle, size: 48, color: ScadaColors.green),
                    const SizedBox(height: 8),
                    const Text('Tum Sistemler Normal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.green)),
                    const SizedBox(height: 4),
                    const Text('AI analizi sonucunda anomali veya ariza riski tespit edilmedi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
                  ]),
                ),

              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }

  Widget _summaryBar(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: ScadaColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: ScadaColors.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _miniStat(Icons.sensors, ScadaColors.cyan, '${summary["total_sensors"]}', 'Sensor'),
        Container(width: 1, height: 28, color: ScadaColors.border),
        _miniStat(Icons.favorite, _healthColor(summary["avg_health"]), '${summary["avg_health"]}%', 'Saglik'),
        Container(width: 1, height: 28, color: ScadaColors.border),
        _miniStat(Icons.bug_report, summary["anomaly_count"] > 0 ? ScadaColors.amber : ScadaColors.green, '${summary["anomaly_count"]}', 'Anomali'),
        Container(width: 1, height: 28, color: ScadaColors.border),
        _miniStat(Icons.trending_up, summary["prediction_count"] > 0 ? ScadaColors.red : ScadaColors.green, '${summary["prediction_count"]}', 'Tahmin'),
      ]),
    );
  }

  Widget _miniStat(IconData icon, Color color, String value, String label) {
    return Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
    ]);
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: ScadaColors.textDim),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
    ]);
  }

  Widget _healthCard(Map<String, dynamic> unit) {
    final score = unit['health_score'] as int;
    final color = _healthColor(score);
    final statusText = score >= 80 ? 'Normal' : score >= 60 ? 'Dikkat' : 'Kritik';
    final sensors = (unit['sensors'] as List).cast<Map<String, dynamic>>();
    final iconData = _unitIcon(unit['icon'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ScadaColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: ScadaColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(iconData, size: 16, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unit['unit_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            Text('${sensors.length} sensor', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$score%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 4),
              Text(statusText, style: TextStyle(fontSize: 9, color: color)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: score / 100, minHeight: 4, backgroundColor: ScadaColors.border, color: color)),
        const SizedBox(height: 8),
        // Sensor chips
        Wrap(spacing: 6, runSpacing: 4, children: sensors.map((s) {
          final sColor = s['status'] == 'critical' ? ScadaColors.red : s['status'] == 'warning' ? ScadaColors.amber : ScadaColors.green;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: sColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4), border: Border.all(color: sColor.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('${s["name"]}', style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
              const SizedBox(width: 4),
              Text('${s["current_value"]}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sColor)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _anomalyCard(Map<String, dynamic> a) {
    final color = a['severity'] == 'critical' ? ScadaColors.red : ScadaColors.amber;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.bug_report, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['sensor_name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(a['message'], style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            Text('Mevcut: ${a["current"]}', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
            const SizedBox(width: 12),
            Text('Beklenen: ${a["expected"]}', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
            const SizedBox(width: 12),
            Text('Z: ${a["z_score"]}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ]),
        ])),
      ]),
    );
  }

  Widget _predictionCard(Map<String, dynamic> p) {
    final hours = p['hours_to_breach'];
    final confidence = p['confidence'];
    final color = hours < 6 ? ScadaColors.red : hours < 24 ? ScadaColors.amber : ScadaColors.cyan;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.trending_up, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['sensor_name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(p['message'], style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            Text('~$hours saat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(width: 12),
            Text('Guven: %$confidence', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
            const SizedBox(width: 12),
            Text('Esik: ${p["threshold"]}', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
          ]),
        ])),
      ]),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return ScadaColors.green;
    if (score >= 60) return ScadaColors.amber;
    return ScadaColors.red;
  }

  IconData _unitIcon(String icon) {
    switch (icon) {
      case 'fire': return Icons.local_fire_department;
      case 'snowflake': return Icons.ac_unit;
      case 'wind': return Icons.air;
      case 'water': return Icons.water_drop;
      case 'bolt': return Icons.bolt;
      default: return Icons.developer_board;
    }
  }
}
