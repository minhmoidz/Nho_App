import 'package:flutter/material.dart';
import 'dart:convert';
import '../../chatbot/services/gemini_service.dart';
import '../knowledge_data.dart';
class MedicineTab extends StatefulWidget {
  const MedicineTab({super.key});

  @override
  State<MedicineTab> createState() => _MedicineTabState();
}

class _MedicineTabState extends State<MedicineTab> {
  // Sử dụng GeminiService thay vì ApiService
  final GeminiService _geminiService = GeminiService();

  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _displayList = [];
  bool _isLoading = false;
  bool _isAIResult = false;

  @override
  void initState() {
    super.initState();
    _displayList = List.from(sampleMedicines);
  }

  Future<void> _handleSearch() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _displayList = List.from(sampleMedicines);
        _isAIResult = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // 1. Tìm trong dữ liệu local trước
    final localResults = sampleMedicines
        .where((med) => med.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (localResults.isNotEmpty) {
      setState(() {
        _displayList = localResults;
        _isLoading = false;
        _isAIResult = false;
      });
    } else {
      // 2. Nếu không có, hỏi AI qua ChatApiService
      await _askAIForMedicine(query);
    }
  }

  // --- HÀM TRA CỨU QUA API RIÊNG ---
  Future<void> _askAIForMedicine(String drugName) async {
    try {
      // Prompt bắt buộc trả về JSON
      final String prompt =
          "Bạn là dược sĩ AI. Hãy cung cấp thông tin về thuốc: '$drugName'. "
          "Yêu cầu QUAN TRỌNG: Chỉ trả về 1 đoạn JSON duy nhất (không có văn bản dẫn dắt) theo định dạng sau: "
          "{\\\"name\\\": \\\"Tên thuốc\\\", \\\"usage\\\": \\\"Công dụng chính\\\", \\\"dosage\\\": \\\"Liều dùng tham khảo\\\", \\\"warning\\\": \\\"Lưu ý quan trọng\\\"}. "
          "Nếu không tìm thấy thông tin, hãy trả về JSON với name='Không tìm thấy'. Trả lời bằng tiếng Việt.";

      // Gọi Gemini API Service
      final String? aiResponse = await _geminiService.sendMessage(prompt);

      if (aiResponse != null && aiResponse.isNotEmpty) {
        // --- XỬ LÝ CHUỖI JSON ---
        // AI có thể trả về: "Dưới đây là JSON: ```json {...} ```"
        String cleanJson = aiResponse.replaceAll(RegExp(r'```json|```'), '').trim();

        // Tìm vị trí bắt đầu { và kết thúc } để đảm bảo an toàn
        final start = cleanJson.indexOf('{');
        final end = cleanJson.lastIndexOf('}');

        if (start != -1 && end != -1) {
          cleanJson = cleanJson.substring(start, end + 1);

          final Map<String, dynamic> jsonData = jsonDecode(cleanJson);

          setState(() {
            _displayList = [Medicine(
                id: 'ai_generated',
                name: jsonData['name'] ?? drugName,
                usage: jsonData['usage'] ?? 'Chưa rõ công dụng',
                dosage: jsonData['dosage'] ?? 'Tham khảo ý kiến bác sĩ',
                warning: jsonData['warning'] ?? 'Đọc kỹ hướng dẫn sử dụng'
            )];
            _isAIResult = true;
          });
        } else {
          // Trường hợp AI trả về text thường mà không phải JSON
          _handleFallbackText(aiResponse, drugName);
        }
      } else {
        _showErrorSnackBar("Không nhận được phản hồi từ Gemini AI.");
      }
    } catch (e) {
      debugPrint("Lỗi phân tích thuốc: $e");
      setState(() {
        _displayList = [];
      });
      _showErrorSnackBar("Có lỗi khi phân tích dữ liệu thuốc.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm phụ: Xử lý nếu AI "lỡ" trả về text thường thay vì JSON
  void _handleFallbackText(String text, String drugName) {
    setState(() {
      _displayList = [Medicine(
          id: 'ai_fallback',
          name: drugName,
          usage: text, // Hiển thị toàn bộ text vào phần công dụng
          dosage: 'Xem chi tiết ở trên',
          warning: 'Thông tin được tạo tự động'
      )];
      _isAIResult = true;
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- PHẦN UI ---
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên thuốc cần tra cứu...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _handleSearch,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                ),
                child: const Icon(Icons.send),
              )
            ],
          ),
        ),
        if (_isAIResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.teal.withOpacity(0.1),
            width: double.infinity,
            child: const Text(
              "🤖 Kết quả được tạo bởi AI (Cần tham khảo ý kiến bác sĩ)",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayList.isEmpty
              ? const Center(child: Text("Không tìm thấy thuốc nào"))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _displayList.length,
            itemBuilder: (context, index) {
              final med = _displayList[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: _isAIResult ? Colors.blue.shade100 : Colors.teal.shade100,
                    child: Icon(
                        _isAIResult ? Icons.smart_toy : Icons.medication,
                        color: _isAIResult ? Colors.blue : Colors.teal
                    ),
                  ),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(med.usage, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    _showMedicineDetail(med);
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _showMedicineDetail(Medicine med) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                  ),
                ),
                const SizedBox(height: 20),
                Text(med.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(thickness: 1, height: 30),
                _buildDetailItem(Icons.info_outline, "Công dụng", med.usage),
                _buildDetailItem(Icons.access_time, "Liều dùng", med.dosage),
                _buildDetailItem(Icons.warning_amber_rounded, "Lưu ý quan trọng", med.warning, isWarning: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String content, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isWarning ? Colors.red : Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWarning ? Colors.red : Colors.black87)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}