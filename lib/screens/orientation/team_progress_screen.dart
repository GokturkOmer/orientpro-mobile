import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/turkish_string.dart';
import '../../core/auth/role_helper.dart';
import '../../models/training.dart';

class TeamProgressScreen extends ConsumerStatefulWidget {
  const TeamProgressScreen({super.key});

  @override
  ConsumerState<TeamProgressScreen> createState() => _TeamProgressScreenState();
}

class _TeamProgressScreenState extends ConsumerState<TeamProgressScreen> {
  List<TeamMemberProgress> _team = [];
  bool _loading = true;
  bool _unauthorized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = ref.read(authProvider);
      // Supervisor kontrolu: sadece mudur ve sef roller ekip verisini gorebilir
      if (!RoleHelper.isSupervisor(auth.user?.role)) {
        if (mounted) setState(() { _unauthorized = true; _loading = false; });
        return;
      }
      if (auth.user?.department != null) {
        final team = await ref.read(trainingProvider.notifier).loadTeamProgress(auth.user!.department!);
        if (mounted) setState(() { _team = team; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              color: ScadaColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.group, color: ScadaColors.red, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('Ekip Eğitim Takibi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : _unauthorized
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock, size: 48, color: ScadaColors.textDim),
                  const SizedBox(height: 12),
                  const Text('Bu sayfaya erişim yetkiniz yok', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Sadece mudur ve sef roller ekip takibini gorebilir', style: TextStyle(color: ScadaColors.textDim, fontSize: 11)),
                ]))
          : _team.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.group_off, size: 48, color: ScadaColors.textDim),
                  const SizedBox(height: 12),
                  const Text('Departmaninizda henuz personel yok', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _team.length,
                  itemBuilder: (context, index) => _buildMemberCard(_team[index]),
                ),
    );
  }

  Widget _buildMemberCard(TeamMemberProgress member) {
    final progressColor = member.completionPercent >= 80
        ? ScadaColors.green
        : member.completionPercent >= 40
            ? ScadaColors.amber
            : ScadaColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text(
              member.userName.isNotEmpty ? turkishUpperCase(member.userName[0]) : '?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            if (member.department != null)
              Text(member.department!, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('%${member.completionPercent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: progressColor)),
            Text('tamamlama', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
          ]),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: member.completionPercent / 100,
            minHeight: 6,
            backgroundColor: ScadaColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.verified_user, size: 12, color: ScadaColors.textDim),
          const SizedBox(width: 4),
          Text('${member.acknowledgedCount}/${member.totalRequired} onay', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          const Spacer(),
          if (member.lastActivity != null) ...[
            const Icon(Icons.access_time, size: 12, color: ScadaColors.textDim),
            const SizedBox(width: 4),
            Text('Son: ${_formatDate(member.lastActivity!)}', style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
          ],
        ]),
      ]),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
