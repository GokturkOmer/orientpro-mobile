import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';

class SuperAdminOrgsScreen extends ConsumerStatefulWidget {
  const SuperAdminOrgsScreen({super.key});

  @override
  ConsumerState<SuperAdminOrgsScreen> createState() => _SuperAdminOrgsScreenState();
}

class _SuperAdminOrgsScreenState extends ConsumerState<SuperAdminOrgsScreen> {
  List<Map<String, dynamic>> _orgs = [];
  bool _isLoading = true;
  String? _error;
  String? _filterPlan;
  String? _filterHealth;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final params = <String, String>{};
      if (_filterPlan != null) params['plan_type'] = _filterPlan!;
      if (_filterHealth != null) params['health'] = _filterHealth!;
      final res = await dio.get('/super-admin/organizations', queryParameters: params);
      setState(() {
        _orgs = List<Map<String, dynamic>>.from(res.data['organizations'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _healthColor(String? h) {
    if (h == 'green') return Colors.green;
    if (h == 'yellow') return Colors.orange;
    return Colors.red;
  }

  IconData _healthIcon(String? h) {
    if (h == 'green') return Icons.check_circle_outline;
    if (h == 'yellow') return Icons.warning_amber_outlined;
    return Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filtreler
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: context.scada.surface,
        child: Row(children: [
          _FilterChip('Hepsi', _filterPlan == null && _filterHealth == null, () {
            setState(() { _filterPlan = null; _filterHealth = null; });
            _load();
          }),
          const SizedBox(width: 6),
          _FilterChip('Trial', _filterPlan == 'trial', () {
            setState(() { _filterPlan = _filterPlan == 'trial' ? null : 'trial'; });
            _load();
          }),
          const SizedBox(width: 6),
          _FilterChip('🔴 Risk', _filterHealth == 'red', () {
            setState(() { _filterHealth = _filterHealth == 'red' ? null : 'red'; });
            _load();
          }),
        ]),
      ),
      // Liste
      Expanded(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
                color: const Color(0xFFE53935),
                onRefresh: _load,
                child: _orgs.isEmpty
                  ? const Center(child: Text('Organizasyon bulunamadi'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orgs.length,
                      itemBuilder: (_, i) => _OrgCard(_orgs[i], _healthColor, _healthIcon),
                    ),
              ),
      ),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE53935).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFE53935) : context.scada.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? const Color(0xFFE53935) : context.scada.textSecondary)),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final Map<String, dynamic> org;
  final Color Function(String?) healthColor;
  final IconData Function(String?) healthIcon;
  const _OrgCard(this.org, this.healthColor, this.healthIcon);

  @override
  Widget build(BuildContext context) {
    final health = org['health'] as String?;
    final activeUsers = org['active_users'] ?? 0;
    final maxUsers = org['max_users'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor(health).withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(org['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            Text('${org['sector'] ?? ''} • ${org['plan_type'] ?? ''}',
              style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
          ])),
          Icon(healthIcon(health), color: healthColor(health), size: 20),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Stat('Kullanici', '$activeUsers / $maxUsers')),
          Expanded(child: _Stat('Son Aktivite', _formatDate(org['last_activity']))),
          Expanded(child: _Stat('Kayıt', _formatDate(org['created_at']))),
        ]),
      ]),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays} gun once';
      if (diff.inHours > 0) return '${diff.inHours} saat once';
      return 'Az once';
    } catch (_) { return '-'; }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
    ]);
  }
}
