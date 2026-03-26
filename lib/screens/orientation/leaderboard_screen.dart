import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/scada_app_bar.dart';
import '../../widgets/section_header.dart';

class _LeaderboardEntry {
  final String userId;
  final String userName;
  final String? department;
  final double completionPercent;
  final int completedModules;
  final int totalModules;

  _LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.department,
    required this.completionPercent,
    required this.completedModules,
    required this.totalModules,
  });

  factory _LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return _LeaderboardEntry(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Bilinmeyen',
      department: json['department'],
      completionPercent: (json['completion_percent'] ?? json['completionPercent'] ?? 0).toDouble(),
      completedModules: json['completed_modules'] ?? json['completedModules'] ?? 0,
      totalModules: json['total_modules'] ?? json['totalModules'] ?? 0,
    );
  }
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<_LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final auth = ref.read(authProvider);
      final department = auth.user?.department ?? 'teknik';
      final response = await dio.get('/training/team-progress/$department');
      final data = response.data as List;
      final entries = data.map((d) => _LeaderboardEntry.fromJson(d)).toList();
      // Sort by completion percent descending
      entries.sort((a, b) => b.completionPercent.compareTo(a.completionPercent));
      // Take top 10
      setState(() {
        _entries = entries.take(10).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.response?.data?['detail'] ?? 'Siralama yuklenemedi';
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Beklenmeyen hata'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.read(authProvider).user?.id;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: const ScadaAppBar(
        title: 'Siralama',
        titleIcon: Icons.leaderboard,
        titleIconColor: ScadaColors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadLeaderboard, child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.amber))),
                  ]),
                )
              : _entries.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.group_off, size: 48, color: context.scada.textDim),
                        const SizedBox(height: 12),
                        Text('Siralama verisi bulunamadi', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: ScadaColors.amber,
                      onRefresh: _loadLeaderboard,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        children: [
                          // Top 3 podium
                          if (_entries.length >= 3) ...[
                            _buildPodium(),
                            const SizedBox(height: 20),
                          ],

                          // Section header
                          const SectionHeader(icon: Icons.format_list_numbered, title: 'DEPARTMAN SIRALAMASI'),
                          const SizedBox(height: 12),

                          // Full list
                          ...List.generate(_entries.length, (index) {
                            final entry = _entries[index];
                            final isCurrentUser = entry.userId == currentUserId;
                            return _buildRankCard(index + 1, entry, isCurrentUser);
                          }),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPodium() {
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
          if (_entries.length > 1) _buildPodiumItem(_entries[1], 2, 80),
          _buildPodiumItem(_entries[0], 1, 100),
          if (_entries.length > 2) _buildPodiumItem(_entries[2], 3, 64),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(_LeaderboardEntry entry, int rank, double height) {
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
            entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
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

  Widget _buildRankCard(int rank, _LeaderboardEntry entry, bool isCurrentUser) {
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
        // Rank number
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

        // Avatar
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(
            entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: progressColor),
          )),
        ),
        const SizedBox(width: 10),

        // Name
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
            Text('${entry.completedModules}/${entry.totalModules} modul', style: TextStyle(fontSize: 10, color: context.scada.textDim)),
          ]),
        ),

        // Percentage
        Text('%${entry.completionPercent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor)),
      ]),
    );
  }
}
