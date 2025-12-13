import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_service.dart'; // Import file chứa MemoryService

// --- MÀU SẮC CHỦ ĐẠO ---
const Color kPrimaryColor = Color(0xFF009688);
const Color kPrimaryDark = Color(0xFF00796B);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;

class MemoryDetailPage extends StatefulWidget {
  final int memoryId;
  final Map<String, dynamic> initialData; // Dữ liệu từ màn hình danh sách truyền sang
  final MemoryService memoryService;

  const MemoryDetailPage({
    super.key,
    required this.memoryId,
    required this.initialData,
    required this.memoryService,
  });

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  late Map<String, dynamic> _memoryData;

  // Future để chờ lấy link thật (Signed URL)
  Future<String?>? _signedImageFuture;
  Future<String?>? _signedAudioFuture;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    _memoryData = widget.initialData;

    // 1. Kích hoạt lấy link thật ngay lập tức cho dữ liệu ban đầu
    _refreshSignedUrls();

    // 2. Gọi API lấy dữ liệu mới nhất (đề phòng có sửa đổi nội dung)
    _fetchDetail();

    // Lắng nghe trạng thái Audio
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _isPlaying = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Hàm cập nhật các Future lấy link
  void _refreshSignedUrls() {
    setState(() {
      _signedImageFuture = widget.memoryService.getSignedUrl(_memoryData['image_url']);
      _signedAudioFuture = widget.memoryService.getSignedUrl(_memoryData['audio_url']);
    });
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await widget.memoryService.getMemoryDetail(widget.memoryId);
      if (mounted) {
        setState(() {
          _memoryData = data;
        });
        // Nếu dữ liệu thay đổi (ví dụ ảnh khác), cần lấy link mới
        _refreshSignedUrls();
      }
    } catch (e) {
      debugPrint("Lỗi tải chi tiết: $e");
    }
  }

  Future<void> _toggleAudio(String? signedUrl) async {
    if (signedUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => _isAudioLoading = true);
      try {
        await _audioPlayer.play(UrlSource(signedUrl));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi phát audio: $e")));
      } finally {
        setState(() => _isAudioLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String content = _memoryData['content'] ?? "";

    // Xử lý ngày tháng đẹp
    String dateStr = "";
    String timeStr = "";
    if (_memoryData['created_at'] != null) {
      try {
        DateTime dt = DateTime.parse(_memoryData['created_at']).toLocal();
        dateStr = "Ngày ${dt.day} tháng ${dt.month}, ${dt.year}";
        timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER ẢNH (Dạng Parallax - Co giãn)
          SliverAppBar(
            expandedHeight: 400, // Ảnh cao to cho đẹp
            pinned: true,
            backgroundColor: kPrimaryColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), // Nền mờ cho nút back dễ nhìn
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _memoryData['image_url'] != null
                  ? FutureBuilder<String?>(
                future: _signedImageFuture, // Chờ link thật
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey));
                  }

                  // Có link thật -> Hiển thị
                  return Hero(
                    tag: 'img_${widget.memoryId}', // Hiệu ứng phóng to mượt mà
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      // Thêm header giả lập trình duyệt để tránh bị chặn 403
                      headers: const {
                        "User-Agent": "Mozilla/5.0",
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error_outline, size: 40, color: Colors.red)),
                      ),
                    ),
                  );
                },
              )
                  : Container(
                color: kPrimaryColor,
                child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.white54)),
              ),
            ),
          ),

          // 2. NỘI DUNG CHI TIẾT (Bo góc trùm lên ảnh)
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0), // Đẩy lên đè vào ảnh 30px
              decoration: const BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh ngang nhỏ trang trí
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng ngày tháng
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 16, color: kPrimaryColor),
                                  const SizedBox(width: 6),
                                  Text(dateStr, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // NỘI DUNG TEXT
                        if (content.isNotEmpty)
                          Text(
                            content,
                            style: const TextStyle(fontSize: 18, height: 1.6, color: Color(0xFF2D3436)),
                          )
                        else
                          const Text("Không có nội dung mô tả.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),

                        const SizedBox(height: 30),

                        // KHUNG PHÁT AUDIO (NẾU CÓ)
                        if (_memoryData['audio_url'] != null)
                          FutureBuilder<String?>(
                            future: _signedAudioFuture, // Chờ link audio thật
                            builder: (context, snapshot) {
                              if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
                                return const SizedBox(); // Đang load link thì ẩn tạm
                              }

                              final signedAudioUrl = snapshot.data;
                              if (signedAudioUrl == null) return const SizedBox();

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                                ),
                                child: Row(
                                  children: [
                                    // Nút Play to đẹp
                                    GestureDetector(
                                      onTap: () => _toggleAudio(signedAudioUrl),
                                      child: Container(
                                        width: 55, height: 55,
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
                                        child: _isAudioLoading
                                            ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : Icon(_isPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Thông tin Audio
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Bản ghi âm kỷ niệm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isPlaying ? "Đang phát âm thanh..." : "Nhấn để nghe lại khoảnh khắc này",
                                            style: TextStyle(color: _isPlaying ? kPrimaryColor : Colors.grey, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.graphic_eq, color: _isPlaying ? kPrimaryColor : Colors.grey[300]),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 100), // Khoảng trống dưới cùng để cuộn hết
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