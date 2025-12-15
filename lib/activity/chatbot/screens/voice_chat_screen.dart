import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:async';

// Đảm bảo import đúng đường dẫn 2 file này của bạn
import '../services/api_service.dart';
import '../models/chat_model.dart';

class VoiceChatScreen extends StatefulWidget {
  final String conversationId; // ID nhận từ màn hình trước

  const VoiceChatScreen({super.key, required this.conversationId});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with TickerProviderStateMixin {
  // --- SERVICE & CONTROLLERS ---
  final ApiService _apiService = ApiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _micAnimController;

  // --- BIẾN TRẠNG THÁI (STATE) ---
  late String _currentId;             // ID hội thoại đang xem
  List<ChatMessage> _messages = [];    // Danh sách tin nhắn hiển thị
  List<Conversation> _historyList = []; // Danh sách menu lịch sử

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoadingMessages = true;      // Biến để hiện vòng quay khi tải tin nhắn cũ
  bool _isBotThinking = false;
  String _liveVoiceText = "";

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraOn = false;

  @override
  void initState() {
    super.initState();
    // 1. Gán ID ban đầu
    _currentId = widget.conversationId;

    // 2. Animation Mic
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 3. Setup
    _setupTTS();
    _loadMessages();    // Tải tin nhắn của ID hiện tại ngay khi vào
    _loadHistoryList(); // Tải danh sách menu
  }

  // ==================== 1. LOGIC TẢI TIN NHẮN (Get Detail) ====================

  // Hàm này gọi API lấy chi tiết cuộc hội thoại và hiển thị lên
  Future<void> _loadMessages() async {
    print(">>> Đang tải nội dung cho ID: $_currentId");

    // Nếu ID rỗng thì thôi không tải, tắt loading ngay
    if (_currentId.isEmpty || _currentId == "null") {
      setState(() => _isLoadingMessages = false);
      return;
    }

    setState(() => _isLoadingMessages = true); // Bắt đầu quay

    try {
      // Gọi API
      final msgs = await _apiService.getConversationDetail(_currentId);

      if (mounted) {
        setState(() {
          _messages = msgs;
          // QUAN TRỌNG: Nếu danh sách rỗng, thêm tin nhắn báo hiệu
          if (msgs.isEmpty) {
            _messages.add(ChatMessage(content: "Cuộc trò chuyện này chưa có tin nhắn nào.", isUser: false));
          }
        });
      }
    } catch (e) {
      print("Lỗi UI Load Messages: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải tin nhắn: $e")));
      }
    } finally {
      // Dù thành công hay thất bại, BẮT BUỘC phải tắt loading
      if (mounted) {
        setState(() => _isLoadingMessages = false);
        _scrollToBottom();
      }
    }
  }

  // ==================== 2. LOGIC MENU & CHUYỂN HỘI THOẠI ====================

  // Tải danh sách lịch sử cho Menu bên phải
  Future<void> _loadHistoryList() async {
    final history = await _apiService.getHistory();
    if (mounted) {
      setState(() {
        _historyList = history;
      });
    }
  }

  // HÀM QUAN TRỌNG: Xử lý khi bấm vào 1 dòng lịch sử
  void _switchConversation(String newId) {
    Navigator.pop(context); // Đóng Menu

    // Cập nhật State để chuyển sang hội thoại mới
    setState(() {
      _currentId = newId;        // Đổi ID
      _messages = [];            // Xóa trắng màn hình hiện tại
      _isLoadingMessages = true; // Hiện loading
    });

    // Gọi hàm tải chi tiết của ID mới
    _loadMessages();
  }

  // ==================== 3. LOGIC TẠO MỚI (New Chat) ====================

  // Gọi API POST /api/v1/chat/history/new
  Future<void> _createNewChat() async {
    Navigator.pop(context); // Đóng menu

    // Hiện loading dialog
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator())
    );

    // Gọi API tạo mới
    final newId = await _apiService.createNewConversation();

    if (mounted) Navigator.pop(context); // Tắt dialog

    if (newId != null) {
      // Nếu tạo thành công
      setState(() {
        _currentId = newId.toString(); // Gán ID mới
        _messages = [];                // Màn hình trắng
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tạo cuộc trò chuyện mới")));

      // Tải lại menu lịch sử để thấy cái mới tạo
      _loadHistoryList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi tạo hội thoại mới")));
    }
  }

  // ==================== 4. LOGIC CHAT (Gửi tin) ====================

  Future<void> _handleSend(String text) async {
    if (_isSpeaking) await _stopSpeaking();
    if (text.trim().isEmpty) return;

    // Hiển thị tin nhắn User ngay
    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isBotThinking = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Gọi API Chat (Gửi kèm _currentId để server biết chat tiếp vào đâu)
    final botResponse = await _apiService.sendMessage(text, _currentId);

    if (mounted) {
      setState(() {
        _isBotThinking = false;
        if (botResponse != null) {
          String cleanText = botResponse.replaceAll('*', '');
          _messages.add(ChatMessage(content: cleanText, isUser: false));
          _tts.speak(cleanText);

          // Sau khi chat xong, tải lại lịch sử để cập nhật tiêu đề mới nhất (nếu API có trả title)
          _loadHistoryList();
        } else {
          _messages.add(ChatMessage(content: "⚠️ Lỗi kết nối", isUser: false));
        }
      });
      _scrollToBottom();
    }
  }

  // ==================== 5. XÓA HỘI THOẠI ====================

  Future<void> _deleteConversation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn muốn xóa cuộc trò chuyện này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _apiService.deleteConversation(id);

    if (success) {
      setState(() {
        _historyList.removeWhere((item) => item.id.toString() == id.toString());
      });
      // Nếu xóa đúng cái đang xem -> Reset màn hình
      if (id.toString() == _currentId.toString()) {
        setState(() {
          _messages = [];
          _messages.add(ChatMessage(content: "Đã xóa cuộc hội thoại này.", isUser: false));
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi xóa")));
    }
  }

  // ==================== VOICE & CAMERA UTILS ====================

  Future<void> _setupTTS() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.5);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((msg) => setState(() => _isSpeaking = false));
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _startListening() async {
    if (_isSpeaking) await _stopSpeaking();
    bool available = await _speech.initialize(
      onError: (val) {
        setState(() { _isListening = false; _liveVoiceText = ""; });
        _micAnimController.stop();
      },
    );
    if (available) {
      setState(() { _isListening = true; _liveVoiceText = "Đang nghe..."; });
      _micAnimController.repeat(reverse: true);
      _speech.listen(
        localeId: "vi_VN",
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        onResult: (result) {
          setState(() => _liveVoiceText = result.recognizedWords);
          _scrollToBottom();
          if (result.finalResult) _stopListeningAndSend();
        },
      );
    }
  }

  Future<void> _stopListeningAndSend() async {
    if (!_isListening) return;
    String finalVoiceText = _liveVoiceText;
    setState(() { _isListening = false; _liveVoiceText = ""; });
    _micAnimController.stop();
    _micAnimController.reset();
    await _speech.stop();
    if (finalVoiceText.trim().isNotEmpty && finalVoiceText != "Đang nghe...") {
      _handleSend(finalVoiceText);
    }
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
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

  // ==================== GIAO DIỆN (UI) ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),

      // --- MENU BÊN PHẢI ---
      endDrawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: const Text("Lịch sử Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text("${_historyList.length} cuộc hội thoại"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.history, color: Colors.blueAccent),
              ),
            ),

            // Nút Tạo Mới
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green, size: 30),
              title: const Text("Tạo đoạn chat mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              onTap: _createNewChat,
            ),
            const Divider(thickness: 1),

            Expanded(
              child: _historyList.isEmpty
                  ? const Center(child: Text("Chưa có lịch sử"))
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _historyList.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _historyList[index];
                  final isSelected = item.id.toString() == _currentId.toString();

                  return ListTile(
                    tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color: isSelected ? Colors.blueAccent : Colors.grey,
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blueAccent : Colors.black87,
                      ),
                    ),
                    // Nút Xóa
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteConversation(item.id),
                    ),
                    // Bấm vào để xem chi tiết
                    onTap: () => _switchConversation(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Assistant",
                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Hiển thị ID nhỏ bên dưới để bạn dễ test (sau này có thể xóa)
                  Text("ID: $_currentId", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off, color: _isCameraOn ? Colors.blue : Colors.grey),
            onPressed: _toggleCameraState,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.blueAccent, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      extendBodyBehindAppBar: _isCameraOn,

      body: Stack(
        children: [
          if (_isCameraOn && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!)),
          if (_isCameraOn) Container(color: Colors.white.withOpacity(0.85)),

          Column(
            children: [
              if (_isCameraOn) const SizedBox(height: 90),

              Expanded(
                child: _isLoadingMessages
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(child: Text("Hãy bắt đầu trò chuyện...", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
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

              if (_isSpeaking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FloatingActionButton.extended(
                    onPressed: _stopSpeaking,
                    backgroundColor: Colors.redAccent,
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                    label: const Text("Dừng đọc", style: TextStyle(color: Colors.white)),
                  ),
                ),

              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy, size: 18, color: Colors.blueGrey),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00C6FF)])
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVoiceBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _liveVoiceText.isEmpty ? "Đang nghe..." : _liveVoiceText,
                      style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.blueGrey),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Đang suy nghĩ...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                      color: _isListening ? Colors.redAccent : const Color(0xFFF2F4F8),
                      boxShadow: _isListening
                          ? [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10 + (_micAnimController.value * 10))]
                          : [],
                    ),
                    child: Icon(_isListening ? Icons.graphic_eq : Icons.mic_rounded,
                        color: _isListening ? Colors.white : Colors.blueGrey, size: 24),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF2F4F8), borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: _handleSend,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              child: IconButton(
                onPressed: () => _handleSend(_textController.text),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}