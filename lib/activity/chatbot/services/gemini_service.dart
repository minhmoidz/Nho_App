import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }
  
  /// Gửi tin nhắn đơn giản
  Future<String?> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error Gemini API: $e');
      return null;
    }
  }
  
  /// Gửi tin nhắn với ngữ cảnh
  Future<String?> sendMessageWithContext(String message, String contextPrompt) async {
    try {
      final combinedMessage = '$contextPrompt\n\nNgười dùng hỏi: $message';
      final content = [Content.text(combinedMessage)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error Gemini API with context: $e');
      return null;
    }
  }
  
  /// Tạo chat session để duy trì lịch sử
  ChatSession createChatSession({List<Content>? history}) {
    return _model.startChat(history: history ?? []);
  }
  
  /// Gửi tin nhắn trong session
  Future<String?> sendMessageInSession(ChatSession session, String message) async {
    try {
      final content = Content.text(message);
      final response = await session.sendMessage(content);
      return response.text;
    } catch (e) {
      print('Error sending message in session: $e');
      return null;
    }
  }
}
