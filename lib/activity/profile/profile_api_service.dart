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

  static Future<UserProfile?> getProfile() async {
   final uri = Uri.parse('$_baseUrl/api/v1/profile');
   final headers = await _getAuthenticatedHeaders(isJson: false);

   final response = await http.get(uri, headers: headers);

   // 👉 CHƯA CÓ PROFILE → trả về null
   if (response.statusCode == 404) {
    return null;
   }

   // 👉 CÁC LỖI THẬT
   if (response.statusCode != 200) {
    throw Exception(
     'Lỗi tải hồ sơ: ${response.statusCode}',
    );
   }

   final body = json.decode(utf8.decode(response.bodyBytes));

   if (body['success'] != true) {
    throw Exception(body['message'] ?? 'Không lấy được profile');
   }

   final data = body['data'];

   if (data == null || data is! Map || data.isEmpty) {
    return null;
   }

   return UserProfile.fromJson(
    Map<String, dynamic>.from(data),
   );
  }

  static Future<UserProfile> updateProfile({
   required String fullName,
   required String birthDate,
   required String phone,
   String? address,
  }) async {
   final uri = Uri.parse('$_baseUrl/api/v1/profile');
   final headers = await _getAuthenticatedHeaders(isJson: true);

   final body = jsonEncode({
    "full_name": fullName,
    "birth_date": birthDate,
    "phone": phone,
    "address": address,
   });

   final response = await http.post(
    uri,
    headers: headers,
    body: body,
   );

   if (response.statusCode != 200) {
    throw Exception(
     'Lỗi cập nhật hồ sơ: ${response.statusCode}',
    );
   }

   final decoded = json.decode(utf8.decode(response.bodyBytes));

   if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? 'Cập nhật thất bại');
   }

   return UserProfile.fromJson(
    Map<String, dynamic>.from(decoded['data']),
   );
  }

}