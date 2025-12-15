import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../login/auth_service.dart';
import '../models/chat_model.dart';


class ApiService {
  final AuthService _authService = AuthService(); // Khởi tạo AuthService

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? "http://192.168.30.28:8010";

  // --- HÀM TẠO HEADERS ĐỘNG ---
  // Headers giờ phải là Future vì cần đợi đọc Token từ SecureStorage
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();

    // Header cơ bản
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    // Nếu có token thì kẹp vào Authorization
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  // --- CÁC HÀM GỌI API ---

  // 1. Lấy danh sách lịch sử
  Future<List<Conversation>> getHistory() async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history');
    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print("Status: ${response.statusCode}");
      // In ra body để biết chính xác cấu trúc JSON
      print("API Body: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> listData = [];

        // TRƯỜNG HỢP 1: API trả về List trực tiếp []
        if (decodedData is List) {
          listData = decodedData;
        }
        // TRƯỜNG HỢP 2: API trả về Map {} chứa List
        else if (decodedData is Map<String, dynamic>) {
          // Bạn cần thử các key phổ biến hoặc xem log "API Body" ở trên để biết key đúng
          if (decodedData.containsKey('data')) {
            listData = decodedData['data'];
          } else if (decodedData.containsKey('items')) {
            listData = decodedData['items'];
          } else if (decodedData.containsKey('conversations')) {
            listData = decodedData['conversations'];
          } else if (decodedData.containsKey('history')) {
            listData = decodedData['history'];
          } else {
            print("⚠️ Không tìm thấy key chứa danh sách trong JSON Object");
          }
        }

        return listData.map((e) => Conversation.fromJson(e)).toList();
      }
    } catch (e) {
      print("❌ Lỗi getHistory: $e");
    }
    return [];
  }

  // 2. Tạo hội thoại mới
  Future<String?> createNewConversation() async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/new');
    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['conversation_id'] ?? data['id'];
      }
    } catch (e) {
      print("Lỗi createNewConversation: $e");
    }
    return null;
  }

  // 3. Lấy chi tiết
  Future<List<ChatMessage>> getConversationDetail(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/$conversationId');
    print("GET DETAIL URL: $uri"); // Debug URL

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print("Detail Status: ${response.statusCode}");
      print("Detail Body: ${utf8.decode(response.bodyBytes)}"); // QUAN TRỌNG: Xem server trả về gì

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> rawList = [];

        // Logic "thông minh" để tìm danh sách tin nhắn bất kể cấu trúc
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Trường hợp 1: {"messages": [...]}
          if (decoded.containsKey('messages')) {
            rawList = decoded['messages'];
          }
          // Trường hợp 2: {"data": [...]} (List tin nhắn nằm trong data)
          else if (decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data is List) {
              rawList = data;
            } else if (data is Map && data.containsKey('messages')) {
              // Trường hợp 3: {"data": {"messages": [...]}}
              rawList = data['messages'];
            }
          }
        }

        return rawList.map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      print("❌ Lỗi getConversationDetail: $e");
    }
    return [];
  }

  // 4. Xóa hội thoại
  Future<bool> deleteConversation(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/$conversationId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi deleteConversation: $e");
      return false;
    }
  }

  // 5. Gửi tin nhắn
  Future<String?> sendMessage(String message, String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat').replace(queryParameters: {
      'conversation_id': conversationId,
    });

    try {
      final headers = await _getHeaders();
      final body = jsonEncode({"message": message});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? data['message'] ?? data['text'];
      } else {
        print("Chat Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Lỗi sendMessage: $e");
    }
    return null;
  }
}