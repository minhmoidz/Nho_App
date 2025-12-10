import 'dart:convert';
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // BẮT BUỘC: Để set Content-Type
import 'package:mime/mime.dart';

import '../../login/auth_service.dart'; // BẮT BUỘC: Để nhận diện đuôi file (jpg, png)

class OcrApiService {
  // Địa chỉ API OCR
  static const String _apiUrl = 'https://be1-service-441093451544.asia-east1.run.app/api/v1/ocr';

  /// Hàm gửi ảnh lên Server để lấy text
  static Future<String> extractTextFromImage(XFile image) async {
    try {
      debugPrint('--- Bắt đầu gọi API OCR ---');

      // 1. Lấy Token xác thực
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('Bạn chưa đăng nhập (Token không tồn tại).');
      }

      // 2. Chuẩn bị Request Multipart
      final uri = Uri.parse(_apiUrl);
      var request = http.MultipartRequest('POST', uri);

      // Thêm Header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      // 3. XỬ LÝ QUAN TRỌNG: CONTENT-TYPE CỦA ẢNH
      // Server cần biết chính xác đây là image/jpeg hay image/png
      // Nếu không có bước này, server nhận diện là binary rác và trả về lỗi 500/400

      // Tự động đoán loại file dựa trên đuôi hoặc header bytes
      final mimeTypeData = lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]);

      // Mặc định là image/jpeg nếu không đoán được
      final String mimeType = mimeTypeData ?? 'image/jpeg';

      // Tách chuỗi 'image/jpeg' thành ['image', 'jpeg']
      final List<String> mimeTypeSplit = mimeType.split('/');

      debugPrint('Đang upload file: ${image.path}');
      debugPrint('Loại file nhận diện (MimeType): $mimeType');

      // Thêm file vào request với contentType cụ thể
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Tên trường mà Server yêu cầu (FastAPI thường là 'file')
          image.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

      // 4. Gửi Request
      var streamedResponse = await request.send();

      // 5. Đọc phản hồi
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('HTTP Status Code: ${response.statusCode}');

      // Giải mã body response (dùng utf8 để không lỗi font tiếng Việt)
      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data['success'] == true) {
          // Lấy trường text trả về.
          // Kiểm tra xem API trả về data['text'] hay data['data']['text']
          if (data['data'] != null && data['data'] is Map && data['data']['text'] != null) {
            return data['data']['text'];
          } else if (data['text'] != null) {
            return data['text'];
          } else {
            return ''; // Trả về rỗng nếu không tìm thấy text
          }
        } else {
          throw Exception(data['message'] ?? 'API xử lý thất bại.');
        }
      } else if (response.statusCode == 413) {
        throw Exception('Ảnh quá lớn, server từ chối nhận.');
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      } else {
        // Ném lỗi chi tiết từ server để debug
        throw Exception('Lỗi Server (${response.statusCode}): $responseBody');
      }

    } catch (e) {
      debugPrint('Lỗi tại extractTextFromImage: $e');
      // Ném lỗi ra ngoài để giao diện (UI) hiển thị thông báo cho người dùng
      rethrow;
    }
  }
}