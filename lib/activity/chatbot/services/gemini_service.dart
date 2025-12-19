import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
    ];

    final generationConfig = GenerationConfig(
      temperature: 1.0, // Model 2.5 cho phép nhiệt độ cao hơn
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 8192,
    );

    _model = GenerativeModel(
      // SỬA TÊN MODEL TẠI ĐÂY
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      safetySettings: safetySettings,
      generationConfig: generationConfig,
    );
  }

  // ... (Giữ nguyên các hàm sendMessage bên dưới)

  Future<String?> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('❌ Lỗi Gemini API: $e');
      return "Lỗi kết nối: ${e.toString()}";
    }
  }

  ChatSession createChatSession({List<Content>? history}) {
    return _model.startChat(history: history ?? []);
  }

  Future<String?> sendMessageInSession(ChatSession session, String message) async {
    try {
      final content = Content.text(message);
      final response = await session.sendMessage(content);
      return response.text;
    } catch (e) {
      print('❌ Lỗi gửi tin nhắn trong session: $e');
      return null;
    }
  }
}