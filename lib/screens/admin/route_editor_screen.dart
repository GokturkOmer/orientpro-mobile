import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class RouteEditorScreen extends ConsumerStatefulWidget {
  const RouteEditorScreen({super.key, this.routeId});
  final String? routeId;

  @override
  ConsumerState<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends ConsumerState<RouteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController(text: '60');
  final _passingScoreController = TextEditingController(text: '70');

  String? _selectedDepartmentId;
  String _selectedDifficulty = 'beginner';
  bool _isMandatory = true;
  bool _certificateEnabled = false;
  bool _loaded = false;

  bool get _isEditMode => widget.routeId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadDepartments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && _isEditMode) {
      Future.microtask(() {
        ref.read(adminProvider.notifier).loadRouteDetail(widget.routeId!);
      });
      _loaded = true;
    }
  }

  void _prefillForm() {
    final route = ref.read(adminProvider).selectedRoute;
    if (route == null) return;
    _titleController.text = route.title;
    _descriptionController.text = route.description ?? '';
    _selectedDepartmentId = route.departmentId;
    _selectedDifficulty = route.difficulty;
    _estimatedMinutesController.text = route.estimatedMinutes.toString();
    _passingScoreController.text = route.passingScore.toString();
    _isMandatory = route.isMandatory;
    _certificateEnabled = route.certificateEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lutfen departman secin'), backgroundColor: ScadaColors.red),
      );
      return;
    }

    final data = {
      'department_id': _selectedDepartmentId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'difficulty': _selectedDifficulty,
      'estimated_minutes': int.tryParse(_estimatedMinutesController.text) ?? 60,
      'passing_score': int.tryParse(_passingScoreController.text) ?? 70,
      'is_mandatory': _isMandatory,
      'certificate_enabled': _certificateEnabled,
    };

    final notifier = ref.read(adminProvider.notifier);
    final bool success;
    if (_isEditMode) {
      success = await notifier.updateRoute(widget.routeId!, data);
    } else {
      success = await notifier.createRoute(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Rota basariyla guncellendi' : 'Rota basariyla olusturuldu'),
          backgroundColor: ScadaColors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _confirmDeleteModule(String moduleId, String moduleTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        title: const Text('Modulu Sil', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16)),
        content: Text(
          '"$moduleTitle" modulunu silmek istediginize emin misiniz?',
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
              final success = await ref.read(adminProvider.notifier).deleteModule(moduleId);
              if (success && mounted) {
                ref.read(adminProvider.notifier).loadRouteDetail(widget.routeId!);
              }
            },
            child: const Text('Sil', style: TextStyle(color: ScadaColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderModule(List<dynamic> modules, int oldIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= modules.length) return;
    final ids = modules.map<String>((m) => m.id as String).toList();
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    final success = await ref.read(adminProvider.notifier).reorderModules(ids);
    if (success && mounted) {
      ref.read(adminProvider.notifier).loadRouteDetail(widget.routeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final route = admin.selectedRoute;

    // Pre-fill once when route loads in edit mode
    if (_isEditMode && route != null && !_loaded) {
      // handled via didChangeDependencies
    }
    if (_isEditMode && route != null && _titleController.text.isEmpty && route.title.isNotEmpty) {
      Future.microtask(() => _prefillForm());
    }

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Rotayi Duzenle' : 'Yeni Egitim Rotasi',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      body: admin.isLoading && _isEditMode
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ScadaColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ScadaColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baslik
                          _buildLabel('Baslik'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                            decoration: _inputDecoration('Egitim rotasi basligi'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Baslik zorunludur' : null,
                          ),
                          const SizedBox(height: 16),

                          // Aciklama
                          _buildLabel('Aciklama'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                            maxLines: 3,
                            decoration: _inputDecoration('Rota hakkinda kisa aciklama'),
                          ),
                          const SizedBox(height: 16),

                          // Departman
                          _buildLabel('Departman'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDepartmentId,
                            dropdownColor: ScadaColors.surface,
                            style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                            decoration: _inputDecoration('Departman secin'),
                            items: admin.departments.map((d) {
                              return DropdownMenuItem(value: d.id, child: Text(d.name));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedDepartmentId = val),
                          ),
                          const SizedBox(height: 16),

                          // Zorluk
                          _buildLabel('Zorluk'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDifficulty,
                            dropdownColor: ScadaColors.surface,
                            style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                            decoration: _inputDecoration('Zorluk seviyesi'),
                            items: const [
                              DropdownMenuItem(value: 'beginner', child: Text('Baslangic')),
                              DropdownMenuItem(value: 'intermediate', child: Text('Orta')),
                              DropdownMenuItem(value: 'advanced', child: Text('Ileri')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDifficulty = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tahmini Sure + Gecme Puani
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Tahmini Sure (dakika)'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _estimatedMinutesController,
                                      style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('60'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Gecme Puani (%)'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passingScoreController,
                                      style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('70'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Zorunlu Egitim
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Zorunlu Egitim', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 13)),
                            subtitle: const Text('Bu rota zorunlu olarak atansin', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 11)),
                            value: _isMandatory,
                            activeThumbColor: ScadaColors.cyan,
                            onChanged: (val) => setState(() => _isMandatory = val),
                          ),

                          // Sertifika
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sertifika Verilsin', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 13)),
                            subtitle: const Text('Tamamlayanlara sertifika olusturulsun', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 11)),
                            value: _certificateEnabled,
                            activeThumbColor: ScadaColors.cyan,
                            onChanged: (val) => setState(() => _certificateEnabled = val),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Module list (edit mode only)
                  if (_isEditMode) ...[
                    _buildModuleSection(route),
                  ],

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: admin.isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.cyan,
                        foregroundColor: ScadaColors.bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: ScadaColors.cyan.withValues(alpha: 0.4),
                      ),
                      child: admin.isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.bg))
                          : Text(
                              _isEditMode ? 'Rotayi Guncelle' : 'Rotayi Olustur',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildModuleSection(dynamic route) {
    final modules = route?.modules as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.menu_book, size: 14, color: ScadaColors.textDim),
            const SizedBox(width: 6),
            Text(
              'MODULLER',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ScadaColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${modules.length}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ScadaColors.cyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Module cards
        if (modules.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ScadaColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.menu_book, size: 36, color: ScadaColors.textDim),
                  SizedBox(height: 8),
                  Text('Henuz modul eklenmemis', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...modules.asMap().entries.map((entry) {
            final idx = entry.key;
            final module = entry.value;
            return _buildModuleCard(module, idx, modules.length);
          }),

        const SizedBox(height: 12),

        // Add module button
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin/module-editor', arguments: {'routeId': widget.routeId});
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Modul Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: ScadaColors.cyan,
              side: const BorderSide(color: ScadaColors.cyan, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(dynamic module, int index, int total) {
    final String moduleType = module.moduleType ?? 'lesson';
    final IconData typeIcon;
    switch (moduleType) {
      case 'video':
        typeIcon = Icons.play_circle_fill;
        break;
      case 'practice':
        typeIcon = Icons.build;
        break;
      case 'assessment':
        typeIcon = Icons.assignment;
        break;
      default:
        typeIcon = Icons.menu_book;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ScadaColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, size: 18, color: ScadaColors.cyan),
            ),
            const SizedBox(width: 10),

            // Title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        module.typeText ?? moduleType,
                        style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 10, color: ScadaColors.textDim),
                      const SizedBox(width: 2),
                      Text(
                        '${module.estimatedMinutes ?? 15} dk',
                        style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reorder buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_upward, size: 14, color: index > 0 ? ScadaColors.textSecondary : ScadaColors.textDim),
                    onPressed: index > 0 ? () => _reorderModule(ref.read(adminProvider).selectedRoute?.modules ?? [], index, index - 1) : null,
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_downward, size: 14, color: index < total - 1 ? ScadaColors.textSecondary : ScadaColors.textDim),
                    onPressed: index < total - 1 ? () => _reorderModule(ref.read(adminProvider).selectedRoute?.modules ?? [], index, index + 1) : null,
                  ),
                ),
              ],
            ),

            // Edit button
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit, size: 15, color: ScadaColors.amber),
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/module-editor', arguments: {'routeId': widget.routeId, 'moduleId': module.id});
                },
              ),
            ),

            // Delete button
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline, size: 15, color: ScadaColors.red),
                onPressed: () => _confirmDeleteModule(module.id, module.title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 0.5),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: ScadaColors.textDim, fontSize: 13),
      filled: true,
      fillColor: ScadaColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ScadaColors.border),
      ),
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
    );
  }
}
