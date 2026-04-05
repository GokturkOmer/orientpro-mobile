import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/chatbot.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class ChatBotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? lastError;
  final DateTime? lastSentAt;

  const ChatBotState({
    this.messages = const [],
    this.isLoading = false,
    this.lastError,
    this.lastSentAt,
  });

  ChatBotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? lastError,
    DateTime? lastSentAt,
  }) {
    return ChatBotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      lastError: lastError,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  /// Rate limit: son mesajdan 2 saniye gecmeli
  bool get canSend {
    if (isLoading) return false;
    if (lastSentAt == null) return true;
    return DateTime.now().difference(lastSentAt!).inSeconds >= 2;
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatBotState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatBotState> {
  static const maxMessageLength = 500;

  @override
  ChatBotState build() {
    return const ChatBotState();
  }

  void addWelcomeMessage(String userName) {
    if (state.messages.isNotEmpty) return; // Zaten mesaj varsa ekleme
    final welcome = ChatMessage(
      text: 'Merhaba${userName.isNotEmpty ? ' $userName' : ''}! Ben OrientPro AI Asistanıyım. Oryantasyon süreçiyle ilgili sorularınızi yanıtlayabilirim.\n\n'
          '**Soru sorabilecaginiz konular:**\n'
          '- **ISG & Guvenlik** - Is sagligi, yangin, tahliye\n'
          '- **KVKK & Hukuk** - Veri koruma, etik kurallar\n'
          '- **Departman Eğitim** - Oda temizligi, servis, resepsiyon\n'
          '- **Teknik Sistemler** - SCADA, dijital ikiz, QR tur\n'
          '- **Acil Durumlar** - Ilk yardim, deprem, yangin\n\n'
          'Aşağıdaki hızlı erişim butonlarıni da kullanabilirsiniz.',
      isUser: false,
    );
    state = state.copyWith(messages: [welcome]);
  }

  Future<void> sendMessage(String question, {String? userId}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    if (!state.canSend) return;

    // Uzunluk limiti
    final limited = trimmed.length > maxMessageLength ? trimmed.substring(0, maxMessageLength) : trimmed;

    final userMsg = ChatMessage(text: limited, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      lastError: null,
      lastSentAt: DateTime.now(),
    );

    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/chatbot/chat', data: {
        'question': limited,
      });

      final reply = response.data['response'] ?? response.data['answer'] ?? response.data['message'] ?? 'Yanit alinamadi.';
      final sources = response.data['sources'] != null ? List<String>.from(response.data['sources']) : <String>[];
      final verified = response.data['verified'] as bool?;
      final botMsg = ChatMessage(text: reply.toString(), isUser: false, sources: sources, verified: verified);
      state = state.copyWith(messages: [...state.messages, botMsg], isLoading: false);
    } on DioException catch (e) {
      final errText = 'Hata: ${ErrorHelper.getMessage(e)}';
      final errMsg = ChatMessage(text: errText, isUser: false);
      state = state.copyWith(messages: [...state.messages, errMsg], isLoading: false, lastError: errText);
    } catch (e) {
      final errText = 'Baglanti hatasi olustu. Bilgiler getirilemedi, lütfen tekrar deneyin.';
      final errMsg = ChatMessage(text: errText, isUser: false);
      state = state.copyWith(messages: [...state.messages, errMsg], isLoading: false, lastError: errText);
    }
  }

  /// Son hata mesajini kaldirip tekrar gönder
  void retryLast({String? userId}) {
    if (state.lastError == null || state.messages.length < 2) return;
    // Son bot hata mesajini kaldir
    final msgs = [...state.messages];
    msgs.removeLast();
    // Son kullanıcı mesajini bul
    final lastUserMsg = msgs.lastWhere((m) => m.isUser, orElse: () => msgs.last);
    state = state.copyWith(messages: msgs, lastError: null);
    sendMessage(lastUserMsg.text, userId: userId);
  }

  void clearChat() {
    state = const ChatBotState();
  }
}
