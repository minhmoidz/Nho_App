import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Cần import này để set MediaType
import '../../login/auth_service.dart';
import 'package:flutter/foundation.dart'; // Để dùng debugPrint

class MemoryService {
  // Cấu hình IP
  final String _baseUrl = "http://192.168.30.28:8010"; // IP máy thật
  final String _workerUrl = "https://my-r2-worker.sangtd.workers.dev";
  final AuthService _authService = AuthService();

  // --- HELPER: Xử lý Response ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return null; // No Content

    // Decode UTF-8 để không bị lỗi font tiếng Việt
    final dynamic body = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMsg = response.reasonPhrase ?? 'Lỗi không xác định';
      if (body is Map) {
        errorMsg = body['detail'] ?? body['message'] ?? errorMsg;
      }
      throw HttpException('$errorMsg (Code: ${response.statusCode})');
    }
  }

  // ===========================================================================
  // 1. GET MEMORIES (Lấy danh sách)
  // ===========================================================================
  Future<List<dynamic>> getMemories({int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory?limit=$limit');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      };

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

  // ===========================================================================
  // 2. CREATE MEMORY (Multipart: Ảnh + Audio + Text)
  // API: POST /api/v1/memory/photo_audio
  // ===========================================================================
  Future<dynamic> createMemory({
    required File imageFile,
    File? audioFile,
    required String content,
    List<String> tags = const ["family"]
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/photo_audio');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Vui lòng đăng nhập lại");

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // 1. Thêm các fields text
      request.fields['content'] = content;

      // API yêu cầu tags là string, ta convert list -> json string
      request.fields['tags'] = jsonEncode(tags);

      // 2. Thêm file Ảnh (Bắt buộc)
      // Lưu ý: MediaType 'image/jpeg' rất quan trọng với FastAPI
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartImage = http.MultipartFile(
          'image',
          imageStream,
          imageLength,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg')
      );
      request.files.add(multipartImage);

      // 3. Thêm file Audio (Tùy chọn)
      if (audioFile != null) {
        var audioStream = http.ByteStream(audioFile.openRead());
        var audioLength = await audioFile.length();
        var multipartAudio = http.MultipartFile(
            'audio',
            audioStream,
            audioLength,
            filename: audioFile.path.split('/').last,
            contentType: MediaType('audio', 'mpeg') // Hoặc 'audio/wav' tùy file
        );
        request.files.add(multipartAudio);
      }

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 3. CREATE TEXT ONLY MEMORY (JSON)
  // API: POST /api/v1/memory
  // Body: { "content": "string", "tags": ["string"] }
  // ===========================================================================
  Future<dynamic> createTextMemory({
    required String content,
    List<String> tags = const ["family"]
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      };

      final body = jsonEncode({
        "content": content,
        "tags": tags
      });

      final response = await http.post(url, headers: headers, body: body);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 4. UPDATE MEMORY
  // API: PUT /api/v1/memory/{memory_id}
  // Body: { "content": "string", "tags": ["string"] }
  // ===========================================================================
  Future<void> updateMemory({
    required int id,
    required String content,
    List<String> tags = const ["family"]
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      };

      // Format body theo đúng yêu cầu API
      final body = json.encode({
        "content": content,
        "tags": tags
      });

      final response = await http.put(url, headers: headers, body: body);
      _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 5. DELETE MEMORY
  // API: DELETE /api/v1/memory/{memory_id}
  // ===========================================================================
  Future<void> deleteMemory(int id) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.delete(url, headers: headers);
      _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 6. GET DETAIL
  // ===========================================================================
  Future<Map<String, dynamic>> getMemoryDetail(int id) async {
    final url = Uri.parse('$_baseUrl/api/v1/memory/$id');
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("Chưa đăng nhập");

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      };

      final response = await http.get(url, headers: headers);
      final dynamic data = _handleResponse(response);

      if (data is Map<String, dynamic>) return data;
      throw Exception("Format lỗi");
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // HÀM SIGNED URL (GIỮ NGUYÊN TỪ CODE CŨ CỦA BẠN)
  // ===========================================================================
  Future<String?> getSignedUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (!rawUrl.contains("workers.dev") && !rawUrl.contains("r2.cloudflarestorage")) {
      return rawUrl;
    }
    try {
      String fileName = rawUrl.split('/').last;
      String userFolder = "user_2";
      final regex = RegExp(r'user_\d+');
      final match = regex.firstMatch(rawUrl);
      if (match != null) userFolder = match.group(0)!;

      String realKey = "uploads/uploads/$userFolder/images/$fileName";
      // Xử lý riêng cho audio nếu cần, tạm thời để logic cũ của bạn
      if (fileName.endsWith(".mp3") || fileName.endsWith(".m4a") || fileName.endsWith(".wav")) {
        realKey = "uploads/uploads/$userFolder/audios/$fileName";
      }

      final requestUrl = Uri.parse('$_workerUrl/generate-download-url?fileName=${Uri.encodeComponent(realKey)}');
      final response = await http.get(requestUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['downloadUrl'];
      } else {
        return rawUrl;
      }
    } catch (e) {
      return rawUrl;
    }
  }
}