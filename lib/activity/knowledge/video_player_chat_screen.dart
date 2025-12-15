import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'knowledge_data.dart'; // Đảm bảo class VideoItem có trường videoUrl

// LƯU Ý: Tuyệt đối không để lộ API Key lên mạng xã hội hay Github
const String _googleApiKey = "YOUR_API_KEY_HERE";

class VideoPlayerChatScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerChatScreen({super.key, required this.video});

  @override
  State<VideoPlayerChatScreen> createState() => _VideoPlayerChatScreenState();
}

class _VideoPlayerChatScreenState extends State<VideoPlayerChatScreen> {
  late YoutubePlayerController _controller;
  final TextEditingController _chatController = TextEditingController();

  // Danh sách tin nhắn
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

    // 1. Thay thế tên video vào câu chào
    _messages[0]["text"] = _messages[0]["text"]!.replaceAll("{{TITLE}}", widget.video.title);

    // --- PHẦN SỬA LỖI QUAN TRỌNG ---

    // Lấy ID từ videoUrl chứ không phải thumbnailUrl
    // Giả sử videoUrl là: "https://www.youtube.com/watch?v=abcdef123"
    String? videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);

    // Nếu không lấy được ID (do link lỗi), dùng ID dự phòng để app không bị crash
    // Bạn có thể thay bằng ID của một video hướng dẫn mặc định
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

  // --- HÀM GỬI TIN NHẮN (GIỮ NGUYÊN) ---
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isSending = true;
    });
    _chatController.clear();

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_googleApiKey');

      final prompt = """
      Bạn là một trợ lý sức khỏe ân cần cho người già.
      Người dùng đang xem video có tiêu đề: "${widget.video.title}".
      Người dùng hỏi: "$text".
      Hãy trả lời ngắn gọn, dễ hiểu, xưng hô là "Cháu" và gọi người dùng là "Bác".
      Nếu câu hỏi liên quan đến nội dung video, hãy giải thích dựa trên tiêu đề video.
      """;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Kiểm tra xem có data trả về không để tránh lỗi null
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          String aiReply = data['candidates'][0]['content']['parts'][0]['text'];
          setState(() {
            _messages.add({"role": "ai", "text": aiReply});
          });
        }
      } else {
        setState(() {
          _messages.add({"role": "ai", "text": "Cháu đang gặp chút sự cố kết nối, bác thử lại sau nhé!"});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "Xin lỗi bác, mạng đang yếu nên cháu chưa trả lời được ạ."});
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.video.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // --- 1. PHẦN VIDEO PLAYER ---
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.teal,
            onReady: () {
              // Code chạy khi video đã sẵn sàng (nếu cần)
              print('Player is ready.');
            },
          ),

          // --- 2. PHẦN CHAT ---
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange[100],
                    child: const Text(
                      "Hỏi đáp với Trợ lý ảo về video này",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                            child: Text(
                              msg['text']!,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: 'Nhập câu hỏi...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: _isSending
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.teal),
                        ),
                      ],
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