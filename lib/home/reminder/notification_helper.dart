import 'dart:async';
import 'dart:typed_data'; // [QUAN TRỌNG] Thêm dòng này để dùng Int64List
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();

  // Stream để main.dart lắng nghe
  static final StreamController<String?> onNotificationClick = StreamController<String?>.broadcast();

  // --- 1. KHỞI TẠO ---
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          onNotificationClick.add(response.payload);
        }
      },
    );

    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45);
  }

  // --- 2. HẸN GIỜ ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    String payloadData = "$id|$title|$body";

    // [SỬA LỖI] Dùng 'final' thay vì 'const' vì Int64List được tạo lúc chạy
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_final_v2',
      'Báo thức thuốc & Việc',
      channelDescription: 'Kênh báo thức tự động mở màn hình',

      importance: Importance.max,
      priority: Priority.max,

      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,

      fullScreenIntent: true,

      enableVibration: true,
      // [SỬA LỖI] Int64List.fromList giờ đã hoạt động nhờ import ở trên
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),

      color: Colors.red,
      ledColor: Colors.red,
      enableLights: true,
      timeoutAfter: 300000,
    );

    // [SỬA LỖI] Bỏ const ở đây luôn vì androidDetails không còn là const
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payloadData,
    );

    _scheduleMissedAlert(id, title, tzTime.add(const Duration(minutes: 15)));
  }

  // --- 3. BÁO THỨC DỰ PHÒNG ---
  static Future<void> _scheduleMissedAlert(int originId, String originTitle, tz.TZDateTime alertTime) async {
    int alertId = originId + 100000;
    String payloadData = "$originId|CẢNH BÁO QUÊN THUỐC|Bác chưa xác nhận uống $originTitle. Xin hãy kiểm tra ngay!";

    // [SỬA LỖI] Dùng final thay vì const cho an toàn
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alert_channel_final_v2',
      'Cảnh báo khẩn cấp',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      color: Colors.red,
    );

    await _notifications.zonedSchedule(
      alertId,
      "KHẨN CẤP: CHƯA XÁC NHẬN",
      "Bác ơi, hãy vào xác nhận uống thuốc $originTitle ngay!",
      alertTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payloadData,
    );
  }

  // --- 4. HỦY BÁO THỨC ---
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 100000);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}