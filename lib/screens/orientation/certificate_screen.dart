import 'dart:io' show File, Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/file_saver.dart' as file_saver;
import '../../providers/auth_provider.dart';

class CertificateScreen extends ConsumerWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final routeId = args?['routeId'] as String? ?? '';
    final routeName = args?['routeName'] as String? ?? 'Eğitim Rotasi';
    final userName = args?['userName'] as String? ?? ref.read(authProvider).user?.fullName ?? '';
    final completedAt = args?['completedAt'] as String? ?? DateTime.now().toIso8601String();

    final certId = 'CERT-${routeId.length > 8 ? routeId.substring(0, 8) : routeId}-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
    final completedDate = _formatDate(completedAt);

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
            child: const Icon(Icons.workspace_premium, color: ScadaColors.green, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Tamamlama Sertifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
        child: Column(
          children: [
            // Certificate card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.scada.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ScadaColors.green.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(color: ScadaColors.green.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 4),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 3,
                    decoration: BoxDecoration(color: ScadaColors.green, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ScadaColors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.verified, color: ScadaColors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TAMAMLAMA SERTIFIKASI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ScadaColors.green, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Container(width: 40, height: 1, color: context.scada.border),
                  const SizedBox(height: 16),
                  Text('Bu belge ile onaylanir ki', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'aşağıdaki eğitim rotasini başarıyla tamamlamistir',
                    style: TextStyle(fontSize: 11, color: context.scada.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: ScadaColors.cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      routeName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ScadaColors.cyan),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDetailItem(context, Icons.calendar_today, 'Tarih', completedDate),
                      const SizedBox(width: 32),
                      _buildDetailItem(context, Icons.tag, 'Sertifika No', certId),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80, height: 3,
                    decoration: BoxDecoration(color: ScadaColors.green, borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Download PDF button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadPdf(context, ref, routeId),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('PDF İndir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.green.withValues(alpha: 0.15),
                  foregroundColor: ScadaColors.green,
                  side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 14, color: context.scada.textDim),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref, String routeId) async {
    final userId = ref.read(authProvider).user?.id ?? '';

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sertifika indiriliyor...'), backgroundColor: ScadaColors.cyan, duration: Duration(seconds: 1)),
        );
      }

      final dio = ref.read(authDioProvider);
      final response = await dio.get(
        '/training/certificate/$routeId',
        queryParameters: {'user_id': userId},
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as List<int>;

      if (kIsWeb) {
        final webFileName = 'sertifika_${routeId.length > 8 ? routeId.substring(0, 8) : routeId}.pdf';
        await file_saver.saveFileWeb(bytes, webFileName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sertifika indirildi'), backgroundColor: ScadaColors.green),
          );
        }
        return;
      }

      // Mobile: dosyaya kaydet
      String dirPath;
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        dirPath = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
      } else {
        dirPath = (await getApplicationDocumentsDirectory()).path;
      }

      final fileName = 'sertifika_${routeId.length > 8 ? routeId.substring(0, 8) : routeId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$dirPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sertifika kaydedildi: $fileName'),
            backgroundColor: ScadaColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DioException catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF indirme hatasi'), backgroundColor: ScadaColors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya kaydetme hatasi: $e'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }
}
