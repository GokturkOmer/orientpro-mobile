import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:dio/dio.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/chatbot.dart';
import '../../widgets/scada_app_bar.dart';

import 'package:file_picker/file_picker.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});
  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final pickedFile = result.files.first;
    if (!pickedFile.name.endsWith('.pdf')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Sadece PDF yüklenebilir'), backgroundColor: ScadaColors.red));
      return;
    }
    setState(() => _isUploading = true);
    try {
      final bytes = pickedFile.bytes!;
      final dio = ref.read(authDioProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: pickedFile.name),
        'category': 'genel',
      });
      final response = await dio.post('/chatbot/upload-document', data: formData);
      final data = response.data;
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pickedFile.name} yüklendi! (${data["chunks_indexed"]} parca)'), backgroundColor: ScadaColors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yükleme hatasi: $e'), backgroundColor: ScadaColors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: ScadaAppBar(
        title: 'OrientPro AI Asistan',
        titleIcon: Icons.smart_toy,
        showBackButton: true,
        actions: [
          if (_isUploading) Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))),
          IconButton(icon: const Icon(Icons.upload_file, color: ScadaColors.cyan), onPressed: _isUploading ? null : _uploadPdf, tooltip: 'PDF Yükle'),
          IconButton(icon: Icon(Icons.delete_outline, color: context.scada.textDim), onPressed: () => ref.read(chatProvider.notifier).clearChat(), tooltip: 'Sohbeti Temizle'),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty ? _buildWelcome() : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) return _buildTypingIndicator();
                return _buildMessageBubble(chatState.messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: ScadaColors.cyan.withValues(alpha: 0.1), border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3), width: 2)),
              child: const Icon(Icons.smart_toy, size: 48, color: ScadaColors.cyan),
            ),
            const SizedBox(height: 20),
            Text('OrientPro AI Asistan', style: TextStyle(color: context.scada.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Oryantasyon ve eğitim hakkında\nsorularınızi sorun', textAlign: TextAlign.center, style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _buildQuickAction(Icons.health_and_safety, 'ISG nedir?'),
              _buildQuickAction(Icons.shield, 'KVKK kurallari'),
              _buildQuickAction(Icons.local_fire_department, 'Yangin prosedürü'),
              _buildQuickAction(Icons.medical_services, 'Ilk yardim'),
              _buildQuickAction(Icons.cleaning_services, 'Oda temizligi'),
              _buildQuickAction(Icons.restaurant, 'HACCP kurallari'),
              _buildQuickAction(Icons.security, 'SCADA alarmlar'),
              _buildQuickAction(Icons.qr_code_2, 'QR Tur nedir?'),
            ]),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _uploadPdf,
              icon: const Icon(Icons.upload_file, color: ScadaColors.cyan, size: 18),
              label: const Text('PDF Doküman Yükle', style: TextStyle(color: ScadaColors.cyan, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String text) {
    return GestureDetector(
      onTap: () { _controller.text = text; _sendMessage(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: context.scada.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: ScadaColors.cyan.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: ScadaColors.cyan.withValues(alpha: 0.9), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: message.isUser ? ScadaColors.cyan.withValues(alpha: 0.12) : context.scada.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(color: message.isUser ? ScadaColors.cyan.withValues(alpha: 0.25) : context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!message.isUser) ...[
            const Row(children: [
              Icon(Icons.smart_toy, size: 14, color: ScadaColors.cyan),
              SizedBox(width: 4),
              Text('AI Asistan', style: TextStyle(color: ScadaColors.cyan, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
          ],
          message.isUser
              ? Text(message.text, style: const TextStyle(color: ScadaColors.cyan, fontSize: 14))
              : MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: context.scada.textPrimary, fontSize: 14, height: 1.5),
                    strong: const TextStyle(color: ScadaColors.cyan, fontWeight: FontWeight.bold),
                    listBullet: const TextStyle(color: ScadaColors.cyan),
                    h1: TextStyle(color: context.scada.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    h2: TextStyle(color: context.scada.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    code: TextStyle(color: ScadaColors.green, backgroundColor: context.scada.bg, fontSize: 13),
                    codeblockDecoration: BoxDecoration(color: context.scada.bg, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
          if (message.sources.isNotEmpty || message.verified != null) ...[
            const SizedBox(height: 10),
            Divider(color: context.scada.border, height: 1),
            const SizedBox(height: 8),
            // Doğrulama gostergesi
            if (message.verified != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    message.verified! ? Icons.verified : Icons.warning_amber,
                    size: 12,
                    color: message.verified! ? ScadaColors.green : ScadaColors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.verified! ? 'Doğrulandı' : 'Doğrulanamadı — yetkiliye danisin',
                    style: TextStyle(fontSize: 10, color: message.verified! ? ScadaColors.green : ScadaColors.amber),
                  ),
                ]),
              ),
            if (message.sources.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 4, children: message.sources.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.scada.card, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.description, size: 10, color: context.scada.textSecondary),
                  const SizedBox(width: 4),
                  Text(s, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                ]),
              )).toList()),
          ],
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.scada.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.scada.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.smart_toy, size: 14, color: ScadaColors.cyan),
          const SizedBox(width: 8),
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan.withValues(alpha: 0.7))),
          const SizedBox(width: 8),
          Text('Kontrol ediliyor...', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: context.scada.surface, border: Border(top: BorderSide(color: context.scada.border))),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _controller,
          style: TextStyle(color: context.scada.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: 'Sorunuzu yazin...', hintStyle: TextStyle(color: context.scada.textDim, fontSize: 14), filled: true, fillColor: context.scada.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onSubmitted: (_) => _sendMessage(),
        )),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ScadaColors.cyan, ScadaColors.cyan.withValues(alpha: 0.7)])),
          child: IconButton(icon: Icon(Icons.send, color: context.scada.bg, size: 20), onPressed: _sendMessage),
        ),
      ]),
    );
  }
}
