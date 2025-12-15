import 'dart:convert';
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;
import '../../login/auth_service.dart'; // Đảm bảo đường dẫn đúng

class HealthApiService {
  // LƯU Ý QUAN TRỌNG:
  // - Nếu chạy máy ảo (Emulator): dùng 'http://10.0.2.2:8000/api/v1/health'
  // - Nếu chạy máy thật: dùng IP LAN ví dụ 'http://192.168.1.x:8000/api/v1/health'
  static const String _baseUrl = 'http://192.168.30.28:8010/api/v1/health';

  // Helper: Lấy headers và Token
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('❌ LỖI: Không tìm thấy Token. Người dùng chưa đăng nhập?');
      throw Exception('Chưa đăng nhập (Token null)');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- 1. POST: Gửi chỉ số sức khỏe ---
  static Future<void> createHealthLog({
    required String logType,
    required String value,
    String note = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/logs');

    // Chuẩn bị body
    final Map<String, dynamic> bodyData = {
      'log_type': logType, // Ví dụ: "Huyết áp" hoặc "blood_pressure" tùy backend quy định
      'value': value,
      'note': note,
    };

    try {
      final headers = await _getHeaders();

      // [DEBUG] In ra dữ liệu sắp gửi
      debugPrint('------------------------------------------------');
      debugPrint('🚀 Đang POST tới: $uri');
      debugPrint('📦 Body gửi đi: ${json.encode(bodyData)}');
      debugPrint('🔑 Token: ${headers['Authorization']}');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(bodyData),
      );

      // [DEBUG] In ra phản hồi từ server
      debugPrint('⬅️ Server trả về code: ${response.statusCode}');
      debugPrint('⬅️ Server trả về body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ POST thành công!');
      } else {
        throw Exception('Lỗi Server (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ LỖI createHealthLog: $e');
      rethrow; // Ném lỗi ra để màn hình UI hiển thị thông báo
    }
  }

  // --- 2. GET: Lấy lịch sử đo ---
  static Future<List<dynamic>> getHealthLogs({int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/logs?limit=$limit');

    try {
      final headers = await _getHeaders();

      debugPrint('------------------------------------------------');
      debugPrint('🚀 Đang GET từ: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('⬅️ Server trả về code: ${response.statusCode}');
      // debugPrint('⬅️ Body: ${response.body}'); // Bỏ comment nếu muốn xem full data

      if (response.statusCode == 200) {
        // Decode UTF-8 để không lỗi font tiếng Việt
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('✅ Đã lấy được ${data.length} bản ghi.');
        return data;
      } else {
        throw Exception('Lỗi tải lịch sử (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ LỖI getHealthLogs: $e');
      return [];
    }
  }

  // --- 3. GET: Lấy phân tích (Insights) ---
  static Future<Map<String, dynamic>> getHealthInsights() async {
    final uri = Uri.parse('$_baseUrl/insights');
    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        debugPrint('⚠️ Lỗi lấy Insights: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('❌ LỖI getHealthInsights: $e');
      return {};
    }
  }
}