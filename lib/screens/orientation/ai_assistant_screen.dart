import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser, DateTime? time}) : time = time ?? DateTime.now();
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<_QuickAction> _quickActions = [
    _QuickAction(icon: Icons.school, label: 'ISG nedir?', query: 'ISG temel egitimi hakkinda kisaca bilgi ver', category: 'genel'),
    _QuickAction(icon: Icons.security, label: 'KVKK kurallari', query: 'Otel personeli icin KVKK kurallari nelerdir?', category: 'genel'),
    _QuickAction(icon: Icons.local_fire_department, label: 'Yangin proseduru', query: 'Yanginda yapilmasi gerekenleri adim adim anlat', category: 'acil'),
    _QuickAction(icon: Icons.healing, label: 'Ilk yardim', query: 'Otel ortaminda ilk yardim temel prensipleri ve CPR prosedurunu anlat', category: 'acil'),
    _QuickAction(icon: Icons.cleaning_services, label: 'Oda temizligi', query: 'Check-out oda temizlik prosedurunu anlat', category: 'departman'),
    _QuickAction(icon: Icons.restaurant, label: 'HACCP kurallari', query: 'HACCP ve gida guvenligi temel kurallari nelerdir?', category: 'departman'),
    _QuickAction(icon: Icons.engineering, label: 'SCADA alarmlar', query: 'SCADA alarm seviyeleri ve mudahale proseduru nedir?', category: 'teknik'),
    _QuickAction(icon: Icons.qr_code, label: 'QR Tur nedir?', query: 'QR kod tabanli tur sistemi nasil calisir? Guzergahlar ve kontrol noktalari nelerdir?', category: 'teknik'),
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final userName = auth.user?.fullName ?? '';
    _messages.add(_ChatMessage(
      text: 'Merhaba${userName.isNotEmpty ? ' $userName' : ''}! Ben OrientPro AI Asistaniyim. Oryantasyon sureciyle ilgili sorularinizi yanitlayabilirim.\n\n'
          '**Soru sorabilecaginiz konular:**\n'
          '- **ISG & Guvenlik** - Is sagligi, yangin, tahliye\n'
          '- **KVKK & Hukuk** - Veri koruma, etik kurallar\n'
          '- **Departman Egitim** - Oda temizligi, servis, resepsiyon\n'
          '- **Teknik Sistemler** - SCADA, dijital ikiz, QR tur\n'
          '- **Acil Durumlar** - Ilk yardim, deprem, yangin\n\n'
          'Asagidaki hizli erisim butonlarini da kullanabilirsiniz.',
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final auth = ref.read(authProvider);
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/chatbot/chat', data: {
        'message': text,
        'user_id': auth.user?.id ?? 'anonymous',
        'context': 'oryantasyon',
      });

      final reply = response.data['response'] ?? response.data['message'] ?? 'Yanit alinamadi.';
      setState(() {
        _messages.add(_ChatMessage(text: reply.toString(), isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Baglanti hatasi olustu. Lutfen tekrar deneyin.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
              color: ScadaColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.smart_toy, color: ScadaColors.purple, size: 20),
          ),
          const SizedBox(width: 8),
          const Text('AI Asistan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: ScadaColors.textDim),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: 'Sohbet temizlendi. Size nasil yardimci olabilirim?',
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickActions.map((action) {
                  return ActionChip(
                    avatar: Icon(action.icon, size: 14, color: ScadaColors.purple),
                    label: Text(action.label, style: const TextStyle(fontSize: 11, color: ScadaColors.textPrimary)),
                    backgroundColor: ScadaColors.purple.withValues(alpha: 0.08),
                    side: BorderSide(color: ScadaColors.purple.withValues(alpha: 0.2)),
                    onPressed: () => _sendMessage(action.query),
                  );
                }).toList(),
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScadaColors.surface,
              border: Border(top: BorderSide(color: ScadaColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Oryantasyon hakkinda sorun...',
                      hintStyle: const TextStyle(fontSize: 12, color: ScadaColors.textDim),
                      filled: true,
                      fillColor: ScadaColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: ScadaColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: ScadaColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: ScadaColors.purple),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: ScadaColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? ScadaColors.purple.withValues(alpha: 0.15) : ScadaColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(message.isUser ? 12 : 2),
            bottomRight: Radius.circular(message.isUser ? 2 : 12),
          ),
          border: Border.all(
            color: message.isUser ? ScadaColors.purple.withValues(alpha: 0.3) : ScadaColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, size: 12, color: ScadaColors.purple),
                    const SizedBox(width: 4),
                    Text('AI Asistan', style: TextStyle(fontSize: 9, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.4),
                strong: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, fontWeight: FontWeight.w700),
                listBullet: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary),
                h2: const TextStyle(fontSize: 14, color: ScadaColors.cyan, fontWeight: FontWeight.w600),
                h3: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary, fontWeight: FontWeight.w600),
                code: TextStyle(fontSize: 11, color: ScadaColors.green, backgroundColor: ScadaColors.bg),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 8, color: ScadaColors.textDim),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ScadaColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ScadaColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.purple)),
            const SizedBox(width: 8),
            const Text('Dusunuyor...', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String query;
  final String category;

  _QuickAction({required this.icon, required this.label, required this.query, this.category = 'genel'});
}
