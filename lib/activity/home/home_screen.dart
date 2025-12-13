import 'package:flutter/material.dart';
import 'package:gioapp/activity/home/reminder/manual_reminder_screen.dart';
import 'package:gioapp/activity/home/reminders/create_diary_screen.dart';
import 'package:gioapp/activity/home/sos/sos_screen.dart';
import 'package:gioapp/constants/app_colors.dart';
import '../chatbot/chat_page.dart';
import '../chatbot/voice_page.dart';
import '../knowledge/knowledge_screen.dart';
import '../login/auth_service.dart';
import '../notification/notifications_page.dart'; // Đảm bảo đã import file này
import '../profile/profile_screen.dart';
import '../trochoi/brain_training_screen.dart';
import '../wailet/bottom_nav_bar.dart';
import '../wailet/custom_top_bar.dart';
import 'health/health_diary_screen.dart';
import 'memory/memory_page.dart';
import 'ocr_screen/ocr_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  final AuthService _authService = AuthService();

  void _onBottomNavTap(int index) {
    setState(() {
      _tabIndex = index;
    });
  }

  void _goToProfileFromAvatar() {
    setState(() {
      _tabIndex = 3; // Chuyển sang tab Profile trong IndexedStack
    });
  }

  // --- HÀM MỚI: CHUYỂN ĐẾN TRANG THÔNG BÁO ---
  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  Future<void> _logout() async {
    await _authService.deleteToken();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(
              appName: 'Nhớ App',
              userName: 'Minh',
              onAvatarTap: _goToProfileFromAvatar,
              // --- SỬA DÒNG NÀY ---
              // Thay vì gọi NotificationsPage(), ta truyền hàm _goToNotifications
              onNotificationTap: _goToNotifications,
              // --------------------
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildHomeTab(),
                  KnowledgeScreen(),
                  BrainTrainingScreen(), // Giữ lại màn hình Trò chơi
                  UserProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _tabIndex,
        onItemSelected: _onBottomNavTap,
      ),
    );
  }

  // ... (Các phần widget _buildHomeTab, _buildMainActionCard, _buildToolCard giữ nguyên như cũ)
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section với gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hôm nay bạn muốn làm gì?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn một trong các tính năng bên dưới',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Main Actions - Chat & Voice
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trò chuyện với AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Chat Card
                _buildMainActionCard(
                  title: 'Nhắn tin với trợ lý Nhớ',
                  subtitle: 'Trò chuyện văn bản, hỏi đáp thông tin',
                  icon: Icons.chat_bubble_rounded,
                  gradientColors: [
                    AppColors.primary,
                    AppColors.primary,
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceChatPage1(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Voice Card
                _buildMainActionCard(
                  title: 'Gọi điện với trợ lý Nhớ',
                  subtitle: 'Trò chuyện bằng giọng nói tự nhiên',
                  icon: Icons.phone_in_talk_rounded,
                  gradientColors: [
                    AppColors.secondary,
                    AppColors.secondary,
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceOnlyPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Tools Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công cụ hỗ trợ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid Tools
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _buildToolCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Chụp ảnh, đọc chữ',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OcrScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      icon: Icons.book_rounded,
                      label: 'Nhật ký\ntừ ảnh',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateDiaryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      icon: Icons.sos_rounded, // Đổi icon thành SOS
                      label: 'SOS\nKhẩn cấp',  // Đổi tên hiển thị
                      color: AppColors.primary,       // Đổi màu thành màu đỏ (màu cảnh báo)
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>SOSPage(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      icon: Icons.notifications_active_rounded,
                      label: 'Tạo\nnhắc nhở',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReminderScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      icon: Icons.favorite_rounded,
                      label: 'Sức khỏe\nhàng ngày',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToolCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Kỷ niệm\ncủa tôi',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MemoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMainActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}