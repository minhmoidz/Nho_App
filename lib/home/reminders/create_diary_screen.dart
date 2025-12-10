import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'diary_api_service.dart';

// IMPORT QUAN TRỌNG: Dịch vụ OCR chúng ta đã viết trước đó
// Hãy sửa đường dẫn này nếu cấu trúc thư mục của bạn khác
import '../ocr_screen/ocr_api_service.dart';

class CreateDiaryScreen extends StatefulWidget {
  const CreateDiaryScreen({super.key});

  @override
  State<CreateDiaryScreen> createState() => _CreateDiaryScreenState();
}

class _CreateDiaryScreenState extends State<CreateDiaryScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();

  XFile? _selectedImage;
  bool _autoAnalyze = true;
  bool _isUploading = false;
  bool _isExtractingText = false; // Trạng thái đang đọc chữ

  static const MaterialColor primaryColor = Colors.deepPurple;
  static const Color lightColor = Color(0xFFF0ECFF);

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh và tự động OCR
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isExtractingText = true; // Bắt đầu loading OCR
          _contentController.text = ''; // Xóa nội dung cũ
        });

        // --- GỌI API OCR ---
        try {
          String extractedText = await OcrApiService.extractTextFromImage(image);
          if (mounted) {
            setState(() {
              // Điền văn bản đọc được vào ô nhập liệu
              _contentController.text = extractedText;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã trích xuất văn bản từ ảnh!'), backgroundColor: Colors.green),
              );
            });
          }
        } catch (e) {
          debugPrint('Lỗi OCR: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không đọc được chữ: ${e.toString()}'), backgroundColor: Colors.orange),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isExtractingText = false; // Tắt loading OCR
            });
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Không thể mở ảnh. Vui lòng kiểm tra quyền truy cập.');
    }
  }

  Future<void> _saveDiaryEntry() async {
    if (_selectedImage == null) {
      _showErrorDialog('Vui lòng chọn một bức ảnh để tạo nhật ký.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Gọi API tạo nhật ký với cả Ảnh và Nội dung text
      await DiaryApiService.createDiaryEntry(
        image: _selectedImage!,
        content: _contentController.text, // Gửi nội dung đã trích xuất/chỉnh sửa
        autoAnalyze: _autoAnalyze,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo nhật ký thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryColor),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo nhật ký ảnh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- KHUNG ẢNH ---
            const Text('Hình ảnh:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showImageSourceOptions(context),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor.shade100, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: lightColor,
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: FileImage(File(_selectedImage!.path)),
                    fit: BoxFit.contain,
                  )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_rounded, size: 60, color: primaryColor.shade300),
                    const SizedBox(height: 12),
                    Text('Chạm để thêm ảnh', style: TextStyle(color: primaryColor.shade400)),
                  ],
                )
                    : null,
              ),
            ),

            if (_selectedImage != null && !_isExtractingText)
              Center(
                child: TextButton.icon(
                  onPressed: () => _showImageSourceOptions(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Chọn ảnh khác'),
                ),
              ),

            const SizedBox(height: 24),

            // --- KHUNG NỘI DUNG (TRÍCH XUẤT TỪ OCR) ---
            const Text('Nội dung nhật ký:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (_isExtractingText)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                    SizedBox(width: 16),
                    Text("Đang đọc chữ từ ảnh..."),
                  ],
                ),
              )
            else
              TextField(
                controller: _contentController,
                maxLines: 5, // Cho phép nhiều dòng
                decoration: InputDecoration(
                  hintText: 'Văn bản trích xuất sẽ hiện ở đây. Bạn có thể sửa lại...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

            const SizedBox(height: 24),

            // --- TÙY CHỌN AI ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text('Phân tích AI nâng cao', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tạo thêm cảm xúc và tóm tắt từ ảnh.'),
                value: _autoAnalyze,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _autoAnalyze = val),
              ),
            ),

            const SizedBox(height: 32),

            // --- NÚT LƯU ---
            ElevatedButton.icon(
              onPressed: _saveDiaryEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Lưu Nhật Ký', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}