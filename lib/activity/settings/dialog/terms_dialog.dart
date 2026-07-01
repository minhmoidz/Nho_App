import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nhoapp/constants/app_colors.dart';

class TermsDialogWidget extends StatelessWidget {
  const TermsDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const String data = '''
*Cập nhật lần cuối: 19/12/2025*

**1. Chấp nhận điều khoản**
Bằng việc tải xuống, cài đặt và sử dụng An Tâm App, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu trong tài liệu này. Nếu không đồng ý, vui lòng không sử dụng ứng dụng.

**2. Mục đích sử dụng**
An Tâm App được thiết kế để hỗ trợ người cao tuổi trong việc:
* Quản lý sức khỏe và nhắc nhở uống thuốc
* Ghi nhật ký tâm trạng và hoạt động hàng ngày
* Trò chuyện với trợ lý AI về các vấn đề sức khỏe cơ bản
* Luyện tập trí nhớ và thể chất

*Ứng dụng KHÔNG THAY THẾ tư vấn y tế chuyên nghiệp, chẩn đoán hoặc điều trị bệnh.*

**3. Trách nhiệm người dùng**
* Cung cấp thông tin chính xác khi đăng ký
* Bảo mật tài khoản và không chia sẻ mật khẩu
* Sử dụng ứng dụng đúng mục đích và hợp pháp
* Không lạm dụng các tính năng AI hoặc tải lên nội dung vi phạm pháp luật
* Tham khảo ý kiến bác sĩ trước khi đưa ra quyết định về sức khỏe

**4. Quyền sở hữu trí tuệ**
Tất cả nội dung, mã nguồn, thiết kế giao diện, logo và tài liệu trong An Tâm App thuộc quyền sở hữu của An Tâm App Team. Người dùng không được sao chép, phân phối hoặc sử dụng cho mục đích thương mại mà không có sự cho phép bằng văn bản.

**5. Giới hạn trách nhiệm**
* An Tâm App không chịu trách nhiệm về các quyết định y tế dựa trên thông tin từ ứng dụng
* Không đảm bảo ứng dụng hoạt động không bị gián đoạn hoặc lỗi
* Không chịu trách nhiệm về thiệt hại gián tiếp, ngẫu nhiên hoặc hệ quả phát sinh từ việc sử dụng ứng dụng

**6. Thay đổi điều khoản**
Chúng tôi có quyền cập nhật điều khoản sử dụng bất cứ lúc nào. Người dùng sẽ được thông báo qua ứng dụng về các thay đổi quan trọng. Việc tiếp tục sử dụng sau khi có thay đổi đồng nghĩa với việc chấp nhận điều khoản mới.

**7. Chấm dứt dịch vụ**
Chúng tôi có quyền tạm ngưng hoặc chấm dứt tài khoản của người dùng nếu phát hiện hành vi vi phạm điều khoản sử dụng hoặc pháp luật hiện hành.
''';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Điều khoản sử dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
