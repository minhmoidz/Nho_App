import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Rung phản hồi
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nhoapp/constants/app_colors.dart';

// --- CÁC THƯ VIỆN ĐỂ UPLOAD ẢNH ---
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../login/auth_service.dart';
import '../services/api_service.dart';
import '../models/chat_model.dart';


class VoiceChatScreen extends StatefulWidget {
  final String conversationId;

  const VoiceChatScreen({super.key, required this.conversationId});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with TickerProviderStateMixin {
  // CẤU HÌNH API
  static String uri = dotenv.env['API_BASE_URL']!;
  static String _baseUrl = uri + '/api/v1';

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _micAnimController;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  String _currentId = "";
  List<ChatMessage> _messages = [];
  List<Conversation> _historyList = [];

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoadingMessages = true;
  bool _isBotThinking = false;
  bool _isCameraOn = false;
  String _liveVoiceText = "";

  // BIẾN QUAN TRỌNG: Lưu tác vụ OCR đang chạy ngầm
  Future<String>? _pendingAnalysisTask;

  static const String KEY_LAST_CHAT_ID = "LAST_CHAT_ID";

  @override
  void initState() {
    super.initState();
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _setupTTS();
    // Gọi khởi tạo với try-catch để debug lỗi không tải được lịch sử
    _initializeChat().catchError((e) {
      debugPrint("❌ Lỗi khởi tạo: $e");
      if (mounted) setState(() => _isLoadingMessages = false);
    });
  }

  // ==================== 1. TỐI ƯU TẢI LỊCH SỬ ====================

  Future<void> _initializeChat() async {
    // Kiểm tra token trước
    final token = await _authService.getToken();
    if (token == null) {
      debugPrint("⚠️ Chưa có Token, không thể tải lịch sử.");
      if (mounted) setState(() => _isLoadingMessages = false);
      return;
    }

    await _loadHistoryList(); // Tải danh sách lịch sử về trước

    String targetId = "";
    if (widget.conversationId.isNotEmpty) {
      targetId = widget.conversationId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString(KEY_LAST_CHAT_ID);

      // Ưu tiên ID đã lưu -> Nếu không thì lấy bài mới nhất trong lịch sử
      if (savedId != null && savedId.isNotEmpty) {
        targetId = savedId;
      } else if (_historyList.isNotEmpty) {
        targetId = _historyList.first.id;
      }
    }

    if (targetId.isNotEmpty) {
      debugPrint("👉 Đang tải hội thoại ID: $targetId");
      await _switchConversation(targetId, saveToHistory: true, closeMenu: false);
    } else {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _loadHistoryList() async {
    try {
      final history = await _apiService.getHistory();
      debugPrint("✅ Đã tải ${history.length} cuộc hội thoại.");
      if (mounted) setState(() => _historyList = history);
    } catch (e) {
      debugPrint("❌ Lỗi tải lịch sử: $e");
      // Không throw lỗi để app vẫn chạy tiếp được
    }
  }

  Future<void> _loadMessages() async {
    if (_currentId.isEmpty) {
      setState(() => _isLoadingMessages = false);
      return;
    }
    setState(() => _isLoadingMessages = true);
    try {
      final msgs = await _apiService.getConversationDetail(_currentId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("❌ Lỗi tải chi tiết chat: $e");
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  // ==================== 2. TÁC VỤ NGẦM: CHỤP & PHÂN TÍCH ====================

  // Hàm này sẽ chạy NGAY LẬP TỨC khi bắt đầu nói (không chờ nói xong)
  Future<String> _captureAndAnalyzeInBackground() async {
    if (!_isCameraOn || _cameraController == null || !_cameraController!.value.isInitialized) {
      return "";
    }

    try {
      debugPrint("📸 [Background] Đang chụp ảnh...");
      final XFile image = await _cameraController!.takePicture();
      debugPrint("📸 [Background] Đã chụp xong, bắt đầu gửi API...");

      // Gọi hàm OCR (Code cũ)
      return await _callOcrApi(image);
    } catch (e) {
      debugPrint("❌ [Background] Lỗi chụp/phân tích: $e");
      return "Lỗi phân tích hình ảnh: $e";
    }
  }

  Future<String> _callOcrApi(XFile imageFile) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return "Lỗi: Mất kết nối đăng nhập.";

      final uri = Uri.parse('$_baseUrl/note');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeTypeData = lookupMimeType(imageFile.path, headerBytes: [0xFF, 0xD8]);
      final String mimeType = mimeTypeData ?? 'image/jpeg';
      final List<String> mimeTypeSplit = mimeType.split('/');

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
      ));

      request.fields['auto_analyze'] = 'true';
      request.fields['content'] = 'Voice Chat Analysis';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        // Logic lấy kết quả (tuỳ backend trả về)
        if (data is Map<String, dynamic>) {
          if (data['data'] != null && data['data'] is Map && data['data']['analysis'] != null) {
            return data['data']['analysis'].toString();
          }
          if (data['analysis'] != null) return data['analysis'].toString();
          if (data['result'] != null) return data['result'].toString();
        }
        return "Đã phân tích ảnh (Dữ liệu thô): $responseBody";
      } else {
        return "Lỗi Server OCR (${response.statusCode})";
      }
    } catch (e) {
      return "Lỗi kết nối OCR: $e";
    }
  }

  // ==================== 3. XỬ LÝ VOICE THÔNG MINH ====================

  Future<void> _startListening() async {
    if (_isSpeaking) await _stopSpeaking();

    // Reset tác vụ OCR cũ
    _pendingAnalysisTask = null;

    // --- QUAN TRỌNG: KÍCH HOẠT OCR NGẦM NGAY LÚC NÀY ---
    if (_isCameraOn) {
      // Gán Future vào biến để đợi sau này
      _pendingAnalysisTask = _captureAndAnalyzeInBackground();

      // Hiển thị thông báo nhỏ
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📸 Đang chụp và phân tích ảnh..."),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blueAccent,
          )
      );
    }
    // ----------------------------------------------------

    HapticFeedback.heavyImpact();
    bool available = await _speech.initialize(
      onError: (val) {
        debugPrint("Speech Error: ${val.errorMsg}");
        _stopListening(sendNow: false);
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
        // Chế độ dictation giúp nhận diện tốt hơn cho câu dài
        listenMode: stt.ListenMode.dictation,
        // Tăng thời gian chờ im lặng lên 5 giây (mặc định thường là 2-3s)
        pauseFor: const Duration(seconds: 5),
        listenFor: const Duration(seconds: 60),
        cancelOnError: false, // Không tắt nếu lỗi nhỏ
        partialResults: true,
        onResult: (result) {
          setState(() {
            _liveVoiceText = result.recognizedWords;
          });
          _scrollToBottom();
          if (result.finalResult) {
            _stopListening(sendNow: true);
          }
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể truy cập Microphone")));
    }
  }

  Future<void> _stopListening({bool sendNow = true}) async {
    if (!_isListening) return;
    HapticFeedback.lightImpact();

    await _speech.stop();
    _micAnimController.stop();
    _micAnimController.reset();

    String finalVoiceText = _liveVoiceText;
    setState(() {
      _isListening = false;
      _liveVoiceText = "";
    });

    if (sendNow && finalVoiceText.trim().isNotEmpty && finalVoiceText != "Đang nghe...") {
      _handleSend(finalVoiceText);
    }
  }

  // ==================== 4. GỘP KẾT QUẢ VÀ GỬI ====================

  Future<void> _handleSend(String text) async {
    if (_isSpeaking) await _stopSpeaking();
    if (_isListening) await _stopListening(sendNow: false);
    if (text.trim().isEmpty && !_isCameraOn) return;

    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(content: text, isUser: true));
        _isBotThinking = true;
      });
      _scrollToBottom();
    } else {
      setState(() => _isBotThinking = true);
    }

    _textController.clear();
    String finalMessageToSend = text;

    // --- ĐỢI KẾT QUẢ OCR (NẾU CÓ) ---
    if (_isCameraOn && _pendingAnalysisTask != null) {
      try {
        // Thông báo nếu OCR vẫn chưa xong (trường hợp bạn nói quá nhanh)
        // setState(() {
        //   _messages.add(ChatMessage(content: "⏳ Đang đợi kết quả phân tích ảnh...", isUser: true));
        // });
        // _scrollToBottom();

        // AWAIT: Đợi tác vụ ngầm (đã chạy từ lúc bấm mic) hoàn thành
        debugPrint("⏳ Đang đợi kết quả OCR từ tác vụ ngầm...");
        String analysisResult = await _pendingAnalysisTask!;
        debugPrint("✅ Đã nhận kết quả OCR: $analysisResult");

        // Ghép chuỗi
        finalMessageToSend = """
[CÂU HỎI NGƯỜI DÙNG]
"$text"

[THÔNG TIN HÌNH ẢNH]
$analysisResult

[YÊU CẦU]
Dựa vào hình ảnh và câu hỏi để tư vấn.
""";

      } catch (e) {
        finalMessageToSend = "$text\n(Lỗi phân tích ảnh: $e)";
      }

      // Reset task
      _pendingAnalysisTask = null;
    }

    // Gửi Chatbot
    final botResponse = await _apiService.sendMessage(finalMessageToSend, _currentId);

    if (mounted) {
      setState(() {
        _isBotThinking = false;
        if (botResponse != null) {
          String cleanText = botResponse.replaceAll('*', '');
          _messages.add(ChatMessage(content: cleanText, isUser: false));
          _speak(cleanText);
          _loadHistoryList();
        } else {
          _messages.add(ChatMessage(content: "⚠️ Lỗi kết nối Chatbot", isUser: false));
        }
      });
      _scrollToBottom();
    }
  }

  // ==================== UI & CÁC HÀM KHÁC (GIỮ NGUYÊN) ====================
  // (Phần này chỉ là UI và setup cơ bản, không ảnh hưởng logic chính)

  Future<void> _switchConversation(String newId, {bool saveToHistory = true, bool closeMenu = true}) {
    if (closeMenu && Navigator.canPop(context)) {}
    if (newId == _currentId && _messages.isNotEmpty) return Future.value();
    setState(() { _currentId = newId; _messages = []; _isLoadingMessages = true; });
    _loadMessages();
    if (saveToHistory) _saveLastConversationId(newId);
    return Future.value();
  }

  Future<void> _saveLastConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_LAST_CHAT_ID, id);
  }

  Future<void> _setupTTS() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _speak(String text) async { if (text.isEmpty) return; await _tts.stop(); await _tts.speak(text); }
  Future<void> _stopSpeaking() async { await _tts.stop(); setState(() => _isSpeaking = false); }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final backCamera = _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);
      _cameraController = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) { debugPrint("Lỗi camera: $e"); }
  }

  Future<void> _toggleCameraState() async {
    if (_isCameraOn) { setState(() => _isCameraOn = false); await _cameraController?.dispose(); _cameraController = null; }
    else { await _initializeCamera(); setState(() => _isCameraOn = true); }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  Future<void> _createNewChat() async {
    Navigator.pop(context);
    final newId = await _apiService.createNewConversation();
    if (newId != null) { _switchConversation(newId.toString(), saveToHistory: true, closeMenu: false); _loadHistoryList(); }
  }

  Future<void> _deleteConversation(String id) async {
    final success = await _apiService.deleteConversation(id);
    if (success) {
      setState(() => _historyList.removeWhere((item) => item.id.toString() == id.toString()));
      if (id.toString() == _currentId.toString()) {
        if (_historyList.isNotEmpty) _switchConversation(_historyList.first.id, saveToHistory: true, closeMenu: false);
        else setState(() { _currentId = ""; _messages = []; _isLoadingMessages = false; });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop(); _tts.stop(); _textController.dispose(); _scrollController.dispose(); _micAnimController.dispose(); _cameraController?.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      endDrawer: _buildDrawer(),
      appBar: _buildAppBar(),
      extendBodyBehindAppBar: _isCameraOn,
      body: Stack(
        children: [
          if (_isCameraOn && _cameraController != null && _cameraController!.value.isInitialized) SizedBox.expand(child: CameraPreview(_cameraController!)),
          if (_isCameraOn) Container(color: Colors.black.withOpacity(0.1)),
          Column(
            children: [
              if (_isCameraOn) const SizedBox(height: 90),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    itemCount: _messages.length + (_isListening ? 1 : 0) + (_isBotThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isListening && index == _messages.length) return _buildLiveVoiceBubble();
                      if (_isBotThinking && index == (_messages.length + (_isListening ? 1 : 0))) return _buildThinkingBubble();
                      if (index < _messages.length) return _buildChatBubble(_messages[index]);
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              if (_isSpeaking) Padding(padding: const EdgeInsets.only(bottom: 10), child: FloatingActionButton.extended(onPressed: _stopSpeaking, backgroundColor: Colors.redAccent, icon: const Icon(Icons.volume_off, color: Colors.white), label: const Text("Dừng đọc", style: TextStyle(color: Colors.white)))),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: _isCameraOn ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.primary, radius: 16, child: Icon(Icons.medical_services, size: 18, color: Colors.white)),
          const SizedBox(width: 10),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Trợ lý AI", style: TextStyle(color: _isCameraOn ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            Text(_isCameraOn ? "Chế độ Camera" : "ID: $_currentId", style: TextStyle(color: _isCameraOn ? Colors.white70 : Colors.grey, fontSize: 10)),
          ])),
        ],
      ),
      backgroundColor: _isCameraOn ? Colors.black.withOpacity(0.4) : Colors.white, elevation: _isCameraOn ? 0 : 1,
      actions: [
        IconButton(icon: Icon(_isCameraOn ? Icons.videocam_off : Icons.videocam, color: _isCameraOn ? Colors.redAccent : Colors.grey), onPressed: _toggleCameraState),
        Builder(builder: (context) => IconButton(icon: Icon(Icons.history_rounded, color: _isCameraOn ? Colors.white : AppColors.primary, size: 28), onPressed: () => Scaffold.of(context).openEndDrawer())),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(child: Column(children: [
      Container(width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary
        ),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Lịch sử", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          Text("${_historyList.length} cuộc hội thoại", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),

      ListTile(leading: const Icon(Icons.add_circle, color: AppColors.primary), title: const Text("Cuộc hội thoại mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), onTap: _createNewChat),
      const Divider(),
      Expanded(child: ListView.separated(padding: EdgeInsets.zero, itemCount: _historyList.length, separatorBuilder: (ctx, i) => const Divider(height: 1), itemBuilder: (context, index) {
        final item = _historyList[index];
        return ListTile(title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () { Navigator.pop(context); _switchConversation(item.id, saveToHistory: true); }, trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteConversation(item.id)));
      })),
    ]));
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bgColor = isUser ? null : (_isCameraOn ? Colors.white.withOpacity(0.9) : Colors.white);
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
      if (!isUser) const Padding(padding: EdgeInsets.only(right: 8), child: CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, size: 18, color: Colors.blueGrey))),
      Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(gradient: isUser ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary]) : null, color: bgColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Text(message.content, style: TextStyle(fontSize: 16, height: 1.4, color: isUser ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)))),
    ]));
  }

  Widget _buildLiveVoiceBubble() {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: _isCameraOn ? AppColors.primary : AppColors.secondary, borderRadius: BorderRadius.circular(20)), child: Row(children: [const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10), Text(_liveVoiceText.isEmpty ? "..." : _liveVoiceText, style: TextStyle(color: _isCameraOn ? Colors.white : AppColors.primary))]))]));
  }

  Widget _buildThinkingBubble() {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)), child: const Text("Đang xử lý...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))));
  }

  Widget _buildInputArea() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: _isCameraOn ? Colors.black.withOpacity(0.6) : Colors.white), child: SafeArea(child: Row(children: [
      GestureDetector(onTap: _isListening ? () => _stopListening(sendNow: true) : _startListening, child: AnimatedBuilder(animation: _micAnimController, builder: (context, child) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: _isListening ? Colors.redAccent : const Color(0xFFF2F4F8), boxShadow: _isListening ? [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10 + (_micAnimController.value * 10))] : []), child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: _isListening ? Colors.white : Colors.blueGrey, size: 24)); })),
      const SizedBox(width: 10),
      Expanded(child: Container(decoration: BoxDecoration(color: _isCameraOn ? Colors.white.withOpacity(0.2) : const Color(0xFFF2F4F8), borderRadius: BorderRadius.circular(25)), child: TextField(controller: _textController, style: TextStyle(color: _isCameraOn ? Colors.white : Colors.black), decoration: InputDecoration(hintText: _isCameraOn ? "Nói để chụp & phân tích..." : "Nhập tin nhắn...", hintStyle: TextStyle(color: _isCameraOn ? Colors.white54 : Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), onSubmitted: _handleSend))),
      const SizedBox(width: 8),
      IconButton(onPressed: () => _handleSend(_textController.text), icon: const Icon(Icons.send_rounded, color: AppColors.primary)),
    ])));
  }
}