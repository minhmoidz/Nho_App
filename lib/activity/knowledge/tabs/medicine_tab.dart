import 'package:flutter/material.dart';
import 'dart:convert';
import '../../chatbot/services/gemini_service.dart';
import '../knowledge_data.dart'; // Đảm bảo file này có class Medicine và list sampleMedicines

class MedicineTab extends StatefulWidget {
  const MedicineTab({super.key});

  @override
  State<MedicineTab> createState() => _MedicineTabState();
}

class _MedicineTabState extends State<MedicineTab> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _searchController = TextEditingController();

  List<Medicine> _displayList = [];
  bool _isLoading = false;
  bool _isAIResult = false; // Cờ đánh dấu để hiện thông báo warning

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách mặc định từ dữ liệu mẫu local
    _displayList = List.from(sampleMedicines);
  }

  // --- LOGIC TÌM KIẾM ---
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
    FocusScope.of(context).unfocus(); // Ẩn bàn phím

    // 1. Ưu tiên tìm chính xác trong dữ liệu Local (Offline)
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
      // 2. Nếu không thấy trong local, hỏi AI (Online)
      // (Dùng cho trường hợp tên thuốc lạ hoặc mô tả triệu chứng)
      await _askAIForMedicine(query);
    }
  }

  // --- LOGIC GỌI AI & XỬ LÝ JSON ---
  Future<void> _askAIForMedicine(String userInput) async {
    try {
      // PROMPT ĐÃ ĐƯỢC TỐI ƯU & THÊM LƯU Ý AN TOÀN
      final String prompt =
          "Bạn là dược sĩ AI chuyên nghiệp. Người dùng nhập: '$userInput'.\n"
          "Nhiệm vụ của bạn:\n"
          "1. Nếu là tên thuốc: Cung cấp thông tin chi tiết.\n"
          "2. Nếu là triệu chứng bệnh: Gợi ý 2-3 loại thuốc KHÔNG KÊ ĐƠN (OTC) phổ biến nhất.\n"
          "3. LƯU Ý QUAN TRỌNG (SAFETY): Tuyệt đối không gợi ý thuốc kê đơn (kháng sinh nặng, thuốc đặc trị). Nếu triệu chứng có vẻ nguy hiểm, phần 'warning' PHẢI khuyên người dùng đi gặp bác sĩ ngay.\n"
          "4. Nếu input vô nghĩa: Trả về mảng rỗng [].\n\n"
          "ĐỊNH DẠNG TRẢ VỀ: Chỉ trả về một JSON ARRAY (không thêm văn bản thừa) theo mẫu:\n"
          "[\n"
          "  {\n"
          "    \"name\": \"Tên thuốc\",\n"
          "    \"usage\": \"Công dụng chính/Lý do gợi ý\",\n"
          "    \"dosage\": \"Liều dùng tham khảo (Người lớn)\",\n"
          "    \"warning\": \"Chống chỉ định/Cảnh báo an toàn\"\n"
          "  }\n"
          "]";

      final String? aiResponse = await _geminiService.sendMessage(prompt);

      if (aiResponse != null && aiResponse.isNotEmpty) {
        // Làm sạch chuỗi JSON (xóa ```json và ``` nếu có)
        String cleanJson = aiResponse.replaceAll(RegExp(r'```json|```'), '').trim();

        // Tìm điểm bắt đầu [ và kết thúc ] của mảng JSON
        final start = cleanJson.indexOf('[');
        final end = cleanJson.lastIndexOf(']');

        if (start != -1 && end != -1) {
          cleanJson = cleanJson.substring(start, end + 1);

          // Parse JSON Array thành List
          final List<dynamic> jsonList = jsonDecode(cleanJson);

          setState(() {
            _displayList = jsonList.map((item) => Medicine(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${item['name']}',
              name: item['name'] ?? 'Thuốc gợi ý',
              usage: item['usage'] ?? 'Chưa rõ công dụng',
              dosage: item['dosage'] ?? 'Tham khảo ý kiến bác sĩ',
              warning: item['warning'] ?? 'Đọc kỹ hướng dẫn sử dụng',
            )).toList();

            _isAIResult = true; // Bật cờ để hiện banner cảnh báo
          });
        } else {
          // Trường hợp AI trả về text thường (ít xảy ra với prompt này)
          _handleFallbackText(aiResponse, userInput);
        }
      } else {
        _showErrorSnackBar("Không nhận được phản hồi từ AI.");
      }
    } catch (e) {
      debugPrint("Lỗi parse AI: $e");
      _showErrorSnackBar("Lỗi xử lý dữ liệu từ AI. Vui lòng thử lại.");
      setState(() => _displayList = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFallbackText(String text, String userInput) {
    setState(() {
      _displayList = [Medicine(
          id: 'ai_fallback',
          name: userInput,
          usage: text,
          dosage: 'Xem chi tiết trong mô tả',
          warning: 'Dữ liệu thô từ AI'
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

  // --- GIAO DIỆN UI ---
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên thuốc hoặc triệu chứng (vd: đau đầu)...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
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

        // 2. Banner cảnh báo khi dùng AI (QUAN TRỌNG)
        if (_isAIResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue.withOpacity(0.1),
            width: double.infinity,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Gợi ý từ AI chỉ mang tính tham khảo. Vui lòng hỏi ý kiến bác sĩ trước khi sử dụng.",
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[900],
                        fontSize: 13
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 3. Danh sách kết quả
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _displayList.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("Không tìm thấy thuốc phù hợp", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
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
                    backgroundColor: _isAIResult ? Colors.blue.shade50 : Colors.teal.shade50,
                    radius: 25,
                    child: Icon(
                        _isAIResult ? Icons.smart_toy_outlined : Icons.local_pharmacy,
                        color: _isAIResult ? Colors.blue : Colors.teal
                    ),
                  ),
                  title: Text(
                      med.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        med.usage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700])
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _showMedicineDetail(med),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // --- MODAL CHI TIẾT ---
  void _showMedicineDetail(Medicine med) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                  ),
                ),
                const SizedBox(height: 20),
                Text(med.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(thickness: 1, height: 30),
                _buildDetailItem(Icons.healing, "Công dụng", med.usage),
                _buildDetailItem(Icons.access_time_filled, "Liều dùng tham khảo", med.dosage),
                _buildDetailItem(Icons.warning_rounded, "Lưu ý quan trọng", med.warning, isWarning: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String content, {bool isWarning = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isWarning ? Colors.red.shade50 : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isWarning ? Colors.red : Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isWarning ? Colors.red[800] : Colors.teal[800])),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}