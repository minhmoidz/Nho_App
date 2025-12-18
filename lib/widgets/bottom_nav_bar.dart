import 'package:flutter/material.dart';
import 'package:nhoapp/constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Đổ bóng nhẹ phía trên để tách biệt với nội dung
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                isSelected: currentIndex == 0,
                activeColor: AppColors.primary,
                onTap: () => onItemSelected(0),
              ),
              _NavItem(
                icon: Icons.local_library_rounded, // Icon sách vở cho "Kiến thức"
                label: 'Kiến thức',
                isSelected: currentIndex == 1,
                activeColor: AppColors.primary,
                onTap: () => onItemSelected(1),
              ),
              _NavItem(
                icon: Icons.gamepad, // Icon bộ não cho "Trò chơi"
                label: 'Trò chơi',
                isSelected: currentIndex == 2,
                activeColor: AppColors.primary,
                onTap: () => onItemSelected(2),
              ),
              _NavItem(
                icon: Icons.person_rounded, // Icon người cho "Hồ sơ"
                label: 'Hồ sơ',
                isSelected: currentIndex == 3,
                activeColor: AppColors.primary,
                onTap: () => onItemSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng Expanded để chia đều khoảng cách click
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phần Icon có nền màu (Animated)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                // Khi chọn thì hiện màu nền nhạt, không chọn thì trong suốt
                color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20), // Bo tròn dạng viên thuốc
              ),
              child: Icon(
                icon,
                // Khi chọn thì icon to hơn xíu và đổi màu đậm
                size: 26,
                color: isSelected ? activeColor : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),

            // Phần Label (Chữ)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                // Khi chọn thì chữ đậm và có màu, không chọn thì màu xám
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey.shade600,
                fontFamily: 'Montserrat',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}