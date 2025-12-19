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

  // Ảnh mặc định nếu không tải được
  final String _defaultImage = "https://i1-suckhoe.vnecdn.net/2023/01/01/logo-vnexpress-1-1672535695.jpg?w=1200&h=0&q=100&dpr=1&fit=crop&s=Op1g3-y5P8e-28y1J-3sIg";

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

  // --- HÀM TRÍCH XUẤT ẢNH THÔNG MINH (FIX LỖI) ---
  String _extractImageUrl(dynamic article) {
    // 1. Thử lấy từ field 'thumbnail'
    if (article['thumbnail'] != null && article['thumbnail'].toString().isNotEmpty) {
      return article['thumbnail'];
    }

    // 2. Thử lấy từ field 'enclosure' (thường gặp trong RSS chuẩn)
    if (article['enclosure'] != null && article['enclosure']['link'] != null) {
      return article['enclosure']['link'];
    }

    // 3. QUAN TRỌNG: Quét nội dung 'description' để tìm thẻ <img src="...">
    // VnExpress thường để ảnh ở đây mà rss2json đôi khi bỏ qua
    if (article['description'] != null) {
      final RegExp imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
      final match = imgRegex.firstMatch(article['description']);
      if (match != null) {
        return match.group(1) ?? _defaultImage;
      }
    }

    return _defaultImage;
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

  Widget _buildNewsCard(dynamic article) {
    // Lấy URL ảnh bằng hàm mới
    String imageUrl = _extractImageUrl(article);

    // Chuyển http -> https để tránh lỗi bảo mật trên Android/iOS
    if (imageUrl.startsWith('http://')) {
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    // Xử lý ngày tháng
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
            // --- ẢNH BÌA ---
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // --- CỰC KỲ QUAN TRỌNG: HEADERS ĐỂ QUA MẶT CHẶN ẢNH ---
                  headers: const {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                    "Referer": "https://vnexpress.net/", // Mấu chốt để load ảnh VnExpress
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Nếu lỗi thì hiện ảnh mặc định
                    return Image.network(
                      _defaultImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                        color: Colors.teal.withOpacity(0.9),
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

            // --- NỘI DUNG ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}