import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../login/auth_service.dart';

class ChatApiService {
  // Địa chỉ gốc API
  static const String _baseUrl = 'http://192.168.30.28:8010/api/v1';

  // --- HÀM LẤY HEADERS (CÓ TOKEN) ---
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Chưa đăng nhập.');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. Gửi tin nhắn (POST /api/v1/chat)
  static Future<String> sendMessage(String message) async {
    try {
      final uri = Uri.parse('$_baseUrl/chat');
      final headers = await _getHeaders();

      final body = json.encode({
        "message": message
      });

      final response = await http.post(uri, headers: headers, body: body);
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        // Xử lý logic lấy text trả về từ server
        // Giả sử server trả về: { "response": "Xin chào..." } hoặc { "data": "..." }
        if (data is Map) {
          return data['response'] ?? data['data'] ?? data['message'] ?? responseBody;
        }
        return responseBody;
      } else {
        throw Exception('Lỗi ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Lỗi sendMessage: $e');
      throw Exception('Không thể gửi tin nhắn: $e');
    }
  }

  /// 2. Lấy gợi ý hồi tưởng (GET /api/v1/memory-prompt)
  static Future<String> getMemoryPrompt() async {
    try {
      final uri = Uri.parse('$_baseUrl/memory-prompt');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        // Giả sử server trả về: { "prompt": "Hãy kể về kỷ niệm..." }
        return data['prompt'] ?? data['message'] ?? "Hôm nay bạn thế nào?";
      } else {
        throw Exception('Lỗi tải gợi ý: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi getMemoryPrompt: $e');
      return ""; // Trả về rỗng nếu lỗi, để UI không hiển thị gì
    }
  }
}