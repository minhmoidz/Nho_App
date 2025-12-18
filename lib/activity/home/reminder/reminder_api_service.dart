import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../login/auth_service.dart'; // Đảm bảo đường dẫn đúng

class ReminderApiService {
  // Cấu hình đúng đường dẫn API
  static const String _baseUrl = 'http://192.168.30.28:8010/api/v1';

  // --- HELPER: LẤY HEADERS KÈM TOKEN ---
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Lỗi: Bạn chưa đăng nhập!');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    };
  }

  // ==================================================
  // 1. LẤY DANH SÁCH NHẮC NHỞ (GET)
  // API: /api/v1/reminder
  // ==================================================
  static Future<List<dynamic>> getReminders() async {
    try {
      final url = Uri.parse('$_baseUrl/reminder');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Không tải được dữ liệu. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ==================================================
  // 2. TẠO NHẮC NHỞ MỚI (POST)
  // API: /api/v1/reminder
  // ==================================================
  static Future<Map<String, dynamic>> createReminder({
    required String title,
    required String description,
    required DateTime remindAt,
    int noteId = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/reminder');
    final headers = await _getHeaders();

    final body = json.encode({
      "title": title,
      "description": description,
      "remind_at": remindAt.toIso8601String(),
      "note_id": noteId,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không tạo được nhắc nhở: ${response.body}');
    }
  }

  // ==================================================
  // 3. CẬP NHẬT NỘI DUNG (PUT) - Dùng cho Form Sửa
  // API: /api/v1/reminder/{id}
  // ==================================================
  static Future<void> updateReminder({
    required int id,
    required String title,
    required String description,
    required DateTime remindAt,
    required bool isCompleted,
  }) async {
    // SỬA: Dùng /reminder thay vì /diary
    final url = Uri.parse('$_baseUrl/reminder/$id');
    final headers = await _getHeaders();

    final body = json.encode({
      "title": title,
      "description": description,
      "remind_at": remindAt.toIso8601String(),
      "is_completed": isCompleted,
    });

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Lỗi cập nhật: ${response.body}');
    }
  }

  // ==================================================
  // 4. CẬP NHẬT TRẠNG THÁI (PUT) - Dùng cho Checkbox
  // API: /api/v1/reminder/{id}
  // Giữ nguyên logic gửi full data như yêu cầu
  // ==================================================
  static Future<void> updateReminderStatus({
    required int id,
    required bool isCompleted,
    required String currentTitle,
    required String currentDescription,
    required String currentRemindAt,
  }) async {
    final url = Uri.parse('$_baseUrl/reminder/$id');
    final headers = await _getHeaders();

    final body = json.encode({
      "title": currentTitle,
      "description": currentDescription,
      "remind_at": currentRemindAt,
      "is_completed": isCompleted
    });

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Lỗi thay đổi trạng thái: ${response.body}');
    }
  }

  // ==================================================
  // 5. XÓA NHẮC NHỞ (DELETE)
  // API: /api/v1/reminder/{id}
  // ==================================================
  static Future<void> deleteReminder(int id) async {
    final url = Uri.parse('$_baseUrl/reminder/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Không xóa được: ${response.body}');
    }
  }
}