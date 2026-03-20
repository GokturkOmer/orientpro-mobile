import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/training_provider.dart';

class _BadgeInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(TrainingState training) checkEarned;

  const _BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.checkEarned,
  });
}

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  static final List<_BadgeInfo> _badges = [
    _BadgeInfo(
      id: 'ilk_adim',
      name: 'Ilk Adim',
      description: 'Ilk egitim modulunu tamamla',
      icon: Icons.flag,
      color: ScadaColors.green,
      checkEarned: (t) => t.progress.any((p) => p.status == 'completed'),
    ),
    _BadgeInfo(
      id: 'quiz_ustasi',
      name: 'Quiz Ustasi',
      description: '5 quizi basariyla gec',
      icon: Icons.quiz,
      color: ScadaColors.cyan,
      checkEarned: (t) => (t.stats?.quizzesPassed ?? 0) >= 5,
    ),
    _BadgeInfo(
      id: 'hizli_ogrenci',
      name: 'Hizli Ogrenci',
      description: 'Bir modulu 10 dakikadan kisa surede tamamla',
      icon: Icons.bolt,
      color: ScadaColors.amber,
      checkEarned: (t) => t.progress.any((p) => p.status == 'completed' && p.timeSpentMinutes > 0 && p.timeSpentMinutes < 10),
    ),
    _BadgeInfo(
      id: 'tam_puan',
      name: 'Tam Puan',
      description: 'Bir quizden %100 al',
      icon: Icons.star,
      color: ScadaColors.orange,
      checkEarned: (t) => t.quizResults.any((r) => r.score == r.maxScore && r.maxScore > 0),
    ),
    _BadgeInfo(
      id: 'takim_oyuncusu',
      name: 'Takim Oyuncusu',
      description: 'Bir rotadaki tum modulleri tamamla',
      icon: Icons.group,
      color: ScadaColors.purple,
      checkEarned: (t) {
        if (t.routes.isEmpty) return false;
        for (final route in t.routes) {
          if (route.modules == null || route.modules!.isEmpty) continue;
          final moduleIds = route.modules!.map((m) => m.id).toSet();
          final completedIds = t.progress
              .where((p) => p.status == 'completed' && moduleIds.contains(p.moduleId))
              .map((p) => p.moduleId)
              .toSet();
          if (completedIds.length == moduleIds.length) return true;
        }
        return false;
      },
    ),
    _BadgeInfo(
      id: 'bilgi_kurdu',
      name: 'Bilgi Kurdu',
      description: '10 kutuphane dokumanini oku',
      icon: Icons.menu_book,
      color: ScadaColors.cyanDim,
      // Library reading is not tracked in training state, so this stays locked for now
      checkEarned: (t) => false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(trainingProvider);
    final earnedCount = _badges.where((b) => b.checkEarned(training)).length;

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
            child: const Icon(Icons.emoji_events, color: ScadaColors.purple, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Rozetler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ScadaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScadaColors.purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: ScadaColors.purple, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$earnedCount / ${_badges.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                const Text('Rozet kazanildi', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
              ])),
              SizedBox(
                width: 56, height: 56,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: _badges.isEmpty ? 0 : earnedCount / _badges.length,
                    strokeWidth: 5,
                    backgroundColor: ScadaColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(ScadaColors.purple),
                  ),
                  Text(
                    '%${(_badges.isEmpty ? 0 : earnedCount / _badges.length * 100).toInt()}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ScadaColors.purple),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Section header
          Row(children: [
            const Icon(Icons.military_tech, size: 14, color: ScadaColors.textDim),
            const SizedBox(width: 6),
            const Text('TUM ROZETLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),

          // Badges grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final earned = badge.checkEarned(training);
              return _buildBadgeCard(badge, earned);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(_BadgeInfo badge, bool earned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? ScadaColors.card : ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? badge.color.withValues(alpha: 0.4) : ScadaColors.border,
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: earned
                  ? badge.color.withValues(alpha: 0.15)
                  : ScadaColors.textDim.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: earned
                    ? badge.color.withValues(alpha: 0.3)
                    : ScadaColors.textDim.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              earned ? badge.icon : Icons.lock,
              color: earned ? badge.color : ScadaColors.textDim,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: earned ? ScadaColors.textPrimary : ScadaColors.textDim,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 9,
              color: earned ? ScadaColors.textSecondary : ScadaColors.textDim,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (earned) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Kazanildi', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: badge.color)),
            ),
          ],
        ],
      ),
    );
  }
}
