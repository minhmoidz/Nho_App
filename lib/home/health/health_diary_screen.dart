import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm package: intl vào pubspec.yaml để format ngày tháng
import 'health_api_service.dart'; // Import file service của bạn

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // Màu chủ đạo
  final Color _primaryColor = const Color(0xFF1E88E5); // Xanh dương đậm đà
  final Color _accentColor = const Color(0xFFE3F2FD); // Xanh nhạt nền nã

  bool _isLoading = false;
  List<dynamic> _logs = [];
  Map<String, dynamic>? _insights;

  // Controller cho form nhập liệu
  final _typeController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'Huyết áp'; // Mặc định

  // Danh sách loại chỉ số gợi ý
  final List<String> _logTypes = ['Huyết áp', 'Nhịp tim', 'Đường huyết', 'Cân nặng', 'Nhiệt độ'];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Hàm tải lại toàn bộ dữ liệu (Logs + Insights)
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // Gọi song song cả 2 API để tiết kiệm thời gian, nhưng theo logic của bạn
      // thì Insight thường được cập nhật sau khi có log mới.
      final logs = await HealthApiService.getHealthLogs(limit: 20);
      final insights = await HealthApiService.getHealthInsights();

      if (mounted) {
        setState(() {
          _logs = logs;
          _insights = insights;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm xử lý gửi dữ liệu
  Future<void> _submitLog() async {
    if (_valueController.text.isEmpty) return;

    Navigator.pop(context); // Đóng form trước
    setState(() => _isLoading = true); // Hiện loading toàn màn hình hoặc chỉ báo

    try {
      // 1. Gửi Log
      await HealthApiService.createHealthLog(
        logType: _selectedType,
        value: _valueController.text,
        note: _noteController.text,
      );

      // 2. Thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu chỉ số! Đang cập nhật phân tích...'),
            backgroundColor: _primaryColor,
          ),
        );
      }

      // 3. Tự động gọi lại API Logs và API Insights như yêu cầu
      await _refreshData();

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Clear form
      _valueController.clear();
      _noteController.clear();
    }
  }

  // Helper: Format ngày tháng
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper: Icon theo loại log
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'nhịp tim': return Icons.favorite;
      case 'huyết áp': return Icons.water_drop;
      case 'cân nặng': return Icons.monitor_weight;
      case 'nhiệt độ': return Icons.thermostat;
      case 'đường huyết': return Icons.bloodtype;
      default: return Icons.health_and_safety;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền xám xanh rất nhạt
      appBar: AppBar(
        title: const Text('Theo Dõi Sức Khỏe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: _isLoading && _logs.isEmpty
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Phần Insight (Phân tích)
                _buildInsightCard(),
                const SizedBox(height: 24),

                // 2. Tiêu đề danh sách
                Text(
                  'Lịch sử đo gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Danh sách Logs
                _buildLogList(),
              ],
            ),
          ),
        ),
      ),

      // Nút thêm mới (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogModal,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ghi chỉ số", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget hiển thị Insight
  Widget _buildInsightCard() {
    String insightText = _insights?['insights'] ?? 'Chưa có dữ liệu phân tích.';
    String suggestionText = _insights?['suggestion'] ?? '';
    // Giả sử API trả về cấu trúc như trên, nếu khác bạn sửa key map nhé

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Phân tích & Lời khuyên',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insightText,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
          if (suggestionText.isNotEmpty) ...[
            const Divider(color: Colors.white30, height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.yellowAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestionText,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  // Widget danh sách Log
  Widget _buildLogList() {
    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.note_alt_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text('Chưa có bản ghi nào', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final item = _logs[index];
        final type = item['log_type'] ?? 'N/A';
        final value = item['value'] ?? '';
        final note = item['note'] ?? '';
        final date = _formatDate(item['created_at']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconForType(type), color: _primaryColor),
            ),
            title: Text(
              '$type: $value',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(note, style: TextStyle(color: Colors.grey[600])),
                  ),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  // Modal Bottom Sheet để nhập liệu
  void _showAddLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để hiển thị full khi có bàn phím
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ghi chỉ số mới', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor)),
            const SizedBox(height: 24),

            // Chọn loại chỉ số
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration('Loại chỉ số', Icons.category),
              items: _logTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),

            // Nhập giá trị
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.text, // Để text vì value có thể là "120/80"
              decoration: _inputDecoration('Giá trị (VD: 120/80, 65kg...)', Icons.speed),
            ),
            const SizedBox(height: 16),

            // Nhập ghi chú
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: _inputDecoration('Ghi chú (Tùy chọn)', Icons.note),
            ),
            const SizedBox(height: 32),

            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text('LƯU VÀ PHÂN TÍCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}