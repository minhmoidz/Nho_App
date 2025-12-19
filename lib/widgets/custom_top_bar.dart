import 'package:flutter/material.dart';
import 'package:nhoapp/constants/app_colors.dart';

class CustomTopBar extends StatelessWidget {
  final String appName;
  final String? userName;
  final String? avatarUrl;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback onNotificationTap;

  const CustomTopBar({
    super.key,
    this.appName = 'Nhớ App',
    this.userName,
    this.avatarUrl,
    this.notificationCount = 0,
    this.onAvatarTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    // Xác định tên hiển thị: Nếu có tên user thì dùng, không thì dùng tên App
    final String displayName = (userName != null && userName!.isNotEmpty)
        ? userName!
        : appName;

    final String subTitle = (userName != null && userName!.isNotEmpty)
        ? 'Xin chào,'
        : 'Chào mừng đến với';

    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.surface, // Hoặc Colors.transparent nếu muốn nền ảnh
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // --- LEFT SECTION: AVATAR & GREETING ---
            GestureDetector(
              onTap: onAvatarTap,
              child: Row(
                children: [
                  // 1. Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade100, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.teal)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 2. Text Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(), // Đẩy phần thông báo sang phải

            // --- RIGHT SECTION: NOTIFICATION BUTTON ---
            _buildNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNotificationTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.teal.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  notificationCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  size: 26,
                  color: notificationCount > 0
                      ? const Color(0xFFFF6B6B) // Icon màu đỏ nhạt nếu có thông báo
                      : const Color(0xFF64748B), // Màu xám xanh nếu không có
                ),

                // Badge số lượng
                if (notificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}