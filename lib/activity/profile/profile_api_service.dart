import 'dart:convert';

import 'package:http/http.dart' as http;

import './../login/auth_service.dart';
import 'user_profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileApiService {
  static final String _baseUrl = dotenv.env['API_BASE_URL']!;

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

  static Future<UserProfile> getProfile() async {
   try{
    final uri = Uri.parse('$_baseUrl/api/v1/profile');
    final headers = await _getAuthenticatedHeaders(isJson: false);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
     final body = json.decode(utf8.decode(response.bodyBytes));

     if (body['success'] == true && body['data'] != null) {
      return UserProfile.fromJson(body['data']);
     } else {
      throw Exception('API trả về không có data profile');
     }
    } else {
     throw Exception(
      'Lỗi tải hồ sơ: ${response.statusCode} - ${response.body}',
     );
    }
   } catch (e) {
    throw Exception('Không thể kết nối máy chủ. Lỗi: $e');
   }
  }
}