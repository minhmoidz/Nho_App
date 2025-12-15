import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'reminder_api_service.dart'; // Import API của bạn

class AlarmScreen extends StatefulWidget {
  final String payload; // Dạng: "ID|Tiêu đề|Nội dung"

  const AlarmScreen({Key? key, required this.payload}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FlutterTts _tts = FlutterTts();
  Timer? _repeatTimer;
  late AnimationController _animController;

  // Dữ liệu
  int _taskId = 0;
  String _taskTitle = "";
  String _taskDesc = "";

  bool _isProcessing = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Setup Animation Rung chuông (Lặp lại liên tục)
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500), // Rung nhanh
      vsync: this,
    );
    _animController.repeat(reverse: true); // Lặp đi lặp lại: Trái -> Phải -> Trái

    _parseData();
    _initAndStartTTS();
  }

  void _parseData() {
    try {
      List<String> parts = widget.payload.split('|');
      if (parts.isNotEmpty) _taskId = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1) _taskTitle = parts[1];
      if (parts.length > 2) _taskDesc = parts[2];
      _taskTitle = _taskTitle.replaceAll("Bác ơi! Đến giờ: ", "");
    } catch (e) {
      debugPrint("Lỗi tách dữ liệu: $e");
    }
  }

  Future<void> _initAndStartTTS() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (mounted && !_isProcessing) {
        _repeatTimer = Timer(const Duration(seconds: 3), () {
          _speak();
        });
      }
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _speak();
  }

  Future<void> _speak() async {
    if (!mounted || _isProcessing) return;
    _isSpeaking = true;
    String textToSpeak = "Bác ơi! Đến giờ $_taskTitle rồi. ";
    if (_taskDesc.isNotEmpty) textToSpeak += "Ghi chú là: $_taskDesc. ";
    textToSpeak += "Bác nhớ làm ngay nhé!";
    await _tts.speak(textToSpeak);
  }

  Future<void> _onTaskDone() async {
    _stopTTS();
    _animController.stop(); // Dừng rung chuông

    setState(() => _isProcessing = true);

    try {
      await ReminderApiService.updateReminderStatus(
        id: _taskId,
        isCompleted: true,
        currentTitle: _taskTitle,
        currentDescription: _taskDesc,
        currentRemindAt: DateTime.now().toIso8601String(),
      );

      if (mounted) {
        await _tts.speak("Dạ, cháu đã ghi nhận. Chúc bác mạnh khỏe!");
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Nếu lỗi vẫn đóng để đỡ ồn, nhưng báo lỗi nhẹ
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối, nhưng đã tắt chuông.")));
        Navigator.pop(context);
      }
    }
  }

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
    _animController.dispose();
    _stopTTS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao màn hình để cân đối
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SingleChildScrollView giúp không bị vỡ giao diện trên máy nhỏ
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity, // Quan trọng: Full chiều rộng để không bị lệch trái
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            // Min height bằng chiều cao màn hình để nút luôn nằm dưới đáy nếu muốn
            constraints: BoxConstraints(minHeight: size.height - 50),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa tất cả
              children: [
                const SizedBox(height: 20),

                // 1. ICON CHUÔNG RUNG LẮC
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    // Tạo hiệu ứng lắc qua lại (-0.15 rad đến 0.15 rad)
                    double angle = sin(_animController.value * 2 * pi) * 0.15;
                    return Transform.rotate(
                      angle: angle,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1), // Nền đỏ nhạt
                        ),
                        child: const Icon(Icons.notifications_active, size: 80, color: Colors.red),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Text(
                  "ĐẾN GIỜ RỒI BÁC ƠI!",
                  style: TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // 2. CARD HIỂN THỊ CÔNG VIỆC
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _taskTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                      ),

                      if (_taskDesc.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Container(height: 1, width: 100, color: Colors.grey.shade300), // Dòng kẻ mờ
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.note_alt_outlined, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _taskDesc,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 3. NÚT BẤM (FIX LỖI GIẬT HÌNH)
                // Dùng SizedBox cố định chiều cao để khi chuyển sang Loading không bị co lại
                SizedBox(
                  width: double.infinity,
                  height: 75, // Chiều cao cố định
                  child: _isProcessing
                      ? Center(
                    child: SizedBox(
                      width: 40, height: 40,
                      child: CircularProgressIndicator(color: Colors.green[700], strokeWidth: 3),
                    ),
                  )
                      : ElevatedButton(
                    onPressed: _onTaskDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 36),
                        SizedBox(width: 12),
                        Text(
                          "ĐÃ LÀM XONG",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. NÚT ĐỂ SAU
                TextButton.icon(
                  onPressed: _onDismiss,
                  icon: const Icon(Icons.watch_later_outlined, size: 24, color: Colors.grey),
                  label: const Text("Tắt chuông (Làm sau)", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}