import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ
import 'health_api_service.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/app_bar.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // --- MÀU SẮC & THEME ---
  final Color _backgroundColor = const Color(0xFFF0F4F8);

  // --- STATE DỮ LIỆU ---
  bool _isLoading = false;
  List<dynamic> _logs = [];
  Map<String, dynamic>? _insights;

  // --- CONTROLLERS ---
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedInputType = 'Huyết áp'; // Loại đang chọn để nhập liệu
  String _selectedChartType = 'Huyết áp'; // Loại đang chọn để xem biểu đồ

  final List<String> _logTypes = ['Huyết áp', 'Nhịp tim', 'Đường huyết', 'Cân nặng', 'Nhiệt độ'];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // --- LOGIC API & DỮ LIỆU ---

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await HealthApiService.getHealthLogs(limit: 30); // Lấy nhiều hơn để vẽ biểu đồ
      final insights = await HealthApiService.getHealthInsights();

      if (mounted) {
        setState(() {
          _logs = logs;
          _insights = insights;
        });
      }
    } catch (e) {
      if (mounted) _showError('Không thể tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLog() async {
    if (_valueController.text.isEmpty) return;
    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      await HealthApiService.createHealthLog(
        logType: _selectedInputType,
        value: _valueController.text,
        note: _noteController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Đã lưu thành công!'), backgroundColor: Colors.green),
        );
      }
      await _refreshData();
    } catch (e) {
      if (mounted) _showError('Lỗi khi lưu: $e');
    } finally {
      _valueController.clear();
      _noteController.clear();
      // Reset loading state handled in refreshData but good to ensure
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // --- XỬ LÝ DỮ LIỆU BIỂU ĐỒ ---

  // Hàm trích xuất số từ chuỗi (VD: "120/80" -> lấy 120, "65kg" -> lấy 65)
  double _parseValue(String rawValue) {
    try {
      // Loại bỏ các ký tự không phải số hoặc dấu chấm, dấu gạch chéo
      String cleaned = rawValue.replaceAll(RegExp(r'[^\d./]'), '');
      if (cleaned.contains('/')) {
        return double.parse(cleaned.split('/')[0]); // Lấy số đầu tiên (tâm thu)
      }
      return double.parse(cleaned);
    } catch (e) {
      return 0;
    }
  }

  List<FlSpot> _getChartData() {
    // Lọc logs theo loại đang chọn
    final filteredLogs = _logs.where((l) => l['log_type'] == _selectedChartType).toList();

    // Đảo ngược để cũ nhất bên trái, mới nhất bên phải
    final sortedLogs = filteredLogs.reversed.toList();

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedLogs.length; i++) {
      double val = _parseValue(sortedLogs[i]['value'].toString());
      if (val > 0) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }
    return spots;
  }

  // --- UI CHÍNH ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: NhoAppBar(
        title: "Sức khỏe của tôi",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, color: Colors.white,
          ),
        ],
      ),
      body: _isLoading && _logs.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),

              // 1. Phần Phân tích & Lời khuyên (Quan trọng nhất để lên đầu)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildInsightCard(),
              ),
              const SizedBox(height: 24),

              // 2. Phần Biểu đồ theo dõi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Biểu đồ theo dõi", style: _headerStyle()),
                    const SizedBox(height: 12),
                    _buildChartTypeSelector(), // Các nút chọn loại biểu đồ
                    const SizedBox(height: 12),
                    _buildChartCard(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Lịch sử đo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Lịch sử gần đây", style: _headerStyle()),
                    const SizedBox(height: 12),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_task, size: 28, color: Colors.white,),
        label: const Text("GHI CHỈ SỐ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
          ),
          const SizedBox(height: 5),
          const Text(
            "Chúc bạn một ngày khỏe mạnh!",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: PHÂN TÍCH & LỜI KHUYÊN ---
  Widget _buildInsightCard() {
    // Mock data để hiển thị nếu API chưa trả về đủ trường
    String analysis = _insights?['insights'] ?? "Đang chờ thêm dữ liệu để phân tích...";
    String suggestion = _insights?['suggestion'] ?? "Hãy duy trì đo đạc thường xuyên.";

    // Giả lập danh sách hành động (Nên trả về từ API dưới dạng List<String>)
    List<String> actions = [
      "Uống 1 cốc nước ấm",
      "Đi bộ nhẹ nhàng 15 phút",
      "Đo lại huyết áp sau 1 giờ"
    ];
    if (_insights != null && _insights!.containsKey('actions')) {
      actions = List<String>.from(_insights!['actions']);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: AppColors.secondary, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Trợ lý sức khỏe AI",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TÌNH TRẠNG HIỆN TẠI:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                Text(analysis, style: const TextStyle(fontSize: 16, height: 1.5)),
                const Divider(height: 30),

                const Text("VIỆC CẦN LÀM (GỢI Ý):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 10),
                // Danh sách việc làm dạng checklist
                ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(action, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: BIỂU ĐỒ ---
  Widget _buildChartTypeSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _logTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final type = _logTypes[index];
          final isSelected = type == _selectedChartType;
          return ChoiceChip(
            label: Text(type),
            selected: isSelected,
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            onSelected: (val) {
              if (val) setState(() => _selectedChartType = type);
            },
          );
        },
      ),
    );
  }

  Widget _buildChartCard() {
    final spots = _getChartData();

    if (spots.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 50, color: Colors.grey[300]),
            Text("Chưa có đủ dữ liệu $_selectedChartType", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Ẩn ngày dưới đáy cho đỡ rối
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.secondary.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: LỊCH SỬ ---
  Widget _buildHistoryList() {
    if (_logs.isEmpty) return const SizedBox();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final item = _logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              child: Icon(_getIconForType(item['log_type']), color: AppColors.primary),
            ),
            title: Text(
              '${item['log_type']}: ${item['value']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              _formatDate(item['created_at']),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            trailing: item['note'] != null && item['note'].isNotEmpty
                ? const Icon(Icons.note, color: Colors.amber)
                : null,
          ),
        );
      },
    );
  }

  // --- MODAL NHẬP LIỆU ---
  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text('Ghi Nhận Chỉ Số', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 30),

            // Chọn loại (Dạng Grid nút bấm to dễ chọn)
            SizedBox(
              height: 100, // Chiều cao cố định cho vùng chọn
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _logTypes.length,
                itemBuilder: (ctx, i) {
                  final type = _logTypes[i];
                  final isSelected = _selectedInputType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedInputType = type), // Cập nhật state modal (cần StatefulBuilder nếu tách ra)
                    child: Container( // Thay đổi UI ngay lập tức
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getIconForType(type), color: isSelected ? Colors.white : Colors.grey),
                          const SizedBox(height: 5),
                          Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Input to rõ
            TextField(
              controller: _valueController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'VD: 120/80',
                labelText: 'Kết quả đo ($_selectedInputType)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Ghi chú (đau đầu, vừa ăn xong...)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('LƯU LẠI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    ).then((_) {
      // Reset state modal if needed when closed
    });
  }

  // --- HELPERS ---
  TextStyle _headerStyle() => TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]);

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('HH:mm dd/MM/yyyy').format(DateTime.parse(dateStr).toLocal());
    } catch (e) { return dateStr; }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'nhịp tim': return Icons.favorite;
      case 'huyết áp': return Icons.water_drop;
      case 'cân nặng': return Icons.monitor_weight;
      case 'nhiệt độ': return Icons.thermostat;
      case 'đường huyết': return Icons.bloodtype;
      default: return Icons.healing;
    }
  }
}