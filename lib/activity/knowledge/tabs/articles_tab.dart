import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Để format ngày tháng
import 'package:url_launcher/url_launcher.dart'; // Để mở link báo

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

  // --- HÀM LẤY TIN TỨC TỪ VNEXPRESS (QUA RSS) ---
  Future<void> _fetchRealNews() async {
    // URL RSS Sức khỏe của VnExpress được chuyển qua JSON để dễ xử lý
    const String rssUrl = "https://api.rss2json.com/v1/api.json?rss_url=https://vnexpress.net/rss/suc-khoe.rss";

    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _articles = data['items']; // Lấy danh sách bài báo
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi lấy tin: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- HÀM MỞ TRÌNH DUYỆT ĐỌC BÁO ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không thể mở link $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_articles.isEmpty) {
      return const Center(
        child: Text("Không tải được tin tức. Vui lòng kiểm tra mạng.",
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRealNews, // Kéo xuống để tải lại tin
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildNewsCard(article);
        },
      ),
    );
  }

  // --- WIDGET THẺ BÀI BÁO (GIAO DIỆN ĐẸP) ---
  Widget _buildNewsCard(dynamic article) {
    // Xử lý ảnh: Nếu API không trả về thumbnail, dùng ảnh mặc định
    String imageUrl = article['thumbnail'] ?? '';
    if (imageUrl.isEmpty) {
      imageUrl = "https://i1-suckhoe.vnecdn.net/2023/01/01/logo-vnexpress-1-1672535695.jpg?w=1200&h=0&q=100&dpr=1&fit=crop&s=Op1g3-y5P8e-28y1J-3sIg";
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
      elevation: 4, // Đổ bóng
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Cắt ảnh theo bo góc
      child: InkWell(
        onTap: () => _launchURL(article['link']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh bìa bài báo
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                  ),
                ),
                // Tag "Mới" cho bài viết
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
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

            // 2. Nội dung bài báo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 19, // Chữ to cho người già
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
                        "Nguồn: VnExpress",
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Nút Đọc tiếp
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