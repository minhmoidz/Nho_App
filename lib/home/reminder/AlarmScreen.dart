import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlarmScreen extends StatefulWidget {
  final String payload; // Chứa nội dung ghi chú (VD: "Uống thuốc huyết áp")

  const AlarmScreen({Key? key, required this.payload}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterTts _tts = FlutterTts();
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Bắt đầu đọc ngay khi màn hình hiện lên
    _startSpeakingLoop();
  }

  void _startSpeakingLoop() {
    // Đọc lần đầu tiên
    _speak();

    // Hẹn giờ đọc lại mỗi 5 giây (để bác nghe rõ rồi mới đọc tiếp)
    _loopTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _speak();
      }
    });
  }

  Future<void> _speak() async {
    // Tách lấy nội dung ghi chú từ payload
    // Giả sử payload dạng: "ID|Tiêu đề|Ghi chú"
    List<String> parts = widget.payload.split('|');
    String contentToRead = "Bác ơi, đến giờ rồi. ${parts.length > 1 ? parts[1] : ''}. ${parts.length > 2 ? parts[2] : ''}";

    await _tts.speak(contentToRead);
  }

  void _stopAlarm() {
    _loopTimer?.cancel();
    _tts.stop();
    Navigator.pop(context); // Đóng màn hình này
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> parts = widget.payload.split('|');
    String title = parts.length > 1 ? parts[1] : "Đến giờ!";
    String desc = parts.length > 2 ? parts[2] : "";

    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm_on, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "NHẮC NHỞ",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ),
            const Spacer(),
            // NÚT TẮT TO ĐÙNG
            Padding(
              padding: const EdgeInsets.all(30),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: _stopAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text(
                    "ĐÃ BIẾT / TẮT",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}