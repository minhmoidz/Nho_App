import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/auth_check.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Hàm xử lý khi người dùng bấm "Bắt đầu" hoặc "Bỏ qua"
  void _onIntroEnd(context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (context.mounted) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthCheck()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper để build ảnh minh họa
    Widget _buildImage(String assetName, [double width = 250]) {
      return Image.asset('images/$assetName', width: width);
    }

    // Style chung cho phần nội dung chữ
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.black54, height: 1.5);

    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold,
          color: AppColors.primary // Màu xanh chủ đạo
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
      pageColor: Colors.white,
      imagePadding: const EdgeInsets.only(top: 40, bottom: 20),
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,

      // --- DANH SÁCH CÁC TRANG ---
      pages: [
        PageViewModel(
          title: "Chào mừng đến với\nNhớ App",
          body: "Ứng dụng thông minh hỗ trợ sức khỏe và cuộc sống dành riêng cho bạn.",
          image: _buildImage('logo-remove-bg.png', 280),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Nhắc nhở uống thuốc",
          body: "Không còn nỗi lo quên giờ uống thuốc. Chúng tôi sẽ nhắc bạn đúng giờ mỗi ngày.",
          image: Icon(Icons.access_alarm, size: 150, color: AppColors.primary.withOpacity(0.8)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Kết nối & Giải trí",
          body: "Đọc báo, nghe nhạc và trò chuyện cùng trợ lý ảo AI mọi lúc mọi nơi.",
          image: Icon(Icons.people_outline, size: 150, color: AppColors.primary.withOpacity(0.8)),
          decoration: pageDecoration,
        ),
      ],


      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),

      showSkipButton: true,
      showNextButton: true,
      showBackButton: false,

      skip: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Bỏ qua',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
      ),

      next: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1), // Nền nhạt
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 28),
      ),

      done: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Center(
            child: Text(
              'Bắt đầu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),


      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),

      dotsDecorator: DotsDecorator(
        size: const Size(8.0, 8.0),
        color: Colors.grey.shade300, // Màu chấm chưa chọn
        activeSize: const Size(24.0, 10.0), // Chấm đang chọn dài ra
        activeColor: AppColors.primary,
        spacing: const EdgeInsets.symmetric(horizontal: 4),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}