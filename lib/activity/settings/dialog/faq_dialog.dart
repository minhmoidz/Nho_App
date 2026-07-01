import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nhoapp/constants/app_colors.dart';

class FAQDialogWidget extends StatelessWidget {
  const FAQDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const String data = '''
**Bắt đầu sử dụng**

**Q: Làm thế nào để tạo tài khoản?**
A: Mở ứng dụng → Chọn "Đăng ký" → Điền thông tin (họ tên, số điện thoại, mật khẩu) → Xác nhận OTP → Hoàn tất!

**Q: Tôi quên mật khẩu thì làm sao?**
A: Tại màn hình đăng nhập → Chọn "Quên mật khẩu" → Nhập số điện thoại đã đăng ký → Nhận mã OTP → Tạo mật khẩu mới.

---
**Trợ lý AI**

**Q: Làm thế nào để chat với trợ lý AI?**
A: Ở trang chủ → Nhấn vào biểu tượng "Trợ lý chat" → Bắt đầu trò chuyện bằng giọng nói hoặc gõ văn bản. Trợ lý sẽ trả lời các câu hỏi về sức khỏe, thuốc men và đời sống.

**Q: AI có thể làm gì?**
A:
* Tư vấn sức khỏe cơ bản
* Giải đáp thắc mắc về thuốc
* Hỗ trợ tâm lý, trò chuyện
* Gợi ý bài tập thể dục phù hợp
* Nhắc nhở chăm sóc sức khỏe

*Lưu ý: AI không thay thế bác sĩ!*

---
**Nhắc nhở uống thuốc**

**Q: Cách đặt nhắc nhở uống thuốc?**
A: Trang chủ → "Nhắc nhở" → Nút "+" → Nhập thông tin thuốc (tên, liều lượng, giờ uống) → Chọn lịch lặp lại → Lưu. Ứng dụng sẽ thông báo đúng giờ!

**Q: Tôi không nghe thấy thông báo?**
A: Kiểm tra: Cài đặt → Thông báo (bật) → Âm thanh (bật) → Cài đặt điện thoại → Cho phép thông báo từ An Tâm App.

---
**Nhật ký sức khỏe**

**Q: Nhật ký để làm gì?**
A: Ghi lại tâm trạng, triệu chứng, hoạt động hàng ngày để:
* Theo dõi sức khỏe qua thời gian
* Chia sẻ với bác sĩ khi khám
* AI phân tích và đưa ra lời khuyên

**Q: Cách ghi nhật ký?**
A: Trang chủ → "Nhật ký" → Nút "+" → Chọn loại (sức khỏe/tâm trạng/ăn uống) → Viết nội dung → Thêm ảnh (tùy chọn) → Lưu.

---
**Trò chơi trí nhớ**

**Q: Trò chơi có tác dụng gì?**
A: Giúp rèn luyện:
* Trí nhớ ngắn hạn và dài hạn
* Khả năng tập trung
* Tư duy logic
* Phản xạ

Chơi 15-20 phút mỗi ngày để não bộ luôn khỏe mạnh!

---
**Luyện tập thể dục**

**Q: AI nhận diện tư thế hoạt động thế nào?**
A: Bật camera → Chọn bài tập → AI sẽ theo dõi chuyển động qua camera và cho điểm tư thế. Đảm bảo đủ ánh sáng và đứng cách camera 1.5-2m.

---
**Bảo mật & Quyền riêng tư**

**Q: Dữ liệu của tôi có an toàn không?**
A: Có! Chúng tôi:
* Mã hóa tất cả dữ liệu nhạy cảm
* Không chia sẻ thông tin với bên thứ ba
* Lưu trữ trên máy chủ bảo mật
* Tuân thủ luật bảo vệ dữ liệu cá nhân

**Q: Cách xóa tài khoản?**
A: Cài đặt → Tài khoản → Xóa tài khoản → Xác nhận. Tất cả dữ liệu sẽ bị xóa vĩnh viễn và không thể khôi phục.

---
**Chi phí**

**Q: Ứng dụng có miễn phí không?**
A: Có! An Tâm App hoàn toàn MIỄN PHÍ, không có phí ẩn. Tất cả tính năng đều sẵn sàng cho người dùng.

---
**Hỗ trợ kỹ thuật**

**Q: Ứng dụng bị lỗi, tôi phải làm gì?**
A:
1. Tắt và mở lại ứng dụng
2. Kiểm tra kết nối Internet
3. Cập nhật phiên bản mới nhất
4. Xóa bộ nhớ cache: Cài đặt điện thoại → Ứng dụng → An Tâm App → Xóa cache
5. Nếu vẫn lỗi: Liên hệ support@nhoapp.com

---
**Không tìm thấy câu trả lời?**
Liên hệ: support@nhoapp.com
Hotline: 1900-1234
''';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: data,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
              strong: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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
