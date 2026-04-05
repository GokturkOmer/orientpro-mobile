import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/scada_app_bar.dart';
import '../../widgets/section_header.dart';

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;

  const _FaqItem({required this.question, required this.answer, required this.icon});
}

class _GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _GuideStep({required this.title, required this.description, required this.icon, required this.color});
}

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _FaqItem(
      question: 'Nasıl yeni bir eğitim rotası oluşturabilirim?',
      answer: 'Admin paneli > İçerik Yönetimi > Yeni Rota butonuna tıklayın. Departman, zorluk seviyesi ve modülleri ekleyerek rotanızı oluşturabilirsiniz.',
      icon: Icons.route,
    ),
    _FaqItem(
      question: 'Kullanıcı nasıl eklenir?',
      answer: 'Admin paneli > Kullanıcı Yönetimi > Yeni Kullanıcı butonuyla ekleyebilirsiniz. Kullanıcı e-postasina doğrulama kodu gönderilir.',
      icon: Icons.person_add,
    ),
    _FaqItem(
      question: 'AI Chatbot hangi dokümanlari kullanır?',
      answer: 'Chatbot, İçerik Yönetimi üzerinden yüklenen PDF dokümanlarından öğrenilen bilgileri kullanır. Yeni doküman yükledikçe chatbot bilgi tabanını günceller.',
      icon: Icons.smart_toy,
    ),
    _FaqItem(
      question: 'Quiz nasıl oluşturulur?',
      answer: 'İçerik Yönetimi > Quiz Oluştur ile manuel quiz oluşturabilir veya AI ile Dokümandan Soru Üret butonuyla otomatik quiz üretebilirsiniz.',
      icon: Icons.quiz,
    ),
    _FaqItem(
      question: 'Departman bazlı raporları nasıl görebilirim?',
      answer: 'Admin paneli > Analitik ekraninda departman kırılımli tamamlanma oranlari görünür. Excel Raporu İndir butonu ile detaylı rapor alabilirsiniz.',
      icon: Icons.analytics,
    ),
    _FaqItem(
      question: 'İçerik onay akişi nasıl çalışır?',
      answer: 'İçerik editörleri taslak oluşturur, admin İçerik Onayları ekranından onaylar veya reddeder. Onaylanan içerikler çalışanlara görünür hale gelir.',
      icon: Icons.fact_check,
    ),
    _FaqItem(
      question: 'Sertifika nasıl verilir?',
      answer: 'Eğitim rotasında sertifika seçeneği açıksa, çalışan tum modülleri ve quizleri başarıyla tamamladığında otomatik olarak sertifika kazanır ve PDF olarak indirebilir.',
      icon: Icons.workspace_premium,
    ),
    _FaqItem(
      question: 'Aboneligimi nasıl yukseltebilirim?',
      answer: 'Abonelik & Plan ekranından istediğiniz plani secip Ödemeye Gec butonuyla yukseltme yapabilirsiniz.',
      icon: Icons.upgrade,
    ),
  ];

  static const _quickGuide = [
    _GuideStep(
      title: '1. Departmanlari Oluşturun',
      description: 'Sektor şablonları ile otomatik departman oluşturabilir veya manuel ekleyebilirsiniz.',
      icon: Icons.business,
      color: ScadaColors.cyan,
    ),
    _GuideStep(
      title: '2. Eğitim İçeriği Yükleyin',
      description: 'PDF dokümanlari yükleyin, modüller oluşturun ve eğitim rotalarını tanımlayın.',
      icon: Icons.upload_file,
      color: ScadaColors.green,
    ),
    _GuideStep(
      title: '3. Quizler Ekleyin',
      description: 'Her modül için quiz oluşturun. AI ile dokümanlardan otomatik soru üretebilirsiniz.',
      icon: Icons.quiz,
      color: ScadaColors.amber,
    ),
    _GuideStep(
      title: '4. Çalışanlari Davet Edin',
      description: 'Kullanıcı yönetiminden çalışanlarinizi ekleyin, departman ve rol atayın.',
      icon: Icons.group_add,
      color: ScadaColors.orange,
    ),
    _GuideStep(
      title: '5. Ilerlemeleri Takip Edin',
      description: 'Analitik ekraniyla tamamlanma oranlarini, quiz sonuçlarini ve departman performansini izleyin.',
      icon: Icons.trending_up,
      color: ScadaColors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: const ScadaAppBar(
        title: 'Yardim',
        titleIcon: Icons.help_outline,
        titleIconColor: ScadaColors.cyan,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Hizli Baslangic Rehberi
          const SectionHeader(icon: Icons.rocket_launch, title: 'HIZLI BASLANGIC'),
          const SizedBox(height: 12),
          ...List.generate(_quickGuide.length, (i) => _buildGuideCard(context, _quickGuide[i])),

          const SizedBox(height: 24),

          // SSS
          const SectionHeader(icon: Icons.question_answer, title: 'SIK SORULAN SORULAR'),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (i) => _buildFaqCard(context, _faqs[i])),

          const SizedBox(height: 24),

          // Destek
          const SectionHeader(icon: Icons.support_agent, title: 'DESTEK'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.scada.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.headset_mic, color: ScadaColors.cyan, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Teknik Destek', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Sorun yasadiginizda bize ulaşın', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 12),
              _buildContactRow(context, Icons.email, 'destek@orientpro.com'),
              const SizedBox(height: 6),
              _buildContactRow(context, Icons.chat, 'WhatsApp ile iletisime gecin'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, _GuideStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: step.color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(step.icon, color: step.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
          const SizedBox(height: 2),
          Text(step.description, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _buildFaqCard(BuildContext context, _FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        leading: Icon(faq.icon, size: 20, color: ScadaColors.cyan),
        title: Text(faq.question, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
        iconColor: context.scada.textDim,
        collapsedIconColor: context.scada.textDim,
        children: [
          Text(faq.answer, style: TextStyle(fontSize: 12, color: context.scada.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: context.scada.textDim),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
    ]);
  }
}
