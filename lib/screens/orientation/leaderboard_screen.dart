import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/turkish_string.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/scada_app_bar.dart';
import '../../widgets/section_header.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final department = ref.read(authProvider).user?.department ?? 'teknik';
      ref.read(leaderboardProvider.notifier).loadLeaderboard(department);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.read(authProvider).user?.id;
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: const ScadaAppBar(
        title: 'Siralama',
        titleIcon: Icons.leaderboard,
        titleIconColor: ScadaColors.amber,
      ),
      body: leaderboard.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : leaderboard.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(leaderboard.error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        final department = ref.read(authProvider).user?.department ?? 'teknik';
                        ref.read(leaderboardProvider.notifier).loadLeaderboard(department);
                      },
                      child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.amber)),
                    ),
                  ]),
                )
              : leaderboard.entries.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.group_off, size: 48, color: context.scada.textDim),
                        const SizedBox(height: 12),
                        Text('Siralama verisi bulunamadi', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: ScadaColors.amber,
                      onRefresh: () async {
                        final department = ref.read(authProvider).user?.department ?? 'teknik';
                        await ref.read(leaderboardProvider.notifier).loadLeaderboard(department);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        children: [
                          if (leaderboard.entries.length >= 3) ...[
                            _buildPodium(leaderboard.entries),
                            const SizedBox(height: 20),
                          ],
                          const SectionHeader(icon: Icons.format_list_numbered, title: 'DEPARTMAN SIRALAMASI'),
                          const SizedBox(height: 12),
                          ...List.generate(leaderboard.entries.length, (index) {
                            final entry = leaderboard.entries[index];
                            final isCurrentUser = entry.userId == currentUserId;
                            return _buildRankCard(index + 1, entry, isCurrentUser);
                          }),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.scada.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entries.length > 1) _buildPodiumItem(entries[1], 2, 80),
          _buildPodiumItem(entries[0], 1, 100),
          if (entries.length > 2) _buildPodiumItem(entries[2], 3, 64),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double height) {
    final color = rank == 1 ? ScadaColors.amber : rank == 2 ? context.scada.textSecondary : ScadaColors.orange;
    final icon = rank == 1 ? Icons.emoji_events : Icons.military_tech;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: rank == 1 ? 28 : 22),
        const SizedBox(height: 4),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(child: Text(
            entry.userName.isNotEmpty ? turkishUpperCase(entry.userName[0]) : '?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
          )),
        ),
        const SizedBox(height: 6),
        Text(
          entry.userName.length > 10 ? '${entry.userName.substring(0, 10)}...' : entry.userName,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text('%${entry.completionPercent.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text('#$rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color))),
        ),
      ],
    );
  }

  Widget _buildRankCard(int rank, LeaderboardEntry entry, bool isCurrentUser) {
    final progressColor = entry.completionPercent >= 80
        ? ScadaColors.green
        : entry.completionPercent >= 40
            ? ScadaColors.amber
            : ScadaColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? ScadaColors.cyan.withValues(alpha: 0.06) : context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser ? ScadaColors.cyan.withValues(alpha: 0.4) : context.scada.border,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: rank <= 3 ? ScadaColors.amber : context.scada.textSecondary,
            ),
          ),
        ),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(
            entry.userName.isNotEmpty ? turkishUpperCase(entry.userName[0]) : '?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: progressColor),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(
                entry.userName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCurrentUser ? ScadaColors.cyan : context.scada.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              )),
              if (isCurrentUser) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('Sen', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: ScadaColors.cyan)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${entry.completedModules}/${entry.totalModules} modül', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          ]),
        ),
        Text('%${entry.completionPercent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor)),
      ]),
    );
  }
}
