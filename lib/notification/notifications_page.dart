import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm package này để format ngày giờ (nếu chưa có)

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // --- MOCK DATA (Dữ liệu giả) ---
  // Sau này bạn có thể thay bằng API call
  List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Đến giờ uống thuốc!',
      'body': 'Đừng quên uống thuốc huyết áp sau bữa ăn trưa nhé.',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'isRead': false,
      'type': 'reminder', // reminder, system, news
    },
    {
      'id': 2,
      'title': 'Chào mừng bạn mới',
      'body': 'Cảm ơn bạn đã cài đặt ứng dụng Nhớ App. Hãy khám phá các tính năng ngay!',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'type': 'system',
    },
    {
      'id': 3,
      'title': 'Cập nhật hệ thống',
      'body': 'Bản cập nhật v1.0.2 đã sẵn sàng với nhiều tính năng mới.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'type': 'update',
    },
    {
      'id': 4,
      'title': 'Kỷ niệm ngày này năm xưa',
      'body': 'Xem lại bức ảnh bạn chụp vào ngày này năm ngoái.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'type': 'memory',
    },
    {
      'id': 5,
      'title': 'Hoàn thành mục tiêu!',
      'body': 'Chúc mừng! Bạn đã hoàn thành 5 bài tập trí não tuần này.',
      'time': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': true,
      'type': 'success',
    },
  ];

  // Màu chủ đạo
  final Color _primaryColor = const Color(0xFF1565C0);

  // Hàm xử lý: Đánh dấu tất cả là đã đọc
  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã đánh dấu tất cả là đã đọc")),
    );
  }

  // Hàm xử lý: Xóa thông báo
  void _deleteNotification(int index) {
    final removedItem = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });

    // Cho phép hoàn tác (Undo)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Đã xóa thông báo"),
        action: SnackBarAction(
          label: "Hoàn tác",
          onPressed: () {
            setState(() {
              _notifications.insert(index, removedItem);
            });
          },
        ),
      ),
    );
  }

  // Helper: Lấy Icon theo loại thông báo
  IconData _getIconByType(String type) {
    switch (type) {
      case 'reminder': return Icons.alarm;
      case 'system': return Icons.info_outline;
      case 'update': return Icons.system_update;
      case 'memory': return Icons.photo_library;
      case 'success': return Icons.emoji_events;
      default: return Icons.notifications;
    }
  }

  // Helper: Lấy Màu nền Icon theo loại
  Color _getColorByType(String type) {
    switch (type) {
      case 'reminder': return Colors.orange;
      case 'system': return Colors.blue;
      case 'update': return Colors.purple;
      case 'memory': return Colors.pink;
      case 'success': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Helper: Format thời gian thông minh (Vừa xong, 2 giờ trước...)
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    // Tách list thành chưa đọc và đã đọc để hiển thị đẹp hơn (tùy chọn)
    // Ở đây mình hiển thị chung 1 list sorted theo thời gian

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Màu nền xám nhạt
      appBar: AppBar(
        title: const Text(
          'Thông Báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87, // Màu chữ đen
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: _primaryColor),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: _markAllAsRead,
          )
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _buildNotificationItem(item, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 64, color: _primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo mới',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, int index) {
    final bool isRead = item['isRead'];

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart, // Chỉ cho phép vuốt từ phải sang trái
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) => _deleteNotification(index),
      child: GestureDetector(
        onTap: () {
          // Bấm vào để xem chi tiết & đánh dấu đã đọc
          setState(() {
            item['isRead'] = true;
          });
          // Có thể navigate sang trang chi tiết ở đây
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue.shade50, // Chưa đọc thì nền xanh nhạt
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isRead ? null : Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getColorByType(item['type']).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconByType(item['type']),
                  color: _getColorByType(item['type']),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isRead ? Colors.grey[600] : Colors.grey[800],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(item['time']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}