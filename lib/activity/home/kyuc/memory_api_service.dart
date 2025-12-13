import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../login/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MemoryApiService {
  static final String _baseUrl = dotenv.env['API_BASE_URL']!;

  // *** HÀM BỔ TRỢ ĐỂ LẤY HEADERS (GIỐNG NHƯ TRƯỚC) ***
  static Future<Map<String, String>> _getAuthenticatedHeaders(
      {bool isJson = true}) async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Người dùng chưa đăng nhập (không tìm thấy token).');
    }

    final authHeader = 'Bearer $token';

    if (isJson) {
      return {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      };
    } else {
      return {
        'Authorization': authHeader,
      };
    }
  }

  /// 1. Lấy danh sách Ký ức (GET /api/v1/memories)
  static Future<List<dynamic>> getMemories({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/memories').replace(
        queryParameters: {'limit': limit.toString()},
      );

      // 2. LẤY HEADERS CÓ TOKEN
      final headers = await _getAuthenticatedHeaders(isJson: false);

      // 3. GỬI REQUEST VỚI HEADERS MỚI
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data as List<dynamic>;
      } else {
        throw Exception(
            'Lỗi tải Ký ức: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối máy chủ Ký ức. Lỗi: $e');
    }
  }

  /// 2. Tạo một Ký ức mới (POST /api/v1/memories)
  static Future<Map<String, dynamic>> createMemory({
    required String content,
    required List<String> tags,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/memories');

      // 2. LẤY HEADERS CÓ TOKEN
      // (Hàm này đã bao gồm 'Content-Type': 'application/json')
      final headers = await _getAuthenticatedHeaders(isJson: true);

      final body = json.encode({
        'content': content,
        'tags': tags,
      });

      // 3. GỬI REQUEST VỚI HEADERS MỚI
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Lỗi tạo Ký ức: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Không thể tạo Ký ức. Lỗi: $e');
    }
  }
}