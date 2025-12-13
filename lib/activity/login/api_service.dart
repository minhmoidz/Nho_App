import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // *** QUAN TRỌNG: Kiểm tra kỹ IP này. Nếu chạy máy thật cần chung WiFi ***
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  final AuthService _authService = AuthService();

  // 1. Helper lấy Header có Token
  Future<Map<String, String>> _getAuthorizedHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập hoặc token không hợp lệ.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // 2. Helper xử lý Response chung
  dynamic _handleResponse(http.Response response) {
    // Log status code để debug
    debugPrint('API Response Status: ${response.statusCode}');

    try {
      // Decode UTF-8 để hiển thị tiếng Việt không bị lỗi font
      final body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Kiểm tra logic nghiệp vụ (nếu API trả về success: true/false)
        if (body is Map && body.containsKey('success')) {
          if (body['success'] == true) {
            return body;
          } else {
            throw Exception(body['message'] ?? 'Thất bại nhưng không có thông báo lỗi');
          }
        }
        // Trường hợp API không có key 'success', trả về body luôn
        return body;
      } else {
        // Xử lý lỗi HTTP (400, 401, 404, 500...)
        throw HttpException(
          '${response.statusCode}: ${body['detail'] ?? body['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Nếu body không phải JSON hoặc lỗi decode
      if (e is HttpException || e is Exception) rethrow;
      throw Exception('Lỗi xử lý dữ liệu: $e');
    }
  }

  // ===========================================================================
  // CÁC HÀM GỌI API (Đã thêm /v1)
  // ===========================================================================

  // 3. Đăng nhập thường
  Future<Map<String, dynamic>> login(String username, String password) async {
    // SỬA: Thêm /v1 vào đường dẫn
    final url = Uri.parse('$_baseUrl/api/v1/auth/login');

    final body = jsonEncode({
      'username': username,
      'password': password,
    });

    debugPrint('POST Request: $url'); // Log URL để kiểm tra
    debugPrint('Body: $body');

    try {
      final response = await http.post(url, headers: _headers, body: body);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  // 4. Đăng nhập Keycloak
  Future<Map<String, dynamic>> loginKeycloak(String username, String password) async {
    // SỬA: Thêm /v1
    final url = Uri.parse('$_baseUrl/api/v1/auth/login-keycloak');

    final body = jsonEncode({
      'username': username,
      'password': password,
    });

    debugPrint('POST Request: $url');

    final response = await http.post(url, headers: _headers, body: body);
    return _handleResponse(response);
  }

  // 5. Đăng ký tài khoản
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    // SỬA: Thêm /v1
    final url = Uri.parse('$_baseUrl/api/v1/auth/register');
    final body = jsonEncode(userData);

    debugPrint('POST Request: $url');

    final response = await http.post(url, headers: _headers, body: body);
    return _handleResponse(response);
  }

  // 6. Lấy thông tin User (Profile)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // API này của bạn code cũ đã có /v1 -> Giữ nguyên
    final url = Uri.parse('$_baseUrl/api/v1/users/$userId');

    try {
      final headers = await _getAuthorizedHeaders(); // Cần token
      debugPrint('GET Request: $url');

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Get Profile Error: $e');
      rethrow;
    }
  }

  // 7. Cập nhật thông tin User
  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/api/v1/users/$userId');

    try {
      final headers = await _getAuthorizedHeaders();
      final body = jsonEncode(userData);

      debugPrint('PUT Request: $url');

      final response = await http.put(url, headers: headers, body: body);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow;
    }
  }
}