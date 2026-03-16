import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/library_document.dart';
import '../../core/auth/role_helper.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDocType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(libraryProvider.notifier).loadPersonalDocs(auth.user!.id);
        // Admin tum belgeleri gorur, diger kullanicilar sadece kendi departmanini
        final isAdmin = RoleHelper.isAdmin(auth.user!.role);
        ref.read(libraryProvider.notifier).loadSharedDocs(department: isAdmin ? null : auth.user!.department);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);

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
              color: ScadaColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.folder_open, color: ScadaColors.purple, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Icerik Kutuphanesi', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ScadaColors.cyan,
          labelColor: ScadaColors.cyan,
          unselectedLabelColor: ScadaColors.textSecondary,
          tabs: [
            Tab(text: 'Kisisel (${library.personalDocs.length})'),
            Tab(text: 'Paylasilan (${library.sharedDocs.length})'),
          ],
        ),
      ),
      body: library.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : Column(children: [
              // Arama kutusu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Belge ara...',
                    hintStyle: const TextStyle(fontSize: 12, color: ScadaColors.textDim),
                    prefixIcon: const Icon(Icons.search, size: 18, color: ScadaColors.textDim),
                    filled: true,
                    fillColor: ScadaColors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.cyan)),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDocList(_filterDocs(library.personalDocs), isPersonal: true),
                    _buildSharedTab(library.sharedDocs),
                  ],
                ),
              ),
            ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Yukle'),
      ),
    );
  }

  List<LibraryDocument> _filterDocs(List<LibraryDocument> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((d) =>
      d.title.toLowerCase().contains(_searchQuery) ||
      d.docTypeText.toLowerCase().contains(_searchQuery) ||
      (d.department?.toLowerCase().contains(_searchQuery) ?? false) ||
      d.fileName.toLowerCase().contains(_searchQuery)
    ).toList();
  }

  Widget _buildDocList(List<LibraryDocument> docs, {bool isPersonal = false}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.folder_off, size: 48, color: ScadaColors.textDim),
          const SizedBox(height: 12),
          Text(
            isPersonal ? 'Henuz kisisel belgeniz yok' : 'Bu kategoride belge yok',
            style: const TextStyle(color: ScadaColors.textSecondary),
          ),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, i) => _buildDocCard(docs[i], isPersonal: isPersonal),
    );
  }

  Widget _buildSharedTab(List<LibraryDocument> docs) {
    return Column(children: [
      // Filtre chipleri
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          _filterChip('Tumu', null),
          _filterChip('SOP', 'sop'),
          _filterChip('Acil Durum', 'emergency_plan'),
          _filterChip('Sertifika', 'certificate'),
          _filterChip('Diger', 'other'),
        ]),
      ),
      Expanded(
        child: _buildDocList(
          _filterDocs(_selectedDocType == null ? docs : docs.where((d) => d.docType == _selectedDocType).toList()),
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, String? type) {
    final selected = _selectedDocType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: selected ? ScadaColors.bg : ScadaColors.textSecondary, fontSize: 12)),
        selected: selected,
        selectedColor: ScadaColors.cyan,
        backgroundColor: ScadaColors.surface,
        side: BorderSide(color: selected ? ScadaColors.cyan : ScadaColors.border),
        onSelected: (_) {
          setState(() => _selectedDocType = type);
          if (type != null) {
            ref.read(libraryProvider.notifier).loadSharedDocs(docType: type);
          } else {
            final auth = ref.read(authProvider);
            final isAdmin = RoleHelper.isAdmin(auth.user?.role);
            ref.read(libraryProvider.notifier).loadSharedDocs(department: isAdmin ? null : auth.user?.department);
          }
        },
      ),
    );
  }

  Widget _buildDocCard(LibraryDocument doc, {bool isPersonal = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _mimeColor(doc.mimeType).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_mimeIcon(doc.mimeType), color: _mimeColor(doc.mimeType), size: 22),
        ),
        title: Text(doc.title, style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(doc.docTypeText, style: const TextStyle(color: ScadaColors.cyan, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Text(doc.fileSizeText, style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
          if (doc.department != null) ...[
            const SizedBox(width: 8),
            Text(doc.department!, style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11)),
          ],
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (doc.downloadUrl != null)
            IconButton(
              icon: const Icon(Icons.download, color: ScadaColors.green, size: 20),
              onPressed: () => _openUrl(doc.downloadUrl!),
            ),
          if (isPersonal)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: ScadaColors.red, size: 20),
              onPressed: () => _confirmDelete(doc),
            ),
        ]),
      ),
    );
  }

  IconData _mimeIcon(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('image')) return Icons.image;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    if (mime.contains('sheet') || mime.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Color _mimeColor(String? mime) {
    if (mime == null) return ScadaColors.textSecondary;
    if (mime.contains('pdf')) return ScadaColors.red;
    if (mime.contains('image')) return ScadaColors.purple;
    if (mime.contains('word') || mime.contains('document')) return ScadaColors.cyan;
    if (mime.contains('sheet') || mime.contains('excel')) return ScadaColors.green;
    return ScadaColors.textSecondary;
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  void _confirmDelete(LibraryDocument doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaColors.borderBright),
        ),
        title: const Text('Belge Sil', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('${doc.title} silinsin mi?', style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = ref.read(authProvider);
              final ok = await ref.read(libraryProvider.notifier).deleteDocument(doc.id, auth.user!.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Belge silindi'), backgroundColor: ScadaColors.green),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: ScadaColors.red)),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final titleController = TextEditingController();
    String category = _tabController.index == 0 ? 'personal' : 'shared';
    String docType = 'other';
    String? selectedFileName;
    List<int>? selectedFileBytes;
    String? selectedMimeType;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ScadaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScadaColors.borderBright),
          ),
          title: const Row(children: [
            Icon(Icons.upload_file, color: ScadaColors.cyan, size: 18),
            SizedBox(width: 8),
            Text('Dosya Yukle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Baslik', hintText: 'Belge adi'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: docType,
                decoration: const InputDecoration(labelText: 'Belge Tipi'),
                dropdownColor: ScadaColors.surface,
                items: const [
                  DropdownMenuItem(value: 'certificate', child: Text('Sertifika')),
                  DropdownMenuItem(value: 'sop', child: Text('SOP')),
                  DropdownMenuItem(value: 'health_report', child: Text('Saglik Raporu')),
                  DropdownMenuItem(value: 'id_copy', child: Text('Kimlik Fotokopisi')),
                  DropdownMenuItem(value: 'emergency_plan', child: Text('Acil Durum Plani')),
                  DropdownMenuItem(value: 'other', child: Text('Diger')),
                ],
                onChanged: (v) => setDialogState(() => docType = v!),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(selectedFileName ?? 'Dosya Sec'),
                onPressed: () {
                  final input = html.FileUploadInputElement()..accept = '*/*';
                  input.click();
                  input.onChange.listen((e) {
                    final file = input.files?.first;
                    if (file == null) return;
                    final reader = html.FileReader();
                    reader.readAsArrayBuffer(file);
                    reader.onLoadEnd.listen((_) {
                      setDialogState(() {
                        selectedFileName = file.name;
                        selectedFileBytes = (reader.result as List<int>);
                        selectedMimeType = file.type;
                      });
                    });
                  });
                },
              ),
              if (selectedFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(selectedFileName!, style: const TextStyle(color: ScadaColors.green, fontSize: 12)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedFileBytes == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Baslik ve dosya secimi zorunlu'), backgroundColor: ScadaColors.red),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final auth = ref.read(authProvider);
                final ok = await ref.read(libraryProvider.notifier).uploadDocument(
                  title: titleController.text,
                  category: category,
                  docType: docType,
                  userId: auth.user!.id,
                  fileName: selectedFileName!,
                  fileBytes: selectedFileBytes!,
                  mimeType: selectedMimeType ?? 'application/octet-stream',
                  department: auth.user!.department,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Dosya yuklendi' : 'Yukleme basarisiz'),
                      backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
                    ),
                  );
                }
              },
              child: const Text('Yukle'),
            ),
          ],
        ),
      ),
    );
  }
}
