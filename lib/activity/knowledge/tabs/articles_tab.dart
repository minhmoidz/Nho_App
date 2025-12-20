import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nhoapp/constants/app_colors.dart';

class ArticlesTab extends StatefulWidget {
  const ArticlesTab({super.key});

  @override
  State<ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<ArticlesTab> {
  List<dynamic> _articles = [];
  bool _isLoading = true;

  // --- KHO ẢNH SỨC KHỎE CHẤT LƯỢNG CAO (UNSPLASH) ---
  // Danh sách này sẽ được dùng xoay vòng cho các tin tức
  final List<String> _stockImages = [
    "https://images.unsplash.com/photo-1505751172876-fa1923c5c528?q=80&w=800", // Bác sĩ
    "https://images.unsplash.com/photo-1544367563-12123d8965cd?q=80&w=800", // Yoga/Thiền
    "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=800", // Tập thể dục
    "https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?q=80&w=800", // Y tá/Chăm sóc
    "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800", // Thực phẩm lành mạnh
    "https://plus.unsplash.com/premium_photo-1664474619075-644dd191935f?q=80&w=800", // Người cao tuổi vui vẻ
    "https://images.unsplash.com/photo-1505576399279-565b52d4ac71?q=80&w=800", // Bệnh viện sạch sẽ
    "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=800", // Ống nghe y tế
    "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=800", // Nghiên cứu/Thuốc
    "https://images.unsplash.com/photo-1579684385127-1ef15d508118?q=80&w=800", // Trái cây/Vitamin
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealNews();
  }

  Future<void> _fetchRealNews() async {
    // RSS Sức khỏe VnExpress
    const String rssUrl = "https://api.rss2json.com/v1/api.json?rss_url=https://vnexpress.net/rss/suc-khoe.rss";

    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _articles = data['items'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi kết nối: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi lấy tin: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Không tải được tin tức.", style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _fetchRealNews,
              child: const Text("Thử lại", style: TextStyle(color: AppColors.primary)),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRealNews,
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          // --- LOGIC CHỌN ẢNH ---
          // Dùng phép chia lấy dư (%) để xoay vòng danh sách ảnh
          // Ví dụ: Tin số 1 dùng ảnh 1, Tin số 11 dùng lại ảnh 1.
          // Cách này giúp ảnh luôn hiển thị ổn định, không bị nháy khi cuộn lên xuống.
          final String randomImage = _stockImages[index % _stockImages.length];

          return _buildNewsCard(_articles[index], randomImage);
        },
      ),
    );
  }

  Widget _buildNewsCard(dynamic article, String imageUrl) {
    // Xử lý ngày tháng
    String dateStr = article['pubDate'];
    try {
      DateTime date = DateTime.parse(dateStr);
      dateStr = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      dateStr = "Mới nhất";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchURL(article['link']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ẢNH BÌA (Dùng ảnh kho) ---
            Stack(
              children: [
                Image.network(
                  imageUrl, // Sử dụng link ảnh từ danh sách có sẵn
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.teal.shade100,
                      child: const Center(child: Icon(Icons.broken_image, color: AppColors.primary)),
                    );
                  },
                ),

                // Lớp phủ đen mờ để chữ nổi hơn nếu cần thiết
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Tag "Tin mới"
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Text(
                      "Sức Khỏe",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // --- NỘI DUNG ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        "Xem chi tiết >>",
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}