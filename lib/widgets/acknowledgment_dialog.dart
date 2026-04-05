import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/training_provider.dart';

/// Eğitim onay dialog'u - çalışan modulu tamamladiktan sonra
/// "Bu eğitimi okudum, anladim ve uygulamayi taahhut ediyorum" diye onaylar.
class AcknowledgmentDialog extends ConsumerStatefulWidget {
  final String moduleId;
  final String routeId;
  final String moduleTitle;

  const AcknowledgmentDialog({
    super.key,
    required this.moduleId,
    required this.routeId,
    required this.moduleTitle,
  });

  static Future<bool?> show(BuildContext context, {
    required String moduleId,
    required String routeId,
    required String moduleTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AcknowledgmentDialog(
        moduleId: moduleId,
        routeId: routeId,
        moduleTitle: moduleTitle,
      ),
    );
  }

  @override
  ConsumerState<AcknowledgmentDialog> createState() => _AcknowledgmentDialogState();
}

class _AcknowledgmentDialogState extends ConsumerState<AcknowledgmentDialog> {
  bool _confirmed = false;
  bool _submitting = false;

  static const String _acknowledgmentText =
      'Bu eğitimi okudum, anladim ve uygulamayi taahhut ediyorum.';

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    setState(() => _submitting = true);

    final success = await ref.read(trainingProvider.notifier).submitAcknowledgment(
      auth.user!.id,
      widget.moduleId,
      widget.routeId,
      _acknowledgmentText,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onay gonderilemedi'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ScadaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ScadaColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user, color: ScadaColors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Eğitim Onayi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                Text(widget.moduleTitle, style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),

            const SizedBox(height: 20),

            // Onay metni
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ScadaColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScadaColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Onay Metni', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                const Text(
                  _acknowledgmentText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ScadaColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.person_outline, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 6),
                  Text(auth.user?.fullName ?? '', style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: ScadaColors.textDim),
                  const SizedBox(width: 4),
                  Text(
                    _formatNow(),
                    style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
                  ),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Checkbox
            InkWell(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Row(children: [
                SizedBox(
                  width: 24, height: 24,
                  child: Checkbox(
                    value: _confirmed,
                    onChanged: (v) => setState(() => _confirmed = v ?? false),
                    activeColor: ScadaColors.green,
                    side: const BorderSide(color: ScadaColors.textDim),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text(
                  'Yukaridaki metni okudum ve kabul ediyorum',
                  style: TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                )),
              ]),
            ),

            const SizedBox(height: 20),

            // Butonlar
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ScadaColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _confirmed && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.green,
                    disabledBackgroundColor: ScadaColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
