import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';

/// Indirilebilir form ve checklist dokumanlari (PDF/Excel)
class DigitalFormScreen extends ConsumerStatefulWidget {
  const DigitalFormScreen({super.key});

  @override
  ConsumerState<DigitalFormScreen> createState() => _DigitalFormScreenState();
}

class _DigitalFormScreenState extends ConsumerState<DigitalFormScreen> {
  Dio get _dio => ref.read(authDioProvider);
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all, form, checklist

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await _dio.get('/library/shared', queryParameters: {'doc_type': 'form_template'});
      final items = (resp.data as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _documents = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Dokumanlar yuklenemedi. Tekrar deneyin.'; });
    }
  }

  List<Map<String, dynamic>> get _filteredDocs {
    if (_filter == 'all') return _documents;
    if (_filter == 'form') {
      return _documents.where((d) => (d['mime_type'] ?? '').toString().contains('pdf')).toList();
    }
    return _documents.where((d) => !(d['mime_type'] ?? '').toString().contains('pdf')).toList();
  }

  void _openDocument(Map<String, dynamic> doc) {
    final downloadUrl = doc['download_url'];
    if (downloadUrl != null && downloadUrl.toString().isNotEmpty) {
      html.window.open(downloadUrl.toString(), '_blank');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indirme baglantisi bulunamadi'), backgroundColor: ScadaColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredDocs;
    final formCount = _documents.where((d) => (d['mime_type'] ?? '').toString().contains('pdf')).length;
    final checklistCount = _documents.length - formCount;

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
              color: ScadaColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.assignment, color: ScadaColors.green, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Form & Checklistler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      body: Column(children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _buildFilter('Tumu (${_documents.length})', 'all'),
            const SizedBox(width: 6),
            _buildFilter('Formlar ($formCount)', 'form'),
            const SizedBox(width: 6),
            _buildFilter('Checklistler ($checklistCount)', 'checklist'),
          ]),
        ),

        // Info bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ScadaColors.cyan.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14, color: ScadaColors.cyan),
            const SizedBox(width: 6),
            const Expanded(child: Text(
              'PDF formlar tarayicida acilir, Excel checklistler indirilir',
              style: TextStyle(fontSize: 10, color: ScadaColors.cyan),
            )),
          ]),
        ),
        const SizedBox(height: 8),

        // Document list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: ScadaColors.green))
              : docs.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.folder_open, size: 48, color: ScadaColors.textDim),
                      const SizedBox(height: 8),
                      const Text('Dokuman bulunamadi', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      color: ScadaColors.cyan,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) => _buildDocCard(docs[index]),
                      ),
                    ),
        ),

        if (_error != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScadaColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: const TextStyle(fontSize: 11, color: ScadaColors.red)),
          ),
      ]),
    );
  }

  Widget _buildFilter(String label, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? ScadaColors.cyan.withValues(alpha: 0.12) : ScadaColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? ScadaColors.cyan : ScadaColors.border),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: isSelected ? ScadaColors.cyan : ScadaColors.textSecondary,
          )),
        ),
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final isPdf = (doc['mime_type'] ?? '').toString().contains('pdf');
    final tags = (doc['tags'] as List?)?.cast<String>() ?? [];
    final isChecklist = tags.contains('checklist');
    final fileSize = doc['file_size'] as int? ?? 0;

    final color = isPdf ? ScadaColors.red : ScadaColors.green;
    final icon = isPdf ? Icons.picture_as_pdf : Icons.table_chart;
    final typeLabel = isPdf ? 'PDF' : 'Excel';
    final sizeStr = fileSize > 1024 ? '${(fileSize / 1024).toStringAsFixed(1)} KB' : '$fileSize B';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDocument(doc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // File icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
              const SizedBox(height: 2),
              Text(doc['description'] ?? '', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(typeLabel, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isChecklist ? 'Checklist' : 'Form',
                    style: const TextStyle(fontSize: 8, color: ScadaColors.cyan, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Text(sizeStr, style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
                // Department tag
                if (doc['department'] != null) ...[
                  const SizedBox(width: 6),
                  Text(doc['department'].toString(), style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
                ],
              ]),
            ])),
            const SizedBox(width: 8),
            // Download button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(isPdf ? Icons.open_in_new : Icons.download, color: color, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}
