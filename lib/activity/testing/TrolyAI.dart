import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';

class VoiceChatPage1 extends StatefulWidget {
  const VoiceChatPage1({super.key});

  @override
  State<VoiceChatPage1> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage1> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _micAnimController;

  bool _isListening = false;
  bool _isSpeaking = false;

  String _liveVoiceText = "";
  final List<_Message> _messages = [];

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraOn = false;

  final String userId = "user123";
  final String sessionId = "session123";

  @override
  void initState() {
    super.initState();
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _setupTTS();
  }

  Future<void> _setupTTS() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.5);

    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _tts.setCancelHandler(() {
      setState(() => _isSpeaking = false);
    });

    _tts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Lỗi camera: $e");
    }
  }

  Future<void> _toggleCameraState() async {
    if (_isCameraOn) {
      setState(() => _isCameraOn = false);
      await _cameraController?.dispose();
      _cameraController = null;
    } else {
      await _initializeCamera();
      setState(() => _isCameraOn = true);
    }
  }

  Future<void> _switchCamera() async {
    if (!_isCameraOn || _cameras.isEmpty || _cameraController == null) return;
    final currentLens = _cameraController!.description.lensDirection;
    final newLens = currentLens == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;
    final newCamera = _cameras.firstWhere((cam) => cam.lensDirection == newLens, orElse: () => _cameras.first);
    await _cameraController!.dispose();
    _cameraController = CameraController(newCamera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    bool available = await _speech.initialize(
      onError: (val) {
        setState(() {
          _isListening = false;
          _liveVoiceText = "";
        });
        _micAnimController.stop();
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _liveVoiceText = "Đang nghe...";
      });
      _micAnimController.repeat(reverse: true);

      _speech.listen(
        localeId: "vi_VN",
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          setState(() {
            _liveVoiceText = result.recognizedWords;
          });
          _scrollToBottom();

          if (result.finalResult) {
            _stopListeningAndSend();
          }
        },
      );
    }
  }

  Future<void> _stopListeningAndSend() async {
    if (!_isListening) return;

    String finalVoiceText = _liveVoiceText;

    setState(() {
      _isListening = false;
      _liveVoiceText = "";
    });
    _micAnimController.stop();
    _micAnimController.reset();
    await _speech.stop();

    if (finalVoiceText.trim().isNotEmpty && finalVoiceText != "Đang nghe...") {
      _handleSend(finalVoiceText);
    }
  }

  Future<void> _handleSend(String text) async {
    if (_isSpeaking) await _stopSpeaking();

    if (text.trim().isEmpty) return;

    _addMessage(text, isUser: true);
    _textController.clear();

    XFile? imageFile;
    if (_isCameraOn && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        imageFile = await _cameraController!.takePicture();
      } catch (e) {
        debugPrint("Lỗi chụp ảnh: $e");
      }
    }

    await _sendToBot(text, imageFile: imageFile);
  }

  Future<void> _sendToBot(String inputText, {XFile? imageFile}) async {
    final uri = Uri.parse("https://aitools.ptit.edu.vn/nho/analyze-image");
    var request = http.MultipartRequest('POST', uri);
    request.fields['user_id'] = userId;
    request.fields['session_id'] = sessionId;
    request.fields['text'] = inputText;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String botReply = '';
        if (jsonResponse.containsKey('response')) {
          try {
            if (jsonResponse['response'] is String) {
              try {
                final parsed = jsonDecode(jsonResponse['response']);
                botReply = parsed['text'] ?? jsonResponse['response'];
              } catch (e) {
                botReply = jsonResponse['response'];
              }
            } else {
              botReply = jsonResponse['response']['text'] ?? jsonResponse['response'].toString();
            }
          } catch (_) {
            botReply = jsonResponse['response'].toString();
          }
        }

        botReply = botReply.replaceAll('*', '');

        _addMessage(botReply, isUser: false);
        await _tts.speak(botReply);

      } else {
        _addMessage("❌ Lỗi server: ${response.statusCode}", isUser: false);
      }
    } catch (e) {
      _addMessage("⚠️ Mất kết nối: $e", isUser: false);
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(_Message(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageItem(String text, bool isUser, {bool isTemp = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? (isTemp ? Colors.blueAccent.withOpacity(0.7) : Colors.blue[600])
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w400,
            fontStyle: isTemp ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStopSpeakingButton() {
    if (!_isSpeaking) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: InkWell(
          onTap: _stopSpeaking,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Dừng đọc",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.stop_circle_outlined, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    _micAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
            "Trợ lý ảo AI",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(
              _isCameraOn ? Icons.videocam : Icons.videocam_off,
              color: _isCameraOn ? Colors.blue : Colors.grey,
            ),
            onPressed: _toggleCameraState,
          ),
          if (_isCameraOn)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.blue),
              onPressed: _switchCamera,
            ),
        ],
      ),
      extendBodyBehindAppBar: _isCameraOn,
      body: Stack(
        children: [
          if (_isCameraOn && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            Container(color: const Color(0xFFF5F7FB)),

          if (_isCameraOn)
            Container(color: Colors.white.withOpacity(0.3)),

          Column(
            children: [
              if (_isCameraOn) const SizedBox(height: 90),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _messages.length + (_isListening ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isListening && index == _messages.length) {
                      return _buildMessageItem(_liveVoiceText, true, isTemp: true);
                    }
                    return _buildMessageItem(_messages[index].text, _messages[index].isUser);
                  },
                ),
              ),

              _buildStopSpeakingButton(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isListening ? _stopListeningAndSend : _startListening,
                        child: AnimatedBuilder(
                          animation: _micAnimController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? Colors.redAccent : Colors.blue[50],
                                border: _isListening
                                    ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2 + (_micAnimController.value * 3))
                                    : null,
                              ),
                              child: Icon(
                                _isListening ? Icons.graphic_eq : Icons.mic,
                                color: _isListening ? Colors.white : Colors.blue,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: "Nhập tin nhắn...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (val) => _handleSend(val),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      IconButton(
                        onPressed: () => _handleSend(_textController.text),
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.blue,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}
