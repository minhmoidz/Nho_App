import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../login/auth_service.dart';
class DiaryApiService {
  static const String _baseUrl = 'http://192.168.30.28:8010/api/v1';

  static Future<Map<String, String>> _getAuthenticatedHeaders({bool isJson = true}) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) throw Exception('Chưa đăng nhập.');
    final authHeader = 'Bearer $token';
    return isJson
        ? {'Content-Type': 'application/json', 'Authorization': authHeader}
        : {'Authorization': authHeader};
  }

  /// API POST: /api/v1/note
  static Future<Map<String, dynamic>> createDiaryEntry({
    required XFile image,
    required String content,
    required bool autoAnalyze,
  }) async {
    try {
      debugPrint('--- Bắt đầu tạo Note ---');

      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) throw Exception('Người dùng chưa đăng nhập.');

      // CẬP NHẬT ENDPOINT: /note
      final uri = Uri.parse('$_baseUrl/note');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      // 1. Xử lý file ảnh
      final mimeTypeData = lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]);
      final String mimeType = mimeTypeData ?? 'image/jpeg';
      final List<String> mimeTypeSplit = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Tên trường file theo CURL
          image.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

      // 2. Các tham số khác
      request.fields['auto_analyze'] = autoAnalyze.toString();

      // Lưu ý: CURL bạn đưa không có trường content, nhưng UI lại có chỗ nhập text.
      // Tôi vẫn gửi kèm 'content' để backend lưu ghi chú người dùng nhập.
      // Nếu backend quy định tên khác (ví dụ: 'text', 'note'), hãy sửa key này.
      if (content.isNotEmpty) {
        request.fields['content'] = content;
      }

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Lỗi Server (${response.statusCode}): $responseBody');
      }
    } catch (e) {
      debugPrint('Lỗi API createDiaryEntry: $e');
      throw Exception('Không thể tạo nhật ký: $e');
    }
  }

  /// API GET: /api/v1/note
  static Future<List<dynamic>> getDiaryEntries({int limit = 10}) async {
    try {
      // CẬP NHẬT ENDPOINT: /note
      final uri = Uri.parse('$_baseUrl/note').replace(
        queryParameters: {'limit': limit.toString()},
      );

      final headers = await _getAuthenticatedHeaders(isJson: false);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = json.decode(body);

        // Xử lý linh hoạt cấu trúc trả về
        if (data is List) return data;
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          return data['data'];
        }
        return [];
      } else {
        throw Exception('Lỗi tải danh sách (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Không thể tải danh sách note: $e');
    }
  }
}