import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';

class ModuleDetailScreen extends ConsumerStatefulWidget {
  const ModuleDetailScreen({super.key});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final moduleId = ModalRoute.of(context)?.settings.arguments as String?;
      if (moduleId != null) {
        Future.microtask(() {
          ref.read(trainingProvider.notifier).loadModuleDetail(moduleId);
          final auth = ref.read(authProvider);
          if (auth.user != null) {
            ref.read(trainingProvider.notifier).startModule(auth.user!.id, moduleId);
          }
        });
      }
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);
    final module = training.selectedModule;

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          module?.title ?? 'Modul Detayi',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : module == null
              ? const Center(child: Text('Modul bulunamadi', style: TextStyle(color: ScadaColors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Module info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ScadaColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ScadaColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ScadaColors.cyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              module.moduleType == 'video' ? Icons.play_circle_fill : Icons.menu_book,
                              color: ScadaColors.cyan, size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(module.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                            if (module.description != null)
                              Text(module.description!, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                          ])),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.category, size: 12, color: ScadaColors.textDim),
                          const SizedBox(width: 4),
                          Text(module.typeText, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined, size: 12, color: ScadaColors.textDim),
                          const SizedBox(width: 4),
                          Text('${module.estimatedMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                        ]),
                      ]),
                    ),

                    // Contents
                    if (module.contents != null && module.contents!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        const Icon(Icons.article, size: 14, color: ScadaColors.textDim),
                        const SizedBox(width: 6),
                        Text('ICERIKLER (${module.contents!.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 12),
                      ...module.contents!.map((content) => _buildContentCard(content)),
                    ],

                    // Quizzes
                    if (module.quizzes != null && module.quizzes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        const Icon(Icons.quiz, size: 14, color: ScadaColors.textDim),
                        const SizedBox(width: 6),
                        Text('QUIZLER (${module.quizzes!.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 12),
                      ...module.quizzes!.map((quiz) => _buildQuizCard(quiz)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildContentCard(content) {
    final typeIcon = content.contentType == 'text'
        ? Icons.article
        : content.contentType == 'video'
            ? Icons.play_circle
            : content.contentType == 'image'
                ? Icons.image
                : content.contentType == 'checklist'
                    ? Icons.checklist
                    : Icons.insert_drive_file;
    final typeColor = content.contentType == 'text'
        ? ScadaColors.cyan
        : content.contentType == 'checklist'
            ? ScadaColors.green
            : ScadaColors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(typeIcon, color: typeColor, size: 20),
        title: Text(content.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
        iconColor: ScadaColors.textDim,
        collapsedIconColor: ScadaColors.textDim,
        children: [
          if (content.body != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScadaColors.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                content.body!,
                style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.green.withOpacity(0.3)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ScadaColors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.quiz, color: ScadaColors.green, size: 20),
        ),
        title: Text(quiz.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
        subtitle: Row(children: [
          if (quiz.timeLimitMinutes != null) ...[
            Icon(Icons.timer, size: 11, color: ScadaColors.textDim),
            const SizedBox(width: 3),
            Text('${quiz.timeLimitMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
            const SizedBox(width: 8),
          ],
          Text('Gecme: %${quiz.passingScore}', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          const SizedBox(width: 8),
          Text('${quiz.maxAttempts} deneme', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
        ]),
        trailing: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/quiz', arguments: quiz.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: ScadaColors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Basla', style: TextStyle(fontSize: 11, color: Colors.white)),
        ),
      ),
    );
  }
}
