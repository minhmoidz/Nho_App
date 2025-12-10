import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../login/auth_service.dart';

class MemoryService {
  // 1. Cấu hình IP (Dùng 10.0.2.2 cho máy ảo Android, IP thật cho máy thật)
  final String _baseUrl = "http://192.168.30.28:8000";

  // URL Worker của bạn
  final String _workerUrl = "https://my-r2-worker.sangtd.workers.dev";

  final AuthService _authService = AuthService();

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return null;
    final dynamic body = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMsg = response.reasonPhrase ?? 'Lỗi không xác định';
      if (body is Map) errorMsg = body['detail'] ?? body['message'] ?? errorMsg;
      throw HttpException('$errorMsg (Code: ${response.statusCode})');
    }
  }

  // ===========================================================================
  // HÀM QUAN TRỌNG: TẠO KEY CHUẨN ĐỂ LẤY SIGNED URL
  // ===========================================================================
  Future<String?> getSignedUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;

    // Nếu không phải link worker thì trả về luôn
    if (!rawUrl.contains("workers.dev") && !rawUrl.contains("r2.cloudflarestorage")) {
      return rawUrl;
    }

    try {
      // LOGIC TẠO KEY CHUẨN XÁC 100%

      // 1. Lấy tên file (phần cuối cùng)
      // Vd: 20251127_102431_6a123954.jpeg
      String fileName = rawUrl.split('/').last;

      // 2. Lấy User ID (folder user_X)
      String userFolder = "user_2"; // Mặc định nếu không tìm thấy
      final regex = RegExp(r'user_\d+');
      final match = regex.firstMatch(rawUrl);
      if (match != null) {
        userFolder = match.group(0)!;
      }

      // 3. GHÉP CHUỖI THEO CẤU TRÚC THẬT TRÊN R2
      // Cấu trúc này lấy từ việc giải mã link Base64 của bạn
      String realKey = "uploads/uploads/$userFolder/images/$fileName";

      debugPrint("🔑 Key chuẩn gửi lên Worker: $realKey");

      // 4. GỌI API Worker
      final requestUrl = Uri.parse('$_workerUrl/generate-download-url?fileName=${Uri.encodeComponent(realKey)}');

      final response = await http.get(requestUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Lấy link downloadUrl từ JSON trả về
        String finalUrl = data['downloadUrl'];
        // debugPrint("✅ Đã lấy được Link Signed: $finalUrl");
        return finalUrl;
      } else {
        debugPrint("❌ Worker lỗi (${response.statusCode}): ${response.body}");
        return rawUrl;
      }
    } catch (e) {
      debugPrint("❌ Exception getSignedUrl: $e");
      return rawUrl;
    }
  }

  // ===========================================================================
  // CÁC HÀM API KHÁC (GIỮ NGUYÊN)
  // ===========================================================================
  Future<List<dynamic>> getMemories({int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory?limit=$limit');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");
      final headers = {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token'};
      final response = await http.get(url, headers: headers);
      final dynamic data = _handleResponse(response);
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
      return [];
    } catch (e) {
      debugPrint('Error fetching memories: $e');
      rethrow;
    }
  }

  Future<dynamic> createMemory({required File imageFile, File? audioFile, required String content, List<String> tags = const ["family"]}) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/photo_audio');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Vui lòng đăng nhập lại");
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;
      request.fields['tags'] = jsonEncode(tags);
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartImage = http.MultipartFile('image', imageStream, imageLength, filename: imageFile.path.split('/').last, contentType: MediaType('image', 'jpeg'));
      request.files.add(multipartImage);
      if (audioFile != null) {
        var audioStream = http.ByteStream(audioFile.openRead());
        var audioLength = await audioFile.length();
        var multipartAudio = http.MultipartFile('audio', audioStream, audioLength, filename: audioFile.path.split('/').last, contentType: MediaType('audio', 'mpeg'));
        request.files.add(multipartAudio);
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) { rethrow; }
  }

  Future<void> updateMemory({required int id, required String content}) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");
      final headers = {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token'};
      final body = json.encode({"content": content, "tags": ["family"]});
      final response = await http.put(url, headers: headers, body: body);
      _handleResponse(response);
    } catch (e) { rethrow; }
  }

  Future<void> deleteMemory(int id) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.delete(url, headers: headers);
      _handleResponse(response);
    } catch (e) { rethrow; }
  }

  Future<Map<String, dynamic>> getMemoryDetail(int id) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");
      final headers = {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token'};
      final response = await http.get(url, headers: headers);
      final dynamic data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      throw Exception("Format lỗi");
    } catch (e) { rethrow; }
  }
}