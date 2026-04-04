import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/shift_schedule_provider.dart';

class ShiftScheduleScreen extends ConsumerStatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  ConsumerState<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends ConsumerState<ShiftScheduleScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loaded) {
        _loaded = true;
        ref.read(shiftScheduleProvider.notifier).loadShifts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(shiftScheduleProvider);

    ref.listen<ShiftScheduleState>(shiftScheduleProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: ScadaColors.green),
        );
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: ScadaColors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule, color: ScadaColors.amber, size: 18),
          const SizedBox(width: 8),
          Text('Vardiya Ayarlari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
        ]),
      ),
      body: st.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : st.shifts.isEmpty
              ? Center(child: Text('Vardiya bulunamadi', style: TextStyle(color: context.scada.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: st.shifts.map((shift) => _ShiftCard(shift: shift)).toList(),
                  ),
                ),
    );
  }
}

// ── Tek Vardiya Karti ──

class _ShiftCard extends ConsumerStatefulWidget {
  final ShiftScheduleModel shift;
  const _ShiftCard({required this.shift});

  @override
  ConsumerState<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends ConsumerState<_ShiftCard> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TimeOfDay _break1;
  late TimeOfDay _break2;
  late TimeOfDay _break3;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _startTime = _parse(widget.shift.startTime);
    _endTime = _parse(widget.shift.endTime);
    _break1 = _parse(widget.shift.break1Time);
    _break2 = _parse(widget.shift.break2Time);
    _break3 = _parse(widget.shift.break3Time);
  }

  @override
  void didUpdateWidget(covariant _ShiftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shift.id != widget.shift.id) {
      _startTime = _parse(widget.shift.startTime);
      _endTime = _parse(widget.shift.endTime);
      _break1 = _parse(widget.shift.break1Time);
      _break2 = _parse(widget.shift.break2Time);
      _break3 = _parse(widget.shift.break3Time);
      _dirty = false;
    }
  }

  TimeOfDay _parse(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _fmtDisplay(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: ScadaColors.cyan,
              surface: context.scada.surface,
              onSurface: context.scada.textPrimary,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null && picked != current) {
      setState(() {
        onPicked(picked);
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    final data = {
      'start_time': _fmt(_startTime),
      'end_time': _fmt(_endTime),
      'break_1_time': _fmt(_break1),
      'break_2_time': _fmt(_break2),
      'break_3_time': _fmt(_break3),
    };
    final ok = await ref.read(shiftScheduleProvider.notifier).updateShift(widget.shift.id, data);
    if (ok) setState(() => _dirty = false);
  }

  static const _shiftNames = {'A': 'A Vardiyasi (Sabah)', 'B': 'B Vardiyasi (Aksam)', 'C': 'C Vardiyasi (Gece)'};
  static const _shiftColors = {'A': ScadaColors.cyan, 'B': ScadaColors.amber, 'C': ScadaColors.purple};

  @override
  Widget build(BuildContext context) {
    final color = _shiftColors[widget.shift.shiftType] ?? ScadaColors.cyan;
    final name = _shiftNames[widget.shift.shiftType] ?? widget.shift.shiftType;
    final isSaving = ref.watch(shiftScheduleProvider).savingShiftId == widget.shift.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Icon(Icons.schedule, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
            Text('${_fmtDisplay(_startTime)} - ${_fmtDisplay(_endTime)}',
                style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Mesai
            Row(children: [
              Expanded(child: _timeRow('Baslangic', _startTime, (t) => _startTime = t, color)),
              const SizedBox(width: 12),
              Expanded(child: _timeRow('Bitis', _endTime, (t) => _endTime = t, color)),
            ]),
            const SizedBox(height: 12),
            // Molalar
            _timeRow('1. Mola (Sabah)', _break1, (t) => _break1 = t, color),
            const SizedBox(height: 8),
            _timeRow('2. Mola (Ogle)', _break2, (t) => _break2 = t, color),
            const SizedBox(height: 8),
            _timeRow('3. Mola (Aksam)', _break3, (t) => _break3 = t, color),
            const SizedBox(height: 16),
            // Kaydet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dirty && !isSaving ? _save : null,
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: Text(isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dirty ? color : color.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _timeRow(String label, TimeOfDay value, ValueChanged<TimeOfDay> onChanged, Color color) {
    return InkWell(
      onTap: () => _pickTime(value, onChanged),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.scada.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.scada.border),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: context.scada.textSecondary))),
          Text(_fmtDisplay(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 14, color: context.scada.textDim),
        ]),
      ),
    );
  }
}
