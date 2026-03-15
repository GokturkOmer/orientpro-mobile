import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sensor.dart';
import '../../providers/sensor_provider.dart';

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(activeAlarmsProvider);
    final statsAsync = ref.watch(alarmStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(activeAlarmsProvider.notifier).fetch();
              ref.read(alarmStatsProvider.notifier).fetch();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(children: [
                _statBadge('Aktif', stats.totalActive, Colors.red),
                const SizedBox(width: 8),
                _statBadge('Onaylanmış', stats.totalAcknowledged, Colors.orange),
                const SizedBox(width: 8),
                _statBadge('Bugün Temizlenen', stats.totalClearedToday, Colors.green),
              ]),
            ),
          ),

          // Alarm list
          Expanded(
            child: alarmsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (alarms) {
                if (alarms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                        const SizedBox(height: 12),
                        const Text('Aktif alarm yok', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const Text('Tüm sistemler normal çalışıyor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: alarms.length,
                  itemBuilder: (ctx, i) => _alarmCard(context, ref, alarms[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }

  Widget _alarmCard(BuildContext context, WidgetRef ref, AlarmEvent alarm) {
    Color severityColor;
    IconData severityIcon;
    switch (alarm.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

    Color statusColor;
    switch (alarm.status) {
      case 'active':
        statusColor = Colors.red;
        break;
      case 'acknowledged':
        statusColor = Colors.orange;
        break;
      case 'cleared':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/sensor-detail', arguments: alarm.sensorId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(severityIcon, color: severityColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.message.length > 60 ? '${alarm.message.substring(0, 60)}...' : alarm.message,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(alarm.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(alarm.severity.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: severityColor)),
                      ),
                      const Spacer(),
                      Text(_timeAgo(alarm.triggeredAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
              if (alarm.status == 'active')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'Onayla',
                  onPressed: () {
                    ref.read(activeAlarmsProvider.notifier).acknowledge(alarm.id, 'system');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alarm onaylandı'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} sn önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}
