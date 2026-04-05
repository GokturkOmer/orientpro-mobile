class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> sources;
  final bool? verified; // null = kullanıcı mesaji, true = doğrulandı, false = bilgi yok

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp, this.sources = const [], this.verified})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatResponse {
  final String question;
  final String answer;
  final List<String> sources;
  final String timestamp;

  ChatResponse({required this.question, required this.answer, this.sources = const [], required this.timestamp});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
