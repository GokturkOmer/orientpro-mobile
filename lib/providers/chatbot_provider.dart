import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/chatbot.dart';
import '../core/config/api_config.dart';

class ChatBotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  const ChatBotState({this.messages = const [], this.isLoading = false});
}

final chatProvider = NotifierProvider<ChatNotifier, ChatBotState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatBotState> {
  late final Dio _dio;

  @override
  ChatBotState build() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.webUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ));
    return const ChatBotState();
  }

  Future<void> sendMessage(String question) async {
    final userMsg = ChatMessage(text: question, isUser: true);
    state = ChatBotState(messages: [...state.messages, userMsg], isLoading: true);
    try {
      final response = await _dio.post('/chatbot/chat', data: {'question': question});
      final chatResponse = ChatResponse.fromJson(response.data);
      final botMsg = ChatMessage(text: chatResponse.answer, isUser: false, sources: chatResponse.sources);
      state = ChatBotState(messages: [...state.messages, botMsg], isLoading: false);
    } catch (e) {
      final errMsg = ChatMessage(text: 'Hata: Sunucuya baglanilamadi.', isUser: false);
      state = ChatBotState(messages: [...state.messages, errMsg], isLoading: false);
    }
  }

  void clearChat() {
    state = const ChatBotState();
  }
}
