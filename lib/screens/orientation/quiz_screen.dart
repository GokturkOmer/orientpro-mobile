import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/micro_learning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/acknowledgment_dialog.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _loaded = false;
  String? _quizId;
  // Mikro-ogrenme'den gelirse module + assignment bilgisi tasir
  String? _microModuleId;
  String? _microModuleTitle;
  String? _microRouteId;
  String? _microAssignmentId;
  final Map<int, int> _selectedAnswers = {};  // questionIndex -> selectedOptionIndex
  bool _submitted = false;
  bool? _passed;
  double _score = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        // Eski kullanim: sadece quizId
        _quizId = args;
      } else if (args is Map) {
        // Mikro-ogrenme: quizId + module bilgisi
        _quizId = args['quizId'] as String?;
        _microModuleId = args['moduleId'] as String?;
        _microModuleTitle = args['moduleTitle'] as String?;
        _microRouteId = args['routeId'] as String?;
        _microAssignmentId = args['assignmentId'] as String?;
      }
      if (_quizId != null) {
        Future.microtask(() {
          ref.read(trainingProvider.notifier).loadQuizQuestions(_quizId!);
        });
      }
      _loaded = true;
    }
  }

  void _submitQuiz() async {
    final questions = ref.read(trainingProvider).quizQuestions;
    if (questions.isEmpty) return;

    double totalScore = 0;
    double maxScore = 0;
    final answers = <String, dynamic>{};

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      maxScore += q.points;
      final selected = _selectedAnswers[i];
      if (selected != null) {
        final options = q.options ?? [];
        final selectedText = selected < options.length ? options[selected].toString() : '';
        // Backend correct_answer iki formatta olabilir:
        // 1) Index: "1", "2", "3" (seed data)
        // 2) Tam metin: "Dogru cevap metni" (AI quiz)
        final isCorrect = (selected + 1).toString() == q.correctAnswer ||
            selectedText.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
        if (isCorrect) totalScore += q.points;
        // Backend'e gonderirken secilen metni gonder (her iki formati da kapsar)
        answers[q.id] = selectedText;
      } else {
        answers[q.id] = '';
      }
    }

    final auth = ref.read(authProvider);
    if (auth.user == null || _quizId == null) return;

    if (_microAssignmentId != null) {
      // Mikro-ogrenme quiz akisi — microLearningProvider kullan
      final result = await ref.read(microLearningProvider.notifier).submitQuiz(
        _microAssignmentId!, answers.map((k, v) => MapEntry(k, v.toString())),
      );
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/micro-quiz-result', arguments: result);
      } else {
        setState(() { _submitted = true; _passed = false; _score = totalScore; });
      }
    } else {
      // Standart egitim quiz akisi — trainingProvider kullan
      final passed = await ref.read(trainingProvider.notifier).submitQuiz(
        _quizId!, auth.user!.id, totalScore, maxScore, answers,
      );
      setState(() { _submitted = true; _passed = passed; _score = totalScore; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);
    final questions = training.quizQuestions;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ScadaColors.red, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        actions: [
          if (!_submitted && questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${_selectedAnswers.length}/${questions.length}',
                style: TextStyle(fontSize: 13, color: context.scada.textSecondary),
              ),
            ),
        ],
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.green))
          : questions.isEmpty
              ? Center(child: Text('Soru bulunamadi', style: TextStyle(color: context.scada.textSecondary)))
              : _submitted
                  ? _buildResult(questions)
                  : _buildQuiz(questions),
      bottomNavigationBar: !_submitted && questions.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              color: context.scada.surface,
              child: ElevatedButton(
                onPressed: _selectedAnswers.length == questions.length ? _submitQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.green,
                  disabledBackgroundColor: context.scada.textDim.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _selectedAnswers.length == questions.length ? 'Quizi Tamamla' : 'Tum sorulari yanitlayin',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildQuiz(List questions) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        return _buildQuestionCard(index, q);
      },
    );
  }

  Widget _buildQuestionCard(int index, question) {
    final options = question.options as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ScadaColors.cyan))),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ScadaColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${question.points} puan', style: const TextStyle(fontSize: 9, color: ScadaColors.purple)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(question.questionText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.scada.textPrimary, height: 1.4)),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((entry) {
          final optIdx = entry.key;
          final optText = entry.value.toString();
          final isSelected = _selectedAnswers[index] == optIdx;

          return GestureDetector(
            onTap: () => setState(() => _selectedAnswers[index] = optIdx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? ScadaColors.cyan.withValues(alpha: 0.1) : context.scada.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? ScadaColors.cyan : context.scada.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? ScadaColors.cyan : Colors.transparent,
                    border: Border.all(color: isSelected ? ScadaColors.cyan : context.scada.textDim, width: 1.5),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(optText, style: TextStyle(fontSize: 12, color: isSelected ? context.scada.textPrimary : context.scada.textSecondary))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildResult(List questions) {
    final maxScore = questions.fold<double>(0, (sum, q) => sum + q.points);
    final percent = maxScore > 0 ? (_score / maxScore * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            _passed == true ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 64,
            color: _passed == true ? ScadaColors.green : ScadaColors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _passed == true ? 'Tebrikler!' : 'Basarisiz',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _passed == true ? ScadaColors.green : ScadaColors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'Puaniniz: ${_score.toInt()} / ${maxScore.toInt()} (%${percent.toInt()})',
            style: TextStyle(fontSize: 15, color: context.scada.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _passed == true ? 'Quiz basariyla tamamlandi!' : 'Gecme puanina ulasilamadi. Tekrar deneyin.',
            style: TextStyle(fontSize: 12, color: context.scada.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Show correct answers
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final userAnswer = _selectedAnswers[idx];
            final options = q.options as List<dynamic>? ?? [];
            final selectedText = userAnswer != null && userAnswer < options.length
                ? options[userAnswer].toString() : '';
            // Her iki format destegi: index ("1","2") veya tam metin
            final isCorrect = userAnswer != null && (
                (userAnswer + 1).toString() == q.correctAnswer ||
                selectedText.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()
            );
            // Dogru cevap indexi: once index formatini dene, yoksa metin eslemesi yap
            final parsedIdx = int.tryParse(q.correctAnswer);
            final correctIdx = parsedIdx != null
                ? parsedIdx - 1 // 1-tabanli -> 0-tabanli
                : options.indexWhere((o) => o.toString().trim().toLowerCase() == q.correctAnswer.trim().toLowerCase());

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.scada.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCorrect ? ScadaColors.green.withValues(alpha: 0.5) : ScadaColors.red.withValues(alpha: 0.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(isCorrect ? Icons.check_circle : Icons.cancel, size: 16, color: isCorrect ? ScadaColors.green : ScadaColors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(q.questionText, style: TextStyle(fontSize: 11, color: context.scada.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
                if (!isCorrect && correctIdx >= 0 && correctIdx < options.length) ...[
                  const SizedBox(height: 4),
                  Text('Dogru cevap: ${options[correctIdx]}', style: const TextStyle(fontSize: 10, color: ScadaColors.green)),
                ],
                if (q.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(q.explanation!, style: TextStyle(fontSize: 10, color: context.scada.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ]),
            );
          }),

          const SizedBox(height: 16),
          if (_passed == true) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Module bilgisi: mikro-ogrenme'den veya training state'den
                  String? moduleId = _microModuleId;
                  String? routeId = _microRouteId;
                  String? moduleTitle = _microModuleTitle;

                  if (moduleId == null) {
                    final training = ref.read(trainingProvider);
                    final module = training.selectedModule;
                    if (module == null) return;
                    moduleId = module.id;
                    routeId = module.routeId;
                    moduleTitle = module.title;
                  }

                  final result = await AcknowledgmentDialog.show(
                    context,
                    moduleId: moduleId,
                    routeId: routeId ?? '',
                    moduleTitle: moduleTitle ?? 'Egitim',
                  );
                  if (result == true && context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, '/orientation-dashboard', (route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.verified_user, size: 18),
                label: const Text('Egitimi Onayla', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Geri Don', style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ]),
    );
  }
}
