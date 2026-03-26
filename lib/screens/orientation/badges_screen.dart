import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/badge.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/scada_app_bar.dart';
import '../../widgets/section_header.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(badgeProvider.notifier).loadBadges();
      final result = await ref.read(badgeProvider.notifier).checkAndAward();
      if (result != null && result.newlyAwarded.isNotEmpty && mounted) {
        _showNewBadgesDialog(result.newlyAwarded);
      }
    });
  }

  void _showNewBadgesDialog(List<Map<String, dynamic>> badges) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.celebration, color: ScadaColors.amber, size: 24),
          const SizedBox(width: 8),
          Text('Yeni Rozet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badges.map((b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Text(b['badge_icon'] ?? '', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b['badge_name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                Text(_levelText(b['badge_level']), style: TextStyle(fontSize: 10, color: _levelColor(b['badge_level']))),
              ])),
            ]),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(badgeProvider.notifier).clearNewlyAwarded();
            },
            child: const Text('Harika!', style: TextStyle(color: ScadaColors.amber, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeState = ref.watch(badgeProvider);
    final earnedCodes = badgeState.earnedCodes;
    final earnedBadges = badgeState.catalog.where((b) => earnedCodes.contains(b.code)).toList();
    final lockedBadges = badgeState.catalog.where((b) => !earnedCodes.contains(b.code)).toList();
    final totalCount = badgeState.catalog.length;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: const ScadaAppBar(
        title: 'Rozetler',
        titleIcon: Icons.emoji_events,
        titleIconColor: ScadaColors.purple,
      ),
      body: badgeState.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.purple))
          : badgeState.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(badgeState.error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(badgeProvider.notifier).loadBadges(),
                      child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.purple)),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  color: ScadaColors.purple,
                  onRefresh: () async {
                    await ref.read(badgeProvider.notifier).loadBadges();
                    await ref.read(badgeProvider.notifier).checkAndAward();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // Summary card
                      _buildSummaryCard(earnedBadges.length, totalCount),
                      const SizedBox(height: 20),

                      // Kazanilan rozetler
                      if (earnedBadges.isNotEmpty) ...[
                        const SectionHeader(icon: Icons.verified, title: 'KAZANILAN ROZETLER'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10,
                          ),
                          itemCount: earnedBadges.length,
                          itemBuilder: (context, index) {
                            final badge = earnedBadges[index];
                            final earned = badgeState.earnedBadges.firstWhere((e) => e.badgeCode == badge.code);
                            return _buildBadgeCard(badge, true, earnedAt: earned.earnedAt);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Kilitli rozetler
                      if (lockedBadges.isNotEmpty) ...[
                        const SectionHeader(icon: Icons.lock_outline, title: 'KILITLI ROZETLER'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10,
                          ),
                          itemCount: lockedBadges.length,
                          itemBuilder: (context, index) {
                            return _buildBadgeCard(lockedBadges[index], false);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(int earned, int total) {
    final percent = total > 0 ? earned / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.scada.border),
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
          Text('$earned / $total', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
          Text('Rozet kazanildi', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
        ])),
        SizedBox(
          width: 56, height: 56,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: percent,
              strokeWidth: 5,
              backgroundColor: context.scada.border,
              valueColor: const AlwaysStoppedAnimation<Color>(ScadaColors.purple),
            ),
            Text(
              '%${(percent * 100).toInt()}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ScadaColors.purple),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBadgeCard(BadgeCatalogItem badge, bool earned, {String? earnedAt}) {
    final levelColor = _levelColor(badge.level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? context.scada.card : context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? levelColor.withValues(alpha: 0.4) : context.scada.border,
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
                  ? levelColor.withValues(alpha: 0.15)
                  : context.scada.textDim.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: earned
                    ? levelColor.withValues(alpha: 0.3)
                    : context.scada.textDim.withValues(alpha: 0.2),
              ),
            ),
            child: earned
                ? Text(badge.icon, style: const TextStyle(fontSize: 28))
                : Icon(Icons.lock, color: context.scada.textDim, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: earned ? context.scada.textPrimary : context.scada.textDim,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 9,
              color: earned ? context.scada.textSecondary : context.scada.textDim,
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
                color: levelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _levelText(badge.level),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: levelColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _levelColor(String? level) {
    switch (level) {
      case 'gold':
        return ScadaColors.amber;
      case 'silver':
        return ScadaColors.cyan;
      case 'bronze':
        return ScadaColors.orange;
      default:
        return ScadaColors.purple;
    }
  }

  String _levelText(String? level) {
    switch (level) {
      case 'gold':
        return 'Altin';
      case 'silver':
        return 'Gumus';
      case 'bronze':
        return 'Bronz';
      default:
        return 'Kazanildi';
    }
  }
}
