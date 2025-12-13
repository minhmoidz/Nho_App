import 'dart:async';
import 'dart:typed_data'; // Cần cho rung (Int64List)
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Stream để main.dart lắng nghe và điều hướng
  static final StreamController<String?> onNotificationClick = StreamController<String?>.broadcast();

  // --- 1. KHỞI TẠO ---
  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    // Cài đặt Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cài đặt iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          onNotificationClick.add(response.payload);
        }
      },
    );

    // Xin quyền Android 13+ (Thông báo) và 12+ (Hẹn giờ chính xác)
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // --- 2. HẸN GIỜ (KHÔNG DÙNG MP3 RIÊNG) ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Xử lý logic thời gian: Nếu quá khứ < 1 phút thì vẫn báo (để tránh lag), nếu quá lâu thì bỏ
      if (tzScheduledTime.isBefore(now)) {
        if (now.difference(tzScheduledTime).inMinutes < 1) {
          // Nếu vừa mới qua tức thì -> báo ngay sau 3 giây
          tzScheduledTime = now.add(const Duration(seconds: 3));
        } else {
          debugPrint("⚠️ Bỏ qua ID $id vì là quá khứ.");
          return;
        }
      }

      // Chuỗi payload: "ID|Tiêu đề|Nội dung"
      String payloadData = "$id|$title|$body";

      // Cấu hình thông báo Android
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'channel_nhac_viec_v1', // ID Kênh
        'Nhắc nhở thuốc & việc', // Tên kênh
        channelDescription: 'Kênh báo thức quan trọng',

        // --- CẤU HÌNH QUAN TRỌNG ĐỂ BUNG MÀN HÌNH ---
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true, // Yêu cầu bung màn hình (Cần quyền trong Manifest)

        // Âm thanh & Rung
        playSound: true, // Dùng tiếng "Ting ting" mặc định của hệ thống
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 1000, 1000, 1000]), // Rung mạnh: Nghỉ-Rung-Nghỉ-Rung

        // Loại thông báo
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        timeoutAfter: 60000, // Tự tắt thông báo sau 1 phút nếu không ai bấm
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payloadData,
      );

      debugPrint("✅ Đã hẹn giờ ID $id lúc $tzScheduledTime");

    } catch (e) {
      debugPrint("❌ Lỗi hẹn giờ: $e");
    }
  }

  // --- 3. HỦY ---
  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}