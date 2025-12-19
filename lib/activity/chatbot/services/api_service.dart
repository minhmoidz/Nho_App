import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../login/auth_service.dart';
import '../models/chat_model.dart';

class ApiService {
  final AuthService _authService = AuthService();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  Future<List<Conversation>> getHistory() async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history');
    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          listData = decodedData['data'] ??
              decodedData['items'] ??
              decodedData['conversations'] ??
              decodedData['history'] ??
              [];
        }

        return listData.map((e) => Conversation.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error getHistory: $e");
    }
    return [];
  }

  Future<String?> createNewConversation() async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/new');

    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers, body: jsonEncode({}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('conversation_id')) {
            return decoded['conversation_id'].toString();
          }
          if (decoded.containsKey('id')) {
            return decoded['id'].toString();
          }

          if (decoded.containsKey('data')) {
            final innerData = decoded['data'];
            if (innerData is Map) {
              return innerData['conversation_id']?.toString() ??
                  innerData['id']?.toString();
            }
            if (innerData is String || innerData is int) {
              return innerData.toString();
            }
          }
        }
      }
    } catch (e) {
      print("Error createNewConversation: $e");
    }
    return null;
  }

  Future<List<ChatMessage>> getConversationDetail(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/$conversationId');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> rawList = [];

        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('messages')) {
            rawList = decoded['messages'];
          } else if (decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data is List) {
              rawList = data;
            } else if (data is Map && data.containsKey('messages')) {
              rawList = data['messages'];
            }
          }
        }

        return rawList.map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error getConversationDetail: $e");
    }
    return [];
  }

  Future<bool> deleteConversation(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/history/$conversationId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleteConversation: $e");
      return false;
    }
  }

  Future<String?> sendMessage(String message, String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat').replace(
      queryParameters: {'conversation_id': conversationId},
    );

    try {
      final headers = await _getHeaders();
      final body = jsonEncode({"message": message});
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? data['message'] ?? data['text'];
      }
    } catch (e) {
      print("Error sendMessage: $e");
    }
    return null;
  }
}