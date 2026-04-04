import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/auth_dio.dart';

/// Dokuman Havuzu'ndan dokuman secme dialog'u.
/// Tek secim (icerik olusturma) veya coklu secim (quiz) destekler.
class DocumentPickerDialog extends ConsumerStatefulWidget {
  final bool multiSelect;
  final String? initialDepartment;

  const DocumentPickerDialog({
    super.key,
    this.multiSelect = false,
    this.initialDepartment,
  });

  /// Dialog'u acar ve secilen dokuman(lar)i dondurur.
  /// Tek secim: Map<String, dynamic>? — secilen dokuman
  /// Coklu secim: List<Map<String, dynamic>>? — secilen dokumanlar
  static Future<dynamic> show(
    BuildContext context, {
    bool multiSelect = false,
    String? initialDepartment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentPickerDialog(
        multiSelect: multiSelect,
        initialDepartment: initialDepartment,
      ),
    );
  }

  @override
  ConsumerState<DocumentPickerDialog> createState() => _DocumentPickerDialogState();
}

class _DocumentPickerDialogState extends ConsumerState<DocumentPickerDialog> {
  String? _selectedDept;
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  String? _error;
  final Set<String> _selectedIds = {};

  static const _departments = [
    (null, 'Tumu'),
    ('teknik', 'Teknik'),
    ('hk', 'Kat Hizm.'),
    ('fb', 'F&B'),
    ('on_buro', 'On Buro'),
    ('guvenlik', 'Guvenlik'),
    ('genel', 'Genel'),
    ('kurumsal', 'Kurumsal'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDept = widget.initialDepartment;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocs());
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(authDioProvider);
      final params = <String, String>{};
      if (_selectedDept != null) params['department'] = _selectedDept!;
      final resp = await dio.get('/training/pool-documents', queryParameters: params);
      setState(() {
        _docs = (resp.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Dokumanlar yuklenemedi';
      });
    }
  }

  void _onDeptChanged(String? dept) {
    setState(() => _selectedDept = dept);
    _loadDocs();
  }

  void _onSelect(Map<String, dynamic> doc) {
    final id = doc['id'] as String;
    if (widget.multiSelect) {
      setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      });
    } else {
      Navigator.pop(context, doc);
    }
  }

  void _onConfirmMulti() {
    final selected = _docs.where((d) => _selectedIds.contains(d['id'])).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.scada.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(color: context.scada.border, borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Icon(Icons.folder_open, color: ScadaColors.purple, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.multiSelect ? 'Dokumanlar Secin' : 'Dokuman Secin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
            )),
            if (widget.multiSelect && _selectedIds.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _onConfirmMulti,
                icon: const Icon(Icons.check, size: 16),
                label: Text('${_selectedIds.length} Secildi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
          ]),
        ),

        // Department filter
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _departments.map((d) {
              final isActive = d.$1 == _selectedDept;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(d.$2, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : context.scada.textSecondary)),
                  selected: isActive,
                  selectedColor: ScadaColors.cyan,
                  backgroundColor: context.scada.surface,
                  side: BorderSide(color: isActive ? ScadaColors.cyan : context.scada.border),
                  onSelected: (_) => _onDeptChanged(d.$1),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Document list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: ScadaColors.red, fontSize: 13)))
                  : _docs.isEmpty
                      ? Center(child: Text('Bu kategoride dokuman yok', style: TextStyle(color: context.scada.textSecondary)))
                      : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _docs.length,
                      itemBuilder: (_, i) => _buildDocCard(_docs[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final isSelected = _selectedIds.contains(doc['id']);
    final dept = doc['department'] ?? 'genel';
    final tags = (doc['tags'] as List?)?.cast<String>() ?? [];

    return InkWell(
      onTap: () => _onSelect(doc),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ScadaColors.green : context.scada.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.picture_as_pdf, color: ScadaColors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              doc['title'] ?? '',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ScadaColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(dept, style: const TextStyle(fontSize: 9, color: ScadaColors.cyan)),
            ),
            if (widget.multiSelect) ...[
              const SizedBox(width: 8),
              Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? ScadaColors.green : context.scada.textDim, size: 20),
            ],
          ]),
          if (doc['summary'] != null && (doc['summary'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(doc['summary'], style: TextStyle(fontSize: 10, color: context.scada.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 4, children: tags.take(4).map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: context.scada.surface, borderRadius: BorderRadius.circular(3)),
              child: Text(t, style: TextStyle(fontSize: 8, color: context.scada.textDim)),
            )).toList()),
          ],
          const SizedBox(height: 4),
          Text('${doc['chunk_count'] ?? 0} parca | ${((doc['file_size'] ?? 0) / 1024).toStringAsFixed(0)} KB',
              style: TextStyle(fontSize: 9, color: context.scada.textDim)),
        ]),
      ),
    );
  }
}
