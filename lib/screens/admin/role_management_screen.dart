import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/utils/error_helper.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  static const _resources = ['training', 'content', 'users', 'reports', 'settings', 'work_orders'];
  static const _actions = ['view', 'create', 'edit', 'delete', 'approve'];
  static const _resourceLabels = {
    'training': 'Egitim',
    'content': 'Icerik',
    'users': 'Kullanicilar',
    'reports': 'Raporlar',
    'settings': 'Ayarlar',
    'work_orders': 'Is Emirleri',
  };

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.get('/roles');
      setState(() {
        _roles = (response.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = ErrorHelper.getMessage(e); });
    }
  }

  Future<void> _createRole() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        title: Text('Yeni Rol', style: TextStyle(color: context.scada.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Rol Adi')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kod (orn: chef)')),
          const SizedBox(height: 8),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Aciklama')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: TextStyle(color: context.scada.textDim))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.cyan),
            child: const Text('Olustur'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
      nameCtrl.dispose();
      codeCtrl.dispose();
      descCtrl.dispose();
      return;
    }

    try {
      final dio = ref.read(authDioProvider);
      await dio.post('/roles', data: {
        'name': nameCtrl.text,
        'code': codeCtrl.text,
        'description': descCtrl.text,
      });
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol olusturuldu'), backgroundColor: ScadaColors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red));
      }
    } finally {
      nameCtrl.dispose();
      codeCtrl.dispose();
      descCtrl.dispose();
    }
  }

  Future<void> _deleteRole(String roleId, String roleName, bool isSystem) async {
    if (isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sistem rolleri silinemez'), backgroundColor: ScadaColors.amber));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        title: Text('Rolu Sil', style: TextStyle(color: context.scada.textPrimary)),
        content: Text('"$roleName" rolu silinecek. Emin misiniz?', style: TextStyle(color: context.scada.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: TextStyle(color: context.scada.textDim))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(authDioProvider);
      await dio.delete('/roles/$roleId');
      await _loadRoles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red));
      }
    }
  }

  void _showPermissionMatrix(Map<String, dynamic> role) {
    final permissions = (role['permissions'] as List).cast<Map<String, dynamic>>();
    final permSet = <String>{};
    for (final p in permissions) {
      permSet.add('${p['resource']}:${p['action']}');
    }

    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.scada.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.shield, size: 18, color: ScadaColors.cyan),
                const SizedBox(width: 8),
                Expanded(child: Text('${role['name']} — Izinler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary))),
                if (role['is_system'] == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: ScadaColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Sistem', style: TextStyle(fontSize: 9, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: saving ? null : () async {
                    setSheetState(() => saving = true);
                    await _savePermissions(role['id'], permSet);
                    setSheetState(() => saving = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 16),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    // Baslik satiri
                    Row(children: [
                      SizedBox(width: 90, child: Text('Kaynak', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary))),
                      ..._actions.map((a) => Expanded(
                        child: Center(child: Text(_actionLabel(a), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.scada.textSecondary))),
                      )),
                    ]),
                    const Divider(),
                    // Kaynak satırlari — tiklanabilir checkbox
                    ..._resources.map((resource) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        SizedBox(width: 90, child: Text(_resourceLabels[resource] ?? resource, style: TextStyle(fontSize: 11, color: context.scada.textPrimary))),
                        ..._actions.map((action) {
                          final key = '$resource:$action';
                          final hasPermission = permSet.contains(key);
                          return Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    if (hasPermission) {
                                      permSet.remove(key);
                                    } else {
                                      permSet.add(key);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: hasPermission ? ScadaColors.green.withValues(alpha: 0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: hasPermission ? ScadaColors.green : context.scada.textDim.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: hasPermission
                                      ? const Icon(Icons.check, size: 16, color: ScadaColors.green)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ]),
                    )),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'view': return 'Goruntule';
      case 'create': return 'Olustur';
      case 'edit': return 'Duzenle';
      case 'delete': return 'Sil';
      case 'approve': return 'Onayla';
      default: return action;
    }
  }

  Future<void> _savePermissions(String roleId, Set<String> permSet) async {
    try {
      final dio = ref.read(authDioProvider);
      final permissions = permSet.map((key) {
        final parts = key.split(':');
        return {'resource': parts[0], 'action': parts[1]};
      }).toList();

      await dio.put('/roles/$roleId/permissions', data: {'permissions': permissions});
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izinler kaydedildi'), backgroundColor: ScadaColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red),
        );
      }
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
              color: ScadaColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.shield, color: ScadaColors.cyan, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Rol Yonetimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: ScadaColors.cyan, size: 22),
            onPressed: _createRole,
            tooltip: 'Yeni Rol',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _loadRoles, child: const Text('Tekrar Dene')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadRoles,
                  color: ScadaColors.cyan,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // Seed butonu (roller bossa)
                      if (_roles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.scada.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ScadaColors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Column(children: [
                            Text('Henuz rol tanimlanmamis', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _seedDefaults,
                              icon: const Icon(Icons.auto_fix_high, size: 16),
                              label: const Text('Varsayilan Rolleri Olustur'),
                              style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.amber),
                            ),
                          ]),
                        ),

                      // Rol listesi
                      ..._roles.map((role) => _buildRoleCard(role)),
                    ],
                  ),
                ),
    );
  }

  Future<void> _seedDefaults() async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.post('/roles/seed-defaults');
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Varsayilan roller olusturuldu'), backgroundColor: ScadaColors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.getMessage(e)), backgroundColor: ScadaColors.red));
      }
    }
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isSystem = role['is_system'] == true;
    final permCount = (role['permissions'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSystem ? ScadaColors.amber.withValues(alpha: 0.3) : context.scada.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isSystem ? ScadaColors.amber : ScadaColors.cyan).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isSystem ? Icons.verified_user : Icons.person, color: isSystem ? ScadaColors.amber : ScadaColors.cyan, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(role['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
            if (isSystem) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: ScadaColors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
                child: const Text('Sistem', style: TextStyle(fontSize: 8, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(role['description'] ?? '', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          Text('$permCount izin', style: TextStyle(fontSize: 9, color: context.scada.textSecondary)),
        ])),
        IconButton(
          icon: const Icon(Icons.grid_view, size: 18, color: ScadaColors.cyan),
          onPressed: () => _showPermissionMatrix(role),
          tooltip: 'Izin Matrisi',
        ),
        if (!isSystem)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: ScadaColors.red),
            onPressed: () => _deleteRole(role['id'], role['name'], isSystem),
            tooltip: 'Sil',
          ),
      ]),
    );
  }
}
