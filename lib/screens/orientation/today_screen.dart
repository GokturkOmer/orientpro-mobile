import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/micro_learning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/micro_learning.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final Set<String> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(microLearningProvider.notifier).loadToday(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final micro = ref.watch(microLearningProvider);
    final today = micro.todayData;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_stories, color: ScadaColors.cyan, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Bugunku Eğitim',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
      ),
      body: micro.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : today == null || !today.hasAssignment
              ? _buildNoAssignment(context)
              : _buildTodayContent(context, today),
    );
  }

  Widget _buildNoAssignment(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 64, color: context.scada.textDim),
          const SizedBox(height: 16),
          Text('Henuz bir eğitim atanmamis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Yöneticiniz size bir eğitim modulu atadiginda burada gorunecek.',
            style: TextStyle(fontSize: 14, color: context.scada.textDim),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildTodayContent(BuildContext context, TodayData today) {
    final assignment = today.assignment!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header — Modul bilgisi
        _buildHeader(context, assignment, today),
        const SizedBox(height: 16),

        // Encouragement mesaji
        if (today.encouragement.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ScadaColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(today.encouragement,
                  style: TextStyle(fontSize: 13, color: context.scada.textPrimary)),
              ),
            ]),
          ),

        // Kart listesi
        ...today.cards.map((card) => _buildCardTile(context, card)),

        // Quiz bolumu veya tamamlandi mesaji
        if (today.cards.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (assignment.isCompleted || assignment.quizPassed)
            _buildCompletedBanner(context)
          else
            _buildQuizSection(context, today),
        ],

        // Ilerleme cubugu
        const SizedBox(height: 24),
        _buildProgressBar(context, today),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context, MicroAssignment assignment, TodayData today) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ScadaColors.cyan.withValues(alpha: 0.15),
            ScadaColors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Mode badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: assignment.isOnboarding
                ? ScadaColors.green.withValues(alpha: 0.15)
                : ScadaColors.cyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            assignment.isOnboarding ? 'Genel Oryantasyon' : 'Yönetici Atamasi',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: assignment.isOnboarding ? ScadaColors.green : ScadaColors.cyan),
          ),
        ),
        const SizedBox(height: 6),
        if (assignment.routeTitle != null)
          Text(assignment.routeTitle!,
            style: TextStyle(fontSize: 12, color: context.scada.textDim)),
        const SizedBox(height: 4),
        Text(assignment.moduleTitle ?? 'Eğitim Modulu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          _buildInfoChip(context,
            assignment.isOnboarding
                ? 'Hafta ${assignment.learningDay}'
                : 'Gun ${assignment.learningDay}',
            Icons.calendar_today),
          const SizedBox(width: 8),
          _buildInfoChip(context, '${today.cardsRead}/${today.cardsTotal} kart', Icons.style),
          if (assignment.isRetry) ...[
            const SizedBox(width: 8),
            _buildInfoChip(context, 'Tekrar', Icons.refresh, color: ScadaColors.amber),
          ],
        ]),
      ]),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon, {Color? color}) {
    final c = color ?? ScadaColors.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildCardTile(BuildContext context, DripCard card) {
    final isExpanded = _expandedCards.contains(card.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: card.isRead
              ? ScadaColors.green.withValues(alpha: 0.3)
              : ScadaColors.cyan.withValues(alpha: 0.3),
          width: card.isRead ? 1 : 1.5,
        ),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCards.remove(card.id);
              } else {
                _expandedCards.add(card.id);
                // Kart acildiginda okundu say
                if (!card.isRead) {
                  ref.read(microLearningProvider.notifier).markCardRead(card.id);
                }
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Text(card.slotIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.slotText,
                    style: TextStyle(fontSize: 11, color: context.scada.textDim)),
                  Text(card.title,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: context.scada.textPrimary)),
                ]),
              ),
              if (card.isRead)
                const Icon(Icons.check_circle, color: ScadaColors.green, size: 20)
              else
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: context.scada.textDim, size: 20),
            ]),
          ),
        ),
        if (isExpanded && card.body != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(card.body!,
                style: TextStyle(fontSize: 14, height: 1.5, color: context.scada.textPrimary)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildQuizSection(BuildContext context, TodayData today) {
    final allRead = today.cardsRead >= today.cardsTotal && today.cardsTotal > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allRead
            ? ScadaColors.cyan.withValues(alpha: 0.1)
            : context.scada.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allRead
              ? ScadaColors.cyan.withValues(alpha: 0.4)
              : context.scada.textDim.withValues(alpha: 0.2),
        ),
      ),
      child: Column(children: [
        Icon(
          allRead ? Icons.quiz_outlined : Icons.lock_outline,
          size: 32,
          color: allRead ? ScadaColors.cyan : context.scada.textDim,
        ),
        const SizedBox(height: 8),
        Text(
          allRead
              ? 'Konuyu ne kadar ogrendin?'
              : 'Once kartlari oku, sonra quize gec',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: allRead ? context.scada.textPrimary : context.scada.textDim),
          textAlign: TextAlign.center,
        ),
        if (allRead) ...[
          const SizedBox(height: 8),
          Text(
            today.hasAttemptsLeft
                ? 'Kalan hak: ${today.dailyAttemptsLeft}/${today.dailyAttemptsMax} (gunluk)'
                : today.isOnboarding
                    ? 'Bugunluk deneme hakkin doldu, gelecek hafta tekrar dene!'
                    : 'Bugunluk deneme hakkin doldu, yarin tekrar dene!',
            style: TextStyle(
              fontSize: 12,
              color: today.hasAttemptsLeft ? context.scada.textDim : ScadaColors.orange,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: today.hasAttemptsLeft
                  ? () {
                      if (today.quizId != null && today.assignment != null) {
                        Navigator.pushNamed(context, '/quiz', arguments: {
                          'quizId': today.quizId,
                          'moduleId': today.assignment!.moduleId,
                          'moduleTitle': today.assignment!.moduleTitle ?? 'Eğitim',
                          'routeId': today.assignment!.routeId ?? '',
                          'assignmentId': today.assignment!.id,
                        });
                      }
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(today.hasAttemptsLeft ? 'Quize Basla' : 'Yarin Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.cyan,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.scada.surface,
                disabledForegroundColor: context.scada.textDim,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildProgressBar(BuildContext context, TodayData today) {
    // Simdilik modul bazli progress — rota bazli V2'de planli
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scada.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.trending_up, color: ScadaColors.green, size: 20),
        const SizedBox(width: 8),
        Text('Ilerleme: ${today.cardsRead}/${today.cardsTotal} kart okundu',
          style: TextStyle(fontSize: 13, color: context.scada.textPrimary)),
      ]),
    );
  }

  Widget _buildCompletedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        const Icon(Icons.check_circle, color: ScadaColors.green, size: 40),
        const SizedBox(height: 8),
        Text('Eğitim Tamamlandi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.green)),
        const SizedBox(height: 4),
        Text('Bu modulu başarıyla tamamladin. İçerik kartlarini istedigin zaman tekrar okuyabilirsin.',
          style: TextStyle(fontSize: 13, color: context.scada.textDim),
          textAlign: TextAlign.center),
      ]),
    );
  }
}
