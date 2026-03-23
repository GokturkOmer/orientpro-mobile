import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/chatbot.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _quickActions = [
    _QuickAction(icon: Icons.school, label: 'ISG nedir?', query: 'ISG temel egitimi hakkinda kisaca bilgi ver'),
    _QuickAction(icon: Icons.security, label: 'KVKK kurallari', query: 'Otel personeli icin KVKK kurallari nelerdir?'),
    _QuickAction(icon: Icons.local_fire_department, label: 'Yangin proseduru', query: 'Yanginda yapilmasi gerekenleri adim adim anlat'),
    _QuickAction(icon: Icons.healing, label: 'Ilk yardim', query: 'Otel ortaminda ilk yardim temel prensipleri ve CPR prosedurunu anlat'),
    _QuickAction(icon: Icons.cleaning_services, label: 'Oda temizligi', query: 'Check-out oda temizlik prosedurunu anlat'),
    _QuickAction(icon: Icons.restaurant, label: 'HACCP kurallari', query: 'HACCP ve gida guvenligi temel kurallari nelerdir?'),
    _QuickAction(icon: Icons.engineering, label: 'SCADA alarmlar', query: 'SCADA alarm seviyeleri ve mudahale proseduru nedir?'),
    _QuickAction(icon: Icons.qr_code, label: 'QR Tur nedir?', query: 'QR kod tabanli tur sistemi nasil calisir? Guzergahlar ve kontrol noktalari nelerdir?'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      ref.read(chatProvider.notifier).addWelcomeMessage(auth.user?.fullName ?? '');
    });
  }

  void _sendMessage(String text) {
    final chat = ref.read(chatProvider);
    if (!chat.canSend) return;
    final auth = ref.read(authProvider);
    ref.read(chatProvider.notifier).sendMessage(text, userId: auth.user?.id);
    _controller.clear();
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
    final chat = ref.watch(chatProvider);

    // Yeni mesaj geldiginde scroll
    ref.listen(chatProvider, (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

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
              color: ScadaColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.smart_toy, color: ScadaColors.purple, size: 20),
          ),
          const SizedBox(width: 8),
          Text('AI Asistan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: context.scada.textDim),
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              final auth = ref.read(authProvider);
              ref.read(chatProvider.notifier).addWelcomeMessage(auth.user?.fullName ?? '');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions — sadece bos sohbette goster
          if (chat.messages.length <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickActions.map((action) {
                  return ActionChip(
                    avatar: Icon(action.icon, size: 14, color: ScadaColors.purple),
                    label: Text(action.label, style: TextStyle(fontSize: 11, color: context.scada.textPrimary)),
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
              itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chat.messages.length && chat.isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(
                  chat.messages[index],
                  isLastError: chat.lastError != null && index == chat.messages.length - 1,
                );
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: context.scada.surface,
              border: Border(top: BorderSide(color: context.scada.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: ChatNotifier.maxMessageLength,
                    style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Oryantasyon hakkinda sorun...',
                      hintStyle: TextStyle(fontSize: 12, color: context.scada.textDim),
                      counterText: '',
                      filled: true,
                      fillColor: context.scada.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: context.scada.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: context.scada.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: ScadaColors.purple),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                    enabled: !chat.isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: chat.canSend ? ScadaColors.purple : context.scada.textDim,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: chat.canSend ? () => _sendMessage(_controller.text) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool isLastError = false}) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? ScadaColors.purple.withValues(alpha: 0.15) : context.scada.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(message.isUser ? 12 : 2),
            bottomRight: Radius.circular(message.isUser ? 2 : 12),
          ),
          border: Border.all(
            color: message.isUser ? ScadaColors.purple.withValues(alpha: 0.3) : context.scada.border,
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
                  children: const [
                    Icon(Icons.smart_toy, size: 12, color: ScadaColors.purple),
                    SizedBox(width: 4),
                    Text('AI Asistan', style: TextStyle(fontSize: 9, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 12, color: context.scada.textPrimary, height: 1.4),
                strong: TextStyle(fontSize: 12, color: context.scada.textPrimary, fontWeight: FontWeight.w700),
                listBullet: TextStyle(fontSize: 12, color: context.scada.textPrimary),
                h2: const TextStyle(fontSize: 14, color: ScadaColors.cyan, fontWeight: FontWeight.w600),
                h3: TextStyle(fontSize: 13, color: context.scada.textPrimary, fontWeight: FontWeight.w600),
                code: TextStyle(fontSize: 11, color: ScadaColors.green, backgroundColor: context.scada.bg),
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 8, color: context.scada.textDim),
              ),
              if (isLastError) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final auth = ref.read(authProvider);
                    ref.read(chatProvider.notifier).retryLast(userId: auth.user?.id);
                  },
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh, size: 14, color: ScadaColors.amber),
                    SizedBox(width: 4),
                    Text('Tekrar Dene', style: TextStyle(fontSize: 10, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
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
          color: context.scada.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.scada.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.purple)),
            const SizedBox(width: 8),
            Text('Dusunuyor...', style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
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

  const _QuickAction({required this.icon, required this.label, required this.query});
}
