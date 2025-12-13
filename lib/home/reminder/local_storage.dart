import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyReminders = 'saved_reminders_v1';

  // 1. LƯU DỮ LIỆU VÀO MÁY
  static Future<void> saveReminders(List<dynamic> reminders) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Chuyển List Object thành chuỗi JSON String để lưu
    String jsonString = jsonEncode(reminders);
    await prefs.setString(_keyReminders, jsonString);
    print("💾 Đã lưu ${reminders.length} việc vào bộ nhớ máy.");
  }

  // 2. LẤY DỮ LIỆU TỪ MÁY RA
  static Future<List<dynamic>> getReminders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_keyReminders);

    if (jsonString == null || jsonString.isEmpty) {
      return []; // Chưa có gì thì trả về rỗng
    }

    try {
      return jsonDecode(jsonString); // Chuyển chuỗi JSON ngược lại thành List
    } catch (e) {
      print("Lỗi đọc Local Storage: $e");
      return [];
    }
  }
}