import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';



class VoiceOnlyPage extends StatefulWidget {
  const VoiceOnlyPage({super.key});

  @override
  State<VoiceOnlyPage> createState() => _VoiceOnlyPageState();
}

class _VoiceOnlyPageState extends State<VoiceOnlyPage> {
  // --- Khai báo biến ---
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false; // Đang nghe user nói
  bool _isSpeaking = false;  // Bot đang nói

  String _userText = "Nhấn vào micro để bắt đầu nói...";
  String _botText = "";

  final String userId = "user123";
  final String sessionId = "session123";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _setupTts();
  }

  // Cấu hình Bot nói (Tiếng Việt)
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Bắt sự kiện khi bot nói xong
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });
  }

  // Hàm đọc văn bản
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // Hàm xử lý Micro
  void _listen() async {
    // Nếu Bot đang nói thì dừng Bot lại trước
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    }

    if (!_isListening) {
      // Bắt đầu nghe
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (errorNotification) => print('Error: $errorNotification'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _userText = "Đang nghe...";
          _botText = ""; // Xóa lời thoại cũ của bot cho gọn
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _userText = val.recognizedWords;
            });

            // LOGIC QUAN TRỌNG: Nếu nhận diện xong câu (ngừng nói) -> Tự động Gửi
            if (val.finalResult && val.recognizedWords.isNotEmpty) {
              _stopListeningAndSend();
            }
          },
          localeId: "vi_VN",
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3), // Ngừng 3s tự ngắt
          partialResults: true,
        );
      }
    } else {
      // Đang nghe mà bấm nút -> Dừng thủ công và gửi luôn
      _stopListeningAndSend();
    }
  }

  void _stopListeningAndSend() {
    setState(() => _isListening = false);
    _speech.stop();
    // Gửi dữ liệu đi
    if (_userText.isNotEmpty && _userText != "Đang nghe...") {
      sendMessage(_userText);
    }
  }

  Future<void> sendMessage(String message) async {
    final url = Uri.parse("https://aitools.ptit.edu.vn/nho/chat");
    final body = {
      "user_id": userId,
      "session_id": sessionId,
      "text": message,
    };

    setState(() {
      _botText = "Đang suy nghĩ...";
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
        jsonDecode(utf8.decode(response.bodyBytes));

        String botResponseText = '';
        if (jsonResponse.containsKey('response')) {
          final responseText = jsonResponse['response'];
          try {
            final nestedJson = jsonDecode(responseText);
            botResponseText = nestedJson['text'] ?? responseText;
          } catch (_) {
            botResponseText = responseText;
          }
        } else {
          botResponseText = jsonResponse['text'] ?? response.body;
        }

        setState(() {
          _botText = botResponseText;
        });

        // Bot đọc to câu trả lời
        _speak(botResponseText);

      } else {
        setState(() => _botText = "Lỗi kết nối: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _botText = "Lỗi hệ thống: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Trợ lý ảo", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Phân bố đều
          children: [
            // Phần hiển thị hội thoại
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lời User nói
                  Text(
                    _userText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: _isListening ? Colors.blueAccent : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Lời Bot trả lời
                  if (_botText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _botText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Nút Micro lớn
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.redAccent
                        : (_isSpeaking ? Colors.greenAccent : Colors.blueAccent),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening || _isSpeaking)
                            ? Colors.black26 : Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : (_isSpeaking ? Icons.volume_up : Icons.mic_none),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Text trạng thái nhỏ bên dưới
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                _isListening
                    ? "Đang nghe bạn nói..."
                    : (_isSpeaking ? "Bot đang trả lời..." : "Nhấn để nói"),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}