import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class DocumentPoolScreen extends ConsumerStatefulWidget {
  const DocumentPoolScreen({super.key});

  @override
  ConsumerState<DocumentPoolScreen> createState() => _DocumentPoolScreenState();
}

class _DocumentPoolScreenState extends ConsumerState<DocumentPoolScreen> {
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedDepartment;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await ref.read(adminProvider.notifier).loadTrainingDocuments(
      department: _selectedDepartment,
    );
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await ref.read(adminProvider.notifier).searchTrainingContent(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _confirmDeleteDocument(Map<String, dynamic> doc) {
    final docTitle = doc['title'] ?? doc['file_name'] ?? 'Bilinmeyen';
    final docId = doc['id']?.toString();
    if (docId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        title: Text('Dokümani Sil', style: TextStyle(color: context.scada.textPrimary, fontSize: 16)),
        content: Text(
          '"$docTitle" dokümanini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          style: TextStyle(color: context.scada.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteContent(docId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doküman silindi'), backgroundColor: ScadaColors.green),
                );
                _loadDocuments();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.read(adminProvider).error ?? 'Doküman silinemedi'),
                    backgroundColor: ScadaColors.red,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: ScadaColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDialog() async {
    String? pdfFileName;
    Uint8List? pdfFileBytes;
    bool isUploading = false;
    double uploadProgress = 0;
    final titleCtrl = TextEditingController();
    String selectedDepartment = 'genel';
    Map<String, dynamic>? uploadResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: context.scada.card,
              title: Row(children: [
                const Icon(Icons.upload_file, color: ScadaColors.red, size: 22),
                SizedBox(width: 8),
                Text('PDF Yükle', style: TextStyle(color: context.scada.textPrimary, fontSize: 16)),
              ]),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title field
                      TextField(
                        controller: titleCtrl,
                        style: TextStyle(color: context.scada.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Başlık (opsiyonel)',
                          labelStyle: TextStyle(color: context.scada.textSecondary, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: context.scada.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: ScadaColors.cyan),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: context.scada.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        enabled: !isUploading,
                      ),
                      const SizedBox(height: 12),

                      // Departman secici
                      DropdownButtonFormField<String>(
                        initialValue: selectedDepartment,
                        decoration: InputDecoration(
                          labelText: 'Departman',
                          labelStyle: TextStyle(color: context.scada.textSecondary, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: context.scada.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: ScadaColors.cyan),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: context.scada.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        dropdownColor: context.scada.card,
                        style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'genel', child: Text('Genel')),
                          DropdownMenuItem(value: 'teknik', child: Text('Teknik Servis')),
                          DropdownMenuItem(value: 'hk', child: Text('Kat Hizmetleri')),
                          DropdownMenuItem(value: 'fb', child: Text('F&B')),
                          DropdownMenuItem(value: 'on_buro', child: Text('Ön Büro')),
                          DropdownMenuItem(value: 'güvenlik', child: Text('Güvenlik')),
                          DropdownMenuItem(value: 'kurumsal', child: Text('Kurumsal (Tum çalışanlar)')),
                        ],
                        onChanged: isUploading ? null : (v) => setDialogState(() => selectedDepartment = v ?? 'genel'),
                      ),
                      const SizedBox(height: 12),

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
                                  });
                                }
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.scada.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pdfFileName != null ? ScadaColors.green : context.scada.border,
                              width: pdfFileName != null ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(
                              pdfFileName != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                              color: pdfFileName != null ? ScadaColors.red : context.scada.textDim,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              pdfFileName ?? 'PDF dosyasi seçmek için tıklayın',
                              style: TextStyle(
                                color: pdfFileName != null ? context.scada.textPrimary : context.scada.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (pdfFileBytes != null)
                              Text(
                                '${(pdfFileBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(color: context.scada.textDim, fontSize: 10),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // AI info
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ScadaColors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ScadaColors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PDF yüklendiginde AI otomatik olarak:\n'
                              '- Departman ve zorluk sınıflandırmasi yapar\n'
                              '- Anahtar etiketler oluşturur\n'
                              '- Semantik arama için indeksler',
                              style: TextStyle(color: context.scada.textSecondary, fontSize: 10, height: 1.4),
                            ),
                          ),
                        ]),
                      ),

                      // Upload progress
                      if (isUploading) ...[
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: uploadProgress < 1.0 ? uploadProgress : null,
                          backgroundColor: context.scada.surface,
                          color: uploadProgress >= 1.0 ? ScadaColors.purple : ScadaColors.cyan,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uploadProgress >= 1.0 ? 'AI sınıflandırma yapiliyor...' : 'Yükleniyor... %${(uploadProgress * 100).toInt()}',
                          style: TextStyle(
                            color: uploadProgress >= 1.0 ? ScadaColors.purple : ScadaColors.cyan,
                            fontSize: 11,
                          ),
                        ),
                      ],

                      // Result
                      if (uploadResult != null) ...[
                        const SizedBox(height: 16),
                        _buildUploadResultCard(uploadResult!),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: Text(uploadResult != null ? 'Kapat' : 'İptal', style: TextStyle(color: context.scada.textSecondary)),
                ),
                if (uploadResult == null)
                  ElevatedButton.icon(
                    onPressed: isUploading || pdfFileBytes == null
                        ? null
                        : () async {
                            setDialogState(() {
                              isUploading = true;
                              uploadProgress = 0;
                            });

                            final notifier = ref.read(adminProvider.notifier);

                            // Listen to progress
                            ref.listenManual(adminProvider.select((s) => s.uploadProgress), (prev, next) {
                              if (next != null && mounted) {
                                setDialogState(() => uploadProgress = next);
                              }
                            });

                            final result = await notifier.uploadPdfContent(
                              fileName: pdfFileName!,
                              fileBytes: pdfFileBytes!,
                              mimeType: 'application/pdf',
                              title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : null,
                              department: selectedDepartment,
                            );

                            if (mounted) {
                              if (result != null) {
                                setDialogState(() {
                                  isUploading = false;
                                  uploadResult = result;
                                });
                                _loadDocuments(); // Refresh list
                              } else {
                                setDialogState(() => isUploading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ref.read(adminProvider).error ?? 'PDF yüklenemedi'),
                                      backgroundColor: ScadaColors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Yükle & Sınıflandır'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScadaColors.red,
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

  Widget _buildUploadResultCard(Map<String, dynamic> result) {
    final classification = result['classification'] as Map<String, dynamic>? ?? {};
    final ragStatus = result['rag_status'] ?? '';
    final tags = (classification['tags'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: ScadaColors.green, size: 18),
          const SizedBox(width: 8),
          const Text('Başarıyla Yüklendi!', style: TextStyle(color: ScadaColors.green, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        _resultRow('Departman', _departmentLabel(classification['department'] ?? 'genel')),
        _resultRow('Zorluk', _difficultyLabel(classification['difficulty'] ?? 'beginner')),
        _resultRow('RAG', ragStatus == 'indexed' ? 'Indekslendi' : ragStatus),
        if (classification['summary'] != null) ...[
          SizedBox(height: 6),
          Text(
            classification['summary'],
            style: TextStyle(color: context.scada.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ScadaColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t, style: const TextStyle(color: ScadaColors.purple, fontSize: 10)),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: context.scada.textDim, fontSize: 11))),
        Text(value, style: TextStyle(color: context.scada.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _departmentLabel(String key) {
    const map = {
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'yönetim': 'Yönetim',
      'on_buro': 'Ön Büro',
      'spa': 'SPA & Wellness',
      'fb': 'Yiyecek İçecek',
      'güvenlik': 'Güvenlik',
      'genel': 'Genel',
      'kurumsal': 'Kurumsal',
    };
    return map[key] ?? key;
  }

  String _difficultyLabel(String key) {
    const map = {
      'beginner': 'Başlangıç',
      'intermediate': 'Orta',
      'advanced': 'İleri',
    };
    return map[key] ?? key;
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
              color: ScadaColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.library_books, color: ScadaColors.red, size: 20),
          ),
          SizedBox(width: 8),
          Text('Doküman Havuzu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.scada.textDim, size: 20),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: ScadaColors.red,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('PDF Yükle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search & Filter bar
          Container(
            padding: const EdgeInsets.all(12),
            color: context.scada.surface,
            child: Column(children: [
              // Search
              TextField(
                controller: _searchController,
                style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Semantik arama... (içerik bazlı)',
                  hintStyle: TextStyle(color: context.scada.textDim, fontSize: 12),
                  prefixIcon: const Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 18),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.purple)),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16, color: context.scada.textDim),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.scada.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ScadaColors.purple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: context.scada.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 8),
              // Department filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _buildFilterChip(null, 'Tümü'),
                  _buildFilterChip('teknik', 'Teknik'),
                  _buildFilterChip('hk', 'Kat Hizm.'),
                  _buildFilterChip('fb', 'F&B'),
                  _buildFilterChip('on_buro', 'Ön Büro'),
                  _buildFilterChip('güvenlik', 'Güvenlik'),
                  _buildFilterChip('genel', 'Genel'),
                  _buildFilterChip('kurumsal', 'Kurumsal'),
                ]),
              ),
            ]),
          ),

          // Content
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator(color: ScadaColors.red))
                    : _documents.isEmpty
                        ? _buildEmptyState()
                        : _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? dept, String label) {
    final selected = _selectedDepartment == dept;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(
          color: selected ? Colors.white : context.scada.textSecondary,
          fontSize: 11,
        )),
        selected: selected,
        selectedColor: ScadaColors.cyan,
        backgroundColor: context.scada.card,
        side: BorderSide(color: selected ? ScadaColors.cyan : context.scada.border),
        onSelected: (_) {
          setState(() => _selectedDepartment = dept);
          _loadDocuments();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_off, color: context.scada.textDim, size: 64),
        SizedBox(height: 16),
        Text('Henuz doküman yüklenmemis', style: TextStyle(color: context.scada.textSecondary, fontSize: 14)),
        SizedBox(height: 8),
        Text('PDF yüklemek için aşağıdaki butonu kullanin', style: TextStyle(color: context.scada.textDim, fontSize: 12)),
      ]),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final classification = doc['classification'] as Map<String, dynamic>? ?? {};
    final tags = (classification['tags'] as List?)?.cast<String>() ?? [];
    final ragStatus = doc['rag_status'] ?? '';
    final fileSize = doc['file_size'] ?? 0;
    final dept = classification['department'] ?? 'genel';
    final difficulty = classification['difficulty'] ?? 'beginner';
    final summary = classification['summary'] ?? '';
    final createdAt = doc['created_at'] != null
        ? DateTime.tryParse(doc['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          // PDF icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ScadaColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: ScadaColors.red, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                doc['title'] ?? doc['file_name'] ?? 'Bilinmeyen',
                style: TextStyle(color: context.scada.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Row(children: [
                Text(
                  doc['file_name'] ?? '',
                  style: TextStyle(color: context.scada.textDim, fontSize: 10),
                ),
                SizedBox(width: 8),
                Text(
                  '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: TextStyle(color: context.scada.textDim, fontSize: 10),
                ),
                if (createdAt != null) ...[
                  SizedBox(width: 8),
                  Text(
                    '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                    style: TextStyle(color: context.scada.textDim, fontSize: 10),
                  ),
                ],
              ]),
            ]),
          ),
          // RAG status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ragStatus == 'indexed'
                  ? ScadaColors.green.withValues(alpha: 0.12)
                  : ScadaColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ragStatus == 'indexed' ? 'Indekslendi' : ragStatus,
                style: TextStyle(
                  color: ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          // Delete button
          SizedBox(
            width: 32, height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.delete_outline, size: 18, color: ScadaColors.red),
              tooltip: 'Dokümani sil',
              onPressed: () => _confirmDeleteDocument(doc),
            ),
          ),
        ]),

        // Summary
        if (summary.isNotEmpty) ...[
          SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(color: context.scada.textSecondary, fontSize: 11, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Tags & metadata
        const SizedBox(height: 10),
        Row(children: [
          // Department badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _departmentLabel(dept),
              style: const TextStyle(color: ScadaColors.cyan, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _difficultyLabel(difficulty),
              style: const TextStyle(color: ScadaColors.amber, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          // Tags
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tags.take(4).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ScadaColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(t, style: const TextStyle(color: ScadaColors.purple, fontSize: 9)),
              )).toList(),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: ScadaColors.purple),
        SizedBox(height: 12),
        Text('Semantik arama yapiliyor...', style: TextStyle(color: ScadaColors.purple, fontSize: 12)),
      ]));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text('Sonuç bulunamadi', style: TextStyle(color: context.scada.textDim, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final r = _searchResults[index];
        final score = (r['score'] as num?)?.toDouble() ?? 0;
        final scorePercent = (score * 100).toInt();
        final scoreColor = score > 0.8 ? ScadaColors.green : score > 0.6 ? ScadaColors.amber : ScadaColors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.scada.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  r['source'] ?? 'Bilinmeyen kaynak',
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%$scorePercent eslesme',
                  style: TextStyle(color: scoreColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            SizedBox(height: 8),
            Text(
              r['content'] ?? '',
              style: TextStyle(color: context.scada.textSecondary, fontSize: 11, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        );
      },
    );
  }
}
