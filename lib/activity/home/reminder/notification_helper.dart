import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();

  // --- 1. KHỞI TẠO ---
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // KHI NGƯỜI GIÀ BẤM VÀO THÔNG BÁO -> ĐỌC TO LÊN
        if (response.payload != null) {
          // Đợi 1 xíu cho app mở hẳn rồi mới đọc
          Future.delayed(const Duration(milliseconds: 500), () {
            speak(response.payload!);
          });
        }
      },
    );

    // Cấu hình giọng đọc: Chậm, To, Rõ
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45); // Tốc độ 0.45 là vừa phải nhất với người lớn tuổi
    await _tts.setVolume(1.0);      // Max volume
    await _tts.setPitch(1.0);
  }

  // --- 2. HẸN GIỜ (QUAN TRỌNG) ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Cấu hình chi tiết để thông báo kêu to như báo thức
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel_id_v2', // Đổi ID mới để cập nhật setting
      'Nhắc nhở thuốc & Lịch',
      channelDescription: 'Kênh thông báo quan trọng cho người cao tuổi',
      importance: Importance.max, // Mức cao nhất: Hiện popup đè lên màn hình
      priority: Priority.high,    // Ưu tiên cao
      playSound: true,
      enableVibration: true,

      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Đánh thức cả khi máy ngủ
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: "Đến giờ rồi. $title. $body", // Nội dung sẽ đọc khi bấm vào
    );
  }

  // --- 3. HỦY HẸN GIỜ ---
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // --- 4. ĐỌC VĂN BẢN ---
  static Future<void> speak(String text) async {
    await _tts.stop(); // Dừng câu đang nói dở (nếu có)
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  // Hàm dừng đọc (dùng khi người già muốn tắt tiếng ngay)
  static Future<void> stop() async {
    await _tts.stop();
  }
}