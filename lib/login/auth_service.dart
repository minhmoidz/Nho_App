import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  // Sử dụng flutter_secure_storage để bảo mật token
  final _storage = const FlutterSecureStorage();

  // Key để lưu token
  final _tokenKey = 'access_token';

  // 1. HÀM LƯU TOKEN
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // 2. HÀM LẤY TOKEN
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 3. HÀM XÓA TOKEN (Dùng nội bộ hoặc khi cần xóa thủ công)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // 4. HÀM ĐĂNG XUẤT (Wrapper cho deleteToken để dễ gọi từ UI)
  // -> Đây là hàm giúp sửa lỗi "undefined method"
  Future<void> logout() async {
    await deleteToken();
  }

  // 5. HÀM LẤY USER ID TỪ TOKEN
  Future<String?> getUserId() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      // Kiểm tra token hết hạn
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Token đã hết hạn');
        await logout(); // Tự động logout nếu token hết hạn
        return null;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Lấy 'sub' (subject) hoặc 'id' tùy theo cấu trúc token của API bạn
      // Thông thường Keycloak hoặc chuẩn JWT dùng 'sub' làm ID
      return decodedToken['sub'] ?? decodedToken['id'];
    } catch (e) {
      debugPrint('Lỗi giải mã token: $e');
      return null;
    }
  }
}