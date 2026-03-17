import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../models/training.dart';
import '../../core/utils/status_helper.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  bool _loaded = false;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() {
        final auth = ref.read(authProvider);
        final notifier = ref.read(trainingProvider.notifier);
        notifier.loadQuizzes();
        if (auth.user != null) {
          notifier.loadUserQuizResults(auth.user!.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);
    final userRole = auth.user?.role ?? '';
    final userDept = auth.user?.department;

    // RBAC: departman filtreleme
    final allowedDepts = RoleHelper.visibleDepartments(userRole, userDept);

    // Quizleri filtrele
    var quizzes = training.quizList.where((q) => q.isActive).toList();

    if (allowedDepts != null) {
      quizzes = quizzes.where((q) {
        if (q.departmentCode == null) return true;
        return allowedDepts.contains(q.departmentCode);
      }).toList();
    }

    // Teknik tag filtreleme
    final teknikTags = RoleHelper.visibleTeknikTags(userRole);
    if (teknikTags != null && teknikTags.isNotEmpty) {
      // Teknik departman quizleri icin ek filtreleme gerekirse burada yapilabilir
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      quizzes = quizzes.where((q) =>
        q.title.toLowerCase().contains(_searchQuery) ||
        (q.departmentName?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }

    // Departmana gore grupla
    final grouped = <String, List<QuizListItem>>{};
    for (final q in quizzes) {
      final deptName = q.departmentName ?? 'Genel';
      grouped.putIfAbsent(deptName, () => []).add(q);
    }

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quiz & Sinavlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.green))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Quiz ara...',
                    hintStyle: const TextStyle(color: ScadaColors.textDim, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: ScadaColors.textDim, size: 20),
                    filled: true,
                    fillColor: ScadaColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ScadaColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ScadaColors.border)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 13),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              Expanded(
                child: quizzes.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final deptName = grouped.keys.elementAt(index);
                          final items = grouped[deptName]!;
                          return _buildDepartmentGroup(deptName, items, training.quizResults);
                        },
                      ),
              ),
            ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.quiz_outlined, size: 48, color: ScadaColors.textDim),
        SizedBox(height: 12),
        Text('Henuz quiz bulunmuyor', style: TextStyle(fontSize: 14, color: ScadaColors.textSecondary)),
        SizedBox(height: 4),
        Text('Egitim rotalarina quiz eklendikce burada gorunecek', style: TextStyle(fontSize: 11, color: ScadaColors.textDim)),
      ]),
    );
  }

  Widget _buildDepartmentGroup(String deptName, List<QuizListItem> items, List<QuizResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                color: ScadaColors.cyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(deptName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
            const SizedBox(width: 8),
            Text('${items.length} quiz', style: const TextStyle(fontSize: 11, color: ScadaColors.textDim)),
          ]),
        ),
        ...items.map((item) => _buildQuizCard(item, results)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuizCard(QuizListItem item, List<QuizResult> results) {
    // Son sonucu bul
    final quizResults = results.where((r) => r.quizId == item.id).toList();
    quizResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastResult = quizResults.isNotEmpty ? quizResults.first : null;

    // Durum
    final qs = StatusHelper.quizStatus(
      passed: lastResult?.passed,
      percent: lastResult?.percent,
    );
    final statusText = qs.text;
    final statusColor = qs.color;
    final statusIcon = qs.icon;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/quiz', arguments: item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ScadaColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Baslik + durum
          Row(children: [
            Expanded(
              child: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            ),
            Icon(statusIcon, size: 18, color: statusColor),
            const SizedBox(width: 4),
            Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ]),
          const SizedBox(height: 6),

          // Rota > Modul bilgisi
          Text(
            '${item.routeTitle ?? ''} > ${item.moduleTitle ?? ''}',
            style: const TextStyle(fontSize: 10, color: ScadaColors.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Alt bilgi satirlari
          Row(children: [
            _buildDifficultyChip(item.passingScore),
            const SizedBox(width: 10),
            _buildInfoChip(Icons.repeat, 'Maks ${item.maxAttempts} deneme'),
            if (item.timeLimitMinutes != null) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.timer_outlined, '${item.timeLimitMinutes} dk'),
            ],
            if (quizResults.isNotEmpty) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.history, '${quizResults.length} deneme'),
            ],
          ]),

          // Aciklama
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description!, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: ScadaColors.textDim),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
    ]);
  }

  Widget _buildDifficultyChip(int passingScore) {
    final String label;
    final Color color;
    if (passingScore >= 80) {
      label = 'Zor';
      color = ScadaColors.red;
    } else if (passingScore >= 60) {
      label = 'Orta';
      color = ScadaColors.amber;
    } else {
      label = 'Kolay';
      color = ScadaColors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.signal_cellular_alt, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
