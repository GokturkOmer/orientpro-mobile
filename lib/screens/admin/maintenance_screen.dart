import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool _loading = true;
  String? _error;

  // Health
  Map<String, dynamic> _health = {};
  // System
  Map<String, dynamic> _system = {};
  // DB stats
  Map<String, dynamic> _dbStats = {};
  // Recent activity
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final results = await Future.wait([
        dio.get('/health/detailed'),
        dio.get('/maintenance/system-info'),
        dio.get('/maintenance/db-stats'),
        dio.get('/maintenance/recent-activity?limit=20'),
      ]);
      setState(() {
        _health = results[0].data as Map<String, dynamic>;
        _system = results[1].data as Map<String, dynamic>;
        _dbStats = results[2].data as Map<String, dynamic>;
        _recentActivity = results[3].data as List;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = ErrorHelper.getMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: ScadaColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.developer_board, color: ScadaColors.green, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Bakim Paneli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: ScadaColors.cyan, size: 20), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: ScadaColors.green),
              const SizedBox(height: 16),
              Text('Sistem bilgileri yukleniyor...', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
            ]))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _loadAll, child: const Text('Tekrar Dene')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: ScadaColors.green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildHealthSection(),
                      const SizedBox(height: 20),
                      _buildSystemSection(),
                      const SizedBox(height: 20),
                      _buildDbStatsSection(),
                      const SizedBox(height: 20),
                      _buildActivitySection(),
                    ]),
                  ),
                ),
    );
  }

  // ===== SERVIS SAGLIGI =====
  Widget _buildHealthSection() {
    final overall = _health['overall'] ?? 'bilinmiyor';
    final services = _health['services'] as Map<String, dynamic>? ?? {};
    final isHealthy = overall == 'saglikli';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.monitor_heart, 'SERVIS SAGLIGI'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isHealthy ? ScadaColors.green : ScadaColors.red).withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          Icon(isHealthy ? Icons.check_circle : Icons.warning, size: 36, color: isHealthy ? ScadaColors.green : ScadaColors.red),
          const SizedBox(height: 8),
          Text(isHealthy ? 'Tum Servisler Saglikli' : 'Sorun Tespit Edildi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isHealthy ? ScadaColors.green : ScadaColors.red)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ...services.entries.map((e) {
              final svc = e.value as Map<String, dynamic>;
              final ok = svc['status'] == 'ok';
              final ms = svc['response_ms'];
              return Column(children: [
                Icon(ok ? Icons.cloud_done : Icons.cloud_off, size: 20, color: ok ? ScadaColors.green : ScadaColors.red),
                const SizedBox(height: 4),
                Text(e.key.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.scada.textSecondary)),
                if (ms != null) Text('${ms}ms', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
              ]);
            }),
          ]),
        ]),
      ),
    ]);
  }

  // ===== SUNUCU BILGILERI =====
  Widget _buildSystemSection() {
    final mem = _system['memory'] as Map<String, dynamic>? ?? {};
    final disk = _system['disk'] as Map<String, dynamic>? ?? {};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.computer, 'SUNUCU BILGILERI'),
      const SizedBox(height: 12),
      Row(children: [
        _metricCard('CPU', '${_system['cpu_percent'] ?? 0}%', Icons.memory, ScadaColors.cyan),
        const SizedBox(width: 8),
        _metricCard('RAM', '${mem['percent'] ?? 0}%', Icons.storage, ScadaColors.amber),
        const SizedBox(width: 8),
        _metricCard('Disk', '${disk['percent'] ?? 0}%', Icons.disc_full, ScadaColors.purple),
      ]),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow('Platform', '${_system['platform'] ?? ''} ${_system['platform_version'] ?? ''}'),
          _infoRow('Python', _system['python_version'] ?? ''),
          _infoRow('CPU', '${_system['cpu_count'] ?? 0} cekirdek'),
          _infoRow('RAM', '${mem['used_gb'] ?? 0} / ${mem['total_gb'] ?? 0} GB'),
          _infoRow('Disk', '${disk['used_gb'] ?? 0} / ${disk['total_gb'] ?? 0} GB'),
        ]),
      ),
    ]);
  }

  // ===== VERITABANI ISTATISTIKLERI =====
  Widget _buildDbStatsSection() {
    final tables = _dbStats['tables'] as Map<String, dynamic>? ?? {};
    final dbSize = _dbStats['database_size'] ?? 'bilinmiyor';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.table_chart, 'VERITABANI'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.dns, size: 14, color: context.scada.textDim),
            const SizedBox(width: 6),
            Text('DB Boyutu: $dbSize', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          ]),
          const SizedBox(height: 10),
          ...tables.entries.map((e) {
            final val = e.value;
            String display;
            if (val is Map) {
              display = '${val['total']} (${val['active']} aktif)';
            } else {
              display = '$val';
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_tableLabel(e.key), style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                Text(display, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
              ]),
            );
          }),
        ]),
      ),
    ]);
  }

  // ===== SON AKTIVITELER =====
  Widget _buildActivitySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.history, 'SON AKTIVITELER'),
      const SizedBox(height: 12),
      if (_recentActivity.isEmpty)
        Center(child: Text('Henuz aktivite yok', style: TextStyle(fontSize: 12, color: context.scada.textDim)))
      else
        ..._recentActivity.map((log) {
          final action = log['action'] ?? '';
          final resource = log['resource_type'] ?? '';
          final createdAt = log['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.scada.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.scada.border),
            ),
            child: Row(children: [
              Icon(_actionIcon(action), size: 14, color: _actionColor(action)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(action, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.scada.textPrimary)),
                Text('$resource • $createdAt', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
              ])),
            ]),
          );
        }),
    ]);
  }

  // ===== YARDIMCILAR =====

  Widget _sectionHeader(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: context.scada.textDim),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
    ]);
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    final percent = double.tryParse(value.replaceAll('%', '')) ?? 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: percent > 80 ? ScadaColors.red : color)),
          Text(label, style: TextStyle(fontSize: 9, color: context.scada.textSecondary)),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
        Text(value, style: TextStyle(fontSize: 11, color: context.scada.textPrimary)),
      ]),
    );
  }

  String _tableLabel(String key) {
    const labels = {
      'users': 'Kullanicilar',
      'departments': 'Departmanlar',
      'routes': 'Rotalar',
      'modules': 'Moduller',
      'contents': 'Icerikler',
      'quizzes': 'Quizler',
      'progress_records': 'Ilerleme Kayitlari',
      'quiz_results': 'Quiz Sonuclari',
    };
    return labels[key] ?? key;
  }

  IconData _actionIcon(String action) {
    if (action.contains('create')) return Icons.add_circle;
    if (action.contains('update') || action.contains('edit')) return Icons.edit;
    if (action.contains('delete')) return Icons.delete;
    if (action.contains('login')) return Icons.login;
    if (action.contains('approve')) return Icons.check_circle;
    return Icons.info;
  }

  Color _actionColor(String action) {
    if (action.contains('create')) return ScadaColors.green;
    if (action.contains('delete')) return ScadaColors.red;
    if (action.contains('login')) return ScadaColors.cyan;
    if (action.contains('approve')) return ScadaColors.amber;
    return ScadaColors.purple;
  }
}
