import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/training.dart';

class ModuleEditorScreen extends ConsumerStatefulWidget {
  const ModuleEditorScreen({super.key, required this.routeId, this.moduleId});
  final String routeId;
  final String? moduleId; // null = create, non-null = edit

  @override
  ConsumerState<ModuleEditorScreen> createState() => _ModuleEditorScreenState();
}

class _ModuleEditorScreenState extends ConsumerState<ModuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '15');
  String _moduleType = 'lesson';
  bool _isInitialized = false;

  bool get _isEditMode => widget.moduleId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      Future.microtask(() {
        ref.read(adminProvider.notifier).loadModuleDetail(widget.moduleId!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _populateFields(TrainingModule module) {
    if (_isInitialized) return;
    _titleController.text = module.title;
    _descriptionController.text = module.description ?? '';
    _durationController.text = module.estimatedMinutes.toString();
    _moduleType = module.moduleType;
    _isInitialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'route_id': widget.routeId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'module_type': _moduleType,
      'estimated_minutes': int.tryParse(_durationController.text) ?? 15,
    };

    final notifier = ref.read(adminProvider.notifier);
    final bool success;

    if (_isEditMode) {
      success = await notifier.updateModule(widget.moduleId!, data);
    } else {
      success = await notifier.createModule(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Modul basariyla guncellendi'
                : 'Modul basariyla olusturuldu',
          ),
          backgroundColor: ScadaColors.green,
        ),
      );
      if (_isEditMode) {
        notifier.loadModuleDetail(widget.moduleId!);
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showAddContentDialog() {
    String contentType = 'text';
    final contentTitleCtrl = TextEditingController();
    final contentBodyCtrl = TextEditingController();
    final contentUrlCtrl = TextEditingController();
    bool showMarkdownPreview = false;

    // PDF state
    String? pdfFileName;
    Uint8List? pdfFileBytes;
    String? pdfMimeType;
    bool isUploading = false;
    double uploadProgress = 0;
    bool enrichExistingContents = true; // AI ile mevcut icerikleri zenginlestir

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: const Text(
                'Icerik Ekle',
                style: TextStyle(color: ScadaColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: contentType,
                        dropdownColor: ScadaColors.card,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration('Icerik Tipi'),
                        items: const [
                          DropdownMenuItem(value: 'text', child: Text('Metin')),
                          DropdownMenuItem(
                              value: 'image', child: Text('Gorsel')),
                          DropdownMenuItem(
                              value: 'video', child: Text('Video')),
                          DropdownMenuItem(
                              value: 'pdf', child: Text('PDF Dokuman')),
                        ],
                        onChanged: isUploading
                            ? null
                            : (v) {
                                if (v != null) {
                                  setDialogState(() {
                                    contentType = v;
                                    pdfFileName = null;
                                    pdfFileBytes = null;
                                    pdfMimeType = null;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentTitleCtrl,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration('Baslik'),
                        enabled: !isUploading,
                      ),
                      const SizedBox(height: 12),

                      // TEXT fields with markdown toggle
                      if (contentType == 'text') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Markdown', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 28,
                              child: Switch(
                                value: showMarkdownPreview,
                                activeThumbColor: ScadaColors.cyan,
                                onChanged: (v) => setDialogState(() => showMarkdownPreview = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (showMarkdownPreview)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ScadaColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ScadaColors.border),
                            ),
                            child: SingleChildScrollView(
                              child: MarkdownBody(
                                data: contentBodyCtrl.text.isEmpty ? '*Onizleme burada gorunecek...*' : contentBodyCtrl.text,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13, height: 1.4),
                                  h1: const TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                  h2: const TextStyle(color: ScadaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                  strong: const TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.bold),
                                  em: const TextStyle(color: ScadaColors.textSecondary, fontStyle: FontStyle.italic),
                                  listBullet: const TextStyle(color: ScadaColors.cyan, fontSize: 13),
                                  code: TextStyle(color: ScadaColors.cyan, backgroundColor: ScadaColors.surface, fontSize: 12),
                                ),
                              ),
                            ),
                          )
                        else
                          TextField(
                            controller: contentBodyCtrl,
                            style: const TextStyle(color: ScadaColors.textPrimary),
                            decoration: _inputDecoration('Icerik Metni (Markdown destekli)'),
                            maxLines: 6,
                            onChanged: (_) {
                              // Trigger rebuild for preview if needed
                            },
                          ),
                      ],

                      // IMAGE / VIDEO fields
                      if (contentType == 'image' || contentType == 'video')
                        TextField(
                          controller: contentUrlCtrl,
                          style:
                              const TextStyle(color: ScadaColors.textPrimary),
                          decoration: _inputDecoration(
                            contentType == 'image'
                                ? 'Gorsel URL'
                                : 'Video URL',
                          ),
                        ),

                      // PDF fields
                      if (contentType == 'pdf') ...[
                        // File picker area
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
                                      if (contentTitleCtrl.text.trim().isEmpty) {
                                        contentTitleCtrl.text = file.name
                                            .replaceAll('.pdf', '')
                                            .replaceAll('_', ' ');
                                      }
                                    });
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: ScadaColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: pdfFileName != null
                                    ? ScadaColors.green
                                    : ScadaColors.border,
                                style: pdfFileName != null
                                    ? BorderStyle.solid
                                    : BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  pdfFileName != null
                                      ? Icons.picture_as_pdf
                                      : Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: pdfFileName != null
                                      ? ScadaColors.red
                                      : ScadaColors.textSecondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pdfFileName ?? 'PDF dosya secmek icin tikla',
                                  style: TextStyle(
                                    color: pdfFileName != null
                                        ? ScadaColors.textPrimary
                                        : ScadaColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (pdfFileBytes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(pdfFileBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: const TextStyle(
                                      color: ScadaColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Enrich existing contents checkbox
                        if (widget.moduleId != null) ...[
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
                              title: const Text(
                                'Mevcut icerikleri PDF ile zenginlestir',
                                style: TextStyle(color: ScadaColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text(
                                'AI, modulun mevcut ders iceriklerini PDF\'deki bilgilerle analiz edip guncelleyecek',
                                style: TextStyle(color: ScadaColors.textDim, fontSize: 10),
                              ),
                              secondary: const Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 20),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Info text
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ScadaColors.cyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 16, color: ScadaColors.cyan),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'PDF yuklendiginde AI otomatik olarak departman, zorluk ve etiket siniflandirmasi yapacak.',
                                  style: TextStyle(
                                    color: ScadaColors.cyan,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Upload progress
                        if (isUploading) ...[
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              LinearProgressIndicator(
                                value: uploadProgress > 0
                                    ? uploadProgress
                                    : null,
                                backgroundColor:
                                    ScadaColors.border,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  ScadaColors.cyan,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                uploadProgress > 0.99
                                    ? (enrichExistingContents
                                        ? 'AI siniflandirma + icerik zenginlestirme yapiliyor...'
                                        : 'AI siniflandirma yapiliyor...')
                                    : 'Yukleniyor... %${(uploadProgress * 100).toInt()}',
                                style: const TextStyle(
                                  color: ScadaColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isUploading ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Iptal',
                    style: TextStyle(
                      color: isUploading
                          ? ScadaColors.textSecondary.withValues(alpha: 0.3)
                          : ScadaColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan,
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (contentTitleCtrl.text.trim().isEmpty) return;

                          // PDF upload flow
                          if (contentType == 'pdf') {
                            if (pdfFileBytes == null || pdfFileName == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lutfen bir PDF dosya secin'),
                                  backgroundColor: ScadaColors.red,
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isUploading = true;
                              uploadProgress = 0;
                            });

                            // Listen to upload progress from provider
                            final notifier = ref.read(adminProvider.notifier);

                            final result = await notifier.uploadPdfContent(
                              fileName: pdfFileName!,
                              fileBytes: pdfFileBytes!,
                              mimeType: pdfMimeType ?? 'application/pdf',
                              moduleId: widget.moduleId,
                              title: contentTitleCtrl.text.trim(),
                              enrichContents: enrichExistingContents,
                            );

                            if (result != null && context.mounted) {
                              Navigator.pop(ctx);
                              // Show classification review dialog
                              _showClassificationReviewDialog(result);
                              // Refresh module contents
                              ref
                                  .read(adminProvider.notifier)
                                  .loadModuleDetail(widget.moduleId!);
                            } else if (context.mounted) {
                              setDialogState(() {
                                isUploading = false;
                                uploadProgress = 0;
                              });
                              final error =
                                  ref.read(adminProvider).error;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error ?? 'PDF yukleme basarisiz',
                                  ),
                                  backgroundColor: ScadaColors.red,
                                ),
                              );
                            }
                            return;
                          }

                          // Standard content creation
                          final contentData = {
                            'module_id': widget.moduleId,
                            'content_type': contentType,
                            'title': contentTitleCtrl.text.trim(),
                            if (contentType == 'text')
                              'body': contentBodyCtrl.text.trim(),
                            if (contentType == 'image' ||
                                contentType == 'video')
                              'media_url': contentUrlCtrl.text.trim(),
                          };

                          final ok = await ref
                              .read(adminProvider.notifier)
                              .createContent(contentData);
                          if (ok && context.mounted) {
                            Navigator.pop(ctx);
                            ref
                                .read(adminProvider.notifier)
                                .loadModuleDetail(widget.moduleId!);
                          }
                        },
                  child: Text(
                    contentType == 'pdf' ? 'Yukle & Siniflandir' : 'Kaydet',
                    style: const TextStyle(color: ScadaColors.bg),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditContentDialog(ModuleContent content) {
    String contentType = content.contentType;
    final contentTitleCtrl = TextEditingController(text: content.title);
    final contentBodyCtrl = TextEditingController(text: content.body ?? '');
    final contentUrlCtrl = TextEditingController(text: content.mediaUrl ?? '');
    bool showMarkdownPreview = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: const Text(
                'Icerigi Duzenle',
                style: TextStyle(color: ScadaColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: contentType,
                      dropdownColor: ScadaColors.card,
                      style: const TextStyle(color: ScadaColors.textPrimary),
                      decoration: _inputDecoration('Icerik Tipi'),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Metin')),
                        DropdownMenuItem(value: 'image', child: Text('Gorsel')),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                        DropdownMenuItem(
                            value: 'pdf', child: Text('PDF Dokuman')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => contentType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentTitleCtrl,
                      style: const TextStyle(color: ScadaColors.textPrimary),
                      decoration: _inputDecoration('Baslik'),
                    ),
                    const SizedBox(height: 12),
                    if (contentType == 'text') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Markdown', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 28,
                            child: Switch(
                              value: showMarkdownPreview,
                              activeThumbColor: ScadaColors.cyan,
                              onChanged: (v) => setDialogState(() => showMarkdownPreview = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (showMarkdownPreview)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ScadaColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ScadaColors.border),
                          ),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: contentBodyCtrl.text.isEmpty ? '*Onizleme burada gorunecek...*' : contentBodyCtrl.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13, height: 1.4),
                                h1: const TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                h2: const TextStyle(color: ScadaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                strong: const TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.bold),
                                em: const TextStyle(color: ScadaColors.textSecondary, fontStyle: FontStyle.italic),
                                listBullet: const TextStyle(color: ScadaColors.cyan, fontSize: 13),
                                code: TextStyle(color: ScadaColors.cyan, backgroundColor: ScadaColors.surface, fontSize: 12),
                              ),
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: contentBodyCtrl,
                          style: const TextStyle(color: ScadaColors.textPrimary),
                          decoration: _inputDecoration('Icerik Metni (Markdown destekli)'),
                          maxLines: 6,
                        ),
                    ],
                    if (contentType == 'image' || contentType == 'video')
                      TextField(
                        controller: contentUrlCtrl,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration(
                          contentType == 'image' ? 'Gorsel URL' : 'Video URL',
                        ),
                      ),
                    if (contentType == 'pdf')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ScadaColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: ScadaColors.textSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'PDF dosyasi degistirilemez. Sadece baslik duzenlenebilir.',
                                style: TextStyle(
                                  color: ScadaColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Iptal',
                    style: TextStyle(color: ScadaColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan,
                  ),
                  onPressed: () async {
                    if (contentTitleCtrl.text.trim().isEmpty) return;

                    final contentData = {
                      'module_id': widget.moduleId,
                      'content_type': contentType,
                      'title': contentTitleCtrl.text.trim(),
                      if (contentType == 'text')
                        'body': contentBodyCtrl.text.trim(),
                      if (contentType == 'image' || contentType == 'video')
                        'media_url': contentUrlCtrl.text.trim(),
                    };

                    final ok = await ref
                        .read(adminProvider.notifier)
                        .updateContent(content.id, contentData);
                    if (ok && context.mounted) {
                      Navigator.pop(ctx);
                      ref
                          .read(adminProvider.notifier)
                          .loadModuleDetail(widget.moduleId!);
                    }
                  },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(color: ScadaColors.bg),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClassificationReviewDialog(Map<String, dynamic> uploadResult) {
    final classification =
        uploadResult['classification'] as Map<String, dynamic>? ?? {};
    final ragStatus = uploadResult['rag_status'] as String? ?? '';
    final contentId = uploadResult['content_id'] as String?;
    final fileName = uploadResult['file_name'] as String? ?? '';

    String department = classification['department'] ?? 'genel';
    String difficulty = classification['difficulty'] ?? 'beginner';
    List<String> tags = (classification['tags'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    String summary = classification['summary'] ?? '';

    final summaryCtrl = TextEditingController(text: summary);
    final tagCtrl = TextEditingController();

    final departmentLabels = {
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'yonetim': 'Yonetim',
      'on_buro': 'On Buro',
      'spa': 'Spa & Wellness',
      'fb': 'Yiyecek Icecek',
      'guvenlik': 'Guvenlik',
      'genel': 'Genel',
    };

    final difficultyLabels = {
      'beginner': 'Baslangic',
      'intermediate': 'Orta',
      'advanced': 'Ileri',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: ScadaColors.cyan, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Siniflandirma Sonucu',
                      style: TextStyle(
                          color: ScadaColors.textPrimary, fontSize: 18),
                    ),
                  ),
                  // RAG status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ragStatus == 'indexed'
                          ? ScadaColors.green.withValues(alpha: 0.15)
                          : ScadaColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ragStatus == 'indexed'
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 14,
                          color: ragStatus == 'indexed'
                              ? ScadaColors.green
                              : ScadaColors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ragStatus == 'indexed' ? 'Indekslendi' : 'Bekliyor',
                          style: TextStyle(
                            fontSize: 11,
                            color: ragStatus == 'indexed'
                                ? ScadaColors.green
                                : ScadaColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File info
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ScadaColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: ScadaColors.red, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  color: ScadaColors.textPrimary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Department
                      DropdownButtonFormField<String>(
                        initialValue: department,
                        dropdownColor: ScadaColors.card,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration('Departman'),
                        items: departmentLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => department = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Difficulty
                      DropdownButtonFormField<String>(
                        initialValue: difficulty,
                        dropdownColor: ScadaColors.card,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration('Zorluk Seviyesi'),
                        items: difficultyLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => difficulty = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      const Text(
                        'Etiketler',
                        style: TextStyle(
                            color: ScadaColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...tags.map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(
                                    color: ScadaColors.textPrimary,
                                    fontSize: 12),
                              ),
                              backgroundColor:
                                  ScadaColors.cyan.withValues(alpha: 0.15),
                              deleteIconColor: ScadaColors.red,
                              onDeleted: () {
                                setDialogState(() => tags.remove(tag));
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          // Add tag input
                          SizedBox(
                            width: 120,
                            height: 32,
                            child: TextField(
                              controller: tagCtrl,
                              style: const TextStyle(
                                  color: ScadaColors.textPrimary, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: '+ Etiket ekle',
                                hintStyle: const TextStyle(
                                    color: ScadaColors.textSecondary,
                                    fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: ScadaColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: ScadaColors.cyan),
                                ),
                                filled: true,
                                fillColor: ScadaColors.surface,
                              ),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) {
                                  setDialogState(() {
                                    tags.add(v.trim());
                                    tagCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Summary
                      TextField(
                        controller: summaryCtrl,
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: _inputDecoration('AI Ozet'),
                        maxLines: 3,
                      ),

                      // Enrichment results
                      if (uploadResult['enrichment'] != null &&
                          (uploadResult['enrichment'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ScadaColors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ScadaColors.purple.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.auto_fix_high, color: ScadaColors.purple, size: 16),
                                SizedBox(width: 6),
                                Text('Zenginlestirilen Icerikler',
                                    style: TextStyle(color: ScadaColors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 8),
                              ...(uploadResult['enrichment'] as List).map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(children: [
                                      const Icon(Icons.check_circle, color: ScadaColors.green, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${e['content_title']} - ${e['changes_summary']}',
                                          style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11),
                                        ),
                                      ),
                                    ]),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Atla',
                    style: TextStyle(color: ScadaColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.green,
                  ),
                  onPressed: () async {
                    if (contentId == null) {
                      Navigator.pop(ctx);
                      return;
                    }

                    final classificationData = {
                      'department': department,
                      'difficulty': difficulty,
                      'tags': tags,
                      'summary': summaryCtrl.text.trim(),
                    };

                    final ok = await ref
                        .read(adminProvider.notifier)
                        .updateClassification(contentId, classificationData);

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Siniflandirma kaydedildi'
                                : 'Siniflandirma kaydiedilemedi',
                          ),
                          backgroundColor:
                              ok ? ScadaColors.green : ScadaColors.red,
                        ),
                      );
                      ref
                          .read(adminProvider.notifier)
                          .loadModuleDetail(widget.moduleId!);
                    }
                  },
                  child: const Text(
                    'Onayla & Kaydet',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteContent(ModuleContent content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.card,
        title: const Text(
          'Icerigi Sil',
          style: TextStyle(color: ScadaColors.textPrimary),
        ),
        content: Text(
          '"${content.title}" icerigini silmek istediginize emin misiniz?',
          style: const TextStyle(color: ScadaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Iptal',
              style: TextStyle(color: ScadaColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok =
          await ref.read(adminProvider.notifier).deleteContent(content.id);
      if (ok && mounted) {
        ref.read(adminProvider.notifier).loadModuleDetail(widget.moduleId!);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ScadaColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ScadaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ScadaColors.cyan),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ScadaColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ScadaColors.red),
      ),
      filled: true,
      fillColor: ScadaColors.surface,
    );
  }

  Color _contentTypeBadgeColor(String type) {
    switch (type) {
      case 'text':
        return ScadaColors.cyan;
      case 'image':
        return ScadaColors.green;
      case 'video':
        return ScadaColors.purple;
      case 'pdf':
        return ScadaColors.red;
      default:
        return ScadaColors.textSecondary;
    }
  }

  String _contentTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Metin';
      case 'image':
        return 'Gorsel';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final module = admin.selectedModule;

    if (_isEditMode && module != null && !_isInitialized) {
      _populateFields(module);
    }

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Text(
          _isEditMode ? 'Modulu Duzenle' : 'Yeni Modul',
          style: const TextStyle(color: ScadaColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: ScadaColors.textPrimary),
      ),
      body: admin.isLoading && _isEditMode && module == null
          ? const Center(
              child: CircularProgressIndicator(color: ScadaColors.cyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== Section 1: Module Form =====
                  _buildModuleForm(),

                  // ===== Section 2: Content Sections (edit mode only) =====
                  if (_isEditMode && module != null) ...[
                    const SizedBox(height: 24),
                    _buildContentSection(module),
                  ],

                  // ===== Section 3: Quiz (edit mode only) =====
                  if (_isEditMode && module != null) ...[
                    const SizedBox(height: 24),
                    _buildQuizSection(module),
                  ],

                  // ===== Save Button =====
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.cyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: admin.isSaving ? null : _save,
                      child: admin.isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: ScadaColors.bg,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditMode ? 'Guncelle' : 'Olustur',
                              style: const TextStyle(
                                color: ScadaColors.bg,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error display
                  if (admin.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ScadaColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ScadaColors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        admin.error!,
                        style: const TextStyle(color: ScadaColors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildModuleForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modul Bilgileri',
              style: TextStyle(
                color: ScadaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: ScadaColors.textPrimary),
              decoration: _inputDecoration('Baslik *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Baslik gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: ScadaColors.textPrimary),
              decoration: _inputDecoration('Aciklama'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _moduleType,
              dropdownColor: ScadaColors.card,
              style: const TextStyle(color: ScadaColors.textPrimary),
              decoration: _inputDecoration('Modul Tipi'),
              items: const [
                DropdownMenuItem(value: 'lesson', child: Text('Ders')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'practice', child: Text('Uygulama')),
                DropdownMenuItem(
                  value: 'assessment',
                  child: Text('Degerlendirme'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _moduleType = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              style: const TextStyle(color: ScadaColors.textPrimary),
              decoration: _inputDecoration('Tahmini Sure (dakika)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(TrainingModule module) {
    final contents = module.contents ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Icerik Bolumleri',
                style: TextStyle(
                  color: ScadaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: ScadaColors.cyan),
                onPressed: _showAddContentDialog,
                tooltip: 'Icerik Ekle',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'Henuz icerik eklenmedi',
                style: TextStyle(color: ScadaColors.textSecondary),
              ),
            )
          else
            ...contents.asMap().entries.map((entry) => _buildContentCard(entry.value, entry.key, contents.length)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScadaColors.cyan,
                    side: const BorderSide(color: ScadaColors.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Icerik Ekle'),
                  onPressed: _showAddContentDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScadaColors.purple,
                    side: const BorderSide(color: ScadaColors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('PDF\'den Olustur'),
                  onPressed: _showGenerateFromPdfDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateFromPdfDialog() {
    String? pdfFileName;
    Uint8List? pdfFileBytes;
    bool isGenerating = false;
    double uploadProgress = 0;
    bool clearExisting = true;
    Map<String, dynamic>? generationResult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Result view — after generation
            if (generationResult != null) {
              final contents = (generationResult!['contents'] as List?) ?? [];
              final classification = generationResult!['classification'] as Map<String, dynamic>? ?? {};
              return AlertDialog(
                backgroundColor: ScadaColors.card,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ScadaColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle, color: ScadaColors.green, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Icerik Olusturuldu!',
                              style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${contents.length} bolum basariyla olusturuldu',
                              style: const TextStyle(color: ScadaColors.textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: Column(
                    children: [
                      // Classification summary
                      if (classification.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: ScadaColors.cyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: ScadaColors.cyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Departman: ${classification['department'] ?? '-'}  |  Zorluk: ${classification['difficulty'] ?? '-'}',
                                  style: const TextStyle(color: ScadaColors.cyan, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Generated contents list
                      Expanded(
                        child: ListView.builder(
                          itemCount: contents.length,
                          itemBuilder: (context, index) {
                            final item = contents[index] as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ScadaColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ScadaColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: ScadaColors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('${index + 1}',
                                            style: const TextStyle(color: ScadaColors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['title'] ?? '',
                                          style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((item['body'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      (item['body'] as String).length > 150
                                          ? '${(item['body'] as String).substring(0, 150)}...'
                                          : item['body'] as String,
                                      style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11, height: 1.4),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.green),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Refresh module contents
                      ref.read(adminProvider.notifier).loadModuleDetail(widget.moduleId!);
                    },
                    child: const Text('Tamam', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }

            // Upload view
            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PDF\'den Icerik Olustur',
                      style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ScadaColors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ScadaColors.purple.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: ScadaColors.purple),
                                SizedBox(width: 8),
                                Text('AI Icerik Olusturma',
                                    style: TextStyle(color: ScadaColors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'PDF dosyasini yukleyin, AI dokumani analiz edecek ve modulunuz icin yapilandirilmis ders icerikleri olusturacak.\n\n'
                              '• PDF metin icerigi cikarilir\n'
                              '• AI icerigi analiz eder ve bolumlendirir\n'
                              '• Her bolum icin baslik ve Markdown icerik uretilir\n'
                              '• RAG indeksleme yapilir (arama icin)',
                              style: TextStyle(color: ScadaColors.textSecondary, fontSize: 11, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // File picker
                      InkWell(
                        onTap: isGenerating
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
                                  });
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ScadaColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pdfFileName != null ? ScadaColors.purple : ScadaColors.border,
                              width: pdfFileName != null ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                pdfFileName != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                                size: 40,
                                color: pdfFileName != null ? ScadaColors.red : ScadaColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pdfFileName ?? 'PDF dosya secmek icin tikla',
                                style: TextStyle(
                                  color: pdfFileName != null ? ScadaColors.textPrimary : ScadaColors.textSecondary,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (pdfFileBytes != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${(pdfFileBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Clear existing option
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScadaColors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ScadaColors.amber.withValues(alpha: 0.3)),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          activeColor: ScadaColors.amber,
                          checkColor: Colors.white,
                          value: clearExisting,
                          onChanged: isGenerating
                              ? null
                              : (v) => setDialogState(() => clearExisting = v ?? false),
                          title: const Text(
                            'Mevcut metin iceriklerini temizle',
                            style: TextStyle(color: ScadaColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Modulun mevcut metin iceriklerini silerek yenileriyle degistirir',
                            style: TextStyle(color: ScadaColors.textDim, fontSize: 10),
                          ),
                          secondary: const Icon(Icons.cleaning_services, color: ScadaColors.amber, size: 20),
                        ),
                      ),

                      // Progress indicator
                      if (isGenerating) ...[
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: uploadProgress > 0.99 ? null : uploadProgress,
                              backgroundColor: ScadaColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(ScadaColors.purple),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              uploadProgress > 0.99
                                  ? 'AI icerik olusuruyor... Bu islem 1-2 dakika surebilir'
                                  : 'Yukleniyor... %${(uploadProgress * 100).toInt()}',
                              style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12),
                            ),
                            if (uploadProgress > 0.99) ...[
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: ScadaColors.purple, strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('PDF analiz + RAG indeksleme + Icerik olusturma...',
                                      style: TextStyle(color: ScadaColors.purple, fontSize: 11)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isGenerating ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Iptal',
                    style: TextStyle(
                      color: isGenerating ? ScadaColors.textSecondary.withValues(alpha: 0.3) : ScadaColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.purple),
                  onPressed: (isGenerating || pdfFileBytes == null)
                      ? null
                      : () async {
                          setDialogState(() {
                            isGenerating = true;
                            uploadProgress = 0;
                          });

                          final notifier = ref.read(adminProvider.notifier);

                          // Listen to progress
                          ref.listenManual(adminProvider.select((s) => s.uploadProgress), (prev, next) {
                            if (next != null && ctx.mounted) {
                              setDialogState(() => uploadProgress = next);
                            }
                          });

                          final result = await notifier.generateModuleFromPdf(
                            fileName: pdfFileName!,
                            fileBytes: pdfFileBytes!,
                            moduleId: widget.moduleId!,
                            clearExisting: clearExisting,
                          );

                          if (result != null && ctx.mounted) {
                            setDialogState(() {
                              isGenerating = false;
                              generationResult = result;
                            });
                          } else if (ctx.mounted) {
                            setDialogState(() {
                              isGenerating = false;
                              uploadProgress = 0;
                            });
                            final error = ref.read(adminProvider).error;
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error ?? 'Icerik olusturma basarisiz'),
                                  backgroundColor: ScadaColors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    isGenerating ? 'Olusturuluyor...' : 'Olustur',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _swapContentOrder(List<ModuleContent> contents, int oldIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= contents.length) return;
    final orders = <Map<String, String>>[];
    // Swap sort_order values
    orders.add({'id': contents[oldIndex].id, 'sort_order': '$newIndex'});
    orders.add({'id': contents[newIndex].id, 'sort_order': '$oldIndex'});
    final ok = await ref.read(adminProvider.notifier).reorderContents(orders);
    if (ok && mounted) {
      ref.read(adminProvider.notifier).loadModuleDetail(widget.moduleId!);
    }
  }

  Widget _buildContentCard(ModuleContent content, int index, int total) {
    final badgeColor = _contentTypeBadgeColor(content.contentType);
    final typeLabel = _contentTypeLabel(content.contentType);
    final bodyPreview = content.body != null && content.body!.length > 100
        ? '${content.body!.substring(0, 100)}...'
        : content.body ?? '';

    return InkWell(
      onTap: content.isPdf ? () => _showPdfDetailDialog(content) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reorder buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_upward, size: 14,
                        color: index > 0 ? ScadaColors.textSecondary : ScadaColors.textDim.withValues(alpha: 0.3)),
                      onPressed: index > 0
                        ? () => _swapContentOrder(
                            ref.read(adminProvider).selectedModule?.contents ?? [], index, index - 1)
                        : null,
                      tooltip: 'Yukari tasi',
                    ),
                  ),
                  SizedBox(
                    width: 24, height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_downward, size: 14,
                        color: index < total - 1 ? ScadaColors.textSecondary : ScadaColors.textDim.withValues(alpha: 0.3)),
                      onPressed: index < total - 1
                        ? () => _swapContentOrder(
                            ref.read(adminProvider).selectedModule?.contents ?? [], index, index + 1)
                        : null,
                      tooltip: 'Asagi tasi',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // RAG status for PDF
              if (content.isPdf && content.ragStatus != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: content.ragStatus == 'indexed'
                        ? ScadaColors.green
                        : ScadaColors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  content.ragStatus == 'indexed' ? 'RAG' : 'Bekleniyor',
                  style: TextStyle(
                    color: content.ragStatus == 'indexed'
                        ? ScadaColors.green
                        : ScadaColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content.title,
                  style: const TextStyle(
                    color: ScadaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: ScadaColors.amber,
                ),
                onPressed: () => _showEditContentDialog(content),
                tooltip: 'Duzenle',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 18,
                  color: ScadaColors.red,
                ),
                onPressed: () => _deleteContent(content),
                tooltip: 'Sil',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),

          // PDF-specific info
          if (content.isPdf) ...[
            // File info row
            if (content.fileName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf,
                      size: 14, color: ScadaColors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      content.fileName!,
                      style: const TextStyle(
                        color: ScadaColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (content.fileSize > 0)
                    Text(
                      '${(content.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        color: ScadaColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
            // Summary
            if (content.summary != null && content.summary!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                content.summary!,
                style: const TextStyle(
                  color: ScadaColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Tags
            if (content.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: content.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScadaColors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ScadaColors.cyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: ScadaColors.cyan,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],

          // Non-PDF body preview (markdown rendered)
          if (!content.isPdf && bodyPreview.isNotEmpty) ...[
            const SizedBox(height: 6),
            MarkdownBody(
              data: bodyPreview,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13, height: 1.4),
                h1: const TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: ScadaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                strong: const TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.bold),
                em: const TextStyle(color: ScadaColors.textSecondary, fontStyle: FontStyle.italic),
                listBullet: const TextStyle(color: ScadaColors.cyan, fontSize: 13),
                code: TextStyle(color: ScadaColors.cyan, backgroundColor: ScadaColors.surface, fontSize: 12),
                codeblockDecoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ScadaColors.border),
                ),
              ),
            ),
          ],
          if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.link,
                  size: 14,
                  color: ScadaColors.cyan,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    content.mediaUrl!,
                    style: const TextStyle(
                      color: ScadaColors.cyan,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  void _showPdfDetailDialog(ModuleContent content) {
    final classification = content.classification ?? {};
    final dept = classification['department'] ?? 'genel';
    final difficulty = classification['difficulty'] ?? 'beginner';
    final tags = content.tags;
    final summary = content.summary ?? '';
    final ragStatus = content.ragStatus ?? '';
    final ragDocId = content.ragDocId ?? '';
    final chunkCount = content.metadataJson?['chunk_count'] ?? 0;

    final departmentLabels = {
      'teknik': 'Teknik Servis', 'hk': 'Kat Hizmetleri', 'yonetim': 'Yonetim',
      'on_buro': 'On Buro', 'spa': 'Spa & Wellness', 'fb': 'Yiyecek Icecek',
      'guvenlik': 'Guvenlik', 'genel': 'Genel',
    };
    final difficultyLabels = {
      'beginner': 'Baslangic', 'intermediate': 'Orta', 'advanced': 'Ileri',
    };

    // RAG icerik state
    int selectedTab = 0; // 0=siniflandirma, 1=tam metin, 2=chunk'lar
    String? fullText;
    List<dynamic>? chunks;
    bool isLoadingContent = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> loadRagContent() async {
              if (fullText != null || ragDocId.isEmpty) return;
              setDialogState(() => isLoadingContent = true);
              final data = await ref.read(adminProvider.notifier).fetchDocumentChunks(ragDocId);
              if (data != null && ctx.mounted) {
                setDialogState(() {
                  fullText = data['full_text'] ?? '';
                  chunks = data['chunks'] as List? ?? [];
                  isLoadingContent = false;
                });
              } else if (ctx.mounted) {
                setDialogState(() => isLoadingContent = false);
              }
            }

            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ScadaColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: ScadaColors.red, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(content.title,
                        style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    Row(children: [
                      if (content.fileName != null)
                        Text(content.fileName!, style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
                      if (content.fileSize > 0) ...[
                        const SizedBox(width: 8),
                        Text('${(content.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                            style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
                      ],
                    ]),
                  ]),
                ),
                // RAG status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ragStatus == 'indexed'
                        ? ScadaColors.green.withValues(alpha: 0.12)
                        : ScadaColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                    )),
                    const SizedBox(width: 4),
                    Text(ragStatus == 'indexed' ? '$chunkCount chunk' : 'Bekliyor',
                        style: TextStyle(
                          color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                          fontSize: 10, fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              ]),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(children: [
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: ScadaColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      _tabButton('Siniflandirma', Icons.auto_awesome, 0, selectedTab, (i) {
                        setDialogState(() => selectedTab = i);
                      }),
                      _tabButton('Tam Metin', Icons.article, 1, selectedTab, (i) {
                        setDialogState(() => selectedTab = i);
                        loadRagContent();
                      }),
                      _tabButton('Chunk\'lar', Icons.view_list, 2, selectedTab, (i) {
                        setDialogState(() => selectedTab = i);
                        loadRagContent();
                      }),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Tab content
                  Expanded(
                    child: selectedTab == 0
                        ? _buildClassificationTab(dept, difficulty, tags, summary, departmentLabels, difficultyLabels, ragStatus, chunkCount, content)
                        : selectedTab == 1
                            ? _buildFullTextTab(fullText, isLoadingContent)
                            : _buildChunksTab(chunks, isLoadingContent),
                  ),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat', style: TextStyle(color: ScadaColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showClassificationReviewDialog({
                      'classification': classification,
                      'rag_status': ragStatus,
                      'content_id': content.id,
                      'file_name': content.fileName ?? '',
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Siniflandirmayi Duzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tabButton(String label, IconData icon, int index, int selected, Function(int) onTap) {
    final isSelected = index == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ScadaColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: ScadaColors.cyan.withValues(alpha: 0.4)) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: isSelected ? ScadaColors.cyan : ScadaColors.textDim),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: isSelected ? ScadaColors.cyan : ScadaColors.textDim,
              fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildClassificationTab(
    String dept, String difficulty, List<String> tags, String summary,
    Map<String, String> departmentLabels, Map<String, String> difficultyLabels,
    String ragStatus, dynamic chunkCount, ModuleContent content,
  ) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // RAG Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ragStatus == 'indexed'
                ? ScadaColors.green.withValues(alpha: 0.08)
                : ScadaColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(ragStatus == 'indexed' ? Icons.check_circle : Icons.hourglass_empty,
                color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ragStatus == 'indexed' ? 'RAG Indeksleme Tamamlandi' : 'RAG Indeksleme Bekliyor',
                  style: TextStyle(color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber, fontSize: 13, fontWeight: FontWeight.w600)),
              if (chunkCount > 0)
                Text('$chunkCount parca olarak indekslendi — semantik arama icin hazir',
                    style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Department & Difficulty
        Row(children: [
          Expanded(child: _detailItem('Departman', departmentLabels[dept] ?? dept, ScadaColors.cyan)),
          const SizedBox(width: 12),
          Expanded(child: _detailItem('Zorluk', difficultyLabels[difficulty] ?? difficulty, ScadaColors.amber)),
        ]),
        const SizedBox(height: 12),

        // Tags
        if (tags.isNotEmpty) ...[
          const Text('Etiketler', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ScadaColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScadaColors.purple.withValues(alpha: 0.3)),
            ),
            child: Text(tag, style: const TextStyle(color: ScadaColors.purple, fontSize: 12)),
          )).toList()),
          const SizedBox(height: 12),
        ],

        // Summary
        if (summary.isNotEmpty) ...[
          const Text('AI Ozet', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ScadaColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Text(summary, style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12, height: 1.5)),
          ),
        ],

        // Media URL
        if (content.mediaUrl != null) ...[
          const SizedBox(height: 12),
          const Text('Dosya Konumu', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: ScadaColors.surface, borderRadius: BorderRadius.circular(6)),
            child: Text(content.mediaUrl!, style: const TextStyle(color: ScadaColors.cyan, fontSize: 10)),
          ),
        ],
      ]),
    );
  }

  Widget _buildFullTextTab(String? fullText, bool isLoading) {
    if (isLoading) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: ScadaColors.cyan),
        SizedBox(height: 12),
        Text('RAG icerigi yukleniyor...', style: TextStyle(color: ScadaColors.textDim, fontSize: 12)),
      ]));
    }
    if (fullText == null || fullText.isEmpty) {
      return const Center(child: Text('Icerik bulunamadi', style: TextStyle(color: ScadaColors.textDim)));
    }
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ScadaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          fullText,
          style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildChunksTab(List<dynamic>? chunks, bool isLoading) {
    if (isLoading) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: ScadaColors.cyan),
        SizedBox(height: 12),
        Text('Chunk\'lar yukleniyor...', style: TextStyle(color: ScadaColors.textDim, fontSize: 12)),
      ]));
    }
    if (chunks == null || chunks.isEmpty) {
      return const Center(child: Text('Chunk bulunamadi', style: TextStyle(color: ScadaColors.textDim)));
    }
    return ListView.builder(
      itemCount: chunks.length,
      itemBuilder: (context, index) {
        final chunk = chunks[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScadaColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ScadaColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Chunk ${chunk['chunk_index'] ?? index}',
                    style: const TextStyle(color: ScadaColors.cyan, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('${((chunk['content'] ?? '').toString().split(' ').length)} kelime',
                  style: const TextStyle(color: ScadaColors.textDim, fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            SelectableText(
              chunk['content'] ?? '',
              style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11, height: 1.5),
            ),
          ]),
        );
      },
    );
  }

  Widget _detailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: ScadaColors.textDim, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildQuizSection(TrainingModule module) {
    final quizzes = module.quizzes ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz',
            style: TextStyle(
              color: ScadaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (quizzes.isEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.amber,
                  side: const BorderSide(color: ScadaColors.amber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.quiz, size: 18),
                label: const Text('Quiz Ekle'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/admin/quiz-builder',
                    arguments: {'moduleId': widget.moduleId},
                  );
                },
              ),
            )
          else
            ...quizzes.map((quiz) => _buildQuizCard(quiz)),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.quiz,
              color: ScadaColors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    color: ScadaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gecme puani: ${quiz.passingScore}  |  Maks. deneme: ${quiz.maxAttempts}',
                  style: const TextStyle(
                    color: ScadaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/admin/quiz-builder',
                arguments: {
                  'moduleId': widget.moduleId,
                  'quizId': quiz.id,
                },
              );
            },
            child: const Text(
              'Duzenle',
              style: TextStyle(color: ScadaColors.bg, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
