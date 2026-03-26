import 'dart:io' show File, Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';
import '../../core/utils/file_saver.dart' as file_saver;
import '../../widgets/scada_app_bar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_header.dart';

/// Kullanim analitigi ekrani — admin icin
/// Backend endpoint: GET /analytics/usage + GET /analytics/training-summary
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  // Usage data
  int _activeUsers = 0;
  int _maxUsers = 0;
  double _userUtilization = 0;
  int _trainingRoutes = 0;
  int _trainingModules = 0;
  int _departments = 0;
  int _recentLogins = 0;

  // Training summary
  int _totalEnrollments = 0;
  int _completed = 0;
  double _completionRate = 0;
  int _quizzesTaken = 0;
  int _quizzesPassed = 0;
  double _passRate = 0;
  double _averageScore = 0;

  // Departman bazli veri
  List<Map<String, dynamic>> _departmentStats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final results = await Future.wait([
        dio.get('/analytics/usage'),
        dio.get('/analytics/training-summary'),
      ]);

      final usage = results[0].data as Map<String, dynamic>;
      final training = results[1].data as Map<String, dynamic>;

      // Departman listesini de cek
      List<Map<String, dynamic>> deptStats = [];
      try {
        final deptRes = await dio.get('/training/departments');
        final depts = deptRes.data as List;
        for (final dept in depts) {
          try {
            final teamRes = await dio.get('/training/team-progress/${dept['code']}');
            final members = teamRes.data as List;
            deptStats.add({
              'name': dept['name'] ?? dept['code'],
              'code': dept['code'],
              'member_count': members.length,
              'avg_completion': members.isEmpty ? 0.0
                  : members.fold<double>(0, (sum, m) => sum + ((m['completion_percent'] ?? 0) as num).toDouble()) / members.length,
            });
          } catch (_) {
            deptStats.add({'name': dept['name'] ?? dept['code'], 'code': dept['code'], 'member_count': 0, 'avg_completion': 0.0});
          }
        }
      } catch (e) {
        debugPrint('_loadData hata: $e');
      }

      setState(() {
        _activeUsers = usage['active_users'] ?? 0;
        _maxUsers = usage['max_users'] ?? 0;
        _userUtilization = (usage['user_utilization'] ?? 0).toDouble();
        _trainingRoutes = usage['training_routes'] ?? 0;
        _trainingModules = usage['training_modules'] ?? 0;
        _departments = usage['departments'] ?? 0;
        _recentLogins = usage['recent_logins_30d'] ?? 0;

        _totalEnrollments = training['total_enrollments'] ?? 0;
        _completed = training['completed'] ?? 0;
        _completionRate = (training['completion_rate'] ?? 0).toDouble();
        _quizzesTaken = training['quizzes_taken'] ?? 0;
        _quizzesPassed = training['quizzes_passed'] ?? 0;
        _passRate = (training['pass_rate'] ?? 0).toDouble();
        _averageScore = (training['average_score'] ?? 0).toDouble();

        _departmentStats = deptStats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = ErrorHelper.getMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: const ScadaAppBar(
        title: 'Kullanim Analitigi',
        titleIcon: Icons.analytics,
        titleIconColor: ScadaColors.purple,
      ),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: ScadaColors.purple),
              const SizedBox(height: 16),
              Text('Analitik verileri yukleniyor...', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
            ]))
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: ScadaColors.purple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildExportButton(),
                      const SizedBox(height: 16),
                      _buildUsageSection(),
                      const SizedBox(height: 20),
                      _buildTrainingSection(),
                      const SizedBox(height: 20),
                      _buildChartsSection(),
                      if (_departmentStats.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDepartmentSection(),
                      ],
                    ]),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: ScadaColors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(fontSize: 13, color: context.scada.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.purple),
          ),
        ]),
      ),
    );
  }

  // ===== KULLANIM BOLUMU =====

  Widget _buildUsageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: Icons.people, title: 'KULLANIM OZETI'),
      const SizedBox(height: 12),

      // Kullanici kullanim orani — buyuk kart
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text('Kullanici Kullanim Orani', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: 120, height: 120,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(
                  value: _userUtilization / 100,
                  strokeWidth: 10,
                  backgroundColor: context.scada.border,
                  color: _userUtilization > 80 ? ScadaColors.red : _userUtilization > 50 ? ScadaColors.amber : ScadaColors.green,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('%${_userUtilization.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                Text('$_activeUsers / $_maxUsers', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Son 30 gunde $_recentLogins giris', style: TextStyle(fontSize: 11, color: context.scada.textDim)),
        ]),
      ),

      const SizedBox(height: 12),

      // 3 stat kart
      Row(children: [
        StatCard(label: 'Departman', value: '$_departments', color: ScadaColors.cyan, icon: Icons.business, padding: 14, borderRadius: 12),
        const SizedBox(width: 8),
        StatCard(label: 'Rota', value: '$_trainingRoutes', color: ScadaColors.green, icon: Icons.route, padding: 14, borderRadius: 12),
        const SizedBox(width: 8),
        StatCard(label: 'Modul', value: '$_trainingModules', color: ScadaColors.amber, icon: Icons.school, padding: 14, borderRadius: 12),
      ]),
    ]);
  }

  // ===== EGITIM BOLUMU =====

  Widget _buildTrainingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: Icons.school, title: 'EGITIM ISTATISTIKLERI'),
      const SizedBox(height: 12),

      // Tamamlanma ve basari kartlari
      Row(children: [
        Expanded(child: _progressCard(
          'Tamamlanma',
          _completionRate,
          '$_completed / $_totalEnrollments',
          ScadaColors.green,
        )),
        const SizedBox(width: 8),
        Expanded(child: _progressCard(
          'Quiz Basari',
          _passRate,
          '$_quizzesPassed / $_quizzesTaken',
          ScadaColors.cyan,
        )),
      ]),

      const SizedBox(height: 12),

      // Ortalama puan
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star, color: ScadaColors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ortalama Quiz Puani', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
            const SizedBox(height: 4),
            Text(_averageScore.toStringAsFixed(1), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ScadaColors.amber)),
          ])),
          Text('/ 100', style: TextStyle(fontSize: 14, color: context.scada.textDim)),
        ]),
      ),
    ]);
  }

  // ===== GRAFIKLER =====

  Widget _buildChartsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: Icons.bar_chart, title: 'GRAFIKLER'),
      const SizedBox(height: 12),

      // Egitim ozet bar chart
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Egitim Ozeti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _buildSummaryBarChart()),
        ]),
      ),
    ]);
  }

  Widget _buildSummaryBarChart() {
    final data = [
      _BarItem('Kayit', _totalEnrollments.toDouble(), ScadaColors.cyan),
      _BarItem('Tamamla.', _completed.toDouble(), ScadaColors.green),
      _BarItem('Quiz', _quizzesTaken.toDouble(), ScadaColors.amber),
      _BarItem('Basarili', _quizzesPassed.toDouble(), ScadaColors.purple),
    ];
    final maxVal = data.fold<double>(1, (max, item) => item.value > max ? item.value : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}: ${rod.toY.toInt()}',
                TextStyle(fontSize: 11, color: context.scada.textPrimary, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(data[idx].label, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0 || value == 0) return const SizedBox.shrink();
                return Text('${value.toInt()}', style: TextStyle(fontSize: 9, color: context.scada.textDim));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.scada.border.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].value,
                color: data[i].color,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ===== YARDIMCI WIDGETLAR =====

  Widget _progressCard(String title, double percent, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(title, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
        const SizedBox(height: 10),
        SizedBox(
          width: 70, height: 70,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 70, height: 70,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 6,
                backgroundColor: context.scada.border,
                color: color,
              ),
            ),
            Text('%${percent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 10, color: context.scada.textDim)),
      ]),
    );
  }

  // ===== EXCEL EXPORT =====

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _exportExcel,
        icon: _exporting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.green))
            : const Icon(Icons.file_download, size: 18),
        label: Text(_exporting ? 'Hazirlaniyor...' : 'Excel Raporu Indir', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ScadaColors.green.withValues(alpha: 0.12),
          foregroundColor: ScadaColors.green,
          side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.get(
        '/training/export-excel',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as List<int>;
      final fileName = 'orientpro_egitim_raporu_${DateTime.now().toIso8601String().split('T').first}.xlsx';

      if (kIsWeb) {
        await file_saver.saveFileWeb(bytes, fileName);
      } else {
        String dirPath;
        if (Platform.isAndroid) {
          final dir = await getExternalStorageDirectory();
          dirPath = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
        } else {
          dirPath = (await getApplicationDocumentsDirectory()).path;
        }
        final file = File('$dirPath/$fileName');
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor indirildi: $fileName'), backgroundColor: ScadaColors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export hatasi'), backgroundColor: ScadaColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ===== DEPARTMAN KIRILIMI =====

  Widget _buildDepartmentSection() {
    final colors = [ScadaColors.cyan, ScadaColors.green, ScadaColors.amber, ScadaColors.orange, ScadaColors.purple, ScadaColors.red];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: Icons.business, title: 'DEPARTMAN KIRILIMI'),
      const SizedBox(height: 12),

      // Departman tamamlanma bar chart
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Departman Bazli Tamamlanma Orani', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          const SizedBox(height: 16),
          ..._departmentStats.asMap().entries.map((entry) {
            final i = entry.key;
            final dept = entry.value;
            final color = colors[i % colors.length];
            final avg = (dept['avg_completion'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(dept['name'] as String, style: TextStyle(fontSize: 12, color: context.scada.textPrimary))),
                  Text('${dept['member_count']} kisi', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
                  const SizedBox(width: 8),
                  Text('%${avg.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avg / 100,
                    minHeight: 8,
                    backgroundColor: context.scada.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ]),
            );
          }),
        ]),
      ),
    ]);
  }
}

class _BarItem {
  final String label;
  final double value;
  final Color color;
  _BarItem(this.label, this.value, this.color);
}
