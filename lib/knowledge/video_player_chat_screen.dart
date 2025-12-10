import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'knowledge_data.dart';


// API Key của bạn
const String _googleApiKey = "AIzaSyCORVLq4vzKSa71evffOKOWJtclOqVUIIcss";

class VideoPlayerChatScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerChatScreen({super.key, required this.video});

  @override
  State<VideoPlayerChatScreen> createState() => _VideoPlayerChatScreenState();
}

class _VideoPlayerChatScreenState extends State<VideoPlayerChatScreen> {
  late YoutubePlayerController _controller;
  final TextEditingController _chatController = TextEditingController();

  // Danh sách tin nhắn chat
  final List<Map<String, String>> _messages = [
    {
      "role": "ai",
      // ĐÃ SỬA LỖI Ở ĐÂY: Bỏ dấu $ đi, chỉ để {{TITLE}} làm ký hiệu thay thế
      "text": "Chào bác! Cháu là trợ lý ảo. Bác đang xem video về '{{TITLE}}'. Bác có thắc mắc gì về bài tập hay nội dung trong video không ạ?"
    }
  ];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // 1. Thay thế {{TITLE}} bằng tên video thật ngay khi mở màn hình
    // Lúc này _messages[0]["text"] sẽ trở thành câu chào hoàn chỉnh
    _messages[0]["text"] = _messages[0]["text"]!.replaceAll("{{TITLE}}", widget.video.title);

    // 2. Lấy ID video từ URL
    // Logic: Nếu trong data bạn lưu link dạng img.youtube.com/.../ID/hqdefault.jpg thì nó sẽ cắt lấy ID
    // Nếu data là link youtube.com/watch?v=ID thì nó cũng tự lấy ID
    String videoUrl = widget.video.thumbnailUrl;
    // Nếu thumbnail là link ảnh youtube, ta cắt lấy ID từ đó
    if(videoUrl.contains("img.youtube.com")) {
      // Cắt chuỗi thủ công hoặc dùng logic convert (Tạm thời lấy ID mẫu nếu link ảnh)
      // Để đơn giản cho demo, nếu không parse được từ thumbnail, ta dùng ID từ thuộc tính id của VideoItem
      // Hoặc bạn nên thêm trường youtubeId vào model VideoItem để chuẩn nhất.
    }

    // Cách an toàn nhất: Thử convert từ thumbnail, nếu null thì dùng link fallback
    String? videoId = YoutubePlayer.convertUrlToId(widget.video.thumbnailUrl)
        ?? YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=lJdFK19yQa4"); // Link dự phòng

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? 'lJdFK19yQa4', // ID video mặc định nếu lỗi
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // --- HÀM GỬI TIN NHẮN CHO GEMINI ---
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    // 1. Hiển thị tin nhắn người dùng lên màn hình ngay
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isSending = true;
    });
    _chatController.clear(); // Xóa ô nhập

    try {
      // 2. Gọi API Gemini
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_googleApiKey');

      // Prompt (Câu lệnh) gửi cho AI
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
        String aiReply = data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _messages.add({"role": "ai", "text": aiReply});
        });
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
      // ResizeToAvoidBottomInset giúp đẩy chat lên khi bật bàn phím
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.video.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // --- 1. PHẦN VIDEO PLAYER (Cố định ở trên) ---
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.teal,
            progressColors: const ProgressBarColors(
              playedColor: Colors.teal,
              handleColor: Colors.tealAccent,
            ),
          ),

          // --- 2. PHẦN CHAT (Ở dưới) ---
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Tiêu đề nhỏ
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

                  // Danh sách tin nhắn
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
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAi) ...[
                                  const Icon(Icons.smart_toy, color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    msg['text']!,
                                    style: const TextStyle(fontSize: 16, height: 1.4), // Chữ to dễ đọc
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Ô nhập liệu
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Nhập câu hỏi của bác...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: _isSending ? null : _sendMessage,
                          backgroundColor: Colors.teal,
                          mini: true,
                          child: _isSending
                              ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.white),
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