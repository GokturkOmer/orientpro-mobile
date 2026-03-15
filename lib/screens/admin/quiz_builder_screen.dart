import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/training.dart';

class QuizBuilderScreen extends ConsumerStatefulWidget {
  const QuizBuilderScreen({super.key, required this.moduleId, this.quizId});
  final String moduleId;
  final String? quizId;

  @override
  ConsumerState<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends ConsumerState<QuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _maxAttemptsController = TextEditingController(text: '3');
  final _passingScoreController = TextEditingController(text: '70');

  String? _quizId;
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditMode => _quizId != null;

  @override
  void initState() {
    super.initState();
    _quizId = widget.quizId;
    if (_quizId != null) {
      Future.microtask(() => _loadQuizData());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    if (_quizId == null) return;
    setState(() => _isLoading = true);
    try {
      final quiz = await ref.read(adminProvider.notifier).loadQuiz(_quizId!);
      if (quiz != null) {
        _titleController.text = quiz.title;
        _descriptionController.text = quiz.description ?? '';
        _timeLimitController.text = quiz.timeLimitMinutes?.toString() ?? '';
        _maxAttemptsController.text = quiz.maxAttempts.toString();
        _passingScoreController.text = quiz.passingScore.toString();
      }

      final questions = await ref.read(adminProvider.notifier).loadQuizQuestions(_quizId!);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz yuklenemedi: $e'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'module_id': widget.moduleId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'time_limit_minutes': _timeLimitController.text.trim().isEmpty ? null : int.tryParse(_timeLimitController.text.trim()),
      'max_attempts': int.tryParse(_maxAttemptsController.text.trim()) ?? 3,
      'passing_score': int.tryParse(_passingScoreController.text.trim()) ?? 70,
    };

    try {
      final notifier = ref.read(adminProvider.notifier);
      if (_isEditMode) {
        final success = await notifier.updateQuiz(_quizId!, data);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz guncellendi'), backgroundColor: ScadaColors.green),
          );
        }
      } else {
        final newId = await notifier.createQuizAndReturnId(data);
        if (newId != null) {
          setState(() => _quizId = newId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz olusturuldu'), backgroundColor: ScadaColors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: ScadaColors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _loadQuestions() async {
    if (_quizId == null) return;
    final questions = await ref.read(adminProvider.notifier).loadQuizQuestions(_quizId!);
    setState(() => _questions = questions);
  }

  void _showQuestionDialog({QuizQuestion? existing}) {
    final questionController = TextEditingController(text: existing?.questionText ?? '');
    final optionControllers = List.generate(4, (i) {
      final options = existing?.options;
      final text = (options != null && i < options.length) ? options[i].toString() : '';
      return TextEditingController(text: text);
    });
    final pointsController = TextEditingController(text: (existing?.points ?? 10).toString());
    final explanationController = TextEditingController(text: existing?.explanation ?? '');

    String selectedAnswer = 'A';
    if (existing != null && existing.options != null) {
      final idx = existing.options!.indexOf(existing.correctAnswer);
      if (idx >= 0 && idx < 4) {
        selectedAnswer = ['A', 'B', 'C', 'D'][idx];
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ScadaColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                existing != null ? 'Soru Duzenle' : 'Yeni Soru Ekle',
                style: const TextStyle(color: ScadaColors.cyan, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogField(
                        controller: questionController,
                        label: 'Soru Metni',
                        maxLines: 3,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(4, (i) {
                        final letter = ['A', 'B', 'C', 'D'][i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: selectedAnswer == letter
                                      ? ScadaColors.green.withValues(alpha: 0.2)
                                      : ScadaColors.card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: selectedAnswer == letter ? ScadaColors.green : ScadaColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    color: selectedAnswer == letter ? ScadaColors.green : ScadaColors.cyan,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDialogField(
                                  controller: optionControllers[i],
                                  label: '$letter secenegi',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedAnswer,
                        dropdownColor: ScadaColors.card,
                        decoration: InputDecoration(
                          labelText: 'Dogru Cevap',
                          labelStyle: const TextStyle(color: ScadaColors.amber, fontSize: 12),
                          filled: true,
                          fillColor: ScadaColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: ScadaColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: ScadaColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: ScadaColors.cyan),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['A', 'B', 'C', 'D'].map((l) {
                          final idx = ['A', 'B', 'C', 'D'].indexOf(l);
                          final text = optionControllers[idx].text.isEmpty ? l : optionControllers[idx].text;
                          return DropdownMenuItem(value: l, child: Text('$l - $text'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedAnswer = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogField(
                              controller: pointsController,
                              label: 'Puan',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        controller: explanationController,
                        label: 'Aciklama (opsiyonel)',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Iptal', style: TextStyle(color: ScadaColors.amber)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan,
                    foregroundColor: ScadaColors.bg,
                  ),
                  onPressed: () async {
                    if (questionController.text.trim().isEmpty) return;
                    final answerIdx = ['A', 'B', 'C', 'D'].indexOf(selectedAnswer);
                    final options = optionControllers.map((c) => c.text.trim()).toList();
                    if (options.any((o) => o.isEmpty)) return;

                    final data = {
                      'quiz_id': _quizId,
                      'question_text': questionController.text.trim(),
                      'question_type': 'multiple_choice',
                      'options': options,
                      'correct_answer': options[answerIdx],
                      'explanation': explanationController.text.trim().isEmpty ? null : explanationController.text.trim(),
                      'points': int.tryParse(pointsController.text.trim()) ?? 10,
                      'sort_order': existing?.sortOrder ?? _questions.length,
                    };

                    bool success;
                    if (existing != null) {
                      success = await ref.read(adminProvider.notifier).updateQuestion(existing.id, data);
                    } else {
                      success = await ref.read(adminProvider.notifier).createQuestion(data);
                    }

                    if (success && mounted) {
                      Navigator.pop(ctx);
                      _loadQuestions();
                    }
                  },
                  child: Text(existing != null ? 'Guncelle' : 'Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        title: const Text('Soru Sil', style: TextStyle(color: ScadaColors.red, fontSize: 16)),
        content: const Text(
          'Bu soruyu silmek istediginizden emin misiniz?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal', style: TextStyle(color: ScadaColors.amber)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(adminProvider.notifier).deleteQuestion(question.id);
      if (success) _loadQuestions();
    }
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ScadaColors.amber, fontSize: 12),
        filled: true,
        fillColor: ScadaColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Bu alan zorunludur' : null : null,
    );
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
        title: Text(
          _isEditMode ? 'Quiz Duzenle' : 'Quiz Olustur',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuizSettingsCard(),
                  if (_isEditMode) ...[
                    const SizedBox(height: 24),
                    _buildQuestionsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuizSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiz Ayarlari',
              style: TextStyle(color: ScadaColors.cyan, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _titleController,
              label: 'Quiz Basligi',
              required: true,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _descriptionController,
              label: 'Aciklama',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _timeLimitController,
                    label: 'Sure Limiti (dakika)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField(
                    controller: _maxAttemptsController,
                    label: 'Max Deneme',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _passingScoreController,
              label: 'Gecme Puani (%)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.cyan,
                  foregroundColor: ScadaColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaving ? null : _saveQuiz,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.bg))
                    : Icon(_isEditMode ? Icons.save : Icons.add),
                label: Text(_isEditMode ? 'Quiz Guncelle' : 'Quiz Olustur'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ScadaColors.amber, fontSize: 12),
        filled: true,
        fillColor: ScadaColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Bu alan zorunludur' : null : null,
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sorular (${_questions.length} adet)',
              style: const TextStyle(color: ScadaColors.cyan, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.green.withValues(alpha: 0.15),
                foregroundColor: ScadaColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _showQuestionDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Soru Ekle', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_questions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ScadaColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.quiz_outlined, color: ScadaColors.amber, size: 40),
                SizedBox(height: 12),
                Text(
                  'Henuz soru eklenmedi',
                  style: TextStyle(color: ScadaColors.amber, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...List.generate(_questions.length, (i) => _buildQuestionCard(i, _questions[i])),
      ],
    );
  }

  Future<void> _reorderQuestion(int oldIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= _questions.length) return;
    final notifier = ref.read(adminProvider.notifier);
    // Swap sort_order
    await notifier.updateQuestion(_questions[oldIndex].id, {'sort_order': newIndex});
    await notifier.updateQuestion(_questions[newIndex].id, {'sort_order': oldIndex});
    _loadQuestions();
  }

  Widget _buildQuestionCard(int index, QuizQuestion question) {
    final options = question.options ?? [];
    final total = _questions.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reorder buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_upward, size: 14,
                        color: index > 0 ? ScadaColors.textSecondary : ScadaColors.textDim.withValues(alpha: 0.3)),
                      onPressed: index > 0 ? () => _reorderQuestion(index, index - 1) : null,
                    ),
                  ),
                  SizedBox(
                    width: 24, height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_downward, size: 14,
                        color: index < total - 1 ? ScadaColors.textSecondary : ScadaColors.textDim.withValues(alpha: 0.3)),
                      onPressed: index < total - 1 ? () => _reorderQuestion(index, index + 1) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ScadaColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: ScadaColors.cyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ScadaColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${question.points} puan',
                  style: const TextStyle(color: ScadaColors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(options.length, (oi) {
              final isCorrect = options[oi].toString() == question.correctAnswer;
              final letter = oi < 4 ? ['A', 'B', 'C', 'D'][oi] : '${oi + 1}';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCorrect ? ScadaColors.green.withValues(alpha: 0.15) : ScadaColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCorrect ? ScadaColors.green : ScadaColors.border,
                  ),
                ),
                child: Text(
                  '$letter) ${options[oi]}',
                  style: TextStyle(
                    color: isCorrect ? ScadaColors.green : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: ScadaColors.cyan, size: 18),
                onPressed: () => _showQuestionDialog(existing: question),
                tooltip: 'Duzenle',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: ScadaColors.red, size: 18),
                onPressed: () => _deleteQuestion(question),
                tooltip: 'Sil',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
