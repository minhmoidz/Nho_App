import 'dart:io'; // Cần để hiển thị ảnh từ File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Thư viện TTS
import 'ocr_api_service.dart'; // Import file API cùng thư mục
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/app_bar.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();

  // Biến lưu ảnh đã chọn để hiển thị lên UI
  File? _selectedImage;

  String _extractedText = '';
  bool _isProcessing = false;

  // --- CẤU HÌNH TEXT-TO-SPEECH (ĐỌC VĂN BẢN) ---
  late FlutterTts flutterTts;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    flutterTts = FlutterTts();

    // Cố gắng set ngôn ngữ tiếng Việt
    // Lưu ý: Thiết bị cần cài đặt engine TTS hỗ trợ tiếng Việt (như Google TTS)
    flutterTts.setLanguage("vi-VN");
    flutterTts.setSpeechRate(0.5); // Tốc độ đọc: 0.5 là vừa phải, 1.0 là nhanh

    // Khi đọc xong thì tắt trạng thái icon
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    // Xử lý lỗi TTS
    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        debugPrint("TTS Error: $msg");
      }
    });
  }

  @override
  void dispose() {
    flutterTts.stop(); // Dừng đọc khi thoát màn hình
    super.dispose();
  }

  // --- HÀM ĐIỀU KHIỂN ĐỌC ---
  Future<void> _speak() async {
    if (_extractedText.isNotEmpty && !_isSpeaking) {
      setState(() => _isSpeaking = true);
      await flutterTts.speak(_extractedText);
    }
  }

  Future<void> _stop() async {
    if (_isSpeaking) {
      await flutterTts.stop();
      setState(() => _isSpeaking = false);
    }
  }

  // --- CHỌN ẢNH ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Giảm nhẹ chất lượng để upload nhanh hơn
      );

      if (image != null) {
        // 1. Cập nhật UI: Hiển thị ảnh và reset kết quả cũ
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
          _isProcessing = true;
          _stop(); // Dừng đọc nếu đang đọc
        });

        // 2. Gọi API xử lý ảnh
        _processImage(image);
      }
    } catch (e) {
      _showErrorDialog('Không thể chọn ảnh. Vui lòng kiểm tra quyền truy cập Camera/Thư viện.');
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      // Gọi hàm static từ file ocr_api_service.dart
      final text = await OcrApiService.extractTextFromImage(image);

      if (mounted) {
        setState(() {
          _extractedText = text;
        });
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
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

  void _copyToClipboard() {
    if (_extractedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép văn bản!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NhoAppBar(title: "Chụp ảnh đọc chữ"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- KHUNG HIỂN THỊ ẢNH ĐÃ CHỌN (Ô NHỎ) ---
            if (_selectedImage != null)
              Container(
                height: 200, // Chiều cao cố định cho ô ảnh
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.contain, // Hiển thị toàn bộ ảnh, không bị cắt
                  ),
                ),
              )
            else
            // Nếu chưa chọn ảnh thì hiện hướng dẫn
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image_search, size: 48, color: AppColors.primary),
                    const SizedBox(height: 10),
                    const Text(
                      'Chụp hoặc chọn ảnh để bắt đầu đọc',
                      style: TextStyle(fontSize: 16, color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // --- HÀNG NÚT CHỨC NĂNG (CAMERA / THƯ VIỆN) ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Chụp ảnh', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.photo_library, color: AppColors.primary),
                    label: const Text('Thư viện', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- TRẠNG THÁI XỬ LÝ ---
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 10),
                      Text('Đang đọc ảnh...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            // --- KẾT QUẢ VĂN BẢN ---
            if (!_isProcessing && _extractedText.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kết quả:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                  ),
                  // Nút Đọc/Dừng (TTS)
                  IconButton(
                    onPressed: _isSpeaking ? _stop : _speak,
                    icon: Icon(
                      _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                      color: _isSpeaking ? Colors.red : Colors.teal,
                      size: 32,
                    ),
                    tooltip: 'Đọc văn bản',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Khung hiển thị văn bản
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText( // Cho phép người dùng bôi đen copy thủ công
                  _extractedText,
                  style: TextStyle(fontSize: 17, color: Colors.grey[900], height: 1.5),
                ),
              ),

              const SizedBox(height: 16),

              // Nút Sao chép nhanh
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Sao chép văn bản', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}