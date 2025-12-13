import 'package:flutter/material.dart';
import 'memory_api_service.dart'; // Import service

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  // Trạng thái cho việc load danh sách
  late Future<List<dynamic>> _memoriesFuture;
  List<dynamic> _memories = [];

  // Controller cho ô nhập liệu
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load danh sách ký ức ngay khi mở màn hình
    _loadMemories();
  }

  /// Gọi API GET để tải danh sách ký ức
  void _loadMemories() {
    setState(() {
      _memoriesFuture = MemoryApiService.getMemories(limit: 20);
    });
  }

  /// Gọi API POST để lưu ký ức mới
  Future<void> _saveMemory() async {
    if (_contentController.text.isEmpty) {
      _showMessage('Vui lòng nhập nội dung ký ức', false);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Chuyển đổi chuỗi tags (cách nhau bằng dấu phẩy) thành List
      List<String> tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim()) // Xóa khoảng trắng
          .where((tag) => tag.isNotEmpty) // Bỏ tag rỗng
          .toList();

      await MemoryApiService.createMemory(
        content: _contentController.text,
        tags: tags,
      );

      // Nếu thành công:
      _showMessage('Đã lưu ký ức!', true);
      _contentController.clear();
      _tagsController.clear();
      _loadMemories(); // Tải lại danh sách
    } catch (e) {
      _showMessage(e.toString(), false);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showMessage(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giả sử màu chủ đạo là Xanh dương
    const Color primaryColor = Colors.blue;
    const Color lightColor = Color.fromARGB(255, 232, 241, 255);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ký ức của bạn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 30, color: Colors.white),
            onPressed: _loadMemories, // Nút tải lại
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Danh sách Ký ức
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _memoriesFuture,
              builder: (context, snapshot) {
                // Đang tải...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Bị lỗi
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  );
                }

                // Thành công
                _memories = snapshot.data ?? [];

                if (_memories.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có ký ức nào.\nHãy thêm ký ức mới ở bên dưới!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  );
                }

                // Hiển thị danh sách
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memories.length,
                  itemBuilder: (context, index) {
                    final memory = _memories[index];
                    final List<dynamic> tags = memory['tags'] ?? [];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nội dung Ký ức
                            Text(
                              memory['content'] ?? 'Không có nội dung',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Hiển thị Tags
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: tags
                                    .map((tag) => Chip(
                                  label: Text(
                                    tag.toString(),
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ))
                                    .toList(),
                              ),
                            const SizedBox(height: 8),
                            // Thời gian (định dạng đơn giản)
                            Text(
                              memory['created_at']?.substring(0, 10) ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Khung nhập liệu (ở dưới cùng)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ô nhập nội dung
                TextField(
                  controller: _contentController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Bạn đang nghĩ gì...',
                    hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: lightColor,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Ô nhập tags
                    Expanded(
                      child: TextField(
                        controller: _tagsController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Tags (cách nhau bằng dấu phẩy)',
                          hintStyle:
                          TextStyle(fontSize: 16, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút Gửi
                    IconButton(
                      icon: _isSaving
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send_rounded, size: 32),
                      color: primaryColor,
                      onPressed: _isSaving ? null : _saveMemory,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}