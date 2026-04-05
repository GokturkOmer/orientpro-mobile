import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/micro_learning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/micro_learning.dart';

class MicroQuizResultScreen extends ConsumerWidget {
  final MicroQuizResult result;

  const MicroQuizResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            // Sonuç ikonu
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: result.passed
                    ? ScadaColors.green.withValues(alpha: 0.15)
                    : ScadaColors.amber.withValues(alpha: 0.15),
              ),
              child: Icon(
                result.passed ? Icons.celebration : Icons.lightbulb_outline,
                size: 40,
                color: result.passed ? ScadaColors.green : ScadaColors.amber,
              ),
            ),
            const SizedBox(height: 24),

            // Baslik
            Text(
              result.passed ? 'Tebrikler!' : 'Neredeyse!',
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: context.scada.textPrimary),
            ),
            const SizedBox(height: 12),

            // Mesaj
            Text(
              result.encouragement,
              style: TextStyle(fontSize: 15, color: context.scada.textDim, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Skor karti
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.scada.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildScoreStat(context, '${result.correctCount}/${result.totalQuestions}', 'Dogru'),
                Container(width: 1, height: 40, color: context.scada.textDim.withValues(alpha: 0.2)),
                _buildScoreStat(context, '%${result.percent.toInt()}', 'Başarı'),
              ]),
            ),
            const SizedBox(height: 16),

            // Siradaki bilgi
            if (result.passed && result.routeCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScadaColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Text('🎓', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Tum rota tamamlandı! Sertifikan hazir.',
                      style: TextStyle(fontSize: 14, color: ScadaColors.green, fontWeight: FontWeight.w600)),
                  ),
                ]),
              )
            else if (result.passed && result.nextModuleTitle != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScadaColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Text('➡️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Siradaki konu: ${result.nextModuleTitle}${result.mode == "onboarding" ? "" : " (yöneticiniz atayacak)"}',
                      style: TextStyle(fontSize: 14, color: context.scada.textPrimary)),
                  ),
                ]),
              )
            else if (!result.passed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScadaColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Text('📖', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(result.mode == 'manager'
                        ? 'Yarin bu konuyu farkli bir acidan tekrar goreceksin.'
                        : 'Gelecek hafta bu konuyu farkli bir acidan tekrar goreceksin.',
                      style: TextStyle(fontSize: 14, color: context.scada.textPrimary)),
                  ),
                ]),
              ),

            const Spacer(),

            // Devam butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(microLearningProvider.notifier).clearQuizResult();
                  // Yeni atama varsa hemen gösterilsin
                  final auth = ref.read(authProvider);
                  if (auth.user != null) {
                    ref.read(microLearningProvider.notifier).loadToday(auth.user!.id);
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/orientation-dashboard', (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(result.passed ? 'Devam Et' : 'Tamam'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildScoreStat(BuildContext context, String value, String label) {
    return Column(children: [
      Text(value, style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800, color: context.scada.textPrimary)),
      Text(label, style: TextStyle(fontSize: 12, color: context.scada.textDim)),
    ]);
  }
}
