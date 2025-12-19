import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../knowledge_data.dart';
import '../screen/video_player_chat_screen.dart';

class VideosTab extends StatelessWidget {
  VideosTab({super.key});

  // --- KHO ẢNH DỰ PHÒNG CHẤT LƯỢNG CAO (Unsplash) ---
  // Dùng khi ảnh YouTube bị lỗi hoặc không tìm thấy
  final List<String> fallbackImages = [
    "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=800&auto=format&fit=crop", // Tập dưỡng sinh
    "https://images.unsplash.com/photo-1544367563-12123d8965cd?q=80&w=800&auto=format&fit=crop", // Yoga/Thiền
    "https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=800&auto=format&fit=crop", // Gym nữ
    "https://plus.unsplash.com/premium_photo-1664474619075-644dd191935f?q=80&w=800&auto=format&fit=crop", // Người cao tuổi
    "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800&auto=format&fit=crop", // Gym nam
    "https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?q=80&w=800&auto=format&fit=crop", // Hoa quả/Sức khỏe
  ];

  // --- HÀM LẤY LINK ẢNH (Ưu tiên YouTube) ---
  String _getThumbnailUrl(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      // Dùng mqdefault (medium quality) thay vì hqdefault vì nó ổn định hơn
      // hqdefault đôi khi bị lỗi 404 với một số video cũ
      return "https://img.youtube.com/vi/$videoId/mqdefault.jpg";
    }
    return ""; // Trả về rỗng để trigger errorBuilder
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sampleVideos.length,
      itemBuilder: (context, index) {
        final video = sampleVideos[index];

        // 1. Lấy link ảnh từ YouTube
        final String youtubeThumb = _getThumbnailUrl(video.videoUrl);

        // 2. Chọn ảnh dự phòng (fallback) dựa trên index để không bị trùng nhau
        final String backupThumb = fallbackImages[index % fallbackImages.length];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerChatScreen(video: video),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)
                ),
              ],
            ),
            child: Column(
              children: [
                // --- KHUNG ẢNH (QUAN TRỌNG NHẤT) ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        youtubeThumb, // Thử tải ảnh YouTube trước
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,

                        // Khi đang tải -> Hiện khung xám
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
                          );
                        },

                        // --- CHÌA KHÓA Ở ĐÂY ---
                        // Nếu ảnh YouTube lỗi (404) -> Tự động tải ảnh dự phòng
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            backupThumb, // Tải ảnh Unsplash
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,

                            // Nếu ảnh dự phòng cũng lỗi (mất mạng) -> Hiện khung màu
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.teal.withOpacity(0.3),
                                child: const Center(
                                  child: Icon(Icons.videocam_off, color: Colors.white, size: 50),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Lớp phủ đen mờ
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),

                    // Nút Play
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35),
                    ),

                    // Thời lượng
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video.duration,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),

                // --- THÔNG TIN BÊN DƯỚI ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          radius: 20,
                          child: const Icon(Icons.person, color: Colors.teal, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                  height: 1.3
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "GV: ${video.author}",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}