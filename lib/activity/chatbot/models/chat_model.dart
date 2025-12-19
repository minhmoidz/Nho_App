
class Conversation {
  final String id;
  final String title;

  Conversation({required this.id, required this.title});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    String parsedId = (json['id'] ?? '').toString();
    String displayTitle = 'Cuộc hội thoại $parsedId';

    if (json['messages'] != null && (json['messages'] as List).isNotEmpty) {
      final firstMsg = json['messages'][0];
      if (firstMsg['content'] != null) {
        displayTitle = firstMsg['content'];
        if (displayTitle.length > 30) {
          displayTitle = "${displayTitle.substring(0, 30)}...";
        }
      }
    }

    return Conversation(
      id: parsedId,
      title: displayTitle,
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] ?? '',
      isUser: json['role'] == 'user',
    );
  }
}