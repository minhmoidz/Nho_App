import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart'; // Xin quyền

// Import 2 file helper của bạn
import 'reminder_api_service.dart';
import 'notification_helper.dart';

class ReminderScreen extends StatefulWidget {
  // Biến này nhận ID công việc nếu người dùng mở App từ thanh thông báo
  final String? notificationPayload;

  const ReminderScreen({Key? key, this.notificationPayload}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // --- CẤU HÌNH GIAO DIỆN (Màu sắc tương phản cao) ---
  final Color _primaryColor = const Color(0xFF0D47A1); // Xanh dương đậm
  final Color _accentColor = const Color(0xFFE3F2FD);  // Xanh nhạt nền
  final Color _deleteColor = const Color(0xFFD32F2F);  // Đỏ đậm
  final Color _textColor = const Color(0xFF212121);    // Đen đậm

  // --- SỐ ĐIỆN THOẠI NGƯỜI THÂN (Cần cấu hình) ---
  // Trong thực tế, bạn nên lấy số này từ SharedPreferences hoặc Database
  final String _contactPhone = "0912345678";

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
    _checkPermissions(); // Xin quyền SMS
    _fetchReminders(); // Tải dữ liệu

    // Kiểm tra nếu mở app từ thông báo
    if (widget.notificationPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationClick(widget.notificationPayload!);
      });
    }
  }

  // Xin quyền gửi SMS và Thông báo
  Future<void> _checkPermissions() async {
    await Permission.sms.request();
    await Permission.notification.request();
  }

  // --- CẤU HÌNH GIỌNG ĐỌC ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.45); // Đọc chậm rãi
    await _flutterTts.setVolume(1.0);
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

      // Tự động cài lại báo thức để đảm bảo không bị lỡ
      _rescheduleAllAlarms(data);

    } catch (e) {
      _showMsg('Lỗi tải dữ liệu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          title: "Bác ơi! Đến giờ uống thuốc/làm việc: $title",
          body: desc.isNotEmpty ? desc : "Chạm vào để xác nhận đã uống.",
          scheduledTime: remindAt,
        );
      }
    }
  }

  // --- 2. XỬ LÝ KHI MỞ THÔNG BÁO (LOGIC QUAN TRỌNG) ---
  void _handleNotificationClick(String payloadId) {
    int id = int.tryParse(payloadId) ?? -1;
    if (id == -1) return;

    // Tìm công việc trong danh sách
    final item = _reminders.firstWhere((e) => e['id'] == id, orElse: () => null);

    if (item != null && item['is_completed'] == false) {
      // Hiện bảng xác nhận to
      _showMedicineConfirmation(item);
    }
  }

  // Hộp thoại xác nhận KHỔNG LỒ
  void _showMedicineConfirmation(dynamic item) {
    String title = item['title'];
    _speak("Bác ơi, bác đã uống $title chưa ạ? Xin hãy xác nhận.");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF9C4), // Vàng nhạt
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.medication, color: Colors.red, size: 40),
              const SizedBox(width: 10),
              Expanded(child: Text("XÁC NHẬN: ${title.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            ],
          ),
          content: const Text(
            "Bác đã uống thuốc đúng giờ chưa?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            // NÚT CHƯA / QUÊN
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleMissedDose(item); // Xử lý khi chưa uống
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Icon(Icons.close, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 5),
                const Text("CHƯA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            // NÚT ĐÃ UỐNG
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleStatus(item['id'], false); // Đánh dấu hoàn thành
                    _speak("Tuyệt vời, chúc bác mạnh khỏe!");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 5),
                const Text("ĐÃ UỐNG", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    );
  }

  // Xử lý khi bỏ qua / quên -> Gửi SMS
  Future<void> _handleMissedDose(dynamic item) async {
    _speak("Cháu sẽ nhắn tin cho người nhà ngay để hỗ trợ bác.");

    String message = "KHẨN CẤP: Bố/Mẹ chưa uống thuốc '${item['title']}' lúc ${DateFormat('HH:mm').format(DateTime.now())}. Xin hãy gọi kiểm tra!";

  }

  // --- 3. CÁC CHỨC NĂNG CRUD (LƯU, XÓA, UPDATE) ---

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      _speak("Bác chưa nhập tên công việc");
      return;
    }
    if (_selectedDateTime == null) {
      _speak("Bác chưa chọn giờ nhắc");
      return;
    }

    Navigator.pop(context); // Đóng modal
    setState(() => _isLoading = true);

    try {
      int targetId = 0;
      if (_editingId == null) {
        // Tạo mới
        final newReminder = await ReminderApiService.createReminder(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
        );
        targetId = newReminder['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000;
        _showMsg('Đã thêm việc mới');
      } else {
        // Cập nhật
        targetId = _editingId!;
        await ReminderApiService.updateReminder(
          id: targetId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
          isCompleted: false,
        );
        _showMsg('Đã cập nhật xong');
      }

      // Cài báo thức
      if (_selectedDateTime!.isAfter(DateTime.now())) {
        await NotificationHelper.cancel(targetId);
        await NotificationHelper.scheduleNotification(
          id: targetId,
          title: "Bác ơi! Đến giờ ${_titleController.text}",
          body: _descController.text.isNotEmpty ? _descController.text : "Chạm vào để xác nhận.",
          scheduledTime: _selectedDateTime!,
        );
      }

      _cleanForm();
      _fetchReminders();
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg("Lỗi khi lưu: $e", isError: true);
    }
  }

  Future<void> _deleteReminder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('XÓA VIỆC NÀY?', style: TextStyle(color: Colors.red)),
        content: const Text('Bác có chắc chắn muốn xóa không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KHÔNG')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA NGAY', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_editingId != null && mounted) Navigator.pop(context);
      setState(() => _isLoading = true);
      try {
        await ReminderApiService.deleteReminder(id);
        await NotificationHelper.cancel(id); // Hủy báo thức
        _showMsg('Đã xóa xong');
        _fetchReminders();
      } catch (e) {
        setState(() => _isLoading = false);
        _showMsg("Lỗi: $e", isError: true);
      }
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;
    final item = _reminders[index];

    bool newStatus = !currentStatus;
    setState(() => _reminders[index]['is_completed'] = newStatus);

    try {
      await ReminderApiService.updateReminderStatus(
        id: id,
        isCompleted: newStatus,
        currentTitle: item['title'] ?? '',
        currentDescription: item['description'] ?? '',
        currentRemindAt: item['remind_at'] ?? DateTime.now().toIso8601String(),
      );

      if (newStatus) {
        await NotificationHelper.cancel(id); // Xong rồi thì tắt báo thức
      } else {
        // Bật lại nếu chưa xong
        DateTime? t = DateTime.tryParse(item['remind_at'] ?? '');
        if (t != null && t.isAfter(DateTime.now())) {
          NotificationHelper.scheduleNotification(
            id: id,
            title: "Bác ơi! Đến giờ ${item['title']}",
            body: item['description'] ?? "Chạm vào để xác nhận.",
            scheduledTime: t,
          );
        }
      }
      _fetchReminders();
    } catch (e) {
      setState(() => _reminders[index]['is_completed'] = currentStatus);
      _showMsg('Lỗi mạng!', isError: true);
    }
  }

  // --- 4. GIAO DIỆN & HELPER ---

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
      ),
    );
  }

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

  // UI Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 90,
        title: const Column(
          children: [
            Text('NHẮC THUỐC & VIỆC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('(Bác nhớ kiểm tra hàng ngày nhé)', style: TextStyle(fontSize: 16)),
          ],
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _reminders.isEmpty
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
        onRefresh: _fetchReminders,
        child: _reminders.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: _reminders.length,
          itemBuilder: (context, index) => _buildElderlyCard(_reminders[index]),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80, height: 80,
        child: FloatingActionButton(
          onPressed: () => _showModal(),
          backgroundColor: _primaryColor,
          child: const Icon(Icons.add, size: 40, color: Colors.white),
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
          Text('Hôm nay rảnh rỗi!', style: TextStyle(fontSize: 22, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text('Bấm dấu (+) để thêm nhắc nhở', style: TextStyle(fontSize: 18, color: _primaryColor)),
        ],
      ),
    );
  }

  Widget _buildElderlyCard(dynamic item) {
    final bool isCompleted = item['is_completed'] ?? false;
    final String title = item['title'] ?? 'Không tên';
    final String desc = item['description'] ?? '';
    final DateTime? dt = DateTime.tryParse(item['remind_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEEEEEE) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isCompleted ? Colors.transparent : Colors.blueGrey.shade200,
            width: 2
        ),
        boxShadow: isCompleted ? [] : [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showModal(item: item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.8,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: Colors.green,
                  shape: const CircleBorder(),
                  onChanged: (val) => _toggleStatus(item['id'], isCompleted),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : _textColor,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (dt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('HH:mm - dd/MM').format(dt),
                          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 40, color: Colors.deepOrange),
                onPressed: () => _speak("Việc cần làm: $title. ${desc.isNotEmpty ? "Ghi chú: $desc" : ""}"),
              )
            ],
          ),
        ),
      ),
    );
  }

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
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Center(child: Text(_editingId == null ? "THÊM VIỆC" : "SỬA VIỆC", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryColor))),
              const SizedBox(height: 30),

              const Text("1. Tên thuốc / công việc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 22),
                decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.edit_note, size: 30),
                    hintText: "VD: Uống thuốc huyết áp"
                ),
              ),
              const SizedBox(height: 20),

              const Text("2. Ghi chú (nếu có)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _descController,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.notes, size: 30),
                    hintText: "VD: 2 viên màu đỏ"
                ),
              ),
              const SizedBox(height: 20),

              const Text("3. Giờ nhắc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () async {
                  await _pickDateTime();
                  setModalState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: _primaryColor)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm, size: 30, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDateTime == null ? "BẤM ĐỂ CHỌN GIỜ" : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime!),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              Row(
                children: [
                  if (_editingId != null)
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () => _deleteReminder(_editingId!),
                        style: ElevatedButton.styleFrom(backgroundColor: _deleteColor, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Icon(Icons.delete_forever, size: 30, color: Colors.white),
                      ),
                    ),
                  if (_editingId != null) const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: Text(_editingId == null ? "LƯU LẠI" : "CẬP NHẬT", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
            ],
          ),
        ),
      ),
    );
  }
}