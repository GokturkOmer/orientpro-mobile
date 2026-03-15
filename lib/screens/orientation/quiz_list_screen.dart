import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../models/training.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() {
        final auth = ref.read(authProvider);
        final notifier = ref.read(trainingProvider.notifier);
        notifier.loadDepartments();
        notifier.loadRoutes();
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

    // Departman filtreleme
    final allowedDepts = RoleHelper.visibleDepartments(userRole, userDept);

    // Route'lari filtrele (dept + teknik tag)
    var filteredRoutes = allowedDepts == null
        ? training.routes
        : training.routes.where((r) {
            final dept = training.departments.where((d) => d.id == r.departmentId);
            if (dept.isEmpty) return true;
            return allowedDepts.contains(dept.first.code);
          }).toList();

    // Teknik tag filtreleme
    final teknikTags = RoleHelper.visibleTeknikTags(userRole);
    if (teknikTags != null && teknikTags.isNotEmpty) {
      final teknikDeptIds = training.departments
          .where((d) => d.code == 'teknik')
          .map((d) => d.id)
          .toSet();
      filteredRoutes = filteredRoutes.where((r) {
        if (!teknikDeptIds.contains(r.departmentId)) return true;
        return RoleHelper.canSeeTeknikRoute(userRole, r.tags);
      }).toList();
    }

    // Tum quizleri topla: route → modules → quizzes
    final quizItems = <_QuizItem>[];
    for (final route in filteredRoutes) {
      if (route.modules == null) continue;
      final dept = training.departments.where((d) => d.id == route.departmentId);
      final deptName = dept.isNotEmpty ? dept.first.name : 'Genel';
      final deptCode = dept.isNotEmpty ? dept.first.code : 'GEN';
      for (final module in route.modules!) {
        if (module.quizzes == null) continue;
        for (final quiz in module.quizzes!) {
          if (!quiz.isActive) continue;
          quizItems.add(_QuizItem(
            quiz: quiz,
            routeTitle: route.title,
            moduleTitle: module.title,
            departmentName: deptName,
            departmentCode: deptCode,
          ));
        }
      }
    }

    // Departmana gore grupla
    final grouped = <String, List<_QuizItem>>{};
    for (final item in quizItems) {
      grouped.putIfAbsent(item.departmentName, () => []).add(item);
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
          : quizItems.isEmpty
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

  Widget _buildDepartmentGroup(String deptName, List<_QuizItem> items, List<QuizResult> results) {
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

  Widget _buildQuizCard(_QuizItem item, List<QuizResult> results) {
    // Son sonucu bul
    final quizResults = results.where((r) => r.quizId == item.quiz.id).toList();
    quizResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastResult = quizResults.isNotEmpty ? quizResults.first : null;

    // Durum
    final String statusText;
    final Color statusColor;
    final IconData statusIcon;
    if (lastResult == null) {
      statusText = 'Cozulmedi';
      statusColor = ScadaColors.textDim;
      statusIcon = Icons.radio_button_unchecked;
    } else if (lastResult.passed) {
      statusText = 'Gecti (%${lastResult.percent.toInt()})';
      statusColor = ScadaColors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Kaldi (%${lastResult.percent.toInt()})';
      statusColor = ScadaColors.red;
      statusIcon = Icons.cancel;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/quiz', arguments: item.quiz.id),
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
              child: Text(item.quiz.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            ),
            Icon(statusIcon, size: 18, color: statusColor),
            const SizedBox(width: 4),
            Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ]),
          const SizedBox(height: 6),

          // Rota > Modul bilgisi
          Text(
            '${item.routeTitle} > ${item.moduleTitle}',
            style: const TextStyle(fontSize: 10, color: ScadaColors.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Alt bilgi satirlari
          Row(children: [
            _buildInfoChip(Icons.help_outline, 'Gecme: %${item.quiz.passingScore}'),
            const SizedBox(width: 10),
            _buildInfoChip(Icons.repeat, 'Maks ${item.quiz.maxAttempts} deneme'),
            if (item.quiz.timeLimitMinutes != null) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.timer_outlined, '${item.quiz.timeLimitMinutes} dk'),
            ],
            if (quizResults.isNotEmpty) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.history, '${quizResults.length} deneme'),
            ],
          ]),

          // Aciklama
          if (item.quiz.description != null && item.quiz.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.quiz.description!, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
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
}

class _QuizItem {
  final Quiz quiz;
  final String routeTitle;
  final String moduleTitle;
  final String departmentName;
  final String departmentCode;

  _QuizItem({required this.quiz, required this.routeTitle, required this.moduleTitle, required this.departmentName, required this.departmentCode});
}
