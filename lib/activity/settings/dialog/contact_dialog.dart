import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nhoapp/constants/app_colors.dart';

class ContactDialogWidget extends StatelessWidget {
  const ContactDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const String data = '''
Chúng tôi luôn sẵn sàng hỗ trợ bạn!

**Hotline (Miễn phí)**
0965816163
*24/7 - Tất cả các ngày*

---
**Email hỗ trợ**
doanngocchungk5@gmail.com
*Phản hồi trong 24h*

---
**Báo lỗi**
doanngocchungk5@gmail.com
*Ưu tiên xử lý nhanh*

---
**Bảo mật & Quyền riêng tư**
doanngocchungk5@gmail.com
*Liên hệ về dữ liệu cá nhân*

---
**Website**
www.nhoapp.com
*Tin tức và tài liệu*

---
**Facebook**
fb.com/NhoApp
*Cộng đồng người dùng*

---
**Văn phòng**
RIPT - PTIT
122 Hoàng Quốc Việt, Hà Nội
Việt Nam

*Giờ làm việc: 8:00 - 17:30 (T2-T6)*
''';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Liên hệ hỗ trợ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: data,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              em: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 12),
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
