import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/training.dart';
import '../../widgets/acknowledgment_dialog.dart';
import '../../widgets/content_viewer.dart';

class ModuleDetailScreen extends ConsumerStatefulWidget {
  const ModuleDetailScreen({super.key});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  bool _loaded = false;
  TrainingAcknowledgment? _acknowledgment;
  bool _checkingAck = true;
  String? _routeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? moduleId;
      if (args is Map<String, dynamic>) {
        moduleId = args['moduleId'] as String?;
        _routeId = args['routeId'] as String?;
      } else if (args is String) {
        moduleId = args;
      }
      if (moduleId != null) {
        Future.microtask(() async {
          ref.read(trainingProvider.notifier).loadModuleDetail(moduleId!);
          final auth = ref.read(authProvider);
          if (auth.user != null) {
            ref.read(trainingProvider.notifier).startModule(auth.user!.id, moduleId);
            final ack = await ref.read(trainingProvider.notifier).checkModuleAcknowledgment(auth.user!.id, moduleId);
            if (mounted) setState(() { _acknowledgment = ack; _checkingAck = false; });
          } else {
            if (mounted) setState(() => _checkingAck = false);
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                              color: ScadaColors.cyan.withValues(alpha: 0.12),
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

                    // Egitim Onayi
                    const SizedBox(height: 24),
                    if (!_checkingAck) ...[
                      if (_acknowledgment != null)
                        _buildAcknowledgedBanner()
                      else
                        _buildAcknowledgeButton(module),
                    ],
                  ],
                ),
    );
  }

  Widget _buildContentCard(ModuleContent content) {
    final typeIcon = switch (content.contentType) {
      'text' => Icons.article,
      'pdf' => Icons.picture_as_pdf,
      'image' => Icons.image,
      'checklist' => Icons.checklist,
      _ => Icons.insert_drive_file,
    };
    final typeColor = switch (content.contentType) {
      'text' => ScadaColors.cyan,
      'pdf' => ScadaColors.red,
      'image' => ScadaColors.amber,
      'checklist' => ScadaColors.green,
      _ => ScadaColors.textDim,
    };

    // PDF ve resim icin ExpansionTile yerine direkt gosterim
    final isMediaContent = content.contentType == 'pdf' || content.contentType == 'image';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: isMediaContent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baslik satiri
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(children: [
                    Icon(typeIcon, color: typeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(content.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                    ),
                  ]),
                ),
                // Icerik
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: ContentViewer(content: content),
                ),
              ],
            )
          : ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Icon(typeIcon, color: typeColor, size: 20),
              title: Text(content.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
              iconColor: ScadaColors.textDim,
              collapsedIconColor: ScadaColors.textDim,
              children: [
                ContentViewer(content: content),
              ],
            ),
    );
  }

  Widget _buildAcknowledgedBanner() {
    final ackDate = _acknowledgment!.acknowledgedAt;
    final formatted = ackDate.length >= 10 ? ackDate.substring(0, 10) : ackDate;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScadaColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: ScadaColors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Egitim Onaylandi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.green)),
          Text('Onay tarihi: $formatted', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _buildAcknowledgeButton(TrainingModule module) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final routeId = _routeId ?? module.routeId;
          final result = await AcknowledgmentDialog.show(
            context,
            moduleId: module.id,
            routeId: routeId,
            moduleTitle: module.title,
          );
          if (result == true) {
            final auth = ref.read(authProvider);
            if (auth.user != null) {
              final ack = await ref.read(trainingProvider.notifier).checkModuleAcknowledgment(auth.user!.id, module.id);
              setState(() => _acknowledgment = ack);
            }
          }
        },
        icon: const Icon(Icons.verified_user, size: 18),
        label: const Text('Egitimi Onayla', style: TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ScadaColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildQuizCard(quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ScadaColors.green.withValues(alpha: 0.12),
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
