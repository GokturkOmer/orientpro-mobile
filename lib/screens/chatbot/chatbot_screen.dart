import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import '../../core/network/auth_dio.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/chatbot.dart';

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

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final pickedFile = result.files.first;
    if (!pickedFile.name.endsWith('.pdf')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sadece PDF yuklenebilir'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pickedFile.name} yuklendi! (${data["chunks_indexed"]} parca)'), backgroundColor: Colors.green[700]));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yukleme hatasi: $e'), backgroundColor: Colors.red[700]));
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
      backgroundColor: const Color(0xFF0a0e1a),
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.smart_toy, color: Colors.cyanAccent), SizedBox(width: 8), Text('OrientPro AI Asistan')]),
        backgroundColor: const Color(0xFF101829),
        actions: [
          if (_isUploading) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))),
          IconButton(icon: const Icon(Icons.upload_file, color: Colors.cyanAccent), onPressed: _isUploading ? null : _uploadPdf, tooltip: 'PDF Yukle'),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => ref.read(chatProvider.notifier).clearChat(), tooltip: 'Sohbeti Temizle'),
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2)),
              child: const Icon(Icons.smart_toy, size: 48, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 20),
            const Text('OrientPro AI Asistan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Oryantasyon ve egitim hakkinda\nsorularinizi sorun', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 32),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _buildQuickAction(Icons.health_and_safety, 'ISG nedir?'),
              _buildQuickAction(Icons.shield, 'KVKK kurallari'),
              _buildQuickAction(Icons.local_fire_department, 'Yangin proseduru'),
              _buildQuickAction(Icons.medical_services, 'Ilk yardim'),
              _buildQuickAction(Icons.cleaning_services, 'Oda temizligi'),
              _buildQuickAction(Icons.restaurant, 'HACCP kurallari'),
              _buildQuickAction(Icons.security, 'SCADA alarmlar'),
              _buildQuickAction(Icons.qr_code_2, 'QR Tur nedir?'),
            ]),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _uploadPdf,
              icon: const Icon(Icons.upload_file, color: Colors.cyanAccent, size: 18),
              label: const Text('PDF Dokuman Yukle', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
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
        decoration: BoxDecoration(color: const Color(0xFF1a2332), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.cyanAccent.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.9), fontSize: 12)),
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
          color: message.isUser ? Colors.cyanAccent.withValues(alpha: 0.12) : const Color(0xFF151e2d),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(color: message.isUser ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFF243040)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!message.isUser) ...[
            const Row(children: [
              Icon(Icons.smart_toy, size: 14, color: Colors.cyanAccent),
              SizedBox(width: 4),
              Text('AI Asistan', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
          ],
          message.isUser
              ? Text(message.text, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14))
              : MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    strong: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    listBullet: const TextStyle(color: Colors.cyanAccent),
                    h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    code: TextStyle(color: Colors.greenAccent[400], backgroundColor: const Color(0xFF0d1520), fontSize: 13),
                    codeblockDecoration: BoxDecoration(color: const Color(0xFF0d1520), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
          if (message.sources.isNotEmpty || message.verified != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF243040), height: 1),
            const SizedBox(height: 8),
            // Dogrulama gostergesi
            if (message.verified != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    message.verified! ? Icons.verified : Icons.warning_amber,
                    size: 12,
                    color: message.verified! ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.verified! ? 'Dogrulandi' : 'Dogrulanamadi — yetkiliye danisin',
                    style: TextStyle(fontSize: 10, color: message.verified! ? Colors.green : Colors.orange),
                  ),
                ]),
              ),
            if (message.sources.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 4, children: message.sources.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF1a2a3a), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.description, size: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(s, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
        decoration: BoxDecoration(color: const Color(0xFF151e2d), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF243040))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.smart_toy, size: 14, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent.withValues(alpha: 0.7))),
          const SizedBox(width: 8),
          Text('Analiz ediliyor...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: Color(0xFF101829), border: Border(top: BorderSide(color: Color(0xFF1a2332)))),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Sorunuzu yazin...', hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14), filled: true, fillColor: const Color(0xFF0a0e1a), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onSubmitted: (_) => _sendMessage(),
        )),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.cyanAccent, Colors.cyanAccent.withValues(alpha: 0.7)])),
          child: IconButton(icon: const Icon(Icons.send, color: Color(0xFF0a0e1a), size: 20), onPressed: _sendMessage),
        ),
      ]),
    );
  }
}
