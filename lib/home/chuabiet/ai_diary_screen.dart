import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AiDiaryScreen extends StatefulWidget {
  const AiDiaryScreen({super.key});

  @override
  State<AiDiaryScreen> createState() => _AiDiaryScreenState();
}

class _AiDiaryScreenState extends State<AiDiaryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _aiAnalysis = '';
  bool _isAnalyzing = false;
  final TextEditingController _titleController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _aiAnalysis = '';
        });
      }
    } catch (e) {
      _showErrorDialog('Không thể chọn ảnh');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _aiAnalysis = '';
        });
      }
    } catch (e) {
      _showErrorDialog('Không thể chụp ảnh');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    // TODO: Gọi API AI để phân tích ảnh (OpenAI Vision, Google Cloud Vision, etc.)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _aiAnalysis = 'Hôm nay là một ngày đẹp trời! '
          'Trong ảnh có vẻ như bạn đang ở một nơi thoáng đãng, '
          'có cây xanh và ánh nắng dịu. '
          'Đây có thể là một khoảnh khắc thư giãn, tận hưởng thiên nhiên.\n\n'
          'Gợi ý: Hãy viết thêm cảm xúc của bạn lúc này, '
          'bạn đang cùng ai và đang làm gì nhé!';
      _isAnalyzing = false;
    });
  }

  Future<void> _saveDiary() async {
    if (_titleController.text.isEmpty) {
      _showErrorDialog('Vui lòng đặt tiêu đề cho nhật ký');
      return;
    }

    // TODO: Lưu nhật ký vào database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Đã lưu nhật ký!',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nhật ký từ ảnh',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Tiêu đề nhật ký',
                labelStyle: TextStyle(fontSize: 18, color: Colors.grey[600]),
                hintText: 'VD: Chuyến đi cuối tuần',
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Ảnh preview
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange[200]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_rounded,
                        size: 80, color: Colors.orange[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có ảnh',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Nút chọn/chụp ảnh
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.photo_library_rounded,
                        size: 28, color: Colors.orange),
                    label: Text(
                      'Chọn ảnh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 28),
                    label: const Text(
                      'Chụp ảnh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nút phân tích
            if (_selectedImage != null && _aiAnalysis.isEmpty)
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Icon(Icons.psychology_rounded, size: 28),
                label: Text(
                  _isAnalyzing ? 'Đang phân tích...' : 'AI phân tích ảnh',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Kết quả phân tích
            if (_aiAnalysis.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'AI gợi ý:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange[200]!, width: 2),
                ),
                child: Text(
                  _aiAnalysis,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveDiary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 28),
                label: const Text(
                  'Lưu nhật ký',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}