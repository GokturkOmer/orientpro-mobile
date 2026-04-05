import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final res = await dio.get('/super-admin/dashboard');
      setState(() { _data = res.data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator(color: ScadaColors.red)); }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: ScadaColors.red, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: ScadaColors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      ]));
    }

    final summary = _data?['summary'] as Map? ?? {};
    final churnRisk = (_data?['churn_risk'] as List?) ?? [];

    return RefreshIndicator(
      color: ScadaColors.red,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ozet kartlari
          _SectionTitle('Platform Ozeti'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard('Toplam Musteri', '${summary['total_organizations'] ?? 0}', Icons.business, ScadaColors.red)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard('Aktif', '${summary['active_organizations'] ?? 0}', Icons.check_circle_outline, ScadaColors.green)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MetricCard('Trial', '${summary['trial_organizations'] ?? 0}', Icons.access_time, ScadaColors.amber)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard('Toplam Kullanici', '${summary['total_users'] ?? 0}', Icons.people_outline, ScadaColors.cyan)),
          ]),
          const SizedBox(height: 10),
          _MetricCard('Bu Ay Yeni Musteri', '${summary['new_organizations_30d'] ?? 0}', Icons.trending_up, ScadaColors.purple),

          // Churn riski
          if (churnRisk.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle('Churn Riski (30+ gun giris yok)'),
            const SizedBox(height: 12),
            ...churnRisk.map((org) => _ChurnCard(org)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.scada.textSecondary, letterSpacing: 1),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
      ]),
    );
  }
}

class _ChurnCard extends StatelessWidget {
  final Map org;
  const _ChurnCard(this.org);

  @override
  Widget build(BuildContext context) {
    final days = org['days_since_login'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: ScadaColors.red, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(org['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: context.scada.textPrimary, fontSize: 13)),
          Text(
            days != null ? '$days gundur giris yok • ${org['plan_type']}' : 'Hic giris yapilmadi • ${org['plan_type']}',
            style: TextStyle(fontSize: 11, color: context.scada.textSecondary),
          ),
        ])),
      ]),
    );
  }
}
