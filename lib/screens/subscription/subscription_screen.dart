import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';

/// Abonelik durumu ve plan yonetimi ekrani.
/// Mevcut plan, kalan sure, plan yukseltme ve fatura gecmisi gosterir.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final subRes = await dio.get('/payments/subscription');
      final plansRes = await dio.get('/payments/plans');
      List<Map<String, dynamic>> invoiceList = [];
      try {
        final invRes = await dio.get('/payments/invoices');
        invoiceList = List<Map<String, dynamic>>.from(invRes.data ?? []);
      } catch (_) {}

      setState(() {
        _subscription = subRes.data;
        _plans = List<Map<String, dynamic>>.from(plansRes.data ?? []);
        _invoices = invoiceList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Abonelik bilgisi yuklenemedi'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        title: const Text('Abonelik & Plan'),
        backgroundColor: ScadaColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ScadaColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
                ]))
              : RefreshIndicator(
                  color: ScadaColors.cyan,
                  backgroundColor: ScadaColors.surface,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCurrentPlan(),
                      const SizedBox(height: 24),
                      _buildPlansSection(),
                      if (_invoices.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInvoicesSection(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentPlan() {
    final sub = _subscription;
    final isTrial = sub?['is_trial'] == true;
    final status = sub?['status'] ?? 'free';
    final planName = sub?['plan_display_name'] ?? 'Ucretsiz';
    final periodEnd = sub?['current_period_end'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'trial':
        statusColor = ScadaColors.orange;
        statusText = 'Deneme Suresi';
        statusIcon = Icons.hourglass_top;
      case 'active':
        statusColor = ScadaColors.green;
        statusText = 'Aktif';
        statusIcon = Icons.check_circle;
      case 'cancelled':
        statusColor = ScadaColors.red;
        statusText = 'Iptal Edildi';
        statusIcon = Icons.cancel;
      case 'expired':
        statusColor = ScadaColors.red;
        statusText = 'Suresi Doldu';
        statusIcon = Icons.timer_off;
      default:
        statusColor = ScadaColors.textDim;
        statusText = 'Ucretsiz';
        statusIcon = Icons.card_giftcard;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.15), ScadaColors.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(planName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 4),
            Text(statusText,
              style: TextStyle(fontSize: 14, color: statusColor.withValues(alpha: 0.8))),
          ])),
        ]),
        if (isTrial && sub?['trial_end'] != null) ...[
          const SizedBox(height: 16),
          _buildTrialCountdown(sub!['trial_end']),
        ],
        if (periodEnd != null && !isTrial) ...[
          const SizedBox(height: 12),
          Text('Donem sonu: ${_formatDate(periodEnd)}',
            style: const TextStyle(fontSize: 13, color: ScadaColors.textDim)),
        ],
      ]),
    );
  }

  Widget _buildTrialCountdown(String trialEnd) {
    final endDate = DateTime.tryParse(trialEnd);
    if (endDate == null) return const SizedBox.shrink();

    final remaining = endDate.difference(DateTime.now()).inDays;
    final isExpiring = remaining <= 3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpiring ? ScadaColors.red.withValues(alpha: 0.1) : ScadaColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(isExpiring ? Icons.warning : Icons.timer, size: 20,
          color: isExpiring ? ScadaColors.red : ScadaColors.orange),
        const SizedBox(width: 8),
        Text(
          remaining > 0 ? '$remaining gun kaldi' : 'Deneme suresi doldu',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isExpiring ? ScadaColors.red : ScadaColors.orange),
        ),
      ]),
    );
  }

  Widget _buildPlansSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PLANLAR',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: ScadaColors.textDim, letterSpacing: 1)),
      const SizedBox(height: 12),
      ..._plans.map((plan) => _buildPlanCard(plan)),
    ]);
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final currentPlan = _subscription?['plan_name'];
    final isActive = plan['name'] == currentPlan;
    final priceMonthly = plan['price_monthly'] ?? 0;
    final priceYearly = plan['price_yearly'] ?? 0;
    final features = plan['features'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? ScadaColors.cyan.withValues(alpha: 0.08) : ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? ScadaColors.cyan : ScadaColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(plan['display_name'] ?? plan['name'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Mevcut', style: TextStyle(fontSize: 11, color: ScadaColors.cyan, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            if (priceMonthly > 0)
              Text('${priceMonthly.toStringAsFixed(0)} TL/ay  •  ${priceYearly.toStringAsFixed(0)} TL/yil',
                style: const TextStyle(fontSize: 14, color: ScadaColors.textSecondary))
            else
              const Text('Ucretsiz', style: TextStyle(fontSize: 14, color: ScadaColors.green)),
          ])),
        ]),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            Text('${plan['max_users'] ?? '?'} kullanici', style: const TextStyle(fontSize: 12, color: ScadaColors.textDim)),
            Text('•', style: TextStyle(color: ScadaColors.textDim)),
            Text('${plan['max_storage_gb'] ?? '?'} GB depolama', style: const TextStyle(fontSize: 12, color: ScadaColors.textDim)),
          ]),
        ],
        if (!isActive && priceMonthly > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpgradeDialog(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                foregroundColor: ScadaColors.cyan,
              ),
              child: const Text('Plani Yukselt'),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildInvoicesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FATURA GECMISI',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: ScadaColors.textDim, letterSpacing: 1)),
      const SizedBox(height: 12),
      ..._invoices.take(5).map((inv) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          inv['status'] == 'paid' ? Icons.receipt_long : Icons.pending,
          color: inv['status'] == 'paid' ? ScadaColors.green : ScadaColors.orange,
        ),
        title: Text(inv['description'] ?? 'Fatura',
          style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14)),
        subtitle: Text(_formatDate(inv['invoice_date']),
          style: const TextStyle(color: ScadaColors.textDim, fontSize: 12)),
        trailing: Text('${(inv['amount'] ?? 0).toStringAsFixed(0)} ${inv['currency'] ?? 'TRY'}',
          style: const TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  void _showUpgradeDialog(Map<String, dynamic> plan) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ScadaColors.surface,
      title: Text('${plan['display_name']} Planina Yukselt',
        style: const TextStyle(color: ScadaColors.textPrimary)),
      content: Text(
        'Bu plan aylik ${(plan['price_monthly'] ?? 0).toStringAsFixed(0)} TL veya '
        'yillik ${(plan['price_yearly'] ?? 0).toStringAsFixed(0)} TL.\n\n'
        'Yukseltme icin lufen destek ekibi ile iletisime gecin.',
        style: const TextStyle(color: ScadaColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Kapat', style: TextStyle(color: ScadaColors.textDim)),
        ),
      ],
    ));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
