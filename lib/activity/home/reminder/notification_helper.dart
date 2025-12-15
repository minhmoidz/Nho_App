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

  // --- 2. HẸN GIỜ (ĐÃ NÂNG CẤP LẶP LẠI) ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isDaily = false, // <--- THAM SỐ MỚI: Có lặp lại hàng ngày không?
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // --- LOGIC XỬ LÝ THỜI GIAN ---

      if (isDaily) {
        // TRƯỜNG HỢP 1: LẶP HÀNG NGÀY
        // Nếu giờ hẹn đã qua so với hiện tại (VD: Hẹn 8h sáng mà giờ là 9h sáng)
        // -> Thì tự động cộng thêm 1 ngày để báo vào ngày mai
        if (tzScheduledTime.isBefore(now)) {
          tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
        }
      } else {
        // TRƯỜNG HỢP 2: KHÔNG LẶP (BÁO 1 LẦN)
        // Logic cũ: Nếu quá khứ < 1 phút thì vẫn báo (chống lag), lâu quá thì bỏ
        if (tzScheduledTime.isBefore(now)) {
          if (now.difference(tzScheduledTime).inMinutes < 1) {
            tzScheduledTime = now.add(const Duration(seconds: 3));
          } else {
            debugPrint("⚠️ Bỏ qua ID $id vì là quá khứ.");
            return;
          }
        }
      }

      // Chuỗi payload: "ID|Tiêu đề|Nội dung"
      String payloadData = "$id|$title|$body";

      // Cấu hình thông báo Android
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'channel_nhac_viec_v2', // Đổi ID kênh lên v2 để cập nhật cài đặt mới nếu cần
        'Nhắc nhở thuốc & việc',
        channelDescription: 'Kênh báo thức quan trọng',

        // --- CẤU HÌNH BUNG MÀN HÌNH ---
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,

        // Âm thanh & Rung
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 1000, 1000, 1000]),

        // Loại thông báo
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        timeoutAfter: 60000, // Tự tắt sau 1 phút
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadData,

        // --- QUAN TRỌNG: CẤU HÌNH LẶP LẠI ---
        // Nếu isDaily = true -> DateTimeComponents.time (Chỉ so khớp giờ:phút -> Lặp mỗi ngày)
        // Nếu isDaily = false -> DateTimeComponents.dateAndTime (So khớp cả ngày giờ -> Chỉ báo 1 lần)
        matchDateTimeComponents: isDaily ? DateTimeComponents.time : DateTimeComponents.dateAndTime,
      );

      debugPrint("✅ Đã hẹn giờ ID $id lúc $tzScheduledTime (Lặp lại: $isDaily)");

    } catch (e) {
      debugPrint("❌ Lỗi hẹn giờ: $e");
    }
  }

  // --- 3. HỦY ---
  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}