import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticlesTab extends StatefulWidget {
  const ArticlesTab({super.key});

  @override
  State<ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<ArticlesTab> {
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealNews();
  }

  // --- HÀM LẤY TIN TỨC TỪ VNEXPRESS ---
  Future<void> _fetchRealNews() async {
    // Sử dụng api.rss2json.com để chuyển đổi RSS VnExpress sang JSON
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
      print("Lỗi lấy tin: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HÀM MỞ TRÌNH DUYỆT ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Nếu không mở được bằng external, thử mở in-app
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Không tải được tin tức.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            TextButton(
              onPressed: _fetchRealNews,
              child: const Text("Thử lại", style: TextStyle(color: Colors.teal)),
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
          return _buildNewsCard(_articles[index]);
        },
      ),
    );
  }

  // --- WIDGET THẺ BÀI BÁO (ĐÃ KHẮC PHỤC LỖI ẢNH) ---
  Widget _buildNewsCard(dynamic article) {
    // 1. Lấy URL ảnh và xử lý https
    String imageUrl = article['thumbnail'] ?? '';

    // Nếu rỗng, dùng ảnh mặc định
    if (imageUrl.isEmpty) {
      imageUrl = "https://i1-suckhoe.vnecdn.net/2023/01/01/logo-vnexpress-1-1672535695.jpg?w=1200&h=0&q=100&dpr=1&fit=crop&s=Op1g3-y5P8e-28y1J-3sIg";
    }

    // Android rất ghét http thường, ép về https
    if (imageUrl.startsWith('http://')) {
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    // 2. Xử lý ngày tháng
    String dateStr = article['pubDate'];
    try {
      DateTime date = DateTime.parse(dateStr);
      dateStr = DateFormat('dd/MM/yyyy - HH:mm').format(date);
    } catch (e) {
      dateStr = "";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchURL(article['link']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ẢNH BÌA (FIXED) ---
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // QUAN TRỌNG: Header giả lập trình duyệt Chrome để server không chặn
                  headers: const {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                  },
                  // Hiệu ứng khi đang tải ảnh
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.teal,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  // Xử lý khi lỗi ảnh
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                          SizedBox(height: 5),
                          Text("Không tải được ảnh", style: TextStyle(color: Colors.grey))
                        ],
                      ),
                    );
                  },
                ),

                // Tag chủ đề
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                        ]
                    ),
                    child: const Text(
                      "Sức Khỏe",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            // --- NỘI DUNG BÀI ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ngày đăng & Nguồn
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      const Text(
                        "VnExpress",
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Nút hành động
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nhấn để đọc chi tiết",
                        style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 15
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.teal[700]),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}