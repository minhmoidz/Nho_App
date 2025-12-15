import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart'; // --- MỚI THÊM: Import TTS ---

// --- IMPORTS SERVICES ---
import 'diary_api_service.dart';
import '../ocr_screen/ocr_api_service.dart';

class CreateDiaryScreen extends StatefulWidget {
  const CreateDiaryScreen({super.key});

  @override
  State<CreateDiaryScreen> createState() => _CreateDiaryScreenState();
}

class _CreateDiaryScreenState extends State<CreateDiaryScreen> {
  // --- CONTROLLERS & VARIABLES ---
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts(); // --- MỚI THÊM: Khởi tạo TTS ---

  XFile? _selectedImage;
  bool _autoAnalyze = true;
  bool _isUploading = false;
  bool _isExtractingText = false;
  bool _isSpeaking = false; // --- MỚI THÊM: Trạng thái đang đọc ---

  // --- MODERN COLOR PALETTE ---
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color surfaceColor = Color(0xFFF3F0F7);
  static const Color onSurfaceColor = Color(0xFF1C1B1F);

  @override
  void initState() {
    super.initState();
    _initTts(); // --- MỚI THÊM: Cấu hình giọng đọc ---
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Dừng đọc khi thoát màn hình
    _contentController.dispose();
    super.dispose();
  }

  // --- MỚI THÊM: CẤU HÌNH TTS ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN"); // Thiết lập tiếng Việt
    await _flutterTts.setSpeechRate(0.5);   // Tốc độ đọc (0.0 đến 1.0)
    await _flutterTts.setVolume(1.0);       // Âm lượng
    await _flutterTts.setPitch(1.0);        // Cao độ

    // Lắng nghe trạng thái
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setCancelHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  // --- MỚI THÊM: HÀM ĐỌC/DỪNG ---
  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    if (_isSpeaking) {
      await _flutterTts.stop();
    } else {
      await _flutterTts.speak(text);
    }
  }

  // --- LOGIC 1: CHỌN ẢNH & GỌI OCR ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Dừng đọc nếu đang đọc cái cũ
      if (_isSpeaking) await _flutterTts.stop();

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isExtractingText = true;
          _contentController.text = '';
        });

        try {
          String extractedText = await OcrApiService.extractTextFromImage(image);

          if (mounted) {
            setState(() {
              _contentController.text = extractedText;
              _showSnackBar('Đã trích xuất văn bản thành công!', Colors.green);
            });

            // --- MỚI THÊM: TỰ ĐỘNG ĐỌC NGAY SAU KHI CÓ CHỮ ---
            if (extractedText.isNotEmpty) {
              _speak(extractedText);
            }
          }
        } catch (e) {
          debugPrint('Lỗi OCR: $e');
          if (mounted) {
            _showSnackBar('Không đọc được chữ từ ảnh này (Lỗi OCR).', Colors.orange);
          }
        } finally {
          if (mounted) {
            setState(() => _isExtractingText = false);
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Không thể truy cập ảnh. Vui lòng kiểm tra quyền truy cập.');
    }
  }

  // --- LOGIC 2: LƯU NHẬT KÝ ---
  Future<void> _saveDiaryEntry() async {
    if (_selectedImage == null) {
      _showErrorDialog('Vui lòng chọn một bức ảnh minh họa.');
      return;
    }

    // Dừng đọc khi bấm lưu
    if (_isSpeaking) await _flutterTts.stop();

    setState(() => _isUploading = true);

    try {
      await DiaryApiService.createDiaryEntry(
        image: _selectedImage!,
        content: _contentController.text,
        autoAnalyze: _autoAnalyze,
      );

      if (mounted) {
        _showSnackBar('Tạo Note thành công!', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo Note Mới',
          style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _saveDiaryEntry,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('LƯU'),
              ),
            )
        ],
      ),
      body: _isUploading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text("Đang tải lên...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KHUNG ẢNH
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: FileImage(File(_selectedImage!.path)),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Thêm hình ảnh minh họa', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  ],
                )
                    : Stack(
                  children: [
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. KHUNG NHẬP LIỆU & NÚT LOA
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nội dung",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurfaceColor),
                      ),

                      // --- MỚI THÊM: KHU VỰC TRẠNG THÁI (LOADING / LOA) ---
                      Row(
                        children: [
                          if (_isExtractingText)
                            const SizedBox(
                              height: 16, width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                            )
                          else if (_contentController.text.isNotEmpty)
                          // Nút bấm nghe/dừng
                            InkWell(
                              onTap: () => _speak(_contentController.text),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isSpeaking ? primaryColor.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: _isSpeaking ? Border.all(color: primaryColor) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                                      color: _isSpeaking ? primaryColor : Colors.grey,
                                      size: 22,
                                    ),
                                    if (_isSpeaking) ...[
                                      const SizedBox(width: 4),
                                      const Text("Đang đọc", style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold))
                                    ]
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 4,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: _isExtractingText
                          ? 'Đang đọc chữ từ ảnh...'
                          : 'Viết suy nghĩ của bạn hoặc chờ OCR trích xuất...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. TÙY CHỌN AI
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: SwitchListTile(
                activeColor: primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 10),
                    Text('AI Phân tích', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                subtitle: const Text('Tự động nhận diện cảm xúc và gắn thẻ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                value: _autoAnalyze,
                onChanged: (val) => setState(() => _autoAnalyze = val),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}