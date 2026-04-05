import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';
// ignore: unused_import
import '../../core/utils/turkish_string.dart';
import '../../core/utils/error_helper.dart';

class MicroLearningResultsScreen extends ConsumerStatefulWidget {
  const MicroLearningResultsScreen({super.key});

  @override
  ConsumerState<MicroLearningResultsScreen> createState() => _MicroLearningResultsScreenState();
}

class _MicroLearningResultsScreenState extends ConsumerState<MicroLearningResultsScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String? _error;
  String? _filterDepartment;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      String url = '/micro-learning/assignments?limit=100';
      if (_filterStatus != null) url += '&status=$_filterStatus';
      final resp = await dio.get(url);
      setState(() {
        _assignments = List<Map<String, dynamic>>.from(resp.data ?? []);
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = ErrorHelper.getMessage(e); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterDepartment == null) return _assignments;
    return _assignments.where((a) => a['user_department'] == _filterDepartment).toList();
  }

  Set<String> get _departments {
    return _assignments
        .map((a) => a['user_department'] as String?)
        .whereType<String>()
        .toSet();
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
        title: Text('Mikro-Ogrenme Sonuclari',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: ScadaColors.cyan, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(children: [
        // Filtreler
        _buildFilters(context),
        // Istatistikler
        _buildStats(context),
        // Liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: ScadaColors.red)))
                  : _filtered.isEmpty
                      ? Center(child: Text('Henuz atama yok', style: TextStyle(color: context.scada.textDim)))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _buildAssignmentCard(ctx, _filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        // Departman filtresi
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.scada.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.scada.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _filterDepartment,
                hint: Text('Departman', style: TextStyle(color: context.scada.textDim, fontSize: 13)),
                isExpanded: true,
                dropdownColor: context.scada.surface,
                items: [
                  DropdownMenuItem<String?>(value: null,
                    child: Text('Tumu', style: TextStyle(color: context.scada.textPrimary, fontSize: 13))),
                  ..._departments.map((d) => DropdownMenuItem(value: d,
                    child: Text(d, style: TextStyle(color: context.scada.textPrimary, fontSize: 13)))),
                ],
                onChanged: (v) => setState(() => _filterDepartment = v),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Durum filtresi
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.scada.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.scada.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _filterStatus,
                hint: Text('Durum', style: TextStyle(color: context.scada.textDim, fontSize: 13)),
                isExpanded: true,
                dropdownColor: context.scada.surface,
                items: [
                  DropdownMenuItem<String?>(value: null,
                    child: Text('Tumu', style: TextStyle(color: context.scada.textPrimary, fontSize: 13))),
                  DropdownMenuItem(value: 'active',
                    child: Text('Aktif', style: TextStyle(color: ScadaColors.cyan, fontSize: 13))),
                  DropdownMenuItem(value: 'completed',
                    child: Text('Tamamlanan', style: TextStyle(color: ScadaColors.green, fontSize: 13))),
                  DropdownMenuItem(value: 'failed_retry',
                    child: Text('Tekrar', style: TextStyle(color: ScadaColors.amber, fontSize: 13))),
                ],
                onChanged: (v) {
                  setState(() => _filterStatus = v);
                  _loadData();
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStats(BuildContext context) {
    final total = _assignments.length;
    final completed = _assignments.where((a) => a['status'] == 'completed').length;
    final active = _assignments.where((a) => a['status'] == 'active').length;
    final retry = _assignments.where((a) => a['status'] == 'failed_retry').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        _buildStatChip(context, '$total', 'Toplam', context.scada.textPrimary),
        const SizedBox(width: 6),
        _buildStatChip(context, '$active', 'Aktif', ScadaColors.cyan),
        const SizedBox(width: 6),
        _buildStatChip(context, '$completed', 'Tamamlanan', ScadaColors.green),
        const SizedBox(width: 6),
        _buildStatChip(context, '$retry', 'Tekrar', ScadaColors.amber),
      ]),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Map<String, dynamic> a) {
    return InkWell(
      onTap: () => _showUserDetail(context, a),
      borderRadius: BorderRadius.circular(10),
      child: _buildAssignmentCardContent(context, a),
    );
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> a) async {
    final userId = a['user_id'];
    final userName = a['user_name'] ?? 'Bilinmiyor';
    if (userId == null) return;

    // Onaylari getir
    try {
      final dio = ref.read(authDioProvider);
      final resp = await dio.get('/training/acknowledgments/$userId');
      final acks = List<Map<String, dynamic>>.from(resp.data ?? []);

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Container(
          margin: const EdgeInsets.only(top: 100),
          decoration: BoxDecoration(
            color: context.scada.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.scada.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              // Header
              Row(children: [
                CircleAvatar(radius: 20, backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                  child: Text(userName[0].toTurkishUpperCase(), style: const TextStyle(color: ScadaColors.cyan, fontWeight: FontWeight.w700))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                  Text(a['user_department'] ?? '-', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
                ])),
              ]),
              const SizedBox(height: 16),
              // Onaylar
              if (acks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Henuz egitim onayi yok', style: TextStyle(color: context.scada.textDim)),
                )
              else
                ...acks.map((ack) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scada.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.verified_user, color: ScadaColors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(a['module_title'] ?? ack['module_id']?.toString().substring(0, 8) ?? 'Modul',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary))),
                    ]),
                    const SizedBox(height: 6),
                    Text(ack['acknowledgment_text'] ?? '',
                      style: TextStyle(fontSize: 12, color: context.scada.textDim, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time, size: 12, color: context.scada.textDim),
                      const SizedBox(width: 4),
                      Text(_formatDate(ack['acknowledged_at']),
                        style: TextStyle(fontSize: 11, color: context.scada.textDim)),
                      if (ack['ip_address'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.language, size: 12, color: context.scada.textDim),
                        const SizedBox(width: 4),
                        Text(ack['ip_address'], style: TextStyle(fontSize: 11, color: context.scada.textDim)),
                      ],
                    ]),
                  ]),
                )),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      );
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onaylar yuklenemedi: ${ErrorHelper.getMessage(e)}'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '-';
    try {
      final d = DateTime.parse(dt.toString());
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt.toString();
    }
  }

  Widget _buildAssignmentCardContent(BuildContext context, Map<String, dynamic> a) {
    final status = a['status'] ?? 'active';
    final quizPassed = a['quiz_passed'] == true;
    final userName = a['user_name'] ?? 'Bilinmiyor';
    final userDept = a['user_department'] ?? '-';
    final moduleTitle = a['module_title'] ?? 'Modul';
    final routeTitle = a['route_title'] ?? '';
    final learningDay = a['learning_day'] ?? 1;
    final startedDate = a['started_date'] ?? '';
    final completedDate = a['completed_date'];

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = ScadaColors.green;
        statusText = 'Tamamlandi';
        statusIcon = Icons.check_circle;
        break;
      case 'failed_retry':
        statusColor = ScadaColors.amber;
        statusText = 'Tekrar';
        statusIcon = Icons.refresh;
        break;
      default:
        statusColor = ScadaColors.cyan;
        statusText = 'Aktif';
        statusIcon = Icons.play_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Calisan adi + durum
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Text(userName.isNotEmpty ? userName[0].toTurkishUpperCase() : '?',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
              Text(userDept, style: TextStyle(fontSize: 11, color: context.scada.textDim)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 3),
              Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Modul bilgisi
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.scada.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.school, size: 16, color: context.scada.textDim),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(moduleTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.scada.textPrimary)),
                if (routeTitle.isNotEmpty)
                  Text(routeTitle, style: TextStyle(fontSize: 11, color: context.scada.textDim)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Detaylar
        Row(children: [
          _buildDetailChip(context, 'Gun $learningDay', Icons.calendar_today),
          const SizedBox(width: 8),
          _buildDetailChip(context, quizPassed ? 'Quiz Gecti' : 'Quiz Bekliyor',
            quizPassed ? Icons.check : Icons.hourglass_empty,
            color: quizPassed ? ScadaColors.green : context.scada.textDim),
          const Spacer(),
          Text(startedDate, style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          if (completedDate != null) ...[
            Text(' → ', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
            Text(completedDate, style: TextStyle(fontSize: 10, color: ScadaColors.green)),
          ],
        ]),
      ]),
    );
  }

  Widget _buildDetailChip(BuildContext context, String text, IconData icon, {Color? color}) {
    final c = color ?? context.scada.textDim;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: c)),
    ]);
  }
}
