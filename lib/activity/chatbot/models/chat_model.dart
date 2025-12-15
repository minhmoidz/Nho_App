
class Conversation {
  final String id;
  final String title;

  Conversation({required this.id, required this.title});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý ID: Dùng .toString() để chấp nhận cả số và chữ
    String parsedId = (json['id'] ?? '').toString();

    // 2. Xử lý Title: API của bạn không có trường 'title' hay 'name'.
    // Ta sẽ lấy nội dung tin nhắn đầu tiên (nếu có) để làm tiêu đề.
    String displayTitle = 'Cuộc hội thoại $parsedId';

    if (json['messages'] != null && (json['messages'] as List).isNotEmpty) {
      // Lấy tin nhắn đầu tiên
      final firstMsg = json['messages'][0];
      if (firstMsg['content'] != null) {
        displayTitle = firstMsg['content'];
        // Cắt ngắn nếu quá dài
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
      // API của bạn trả về 'role': 'user' hoặc 'assistant'
      isUser: json['role'] == 'user',
    );
  }
}