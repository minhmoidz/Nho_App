import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // API Key của Gemini
  static const String _apiKey = 'AIzaSyCORVLq4vzKSa71evffOKOWJtclOqVUIIc';
  
  late final GenerativeModel _model;
  
  GeminiService() {
    // Khởi tạo model Gemini Pro
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
  }
  
  /// Gửi tin nhắn đơn giản đến Gemini API
  /// 
  /// [message] - Nội dung tin nhắn cần gửi
  /// Returns: Phản hồi từ Gemini hoặc null nếu có lỗi
  Future<String?> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text;
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi Gemini API: $e');
      return null;
    }
  }
  
  /// Gửi tin nhắn với ngữ cảnh (context injection)
  /// Dùng cho các tình huống cần cung cấp thông tin nền trước khi hỏi
  /// 
  /// [message] - Câu hỏi của người dùng
  /// [contextPrompt] - Thông tin ngữ cảnh (về video, tài liệu, etc.)
  /// Returns: Phản hồi từ Gemini hoặc null nếu có lỗi
  Future<String?> sendMessageWithContext(String message, String contextPrompt) async {
    try {
      // Kết hợp context và message
      final combinedMessage = '$contextPrompt\n\nNgười dùng hỏi: $message';
      
      final content = [Content.text(combinedMessage)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text;
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi Gemini API với context: $e');
      return null;
    }
  }
  
  /// Tạo một chat session để duy trì lịch sử hội thoại
  /// Dùng khi cần chat nhiều lượt và AI nhớ ngữ cảnh
  /// 
  /// Returns: ChatSession object để sử dụng cho các cuộc trò chuyện liên tục
  ChatSession createChatSession({List<Content>? history}) {
    return _model.startChat(history: history ?? []);
  }
  
  /// Gửi tin nhắn trong một chat session (multi-turn conversation)
  /// 
  /// [session] - ChatSession đã được tạo trước đó
  /// [message] - Tin nhắn cần gửi
  /// Returns: Phản hồi từ Gemini hoặc null nếu có lỗi
  Future<String?> sendMessageInSession(ChatSession session, String message) async {
    try {
      final content = Content.text(message);
      final response = await session.sendMessage(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text;
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi gửi tin nhắn trong session: $e');
      return null;
    }
  }
}
