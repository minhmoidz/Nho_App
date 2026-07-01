import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutDialogWidget extends StatefulWidget {
  const AboutDialogWidget({super.key});

  @override
  State<AboutDialogWidget> createState() => _AboutDialogWidgetState();
}

class _AboutDialogWidgetState extends State<AboutDialogWidget> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String data = '''
**🌿 An Tâm App - Người Bạn Đồng Hành Sức Khỏe**

An Tâm App là ứng dụng chăm sóc sức khỏe toàn diện dành riêng cho người cao tuổi, được phát triển với sứ mệnh mang đến cuộc sống khỏe mạnh, hạnh phúc và an tâm cho thế hệ bạc đầu.

**Tính năng nổi bật:**
* Trợ lý AI thông minh hỗ trợ 24/7
* Nhắc nhở uống thuốc và khám bệnh định kỳ
* Nhật ký sức khỏe và tâm trạng hàng ngày
* Trò chơi rèn luyện trí nhớ và tư duy
* Kho kiến thức sức khỏe đa dạng
* Luyện tập thể dục với AI nhận diện tư thế

Phiên bản: $_appVersion
© 2024-2025 An Tâm App Team
''';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Về An Tâm App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: data,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              listBullet: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
