import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/micro_learning_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/document_picker_dialog.dart';

class MicroLearningAssignScreen extends ConsumerStatefulWidget {
  const MicroLearningAssignScreen({super.key});

  @override
  ConsumerState<MicroLearningAssignScreen> createState() => _MicroLearningAssignScreenState();
}

class _MicroLearningAssignScreenState extends ConsumerState<MicroLearningAssignScreen> {
  // Adim takibi
  int _step = 0; // 0=modul sec, 1=calisan sec, 2=vardiya sec, 3=onayla

  // Secimler
  String? _selectedRouteId;
  final Set<String> _selectedModuleIds = {};
  final Set<String> _selectedUserIds = {};
  String _selectedShift = 'A';
  String? _selectedDepartment;
  bool _selectAllUsers = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(trainingProvider.notifier).loadDepartments();
      ref.read(trainingProvider.notifier).loadRoutes();
      ref.read(adminProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _stepTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text('${_step + 1}/4', style: TextStyle(fontSize: 13, color: context.scada.textDim)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_step + 1) / 4,
          backgroundColor: context.scada.border,
          color: ScadaColors.cyan,
          minHeight: 3,
        ),
        Expanded(
          child: _step == 0
              ? _buildModuleSelection()
              : _step == 1
                  ? _buildUserSelection()
                  : _step == 2
                      ? _buildShiftSelection()
                      : _buildConfirmation(),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Modul Sec';
      case 1: return 'Calisan Sec';
      case 2: return 'Vardiya Sec';
      case 3: return 'Onayla';
      default: return '';
    }
  }

  // ── ADIM 1: MODUL SEC ──

  Future<void> _showGenerateFromDocumentFlow() async {
    final doc = await DocumentPickerDialog.show(context);
    if (doc == null || !mounted) return;

    // Gun sayisi sec
    int dayCount = 5;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: context.scada.card,
          title: Text('Drip Kartlari Olustur', style: TextStyle(color: context.scada.textPrimary, fontSize: 15)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('"${doc['title']}" dokumanindan mikro-ogrenme kartlari olusturulacak.',
                style: TextStyle(color: context.scada.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            Text('Gun Sayisi', style: TextStyle(color: context.scada.textDim, fontSize: 11)),
            Slider(
              value: dayCount.toDouble(), min: 3, max: 7, divisions: 4,
              label: '$dayCount gun',
              activeColor: ScadaColors.green,
              onChanged: (v) => setDlgState(() => dayCount = v.round()),
            ),
            Text('$dayCount gun x 3 kart = ${dayCount * 3} kart + quiz',
                style: TextStyle(color: context.scada.textSecondary, fontSize: 11)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: TextStyle(color: context.scada.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.green),
              child: const Text('Olustur', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Modul secimi gerekli — once rota/modul sec
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oncelikle bir rota ve modul secin, ardindan kartlar bu module olusturulacak.'),
        backgroundColor: ScadaColors.cyan,
      ),
    );
    // TODO: Ileride otomatik modul olusturma akisi eklenebilir
  }

  Widget _buildModuleSelection() {
    final training = ref.watch(trainingProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Dokumandan Olustur butonu
        InkWell(
          onTap: _showGenerateFromDocumentFlow,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ScadaColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: ScadaColors.green, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dokumandan Olustur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.green)),
                const SizedBox(height: 2),
                Text('Havuzdaki bir PDF den otomatik drip kartlari + quiz olustur',
                    style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: ScadaColors.green, size: 14),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: context.scada.border),
        const SizedBox(height: 12),

        // Rota filtresi
        Text('Egitim Rotasi', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.scada.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.scada.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRouteId,
              hint: Text('Rota secin...', style: TextStyle(color: context.scada.textDim, fontSize: 14)),
              isExpanded: true,
              dropdownColor: context.scada.surface,
              items: training.routes.map((r) => DropdownMenuItem(
                value: r.id,
                child: Text(r.title, style: TextStyle(color: context.scada.textPrimary, fontSize: 14)),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedRouteId = v;
                  _selectedModuleIds.clear();
                });
                if (v != null) {
                  ref.read(trainingProvider.notifier).loadRouteDetail(v);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Moduller
        if (_selectedRouteId != null && training.selectedRoute != null) ...[
          Text('Moduller', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
          const SizedBox(height: 6),
          ...(training.selectedRoute!.modules ?? []).map((m) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: context.scada.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedModuleIds.contains(m.id)
                    ? ScadaColors.cyan.withValues(alpha: 0.5)
                    : context.scada.border,
              ),
            ),
            child: CheckboxListTile(
              value: _selectedModuleIds.contains(m.id),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedModuleIds.add(m.id);
                  } else {
                    _selectedModuleIds.remove(m.id);
                  }
                });
              },
              title: Text(m.title, style: TextStyle(fontSize: 14, color: context.scada.textPrimary)),
              subtitle: Text('${m.estimatedMinutes} dk', style: TextStyle(fontSize: 11, color: context.scada.textDim)),
              activeColor: ScadaColors.cyan,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          )),
        ],
      ],
    );
  }

  // ── ADIM 2: CALISAN SEC ──

  Widget _buildUserSelection() {
    final admin = ref.watch(adminProvider);
    final users = admin.users.where((u) => u.role != 'admin' && u.isActive).toList();
    final departments = users.map((u) => u.department).whereType<String>().toSet().toList()..sort();

    final filtered = _selectedDepartment != null
        ? users.where((u) => u.department == _selectedDepartment).toList()
        : users;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Departman filtresi
        Text('Departman', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text('Tumu', style: TextStyle(fontSize: 12, color: _selectedDepartment == null ? Colors.white : context.scada.textPrimary)),
              selected: _selectedDepartment == null,
              selectedColor: ScadaColors.cyan,
              backgroundColor: context.scada.surface,
              onSelected: (_) => setState(() => _selectedDepartment = null),
            ),
            ...departments.map((d) => ChoiceChip(
              label: Text(d, style: TextStyle(fontSize: 12, color: _selectedDepartment == d ? Colors.white : context.scada.textPrimary)),
              selected: _selectedDepartment == d,
              selectedColor: ScadaColors.cyan,
              backgroundColor: context.scada.surface,
              onSelected: (_) => setState(() => _selectedDepartment = d),
            )),
          ],
        ),

        const SizedBox(height: 12),

        // Tumunu sec
        CheckboxListTile(
          value: _selectAllUsers,
          onChanged: (v) {
            setState(() {
              _selectAllUsers = v ?? false;
              if (_selectAllUsers) {
                _selectedUserIds.addAll(filtered.map((u) => u.id));
              } else {
                _selectedUserIds.clear();
              }
            });
          },
          title: Text('Tumunu Sec (${filtered.length} calisan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          activeColor: ScadaColors.cyan,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        const Divider(height: 1),

        // Calisan listesi
        ...filtered.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: context.scada.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedUserIds.contains(u.id)
                  ? ScadaColors.cyan.withValues(alpha: 0.5)
                  : context.scada.border,
            ),
          ),
          child: CheckboxListTile(
            value: _selectedUserIds.contains(u.id),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedUserIds.add(u.id);
                } else {
                  _selectedUserIds.remove(u.id);
                }
              });
            },
            title: Text(u.fullName, style: TextStyle(fontSize: 14, color: context.scada.textPrimary)),
            subtitle: Text('${u.department ?? "-"} / ${u.role}', style: TextStyle(fontSize: 11, color: context.scada.textDim)),
            activeColor: ScadaColors.cyan,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        )),
      ],
    );
  }

  // ── ADIM 3: VARDIYA SEC ──

  Widget _buildShiftSelection() {
    const shifts = [
      {'code': 'A', 'name': 'A Vardiyasi (06:00-14:00)', 'times': '06:30 / 10:00 / 13:30'},
      {'code': 'B', 'name': 'B Vardiyasi (14:00-22:00)', 'times': '14:30 / 18:00 / 21:30'},
      {'code': 'C', 'name': 'C Vardiyasi (22:00-06:00)', 'times': '22:30 / 02:00 / 05:30'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bildirim Saatleri', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
        const SizedBox(height: 4),
        Text('Sectiginiz vardiyaya gore gun icinde 3 bildirim gonderilecek.',
          style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
        const SizedBox(height: 16),
        ...shifts.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: context.scada.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedShift == s['code']
                  ? ScadaColors.cyan.withValues(alpha: 0.6)
                  : context.scada.border,
              width: _selectedShift == s['code'] ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            value: s['code']!,
            groupValue: _selectedShift,
            onChanged: (v) => setState(() => _selectedShift = v!),
            title: Text(s['name']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
            subtitle: Row(children: [
              Icon(Icons.notifications_outlined, size: 14, color: ScadaColors.cyan),
              const SizedBox(width: 4),
              Text(s['times']!, style: TextStyle(fontSize: 12, color: ScadaColors.cyan)),
            ]),
            activeColor: ScadaColors.cyan,
          ),
        )),
      ],
    );
  }

  // ── ADIM 4: ONAYLA ──

  Widget _buildConfirmation() {
    final training = ref.watch(trainingProvider);
    final admin = ref.watch(adminProvider);
    final micro = ref.watch(microLearningProvider);

    final selectedModules = (training.selectedRoute?.modules ?? [])
        .where((m) => _selectedModuleIds.contains(m.id)).toList();
    final selectedUsers = admin.users
        .where((u) => _selectedUserIds.contains(u.id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (micro.error != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: ScadaColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(micro.error!, style: const TextStyle(color: ScadaColors.red, fontSize: 13)),
          ),

        _buildSummaryCard('Moduller', '${selectedModules.length} modul',
          selectedModules.map((m) => m.title).join(', '), Icons.school),
        const SizedBox(height: 8),
        _buildSummaryCard('Calisanlar', '${selectedUsers.length} kisi',
          selectedUsers.map((u) => u.fullName).join(', '), Icons.people),
        const SizedBox(height: 8),
        _buildSummaryCard('Vardiya', '$_selectedShift Vardiyasi',
          _shiftTimesText, Icons.schedule),
      ],
    );
  }

  String get _shiftTimesText {
    switch (_selectedShift) {
      case 'A': return 'Bildirimler: 06:30, 10:00, 13:30';
      case 'B': return 'Bildirimler: 14:30, 18:00, 21:30';
      case 'C': return 'Bildirimler: 22:30, 02:00, 05:30';
      default: return '';
    }
  }

  Widget _buildSummaryCard(String title, String value, String detail, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Row(children: [
        Icon(icon, color: ScadaColors.cyan, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 11, color: context.scada.textDim)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          if (detail.isNotEmpty)
            Text(detail, style: TextStyle(fontSize: 12, color: context.scada.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ── ALT BAR ──

  Widget _buildBottomBar() {
    final micro = ref.watch(microLearningProvider);
    final canProceed = _step == 0
        ? _selectedModuleIds.isNotEmpty
        : _step == 1
            ? _selectedUserIds.isNotEmpty
            : true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.surface,
        border: Border(top: BorderSide(color: context.scada.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canProceed && !micro.isLoading ? _onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _step == 3 ? ScadaColors.green : ScadaColors.cyan,
              disabledBackgroundColor: context.scada.border,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: micro.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_step == 3 ? 'Mikro-Ogrenmeyi Baslat' : 'Devam', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  void _onNext() async {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      // Atama yap
      final success = await ref.read(microLearningProvider.notifier).assignModules(
        moduleIds: _selectedModuleIds.toList(),
        userIds: _selectedUserIds.toList(),
        routeId: _selectedRouteId,
        shiftType: _selectedShift,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikro-ogrenme atamasi basarili!'),
            backgroundColor: ScadaColors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
