import 'package:flutter/material.dart';

// --- MODELS ---

class Article {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String content;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.content,
  });
}

class VideoItem {
  final String id;
  final String title;
  final String duration;
  final String thumbnailUrl; // Link ảnh bìa
  final String videoUrl;     // Link video Youtube chuẩn (MỚI THÊM)
  final String author;

  VideoItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.author,
  });
}

class Medicine {
  final String id;
  final String name;
  final String usage;
  final String dosage;
  final String warning;

  Medicine({
    required this.id,
    required this.name,
    required this.usage,
    required this.dosage,
    required this.warning,
  });
}

// --- MOCK DATA (Dữ liệu mẫu) ---

final List<Article> sampleArticles = [
  Article(
    id: '1',
    title: '5 Thói quen giúp tim mạch khỏe mạnh',
    category: 'Sức khỏe',
    imageUrl: 'https://images.unsplash.com/photo-1628348068343-c6a848d2b6dd?auto=format&fit=crop&q=80&w=500',
    content: '1. Đi bộ mỗi ngày...\n2. Ăn nhạt...\n3. Giữ tinh thần lạc quan...',
  ),
  Article(
    id: '2',
    title: 'Thực đơn tốt cho người tiểu đường',
    category: 'Dinh dưỡng',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
    content: 'Người tiểu đường nên ăn nhiều rau xanh, hạn chế tinh bột trắng...',
  ),
  Article(
    id: '3',
    title: 'Bài tập dưỡng sinh buổi sáng',
    category: 'Vận động',
    imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80&w=500',
    content: 'Hít thở sâu, vươn vai nhẹ nhàng giúp khí huyết lưu thông...',
  ),
];

final List<Medicine> sampleMedicines = [
  Medicine(
    id: 'm1',
    name: 'Panadol (Giảm đau, hạ sốt)',
    usage: 'Dùng khi đau đầu, sốt nhẹ.',
    dosage: '1 viên/lần, cách nhau 4-6 tiếng.',
    warning: 'Không uống rượu bia khi dùng thuốc. Không dùng quá liều.',
  ),
  Medicine(
    id: 'm2',
    name: 'Hoạt huyết dưỡng não',
    usage: 'Tăng tuần hoàn máu não, giảm đau đầu chóng mặt.',
    dosage: '2 viên/lần, ngày 2 lần sau ăn.',
    warning: 'Phụ nữ có thai cần hỏi ý kiến bác sĩ.',
  ),
  Medicine(
    id: 'm3',
    name: 'Berberin (Tiêu hóa)',
    usage: 'Dùng khi đau bụng, đi ngoài.',
    dosage: '4 viên/lần, ngày 2 lần.',
    warning: 'Tránh dùng cho phụ nữ có thai.',
  ),
];

// Dữ liệu video đã cập nhật thêm videoUrl
final List<VideoItem> sampleVideos = [

  VideoItem(
    id: 'v1',
    title: 'Xử lý nhanh khi bị tăng huyết áp đột ngột',
    duration: '08:45',
    author: 'Bác sĩ Gia Đình',
    thumbnailUrl: 'https://img.youtube.com/vi/ScMzIvxBSi4/hqdefault.jpg',
    // Link chuẩn để plugin cắt lấy ID "ScMzIvxBSi4"
    videoUrl: 'https://www.youtube.com/watch?v=ScMzIvxBSi4',
  ),
  VideoItem(
    id: 'v2',
    title: 'Nhạc thiền thư giãn dễ ngủ',
    duration: '60:00',
    author: 'Thiền Đạo',
    thumbnailUrl: 'https://img.youtube.com/vi/1ZYbU82GVz4/hqdefault.jpg',
    videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
  ),
];