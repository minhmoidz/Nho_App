import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nhoapp/constants/app_colors.dart';

class PrivacyDialogWidget extends StatelessWidget {
  const PrivacyDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const String data = '''
*Có hiệu lực từ: 19/12/2025*

Nhớ App cam kết bảo vệ quyền riêng tư và thông tin cá nhân của người dùng. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ dữ liệu của bạn.

**1. Thông tin chúng tôi thu thập**
*Thông tin cá nhân:*
* Họ tên, ngày sinh, giới tính
* Số điện thoại, email, địa chỉ
* Ảnh đại diện (tùy chọn)

*Thông tin sức khỏe:*
* Nhật ký sức khỏe, tâm trạng
* Lịch uống thuốc và khám bệnh
* Lịch sử chat với trợ lý AI

*Thông tin kỹ thuật:*
* Loại thiết bị, phiên bản hệ điều hành
* Địa chỉ IP, nhật ký truy cập
* Thông tin vị trí (khi bật tính năng)

**2. Mục đích sử dụng thông tin**
* Cung cấp và cải thiện các tính năng của ứng dụng
* Cá nhân hóa trải nghiệm người dùng
* Gửi nhắc nhở và thông báo quan trọng
* Phân tích và thống kê sử dụng ứng dụng
* Hỗ trợ khách hàng và xử lý yêu cầu
* Nghiên cứu và phát triển tính năng mới

**3. Bảo vệ thông tin**
Chúng tôi áp dụng các biện pháp bảo mật tiên tiến:

*Mã hóa dữ liệu:*
* Mã hóa end-to-end cho thông tin nhạy cảm
* SSL/TLS cho mọi kết nối mạng

*Kiểm soát truy cập:*
* Xác thực JWT Token
* Phân quyền người dùng chặt chẽ

*Lưu trữ an toàn:*
* Máy chủ được bảo vệ và sao lưu định kỳ
* Tuân thủ các tiêu chuẩn bảo mật quốc tế

**4. Chia sẻ thông tin**
Chúng tôi KHÔNG bán hoặc cho thuê thông tin cá nhân của bạn.

Thông tin có thể được chia sẻ trong các trường hợp:
* Khi có sự đồng ý rõ ràng từ người dùng
* Với các nhà cung cấp dịch vụ (Google AI, server hosting) để vận hành ứng dụng
* Khi pháp luật yêu cầu hoặc để bảo vệ quyền lợi hợp pháp

**5. Quyền của người dùng**
Bạn có quyền:
* Truy cập và xem thông tin cá nhân
* Yêu cầu chỉnh sửa hoặc cập nhật thông tin
* Xóa tài khoản và dữ liệu liên quan
* Rút lại sự đồng ý xử lý dữ liệu
* Khiếu nại về việc xử lý thông tin cá nhân

Để thực hiện các quyền này, vui lòng liên hệ: privacy@nhoapp.com

**6. Cookie và công nghệ theo dõi**
Ứng dụng sử dụng cookie và công nghệ tương tự để:
* Ghi nhớ phiên đăng nhập
* Lưu trữ cài đặt người dùng
* Phân tích hành vi sử dụng

Bạn có thể quản lý cookie trong cài đặt ứng dụng.

**7. Thời gian lưu trữ dữ liệu**
* Dữ liệu tài khoản: Cho đến khi bạn xóa tài khoản
* Nhật ký hoạt động: 12 tháng
* Lịch sử chat: Cho đến khi bạn xóa
* Dữ liệu sao lưu: 30 ngày

**8. Thay đổi chính sách**
Chúng tôi có thể cập nhật chính sách bảo mật để phản ánh thay đổi trong thực tiễn hoặc yêu cầu pháp lý. Bạn sẽ được thông báo về các thay đổi quan trọng qua email hoặc thông báo trong ứng dụng.
''';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Chính sách bảo mật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: data,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              em: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 12),
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
