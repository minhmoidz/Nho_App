import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'bottom_nav_bar.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final String appName;
  final String? userName;
  final int notificationCount;

  // Các hàm callback để xử lý sự kiện từ cha truyền vào
  final ValueChanged<int> onTabChanged;
  final VoidCallback onNotificationTap;
  final VoidCallback? onAvatarTap;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    required this.onTabChanged,      // Bắt buộc phải có để chuyển tab
    required this.onNotificationTap, // Bắt buộc phải có để xử lý thông báo
    this.onAvatarTap,
    this.appName = 'An Tâm App',
    this.userName,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Mở rộng body lên tận nóc để CustomTopBar đè lên đẹp hơn (tuỳ chọn)
      // extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Top Bar
          CustomTopBar(
            appName: appName,
            userName: userName,
            notificationCount: notificationCount,
            onAvatarTap: onAvatarTap ?? () {
              // Mặc định nếu không truyền hàm thì chuyển sang trang hồ sơ
              // (Giả định hồ sơ là tab cuối cùng hoặc route riêng)
              Navigator.pushNamed(context, '/profile');
            },
            onNotificationTap: onNotificationTap,
          ),

          // Nội dung chính
          Expanded(
            child: body,
          ),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onItemSelected: onTabChanged, // Truyền hàm thay đổi index xuống
      ),
    );
  }
}