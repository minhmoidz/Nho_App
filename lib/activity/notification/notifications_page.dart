import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhoapp/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/reminder/local_storage.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;

  // List chứa thông báo hỗn hợp (Cả báo thức từ Local + Thông báo hệ thống)
  List<Map<String, dynamic>> _notifications = [];
  
  // Lưu trạng thái đã đọc của thông báo hệ thống
  Set<int> _readSystemNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
    _loadAllNotifications(); // Gọi hàm load dữ liệu
  }

  // Load trạng thái đã đọc từ SharedPreferences
  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    setState(() {
      _readSystemNotifications = readIds.map((id) => int.parse(id)).toSet();
    });
  }

  // Lưu trạng thái đã đọc vào SharedPreferences
  Future<void> _saveReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_notifications',
      _readSystemNotifications.map((id) => id.toString()).toList(),
    );
  }

  // --- HÀM 1: LOAD DỮ LIỆU TỪ NHIỀU NGUỒN ---
  Future<void> _loadAllNotifications() async {
    // 1. Lấy dữ liệu Báo thức/Việc làm từ Local Storage
    List<dynamic> localReminders = await LocalStorage.getReminders();

    // 2. Chuyển đổi dữ liệu Reminder -> Notification
    List<Map<String, dynamic>> reminderNotifs = localReminders.map((item) {
      DateTime time = DateTime.tryParse(item['remind_at'] ?? '') ?? DateTime.now();
      bool isDone = item['is_completed'] ?? false;

      return {
        'id': item['id'], // Giữ ID để có thể xử lý sau này
        'title': 'Nhắc nhở: ${item['title']}', // Thêm tiền tố để dễ nhận biết
        'body': item['description'] != null && item['description'].isNotEmpty
            ? item['description']
            : 'Đến giờ thực hiện công việc này rồi!',
        'time': time,
        'isRead': isDone, // Nếu làm xong rồi thì coi như đã đọc
        'type': 'reminder', // Đánh dấu là loại nhắc nhở
      };
    }).toList();

    // 3. (Tùy chọn) Thêm thông báo giả lập từ hệ thống (như code cũ)
    List<Map<String, dynamic>> systemNotifs = [
      {
        'id': 999,
        'title': 'Chào mừng quay lại',
        'body': 'Chúc bác một ngày vui vẻ và mạnh khỏe!',
        'time': DateTime.now().subtract(const Duration(hours: 1)),
        'isRead': _readSystemNotifications.contains(999),
        'type': 'system',
      },
    ];

    // 4. Gộp 2 danh sách lại
    List<Map<String, dynamic>> combinedList = [...reminderNotifs, ...systemNotifs];

    // 5. Sắp xếp: Mới nhất lên đầu
    combinedList.sort((a, b) => b['time'].compareTo(a['time']));

    if (mounted) {
      setState(() {
        _notifications = combinedList;
        _isLoading = false;
      });
    }
  }

  // --- CÁC HÀM XỬ LÝ GIAO DIỆN (GIỮ NGUYÊN HOẶC TÙY CHỈNH) ---

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
        // Lưu ID của thông báo hệ thống đã đọc
        if (notif['type'] == 'system') {
          _readSystemNotifications.add(notif['id']);
        }
      }
    });
    
    // Lưu vào SharedPreferences
    await _saveReadStatus();
    
    // Cập nhật trạng thái đã hoàn thành cho reminders
    List<dynamic> reminders = await LocalStorage.getReminders();
    for (var notif in _notifications) {
      if (notif['type'] == 'reminder') {
        final index = reminders.indexWhere((r) => r['id'] == notif['id']);
        if (index != -1) {
          reminders[index]['is_completed'] = true;
        }
      }
    }
    await LocalStorage.saveReminders(reminders);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xem tất cả")),
      );
    }
  }

  void _deleteNotification(int index) {
    // Lưu ý: Ở đây chỉ xóa khỏi danh sách hiển thị tạm thời.
    // Nếu muốn xóa thật trong LocalStorage thì cần gọi API LocalStorage.delete...
    final removedItem = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });
  }

  // Helper: Icon & Màu sắc (Giữ nguyên logic cũ)
  IconData _getIconByType(String type) {
    if (type == 'reminder') return Icons.alarm;
    if (type == 'system') return Icons.info_outline;
    return Icons.notifications;
  }

  Color _getColorByType(String type) {
    if (type == 'reminder') return Colors.orange;
    if (type == 'system') return Colors.blue;
    return Colors.grey;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    // Nếu là tương lai (Reminder chưa đến giờ)
    if (diff.isNegative) {
      return 'Sắp tới: ${DateFormat('HH:mm dd/MM').format(time)}';
    }

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: NhoAppBar(
        title: 'Thông Báo & Nhắc Nhở',
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: _markAllAsRead,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        // Kéo xuống để load lại dữ liệu mới nhất từ Local
        onRefresh: _loadAllNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) => _buildNotificationItem(_notifications[index], index),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text('Chưa có thông báo nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, int index) {
    final bool isRead = item['isRead'];
    final bool isFuture = item['time'].isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.white : Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Đánh dấu đã đọc khi tap vào thông báo
          if (!isRead) {
            setState(() {
              item['isRead'] = true;
              if (item['type'] == 'system') {
                _readSystemNotifications.add(item['id']);
              }
            });
            
            // Lưu trạng thái
            await _saveReadStatus();
            
            // Nếu là reminder, cập nhật vào LocalStorage
            if (item['type'] == 'reminder') {
              List<dynamic> reminders = await LocalStorage.getReminders();
              final reminderIndex = reminders.indexWhere((r) => r['id'] == item['id']);
              if (reminderIndex != -1) {
                reminders[reminderIndex]['is_completed'] = true;
                await LocalStorage.saveReminders(reminders);
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _getColorByType(item['type']).withOpacity(0.1),
            child: Icon(_getIconByType(item['type']), color: _getColorByType(item['type'])),
          ),
          title: Text(
            item['title'],
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item['body'], maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (isFuture)
                    const Icon(Icons.schedule, size: 14, color: Colors.green)
                  else
                    const Icon(Icons.history, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(item['time']),
                    style: TextStyle(
                        fontSize: 12,
                        color: isFuture ? Colors.green[700] : Colors.grey[500],
                        fontWeight: isFuture ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Nút xóa nhanh
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => _deleteNotification(index),
          ),
        ),
      ),
    );
  }
}