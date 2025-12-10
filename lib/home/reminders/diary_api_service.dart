import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../login/auth_service.dart';



class DiaryApiService {
  static const String _baseUrl = 'https://be1-service-441093451544.asia-east1.run.app/api/v1';

  // Hàm lấy Headers (Giữ nguyên)
  static Future<Map<String, String>> _getAuthenticatedHeaders(
      {bool isJson = true}) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) throw Exception('Chưa đăng nhập.');
    final authHeader = 'Bearer $token';
    return isJson
        ? {'Content-Type': 'application/json', 'Authorization': authHeader}
        : {'Authorization': authHeader};
  }

  /// Tạo nhật ký mới (Gửi Ảnh + Nội dung Text)
  static Future<Map<String, dynamic>> createDiaryEntry({
    required XFile image,
    required String content, // <--- THAM SỐ MỚI: Nội dung chữ từ ảnh
    required bool autoAnalyze,
  }) async {
    try {
      debugPrint('--- Bắt đầu tạo nhật ký ---');

      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) throw Exception('Người dùng chưa đăng nhập.');

      final uri = Uri.parse('$_baseUrl/diaries');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      // 1. Xử lý ảnh (Content-Type)
      final mimeTypeData = lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]);
      final String mimeType = mimeTypeData ?? 'image/jpeg';
      final List<String> mimeTypeSplit = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

      // 2. Gửi kèm các trường dữ liệu khác
      request.fields['auto_analyze'] = autoAnalyze.toString();

      // Gửi nội dung văn bản (trích xuất từ OCR hoặc người dùng nhập)
      request.fields['content'] = content;

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Lỗi từ máy chủ: ${response.statusCode}. Body: $responseBody');
      }
    } catch (e) {
      debugPrint('Lỗi createDiaryEntry: $e');
      throw Exception('Không thể tạo nhật ký: $e');
    }
  }

  // Hàm lấy danh sách nhật ký (Giữ nguyên)
  static Future<List<dynamic>> getDiaryEntries({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/diaries').replace(
        queryParameters: {'limit': limit.toString()},
      );
      final headers = await _getAuthenticatedHeaders(isJson: false);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
        if (data is Map && data['data'] is List) return data['data'];
        return [];
      } else {
        throw Exception('Lỗi tải danh sách: ${response.statusCode}.');
      }
    } catch (e) {
      throw Exception('Không thể tải danh sách nhật ký: $e');
    }
  }
}