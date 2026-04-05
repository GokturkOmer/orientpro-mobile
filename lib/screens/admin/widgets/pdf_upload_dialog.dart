import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/training.dart';
import '../../../providers/admin_provider.dart';

/// Shows a dialog for uploading PDF documents with AI classification.
/// Supports module selection, content enrichment, and file picking.
void showPdfUploadDialog({
  required BuildContext context,
  required WidgetRef ref,
  required TrainingRoute? route,
}) {
  String? pdfFileName;
  Uint8List? pdfFileBytes;
  String? pdfMimeType;
  bool isUploading = false;
  bool enrichExistingContents = true;
  final titleCtrl = TextEditingController();

  final modules = route?.modules ?? [];
  String? selectedModuleId = modules.isNotEmpty ? modules.first.id : null;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: context.scada.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.scada.borderBright),
            ),
            title: Text('PDF Doküman Yükle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field
                  TextField(
                    controller: titleCtrl,
                    enabled: !isUploading,
                    style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      labelStyle: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                      filled: true,
                      fillColor: context.scada.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.scada.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: ScadaColors.cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Module selector
                  if (modules.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedModuleId,
                      dropdownColor: context.scada.card,
                      style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Hedef Modul',
                        labelStyle: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                        filled: true,
                        fillColor: context.scada.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.scada.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: ScadaColors.cyan),
                        ),
                      ),
                      items: modules.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.title, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: isUploading ? null : (v) {
                        setDialogState(() => selectedModuleId = v);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // File picker
                  InkWell(
                    onTap: isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              setDialogState(() {
                                pdfFileName = file.name;
                                pdfFileBytes = file.bytes;
                                pdfMimeType = 'application/pdf';
                                if (titleCtrl.text.trim().isEmpty) {
                                  titleCtrl.text = file.name.replaceAll('.pdf', '').replaceAll('_', ' ');
                                }
                              });
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.scada.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: pdfFileName != null ? ScadaColors.green : context.scada.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            pdfFileName != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                            size: 36,
                            color: pdfFileName != null ? ScadaColors.red : context.scada.textDim,
                          ),
                          SizedBox(height: 8),
                          Text(
                            pdfFileName ?? 'PDF dosya seçmek için tikla',
                            style: TextStyle(
                              fontSize: 12,
                              color: pdfFileName != null ? context.scada.textPrimary : context.scada.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (pdfFileBytes != null) ...[
                            SizedBox(height: 4),
                            Text(
                              '${(pdfFileBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: TextStyle(fontSize: 10, color: context.scada.textDim),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Enrichment checkbox
                  if (selectedModuleId != null) ...[
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: ScadaColors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ScadaColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: ScadaColors.purple,
                        checkColor: Colors.white,
                        value: enrichExistingContents,
                        onChanged: isUploading
                            ? null
                            : (v) => setDialogState(() => enrichExistingContents = v ?? false),
                        title: Text(
                          'Mevcut içerikleri PDF ile zenginlestir',
                          style: TextStyle(color: context.scada.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'AI, modülün ders içeriklerini PDF bilgileriyle güncelleyecek',
                          style: TextStyle(color: context.scada.textDim, fontSize: 10),
                        ),
                        secondary: const Icon(Icons.auto_fix_high, color: ScadaColors.purple, size: 20),
                      ),
                    ),
                  ],

                  // AI info
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ScadaColors.cyan.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: ScadaColors.cyan),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI otomatik olarak departman, zorluk ve etiket sınıflandırmasi yapacak.',
                            style: TextStyle(fontSize: 10, color: ScadaColors.cyan),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress
                  if (isUploading) ...[
                    SizedBox(height: 14),
                    LinearProgressIndicator(
                      backgroundColor: context.scada.border,
                      valueColor: AlwaysStoppedAnimation<Color>(ScadaColors.cyan),
                    ),
                    SizedBox(height: 8),
                    Text(
                        enrichExistingContents && selectedModuleId != null
                            ? 'AI sınıflandırma + içerik zenginlestirme yapiliyor...'
                            : 'AI sınıflandırma yapiliyor...',
                        style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: Text('İptal',
                    style: TextStyle(
                        color: isUploading ? context.scada.textDim : context.scada.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (pdfFileBytes == null || pdfFileName == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Lütfen bir PDF dosya seçin'),
                                backgroundColor: ScadaColors.red),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isUploading = true);

                        final result = await ref.read(adminProvider.notifier).uploadPdfContent(
                          fileName: pdfFileName!,
                          fileBytes: pdfFileBytes!,
                          mimeType: pdfMimeType ?? 'application/pdf',
                          moduleId: selectedModuleId,
                          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                          enrichContents: enrichExistingContents && selectedModuleId != null,
                        );

                        if (result != null && ctx.mounted) {
                          Navigator.pop(ctx);
                          final enrichment = result['enrichment'] as List?;
                          final enrichMsg = enrichment != null && enrichment.isNotEmpty
                              ? ' | ${enrichment.length} içerik zenginlestirildi'
                              : '';
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('PDF yüklendi ve AI tarafından sınıflandırildi$enrichMsg'),
                              backgroundColor: ScadaColors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          // Reload route detail to see updated contents
                          if (route != null) {
                            ref.read(adminProvider.notifier).loadRouteDetail(route.id);
                          }
                        } else if (ctx.mounted) {
                          setDialogState(() => isUploading = false);
                          final error = ref.read(adminProvider).error;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(error ?? 'PDF yüklenemedi'),
                              backgroundColor: ScadaColors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                  foregroundColor: ScadaColors.cyan,
                ),
                child: const Text('Yükle & Sınıflandır', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      );
    },
  ).then((_) => titleCtrl.dispose());
}
