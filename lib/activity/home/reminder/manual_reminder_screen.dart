import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Import 2 file helper
import 'reminder_api_service.dart';
import 'notification_helper.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // --- CẤU HÌNH GIAO DIỆN (Màu sắc tương phản cao cho người già) ---
  final Color _primaryColor = const Color(0xFF0D47A1); // Xanh dương đậm
  final Color _accentColor = const Color(0xFFE3F2FD);  // Xanh nhạt nền
  final Color _deleteColor = const Color(0xFFD32F2F);  // Đỏ đậm
  final Color _textColor = const Color(0xFF212121);    // Đen đậm

  bool _isLoading = false;
  List<dynamic> _reminders = [];

  // Cấu hình Giọng nói (TTS)
  final FlutterTts _flutterTts = FlutterTts();

  // Controllers nhập liệu
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDateTime;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchReminders(); // Tải dữ liệu và đồng bộ báo thức ngay khi mở màn hình
  }

  // --- CẤU HÌNH GIỌNG ĐỌC ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.45); // Đọc chậm rãi
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // --- 1. TẢI DỮ LIỆU & ĐỒNG BỘ BÁO THỨC ---
  Future<void> _fetchReminders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await ReminderApiService.getReminders();

      // Sắp xếp: Việc chưa làm lên đầu -> Sắp theo thời gian
      data.sort((a, b) {
        bool aDone = a['is_completed'] ?? false;
        bool bDone = b['is_completed'] ?? false;
        if (aDone != bDone) return aDone ? 1 : -1;

        DateTime aTime = DateTime.tryParse(a['remind_at']) ?? DateTime.now();
        DateTime bTime = DateTime.tryParse(b['remind_at']) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      setState(() => _reminders = data);

      // [QUAN TRỌNG] Tự động cài lại báo thức cho các việc chưa làm
      // Để đảm bảo nếu tắt máy khởi động lại thì vẫn báo thức
      _rescheduleAllAlarms(data);

    } catch (e) {
      _showMsg('Lỗi tải dữ liệu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM ĐỒNG BỘ BÁO THỨC ---
  void _rescheduleAllAlarms(List<dynamic> reminders) {
    final now = DateTime.now();
    for (var item in reminders) {
      bool isCompleted = item['is_completed'] ?? false;
      DateTime? remindAt = DateTime.tryParse(item['remind_at'] ?? '');
      int id = item['id'];
      String title = item['title'] ?? 'Nhắc nhở';
      String desc = item['description'] ?? '';

      // Chỉ hẹn giờ nếu: Chưa xong VÀ Thời gian ở tương lai
      if (!isCompleted && remindAt != null && remindAt.isAfter(now)) {
        NotificationHelper.scheduleNotification(
          id: id,
          title: "Bác ơi! Đến giờ $title",
          body: desc.isNotEmpty ? desc : "Chạm vào để nghe nội dung.",
          scheduledTime: remindAt,
        );
        // print("Đã đồng bộ lại báo thức ID $id lúc $remindAt");
      }
    }
  }

  // --- 2. LƯU (TẠO/SỬA) ---
  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      _showMsg('Bác chưa nhập tên công việc!', isError: true);
      _speak("Bác chưa nhập tên công việc");
      return;
    }
    if (_selectedDateTime == null) {
      _showMsg('Bác chưa chọn giờ nhắc!', isError: true);
      _speak("Bác chưa chọn giờ nhắc");
      return;
    }

    Navigator.pop(context); // Đóng form
    setState(() => _isLoading = true);

    try {
      String speakText = "";
      int targetId = 0;

      if (_editingId == null) {
        // TẠO MỚI
        final newReminder = await ReminderApiService.createReminder(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
        );
        targetId = newReminder['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000;
        speakText = "Đã thêm việc: ${_titleController.text}";
        _showMsg('Đã thêm việc mới thành công');
      } else {
        // CẬP NHẬT
        targetId = _editingId!;
        await ReminderApiService.updateReminder(
          id: targetId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
          isCompleted: false, // Sửa lại nội dung thì coi như chưa xong
        );
        speakText = "Đã sửa xong: ${_titleController.text}";
        _showMsg('Đã cập nhật xong');
      }

      // Cài đặt báo thức riêng cho việc vừa lưu
      if (_selectedDateTime!.isAfter(DateTime.now())) {
        await NotificationHelper.cancel(targetId); // Hủy cũ cho chắc
        await NotificationHelper.scheduleNotification(
          id: targetId,
          title: "Bác ơi! Đến giờ ${_titleController.text}",
          body: _descController.text.isNotEmpty ? _descController.text : "Chạm vào đây để nghe chi tiết.",
          scheduledTime: _selectedDateTime!,
        );
      }

      _speak(speakText);
      _cleanForm();
      _fetchReminders(); // Tải lại danh sách
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg("Lỗi khi lưu: $e", isError: true);
    }
  }

  // --- 3. XÓA ---
  Future<void> _deleteReminder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('XÓA VIỆC NÀY?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Bác có chắc chắn muốn xóa không?', style: TextStyle(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KHÔNG XÓA', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(12)),
            child: const Text('XÓA NGAY', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_editingId != null && mounted) Navigator.pop(context); // Đóng modal
      setState(() => _isLoading = true);
      try {
        await ReminderApiService.deleteReminder(id);
        await NotificationHelper.cancel(id); // Hủy báo thức
        _speak("Đã xóa công việc");
        _showMsg('Đã xóa xong');
        _fetchReminders();
      } catch (e) {
        setState(() => _isLoading = false);
        _showMsg("Không xóa được: $e", isError: true);
      }
    }
  }

  // --- 4. CẬP NHẬT TRẠNG THÁI (SAFE UPDATE) ---
  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;
    final item = _reminders[index];

    bool newStatus = !currentStatus;
    // Optimistic UI (Cập nhật giao diện ngay)
    setState(() => _reminders[index]['is_completed'] = newStatus);

    try {
      // Gửi đầy đủ thông tin cũ để không bị mất title/desc
      await ReminderApiService.updateReminderStatus(
        id: id,
        isCompleted: newStatus,
        currentTitle: item['title'] ?? '',
        currentDescription: item['description'] ?? '',
        currentRemindAt: item['remind_at'] ?? DateTime.now().toIso8601String(),
      );

      if (newStatus) {
        _speak("Hoan hô, bác đã hoàn thành công việc");
        await NotificationHelper.cancel(id); // Xong rồi thì tắt báo thức
      } else {
        // Nếu bỏ tick (chưa xong), tự động cài lại báo thức nếu giờ chưa qua
        DateTime? t = DateTime.tryParse(item['remind_at'] ?? '');
        if (t != null && t.isAfter(DateTime.now())) {
          NotificationHelper.scheduleNotification(
              id: id,
              title: "Bác ơi! Đến giờ ${item['title']}",
              body: item['description'] ?? "Chạm vào để nghe.",
              scheduledTime: t
          );
        }
      }
      _fetchReminders();
    } catch (e) {
      // Revert nếu lỗi
      setState(() => _reminders[index]['is_completed'] = currentStatus);
      _showMsg('Lỗi mạng, chưa lưu được!', isError: true);
    }
  }

  // --- HELPER: DATE PICKER ---
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      locale: const Locale("vi", "VN"),
      helpText: "CHỌN NGÀY",
      builder: (context, child) => Transform.scale(scale: 1.1, child: child!),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      helpText: "CHỌN GIỜ",
      builder: (context, child) => Transform.scale(scale: 1.1, child: child!),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _cleanForm() {
    _titleController.clear();
    _descController.clear();
    _selectedDateTime = null;
    _editingId = null;
  }

  void _showMsg(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        backgroundColor: isError ? Colors.red : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // ==========================================
  //                PHẦN GIAO DIỆN (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 90,
        title: const Column(
          children: [
            Text('SỔ NHẮC VIỆC', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('(Bác nhớ kiểm tra hàng ngày nhé)', style: TextStyle(fontSize: 16)),
          ],
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading && _reminders.isEmpty
          ? Center(child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 6))
          : RefreshIndicator(
        onRefresh: _fetchReminders,
        color: _primaryColor,
        child: _reminders.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          itemCount: _reminders.length,
          itemBuilder: (context, index) => _buildElderlyCard(_reminders[index]),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 85, height: 85,
        child: FloatingActionButton(
          onPressed: () => _showModal(),
          backgroundColor: _primaryColor,
          child: const Icon(Icons.add, size: 45, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text('Hôm nay rảnh rỗi!', style: TextStyle(fontSize: 24, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text('Bấm dấu cộng (+) để thêm việc', style: TextStyle(fontSize: 18, color: _primaryColor)),
        ],
      ),
    );
  }

  Widget _buildElderlyCard(dynamic item) {
    final bool isCompleted = item['is_completed'] ?? false;
    final String title = item['title'] ?? 'Không tên';
    final String desc = item['description'] ?? '';
    final DateTime? dt = DateTime.tryParse(item['remind_at'] ?? '');

    final String speakContent = "Việc cần làm: $title. "
        "${desc.isNotEmpty ? "Ghi chú: $desc. " : ""}"
        "${dt != null ? "Vào lúc ${DateFormat('HH giờ mm phút').format(dt)}" : ""}";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEEEEEE) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isCompleted ? Colors.transparent : Colors.blueGrey.shade200,
            width: isCompleted ? 0 : 2
        ),
        boxShadow: isCompleted ? [] : [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showModal(item: item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.8,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: Colors.green,
                  side: BorderSide(color: _primaryColor, width: 2),
                  shape: const CircleBorder(),
                  onChanged: (val) => _toggleStatus(item['id'], isCompleted),
                ),
              ),
              const SizedBox(width: 16),

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : _textColor,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(desc, style: TextStyle(fontSize: 18, color: Colors.grey[800], fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 10),
                    if (dt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          DateFormat('HH:mm - dd/MM').format(dt),
                          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      )
                  ],
                ),
              ),

              // Nút Loa
              IconButton(
                icon: const Icon(Icons.volume_up, size: 40, color: Colors.deepOrange),
                onPressed: () => _speak(speakContent),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- FORM MODAL ---
  void _showModal({Map<String, dynamic>? item}) {
    if (item != null) {
      _editingId = item['id'];
      _titleController.text = item['title'] ?? '';
      _descController.text = item['description'] ?? '';
      try { _selectedDateTime = DateTime.parse(item['remind_at']); } catch (_) { _selectedDateTime = DateTime.now(); }
      _speak("Sửa công việc: ${item['title']}");
    } else {
      _cleanForm();
      _speak("Thêm việc mới");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Center(child: Text(_editingId == null ? "THÊM VIỆC MỚI" : "SỬA CÔNG VIỆC",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor))),
              const SizedBox(height: 30),

              _buildLabel("1. Tên công việc"),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  contentPadding: const EdgeInsets.all(20),
                  prefixIcon: const Icon(Icons.edit_note, size: 30),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel("2. Ghi chú (nếu có)"),
              TextField(
                controller: _descController,
                style: const TextStyle(fontSize: 20),
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  hintText: "Ví dụ: Thuốc màu đỏ...",
                  prefixIcon: const Icon(Icons.notes, size: 30),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("3. Giờ nhắc"),
              InkWell(
                onTap: () async {
                  await _pickDateTime();
                  setModalState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: _primaryColor, width: 2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_add, size: 36, color: Colors.blue),
                      const SizedBox(width: 15),
                      Text(
                        _selectedDateTime == null ? "CHỌN GIỜ NGAY" : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime!),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Row(
                  children: [
                    if (_editingId != null)
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 65,
                          margin: const EdgeInsets.only(right: 15),
                          child: ElevatedButton(
                            onPressed: () => _deleteReminder(_editingId!),
                            style: ElevatedButton.styleFrom(backgroundColor: _deleteColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            child: const Icon(Icons.delete_forever, size: 36, color: Colors.white),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 65,
                        child: ElevatedButton(
                          onPressed: _saveReminder,
                          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: Text(_editingId == null ? "LƯU LẠI" : "CẬP NHẬT", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
    );
  }
}