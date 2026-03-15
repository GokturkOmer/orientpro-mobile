import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:html' as html;
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
        backgroundColor: ScadaColors.surface,
        title: const Text('Dokumani Sil', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16)),
        content: Text(
          '"$docTitle" dokumanini silmek istediginize emin misiniz?\n\nBu islem geri alinamaz.',
          style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteContent(docId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dokuman silindi'), backgroundColor: ScadaColors.green),
                );
                _loadDocuments();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.read(adminProvider).error ?? 'Dokuman silinemedi'),
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
    Map<String, dynamic>? uploadResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ScadaColors.card,
              title: Row(children: [
                const Icon(Icons.upload_file, color: ScadaColors.red, size: 22),
                const SizedBox(width: 8),
                const Text('PDF Yukle', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16)),
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
                        style: const TextStyle(color: ScadaColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Baslik (opsiyonel)',
                          labelStyle: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: ScadaColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: ScadaColors.cyan),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: ScadaColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        enabled: !isUploading,
                      ),
                      const SizedBox(height: 12),

                      // File picker
                      InkWell(
                        onTap: isUploading
                            ? null
                            : () {
                                final input = html.FileUploadInputElement()..accept = '.pdf';
                                input.click();
                                input.onChange.listen((event) {
                                  final file = input.files?.first;
                                  if (file != null) {
                                    final reader = html.FileReader();
                                    reader.readAsArrayBuffer(file);
                                    reader.onLoadEnd.listen((_) {
                                      setDialogState(() {
                                        pdfFileName = file.name;
                                        pdfFileBytes = Uint8List.fromList(reader.result as List<int>);
                                      });
                                    });
                                  }
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ScadaColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pdfFileName != null ? ScadaColors.green : ScadaColors.border,
                              width: pdfFileName != null ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(
                              pdfFileName != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                              color: pdfFileName != null ? ScadaColors.red : ScadaColors.textDim,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pdfFileName ?? 'PDF dosyasi secmek icin tiklayin',
                              style: TextStyle(
                                color: pdfFileName != null ? ScadaColors.textPrimary : ScadaColors.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (pdfFileBytes != null)
                              Text(
                                '${(pdfFileBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: const TextStyle(color: ScadaColors.textDim, fontSize: 10),
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
                        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PDF yuklendiginde AI otomatik olarak:\n'
                              '- Departman ve zorluk siniflandirmasi yapar\n'
                              '- Anahtar etiketler olusturur\n'
                              '- Semantik arama icin indeksler',
                              style: TextStyle(color: ScadaColors.textSecondary, fontSize: 10, height: 1.4),
                            ),
                          ),
                        ]),
                      ),

                      // Upload progress
                      if (isUploading) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: uploadProgress < 1.0 ? uploadProgress : null,
                          backgroundColor: ScadaColors.surface,
                          color: uploadProgress >= 1.0 ? ScadaColors.purple : ScadaColors.cyan,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uploadProgress >= 1.0 ? 'AI siniflandirma yapiliyor...' : 'Yukleniyor... %${(uploadProgress * 100).toInt()}',
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
                  child: Text(uploadResult != null ? 'Kapat' : 'Iptal', style: const TextStyle(color: ScadaColors.textSecondary)),
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
                                      content: Text(ref.read(adminProvider).error ?? 'PDF yuklenemedi'),
                                      backgroundColor: ScadaColors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Yukle & Siniflandir'),
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
          const Text('Basariyla Yuklendi!', style: TextStyle(color: ScadaColors.green, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        _resultRow('Departman', _departmentLabel(classification['department'] ?? 'genel')),
        _resultRow('Zorluk', _difficultyLabel(classification['difficulty'] ?? 'beginner')),
        _resultRow('RAG', ragStatus == 'indexed' ? 'Indekslendi' : ragStatus),
        if (classification['summary'] != null) ...[
          const SizedBox(height: 6),
          Text(
            classification['summary'],
            style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
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
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: ScadaColors.textDim, fontSize: 11))),
        Text(value, style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _departmentLabel(String key) {
    const map = {
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'yonetim': 'Yonetim',
      'on_buro': 'On Buro',
      'spa': 'SPA & Wellness',
      'fb': 'Yiyecek Icecek',
      'guvenlik': 'Guvenlik',
      'genel': 'Genel',
    };
    return map[key] ?? key;
  }

  String _difficultyLabel(String key) {
    const map = {
      'beginner': 'Baslangic',
      'intermediate': 'Orta',
      'advanced': 'Ileri',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
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
          const SizedBox(width: 8),
          const Text('Dokuman Havuzu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: ScadaColors.textDim, size: 20),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: ScadaColors.red,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('PDF Yukle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search & Filter bar
          Container(
            padding: const EdgeInsets.all(12),
            color: ScadaColors.surface,
            child: Column(children: [
              // Search
              TextField(
                controller: _searchController,
                style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Semantik arama... (icerik bazli)',
                  hintStyle: const TextStyle(color: ScadaColors.textDim, fontSize: 12),
                  prefixIcon: const Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 18),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.purple)),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: ScadaColors.textDim),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ScadaColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ScadaColors.purple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: ScadaColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 8),
              // Department filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _buildFilterChip(null, 'Tumu'),
                  _buildFilterChip('teknik', 'Teknik'),
                  _buildFilterChip('hk', 'Kat Hizm.'),
                  _buildFilterChip('fb', 'F&B'),
                  _buildFilterChip('on_buro', 'On Buro'),
                  _buildFilterChip('guvenlik', 'Guvenlik'),
                  _buildFilterChip('genel', 'Genel'),
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
          color: selected ? Colors.white : ScadaColors.textSecondary,
          fontSize: 11,
        )),
        selected: selected,
        selectedColor: ScadaColors.cyan,
        backgroundColor: ScadaColors.card,
        side: BorderSide(color: selected ? ScadaColors.cyan : ScadaColors.border),
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
        Icon(Icons.folder_off, color: ScadaColors.textDim, size: 64),
        const SizedBox(height: 16),
        const Text('Henuz dokuman yuklenmemis', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        const Text('PDF yuklemek icin asagidaki butonu kullanin', style: TextStyle(color: ScadaColors.textDim, fontSize: 12)),
      ]),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                doc['title'] ?? doc['file_name'] ?? 'Bilinmeyen',
                style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  doc['file_name'] ?? '',
                  style: const TextStyle(color: ScadaColors.textDim, fontSize: 10),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(color: ScadaColors.textDim, fontSize: 10),
                ),
                if (createdAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                    style: const TextStyle(color: ScadaColors.textDim, fontSize: 10),
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
              tooltip: 'Dokumani sil',
              onPressed: () => _confirmDeleteDocument(doc),
            ),
          ),
        ]),

        // Summary
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11, height: 1.4),
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
      return const Center(
        child: Text('Sonuc bulunamadi', style: TextStyle(color: ScadaColors.textDim, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
            color: ScadaColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, color: ScadaColors.purple, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r['source'] ?? 'Bilinmeyen kaynak',
                  style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 8),
            Text(
              r['content'] ?? '',
              style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        );
      },
    );
  }
}
