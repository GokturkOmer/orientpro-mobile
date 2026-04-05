import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';

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
      } catch (e) {
        debugPrint('_loadData hata: $e');
      }

      setState(() {
        _subscription = subRes.data;
        _plans = List<Map<String, dynamic>>.from(plansRes.data ?? []);
        _invoices = invoiceList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Abonelik bilgisi yüklenemedi'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        title: const Text('Abonelik & Plan'),
        backgroundColor: context.scada.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.scada.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
                ]))
              : RefreshIndicator(
                  color: ScadaColors.cyan,
                  backgroundColor: context.scada.surface,
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
        statusColor = context.scada.textDim;
        statusText = 'Ucretsiz';
        statusIcon = Icons.card_giftcard;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.15), context.scada.surface],
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
          Text('Dönem sonu: ${_formatDate(periodEnd)}',
            style: TextStyle(fontSize: 13, color: context.scada.textDim)),
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
      Text('PLANLAR',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: context.scada.textDim, letterSpacing: 1)),
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
        color: isActive ? ScadaColors.cyan.withValues(alpha: 0.08) : context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? ScadaColors.cyan : context.scada.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(plan['display_name'] ?? plan['name'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.scada.textPrimary)),
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
                style: TextStyle(fontSize: 14, color: context.scada.textSecondary))
            else
              const Text('Ucretsiz', style: TextStyle(fontSize: 14, color: ScadaColors.green)),
          ])),
        ]),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            Text('${plan['max_users'] ?? '?'} kullanici', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
            Text('•', style: TextStyle(color: context.scada.textDim)),
            Text('${plan['max_storage_gb'] ?? '?'} GB depolama', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
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
      Text('FATURA GECMISI',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: context.scada.textDim, letterSpacing: 1)),
      const SizedBox(height: 12),
      ..._invoices.take(5).map((inv) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          inv['status'] == 'paid' ? Icons.receipt_long : Icons.pending,
          color: inv['status'] == 'paid' ? ScadaColors.green : ScadaColors.orange,
        ),
        title: Text(inv['description'] ?? 'Fatura',
          style: TextStyle(color: context.scada.textPrimary, fontSize: 14)),
        subtitle: Text(_formatDate(inv['invoice_date']),
          style: TextStyle(color: context.scada.textDim, fontSize: 12)),
        trailing: Text('${(inv['amount'] ?? 0).toStringAsFixed(0)} ${inv['currency'] ?? 'TRY'}',
          style: TextStyle(color: context.scada.textPrimary, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  void _showUpgradeDialog(Map<String, dynamic> plan) {
    String selectedPeriod = 'monthly';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${plan['display_name']} Planina Yukselt',
          style: TextStyle(color: context.scada.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Fiyat secimi
          Row(children: [
            Expanded(child: _buildPeriodOption(
              'Aylik',
              '${(plan['price_monthly'] ?? 0).toStringAsFixed(0)} TL/ay',
              selectedPeriod == 'monthly',
              () => setDialogState(() => selectedPeriod = 'monthly'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildPeriodOption(
              'Yillik',
              '${(plan['price_yearly'] ?? 0).toStringAsFixed(0)} TL/yil',
              selectedPeriod == 'yearly',
              () => setDialogState(() => selectedPeriod = 'yearly'),
            )),
          ]),
          const SizedBox(height: 16),
          // Ozellikler
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scada.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildFeatureRow(Icons.people, '${plan['max_users'] ?? '?'} kullanici'),
              _buildFeatureRow(Icons.cloud, '${plan['max_storage_gb'] ?? '?'} GB depolama'),
              if (plan['features'] != null && (plan['features'] as Map).containsKey('ai_chatbot'))
                _buildFeatureRow(Icons.smart_toy, 'AI Asistan'),
              if (plan['features'] != null && (plan['features'] as Map).containsKey('analytics'))
                _buildFeatureRow(Icons.analytics, 'Detayli Analitik'),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Iptal', style: TextStyle(color: context.scada.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startCheckout(plan, selectedPeriod);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Odemeye Gec'),
          ),
        ],
      ),
    ));
  }

  Widget _buildPeriodOption(String label, String price, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? ScadaColors.cyan.withValues(alpha: 0.08) : context.scada.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? ScadaColors.cyan : context.scada.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? ScadaColors.cyan : context.scada.textSecondary)),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: selected ? ScadaColors.cyan : context.scada.textPrimary)),
        ]),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: ScadaColors.green),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
      ]),
    );
  }

  Future<void> _startCheckout(Map<String, dynamic> plan, String billingPeriod) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/payments/checkout', data: {
        'plan_id': plan['id'],
        'billing_period': billingPeriod,
      });

      final checkoutHtml = response.data['checkout_form_content'] as String?;
      final token = response.data['token'] as String?;

      if (checkoutHtml != null && checkoutHtml.isNotEmpty) {
        setState(() => _isLoading = false);
        if (mounted) _showCheckoutForm(checkoutHtml);
      } else if (token != null) {
        // Token varsa iyzico sayfasina yonlendir
        setState(() => _isLoading = false);
        final uri = Uri.parse('https://sandbox-merchant.iyzipay.com/checkout?token=$token');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        setState(() { _isLoading = false; _error = 'Odeme formu oluşturulamadı'; });
      }
    } on DioException catch (e) {
      setState(() { _isLoading = false; _error = ErrorHelper.getMessage(e); });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Odeme baslatilamadi'; });
    }
  }

  void _showCheckoutForm(String htmlContent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.payment, color: ScadaColors.green, size: 20),
          const SizedBox(width: 8),
          Text('Odeme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () {
            Navigator.pop(ctx);
            _loadData();
          }),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: kIsWeb
            ? const Center(child: Text('Odeme sayfasi tarayicinizda acilacak'))
            : SingleChildScrollView(
                child: Column(children: [
                  const Icon(Icons.open_in_browser, size: 48, color: ScadaColors.cyan),
                  const SizedBox(height: 16),
                  Text(
                    'Odeme formu hazir. Tarayicinizda aciliyor...',
                    style: TextStyle(fontSize: 14, color: context.scada.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Odeme tamamlandiktan sonra bu sayfaya donun ve yenileyin.',
                    style: TextStyle(fontSize: 12, color: context.scada.textDim),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.cyan),
            child: const Text('Odeme Tamamlandi — Yenile'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
