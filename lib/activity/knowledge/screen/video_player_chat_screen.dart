import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:nhoapp/constants/app_colors.dart';
import '../../chatbot/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../knowledge_data.dart';

class VideoPlayerChatScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerChatScreen({super.key, required this.video});

  @override
  State<VideoPlayerChatScreen> createState() => _VideoPlayerChatScreenState();
}

class _VideoPlayerChatScreenState extends State<VideoPlayerChatScreen> {
  final GeminiService _geminiService = GeminiService();
  late YoutubePlayerController _controller;
  final TextEditingController _chatController = TextEditingController();

  late ChatSession _chatSession;

  // Biến kiểm tra xem đây có phải là tin nhắn đầu tiên không
  bool _isFirstMessage = true;

  final List<Map<String, String>> _messages = [
    {
      "role": "ai",
      "text": "Chào bác! Cháu là trợ lý ảo. Bác đang xem video về '{{TITLE}}'. Bác có thắc mắc gì về bài tập hay nội dung trong video không ạ?"
    }
  ];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _messages[0]["text"] = _messages[0]["text"]!.replaceAll("{{TITLE}}", widget.video.title);

    // Tạo Chat Session với Gemini
    _chatSession = _geminiService.createChatSession();

    // Setup Video
    String? videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);
    videoId ??= "lJdFK19yQa4";

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // --- HÀM TẠO NGỮ CẢNH ---
  String _buildContextPrompt() {
    // Bạn có thể thêm description nếu trong VideoItem có trường đó
    // Ví dụ: ${widget.video.description}
    return """
    [HỆ THỐNG - THÔNG TIN NGỮ CẢNH]
    Người dùng đang xem video Youtube này. Hãy đóng vai trợ lý sức khỏe trả lời dựa trên thông tin sau:
    - Tiêu đề video: "${widget.video.title}"
    - Link video: "${widget.video.videoUrl}"
    
    Lưu ý: Trả lời ngắn gọn, thân thiện, xưng hô là "Cháu" và gọi người dùng là "Bác".
    ---------------------------------------------------
    """;
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    // 1. Chỉ hiện câu hỏi của người dùng lên UI (Không hiện ngữ cảnh loằng ngoằng)
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isSending = true;
    });
    _chatController.clear();

    try {
      String textToSend = text;

      // 2. KỸ THUẬT TIÊM NGỮ CẢNH (CONTEXT INJECTION)
      // Nếu là tin nhắn đầu tiên, ta nối thêm thông tin video vào trước câu hỏi
      if (_isFirstMessage) {
        String contextPrompt = _buildContextPrompt();
        textToSend = "$contextPrompt\n\nNgười dùng hỏi: $text";

        // Đánh dấu là đã gửi ngữ cảnh rồi, lần sau không gửi nữa cho đỡ tốn token
        _isFirstMessage = false;
      }

      // 3. Gửi text đã kèm ngữ cảnh lên Gemini API qua chat session
      final botReply = await _geminiService.sendMessageInSession(_chatSession, textToSend);

      if (mounted) {
        setState(() {
          if (botReply != null) {
            String cleanText = botReply.replaceAll('*', '');
            _messages.add({"role": "ai", "text": cleanText});
          } else {
            _messages.add({"role": "ai", "text": "Cháu đang gặp sự cố kết nối, bác thử lại sau nhé."});
          }
        });
      }
    } catch (e) {
      print("Lỗi chat: $e");
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": "Lỗi: $e"});
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Phần giao diện Build giữ nguyên như cũ) ...
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.video.title, style: const TextStyle(fontSize: 16, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.secondary,
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  // ... (Phần tiêu đề cam giữ nguyên)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isAi = msg['role'] == 'ai';
                        return Align(
                          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                            decoration: BoxDecoration(
                              color: isAi ? Colors.white : Colors.teal[100],
                              borderRadius: BorderRadius.circular(12),
                              border: isAi ? Border.all(color: Colors.grey.shade300) : null,
                            ),
                            child: Text(msg['text']!, style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87)),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: InputDecoration(
                                hintText: 'Nhập thắc mắc về video...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: IconButton(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: _isSending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
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
}