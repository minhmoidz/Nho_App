import 'package:flutter/material.dart';

// --- 1. MODEL DỮ LIỆU (Mô phỏng cấu trúc bài viết) ---
class KnowledgeItem {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String summary;
  final String content; // Nội dung chi tiết

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.summary,
    required this.content,
  });
}

// --- 2. MÀN HÌNH CHÍNH: DANH SÁCH KIẾN THỨC ---
class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({Key? key}) : super(key: key);

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  // Màu chủ đạo
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Danh mục đang chọn (Mặc định là 'Tất cả')
  String _selectedCategory = 'Tất cả';

  // Danh sách các danh mục
  final List<String> _categories = ['Tất cả', 'Sức khỏe', 'Dinh dưỡng', 'Vận động', 'Mẹo vặt'];

  // Dữ liệu giả lập (Sau này bạn thay bằng API gọi về)
  final List<KnowledgeItem> _allArticles = [
    KnowledgeItem(
      id: '1',
      title: '5 Thói quen tốt cho tim mạch người cao tuổi',
      category: 'Sức khỏe',
      imageUrl: 'https://img.freepik.com/free-photo/doctor-holding-red-heart_1150-6157.jpg', // Ảnh mẫu
      summary: 'Tim mạch là vấn đề quan trọng. Hãy cùng xem 5 thói quen đơn giản...',
      content: '1. Đi bộ nhẹ nhàng mỗi ngày 30 phút.\n\n2. Giảm ăn mặn, hạn chế muối.\n\n3. Ăn nhiều rau xanh và trái cây.\n\n4. Giữ tinh thần lạc quan, tránh căng thẳng.\n\n5. Khám sức khỏe định kỳ 6 tháng/lần.',
    ),
    KnowledgeItem(
      id: '2',
      title: 'Thực đơn "vàng" giúp xương chắc khỏe',
      category: 'Dinh dưỡng',
      imageUrl: 'https://img.freepik.com/free-photo/fresh-healthy-food-arrangement_23-2148866736.jpg',
      summary: 'Bổ sung canxi qua đường ăn uống là cách tốt nhất để phòng loãng xương.',
      content: 'Người cao tuổi cần bổ sung Canxi và Vitamin D. \n\n- Sữa và các chế phẩm từ sữa.\n- Các loại hạt (hạnh nhân, óc chó).\n- Cá hồi và cá mòi.\n- Rau màu xanh đậm (súp lơ, cải xoăn).',
    ),
    KnowledgeItem(
      id: '3',
      title: 'Bài tập dưỡng sinh buổi sáng',
      category: 'Vận động',
      imageUrl: 'https://img.freepik.com/free-photo/senior-woman-stretching-park_23-2148243256.jpg',
      summary: 'Hướng dẫn bài tập hít thở và vận động nhẹ nhàng giúp lưu thông khí huyết.',
      content: 'Động tác 1: Hít thở sâu, vươn vai.\n\nĐộng tác 2: Xoay cổ tay, cổ chân.\n\nĐộng tác 3: Vặn mình nhẹ nhàng.\n\nLưu ý: Nên tập ở nơi thoáng mát, tránh gió lùa.',
    ),
    KnowledgeItem(
      id: '4',
      title: 'Cách ngủ ngon không cần dùng thuốc',
      category: 'Mẹo vặt',
      imageUrl: 'https://img.freepik.com/free-photo/senior-man-sleeping-bed_23-2148984419.jpg',
      summary: 'Mất ngủ là nỗi lo của nhiều người. Thử ngay các mẹo nhỏ này.',
      content: '- Ngâm chân nước ấm với gừng trước khi ngủ.\n- Không uống trà, cà phê sau 3 giờ chiều.\n- Nghe nhạc không lời nhẹ nhàng.\n- Đọc sách giấy thay vì xem điện thoại.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách theo danh mục
    final displayList = _selectedCategory == 'Tất cả'
        ? _allArticles
        : _allArticles.where((item) => item.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Kiến Thức Sống Khỏe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Thanh danh mục (Cuộn ngang)
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Danh sách bài viết
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                return _buildArticleCard(displayList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget thẻ bài viết
  Widget _buildArticleCard(KnowledgeItem item) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bài viết (Có xử lý lỗi nếu ảnh hỏng)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag danh mục
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tiêu đề
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 8),

                  // Tóm tắt
                  Text(
                    item.summary,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Nút xem thêm
                  Row(
                    children: [
                      Text("Đọc tiếp", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16, color: _primaryColor),
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

// --- 3. MÀN HÌNH CHI TIẾT BÀI VIẾT ---
class ArticleDetailScreen extends StatelessWidget {
  final KnowledgeItem article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar có ảnh nền co giãn (SliverAppBar)
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
              ),
            ),
          ),

          // Nội dung chi tiết
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Danh mục
                    Text(
                      article.category,
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    // Tiêu đề lớn
                    Text(
                      article.title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                    ),
                    const SizedBox(height: 20),

                    // Đường kẻ phân cách
                    const Divider(thickness: 1),
                    const SizedBox(height: 20),

                    // Nội dung bài viết
                    Text(
                      article.content,
                      style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
                      // FontSize 18 rất quan trọng cho người già
                    ),

                    const SizedBox(height: 40),

                    // Nút chia sẻ (Giả lập)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text("Chia sẻ bài này"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}