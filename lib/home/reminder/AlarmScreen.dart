import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'reminder_api_service.dart'; // Import API của bạn

class AlarmScreen extends StatefulWidget {
  final String payload; // Dạng: "ID|Tiêu đề|Nội dung"

  const AlarmScreen({Key? key, required this.payload}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  final FlutterTts _tts = FlutterTts();
  Timer? _repeatTimer;

  // Dữ liệu việc cần làm
  int _taskId = 0;
  String _taskTitle = "";
  String _taskDesc = "";

  bool _isProcessing = false; // Trạng thái đang gọi API
  bool _isSpeaking = false;   // Trạng thái đang đọc

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parseData();
    _initAndStartTTS(); // Bắt đầu đọc ngay khi màn hình hiện
  }

  // 1. Tách dữ liệu từ Payload
  void _parseData() {
    try {
      List<String> parts = widget.payload.split('|');
      if (parts.isNotEmpty) _taskId = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1) _taskTitle = parts[1];
      if (parts.length > 2) _taskDesc = parts[2];

      // Nếu tiêu đề có chữ "Bác ơi! Đến giờ: ", ta cắt bớt để đọc cho tự nhiên
      _taskTitle = _taskTitle.replaceAll("Bác ơi! Đến giờ: ", "");
    } catch (e) {
      debugPrint("Lỗi tách dữ liệu: $e");
    }
  }

  // 2. Cài đặt và Chạy TTS (Vòng lặp)
  Future<void> _initAndStartTTS() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45); // Đọc chậm cho người già dễ nghe
    await _tts.setVolume(1.0);      // Max volume
    await _tts.setPitch(1.0);

    // Cài đặt sự kiện: Khi đọc xong -> Nghỉ 3s -> Đọc lại
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (mounted && !_isProcessing) {
        _repeatTimer = Timer(const Duration(seconds: 3), () {
          _speak();
        });
      }
    });

    // Đợi 0.5s cho UI ổn định rồi bắt đầu đọc
    await Future.delayed(const Duration(milliseconds: 500));
    _speak();
  }

  // Hàm đọc nội dung
  Future<void> _speak() async {
    if (!mounted || _isProcessing) return;

    _isSpeaking = true;

    // Tạo câu nói tự nhiên
    String textToSpeak = "Bác ơi! Đến giờ $_taskTitle rồi. ";
    if (_taskDesc.isNotEmpty && _taskDesc != "Chạm vào để nghe nội dung") {
      textToSpeak += "Ghi chú là: $_taskDesc. ";
    }
    textToSpeak += "Bác nhớ làm ngay nhé!";

    await _tts.speak(textToSpeak);
  }

  // 3. Xử lý nút "ĐÃ XONG"
  Future<void> _onTaskDone() async {
    _stopTTS(); // Im lặng ngay
    setState(() => _isProcessing = true);

    try {
      // Gọi API báo đã xong
      await ReminderApiService.updateReminderStatus(
        id: _taskId,
        isCompleted: true,
        currentTitle: _taskTitle,
        currentDescription: _taskDesc,
        currentRemindAt: DateTime.now().toIso8601String(),
      );

      if (mounted) {
        // Đọc câu khen ngợi cuối cùng trước khi đóng
        await _tts.speak("Dạ, cháu đã ghi nhận rồi ạ.");
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context); // Đóng màn hình
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi mạng: $e")));
        Navigator.pop(context);
      }
    }
  }

  // 4. Xử lý nút "ĐỂ SAU" (Tắt chuông)
  void _onDismiss() {
    _stopTTS();
    Navigator.pop(context);
  }

  void _stopTTS() {
    _repeatTimer?.cancel();
    _tts.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTTS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Icon động rung lắc nhẹ
            TweenAnimationBuilder(
              tween: Tween(begin: -0.1, end: 0.1),
              duration: const Duration(milliseconds: 200),
              builder: (_, double val, __) => Transform.rotate(
                  angle: val,
                  child: const Icon(Icons.notifications_active, size: 80, color: Colors.red)
              ),
              onEnd: () {}, // Có thể làm loop animation ở đây nếu muốn
            ),

            const SizedBox(height: 20),
            const Text("ĐẾN GIỜ RỒI BÁC ƠI!",
                style: TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)
            ),

            const SizedBox(height: 30),

            // Tên việc (Chữ rất to)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _taskTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            // Ghi chú
            if (_taskDesc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber, width: 2)
                  ),
                  child: Text(
                    "📝 $_taskDesc",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.black87),
                  ),
                ),
              ),

            const Spacer(),

            // Nút ĐÃ XONG (Màu xanh to)
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: _onTaskDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 40),
                      SizedBox(width: 15),
                      Text("ĐÃ LÀM XONG", style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Nút TẮT CHUÔNG (Nhỏ hơn)
            TextButton(
              onPressed: _onDismiss,
              child: const Text("Tắt chuông (Làm sau)", style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}