import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';

class SectorTemplateScreen extends ConsumerStatefulWidget {
  const SectorTemplateScreen({super.key});

  @override
  ConsumerState<SectorTemplateScreen> createState() => _SectorTemplateScreenState();
}

class _SectorTemplateScreenState extends ConsumerState<SectorTemplateScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  bool _applying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.get('/sector-templates');
      setState(() {
        _templates = (response.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = ErrorHelper.getMessage(e); });
    }
  }

  Future<void> _applyTemplate(String sectorType, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        title: Text('Sablonu Uygula', style: TextStyle(color: context.scada.textPrimary)),
        content: Text(
          '$name sablonunu uygulamak istediginize emin misiniz?\n\nDepartmanlar ve ornek egitim rotalari olusturulacak.',
          style: TextStyle(color: context.scada.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: TextStyle(color: context.scada.textDim))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.green),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _applying = true);
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/sector-templates/apply', data: {'sector_type': sectorType});
      final result = response.data as Map<String, dynamic>;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${result['created_departments']} departman, ${result['created_routes']} rota olusturuldu'),
          backgroundColor: ScadaColors.green,
        ));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHelper.getMessage(e)),
          backgroundColor: ScadaColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  IconData _sectorIcon(String? icon) {
    switch (icon) {
      case 'hotel': return Icons.hotel;
      case 'factory': return Icons.precision_manufacturing;
      default: return Icons.business;
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
            child: const Icon(Icons.category, color: ScadaColors.green, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Sektor Sablonlari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.green))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _loadTemplates, child: const Text('Tekrar Dene')),
                ]))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    // Aciklama
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.scada.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.scada.border),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 18, color: context.scada.textDim),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Sektorunuze uygun sablonu secin. Departmanlar ve ornek egitim rotalari otomatik olusturulacak.',
                          style: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Sablonlar
                    ..._templates.map((t) => _buildTemplateCard(t)),
                  ],
                ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final sectorType = template['sector_type'] as String;
    final name = template['name'] as String;
    final description = template['description'] as String? ?? '';
    final icon = template['icon'] as String?;
    final deptCount = template['department_count'] as int? ?? 0;
    final routeCount = template['route_count'] as int? ?? 0;
    final color = sectorType == 'hotel' ? ScadaColors.amber : ScadaColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_sectorIcon(icon), color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _infoChip(Icons.business, '$deptCount Departman', color),
          const SizedBox(width: 12),
          _infoChip(Icons.route, '$routeCount Rota', color),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _applying ? null : () => _applyTemplate(sectorType, name),
              icon: _applying
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_done, size: 16),
              label: Text(_applying ? 'Uygulaniyor...' : 'Uygula', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
    ]);
  }
}
