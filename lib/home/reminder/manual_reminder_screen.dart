import 'package:flutter/material.dart';
import 'package:gioapp/home/reminder/reminder_api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_storage.dart';
import 'notification_helper.dart';


class ReminderScreen extends StatefulWidget {
  final String? notificationPayload;

  const ReminderScreen({Key? key, this.notificationPayload}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with WidgetsBindingObserver {
  // --- MÀU SẮC (Tương phản cao cho người già) ---
  final Color _primaryColor = const Color(0xFF0D47A1); // Xanh đậm
  final Color _accentColor = const Color(0xFFE3F2FD);  // Xanh nhạt
  final Color _redColor = const Color(0xFFD32F2F);     // Đỏ

  bool _isLoading = false;
  List<dynamic> _reminders = []; // Danh sách việc

  final FlutterTts _flutterTts = FlutterTts();

  // Controllers cho Modal Thêm/Sửa
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDateTime;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Để lắng nghe khi app mở lại từ background
    _initTts();

    // BƯỚC 1: XIN QUYỀN VÀ LOAD DỮ LIỆU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndFetch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- A. CẤU HÌNH BAN ĐẦU ---

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5); // Đọc chậm
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _checkPermissionsAndFetch() async {
    // Xin quyền Thông báo
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Xin quyền Báo thức chính xác (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Gọi hàm load dữ liệu thông minh
    _loadDataOfflineFirst();
  }

  // --- B. LOGIC OFFLINE FIRST (CỐT LÕI) ---

  Future<void> _loadDataOfflineFirst() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. Load từ Local Storage trước (Hiển thị ngay lập tức)
    List<dynamic> localData = await LocalStorage.getReminders();
    if (localData.isNotEmpty) {
      debugPrint("📂 Đã load ${localData.length} việc từ bộ nhớ máy.");
      setState(() {
        _reminders = _sortData(localData);
        _isLoading = false; // Tắt loading ngay để người dùng xem được
      });
      // Cài đặt báo thức ngay (đề phòng không có mạng)
      _scheduleRemindersToSystem(localData);
    }

    // 2. Gọi API để đồng bộ dữ liệu mới nhất
    try {
      final serverData = await ReminderApiService.getReminders();

      if (serverData.isNotEmpty) {
        debugPrint("☁️ Đã đồng bộ ${serverData.length} việc từ Server.");

        // Cập nhật UI
        setState(() => _reminders = _sortData(serverData));

        // Lưu đè vào Local Storage để lần sau dùng
        await LocalStorage.saveReminders(serverData);

        // Cài đặt lại báo thức theo dữ liệu mới nhất
        _scheduleRemindersToSystem(serverData);
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi mạng: $e. Đang dùng dữ liệu Offline.");
      if (_reminders.isEmpty) {
        _showMsg("Không có mạng và chưa có dữ liệu cũ.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm sắp xếp: Chưa làm lên đầu -> Theo thời gian
  List<dynamic> _sortData(List<dynamic> data) {
    data.sort((a, b) {
      bool aDone = a['is_completed'] ?? false;
      bool bDone = b['is_completed'] ?? false;
      if (aDone != bDone) return aDone ? 1 : -1;

      DateTime aTime = DateTime.tryParse(a['remind_at'] ?? '') ?? DateTime.now();
      DateTime bTime = DateTime.tryParse(b['remind_at'] ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });
    return data;
  }

  // Hàm cài đặt báo thức vào hệ điều hành
  Future<void> _scheduleRemindersToSystem(List<dynamic> data) async {
    await NotificationHelper.cancelAll(); // Xóa sạch cái cũ

    final now = DateTime.now();
    int count = 0;

    for (var item in data) {
      bool isCompleted = item['is_completed'] ?? false;
      DateTime? remindAt = DateTime.tryParse(item['remind_at'] ?? '')?.toLocal();
      int id = item['id'];

      // Chỉ hẹn giờ nếu: Có giờ + Chưa xong + Là tương lai
      if (remindAt != null && !isCompleted && remindAt.isAfter(now)) {
        await NotificationHelper.scheduleNotification(
          id: id,
          title: "Bác ơi! Đến giờ: ${item['title']}",
          body: item['description'] ?? "Chạm vào để nghe nội dung",
          scheduledTime: remindAt,
        );
        count++;
      }
    }
    debugPrint("⏰ Đã cài đặt $count báo thức.");
  }

  // --- C. CÁC TÁC VỤ: THÊM / SỬA / XÓA / CHECK ---

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    // 1. Cập nhật UI ngay (Optimistic Update)
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;

    bool newStatus = !currentStatus;
    setState(() {
      _reminders[index]['is_completed'] = newStatus;
    });

    // 2. Cập nhật Local Storage ngay lập tức (Để lỡ tắt app vẫn nhớ)
    await LocalStorage.saveReminders(_reminders);

    // 3. Xử lý Báo thức & Server
    try {
      final item = _reminders[index];

      // Gọi API
      await ReminderApiService.updateReminderStatus(
        id: id,
        isCompleted: newStatus,
        currentTitle: item['title'] ?? '',
        currentDescription: item['description'] ?? '',
        currentRemindAt: item['remind_at'] ?? DateTime.now().toIso8601String(),
      );

      // Xử lý báo thức
      if (newStatus) {
        await NotificationHelper.cancel(id); // Xong rồi thì tắt chuông
        _speak("Đã xong! Bác giỏi quá.");
      } else {
        // Nếu bỏ tích (chưa xong) -> Cài lại báo thức
        DateTime? t = DateTime.tryParse(item['remind_at'] ?? '')?.toLocal();
        if (t != null && t.isAfter(DateTime.now())) {
          await NotificationHelper.scheduleNotification(
            id: id,
            title: "Bác ơi! Đến giờ: ${item['title']}",
            body: item['description'] ?? "",
            scheduledTime: t,
          );
          _speak("Đã đặt lại nhắc nhở.");
        }
      }

      // Sắp xếp lại danh sách
      setState(() {
        _reminders = _sortData(_reminders);
      });

    } catch (e) {
      // Nếu lỗi mạng -> Không cần revert UI vì Local đã lưu rồi, lần sau có mạng tính sau
      debugPrint("Lỗi sync server: $e");
    }
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      _speak("Bác chưa nhập tên việc");
      return;
    }
    if (_selectedDateTime == null) {
      _speak("Bác chưa chọn giờ");
      return;
    }

    Navigator.pop(context); // Đóng modal
    setState(() => _isLoading = true);

    try {
      if (_editingId == null) {
        // THÊM MỚI
        await ReminderApiService.createReminder(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
        );
        _showMsg("Đã thêm việc mới");
      } else {
        // CẬP NHẬT
        await ReminderApiService.updateReminder(
          id: _editingId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
          isCompleted: false, // Sửa lại thì coi như chưa làm
        );
        _showMsg("Đã cập nhật xong");
      }

      // Quan trọng: Load lại để đồng bộ Server -> Local -> Alarm
      _cleanForm();
      _loadDataOfflineFirst();

    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg("Lỗi lưu: $e", isError: true);
    }
  }

  Future<void> _deleteReminder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('XÓA VIỆC?', style: TextStyle(color: Colors.red)),
        content: const Text('Bác chắc chắn muốn xóa không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KHÔNG')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_editingId != null) Navigator.pop(context); // Đóng modal
      setState(() => _isLoading = true);

      try {
        await ReminderApiService.deleteReminder(id);

        // Xóa trong Local List & Local Storage luôn cho nhanh
        _reminders.removeWhere((r) => r['id'] == id);
        await LocalStorage.saveReminders(_reminders);
        await NotificationHelper.cancel(id); // Hủy báo thức

        setState(() => _isLoading = false);
        _showMsg("Đã xóa xong");
      } catch (e) {
        setState(() => _isLoading = false);
        _showMsg("Lỗi xóa: $e", isError: true);
      }
    }
  }

  // --- D. GIAO DIỆN (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          children: [
            Text('NHẮC THUỐC & VIỆC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('(Dữ liệu được lưu trong máy)', style: TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),

      body: _reminders.isEmpty && !_isLoading
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadDataOfflineFirst,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: _reminders.length,
          itemBuilder: (context, index) => _buildElderlyCard(_reminders[index]),
        ),
      ),

      floatingActionButton: SizedBox(
        width: 75, height: 75,
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
          Text('Bấm dấu (+) để thêm', style: TextStyle(fontSize: 18, color: _primaryColor)),
        ],
      ),
    );
  }

  Widget _buildElderlyCard(dynamic item) {
    final bool isCompleted = item['is_completed'] ?? false;
    final String title = item['title'] ?? 'Không tên';
    final String desc = item['description'] ?? '';
    final DateTime? dt = DateTime.tryParse(item['remind_at'] ?? '')?.toLocal();

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
              // CHECKBOX TO
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

              // NỘI DUNG
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (dt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.alarm, size: 22, color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm - dd/MM').format(dt),
                              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // NÚT ĐỌC
              IconButton(
                icon: const Icon(Icons.volume_up, size: 40, color: Colors.deepOrange),
                onPressed: () => _speak("Việc cần làm: $title. $desc"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- E. CÁC HÀM HỖ TRỢ & MODAL ---

  void _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 18)),
      backgroundColor: isError ? _redColor : Colors.green[700],
    ));
  }

  void _cleanForm() {
    _titleController.clear();
    _descController.clear();
    _selectedDateTime = null;
    _editingId = null;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: "CHỌN NGÀY",
      builder: (ctx, child) => Transform.scale(scale: 1.1, child: child!),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      helpText: "CHỌN GIỜ",
      builder: (ctx, child) => Transform.scale(scale: 1.1, child: child!),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _showModal({Map<String, dynamic>? item}) {
    if (item != null) {
      _editingId = item['id'];
      _titleController.text = item['title'] ?? '';
      _descController.text = item['description'] ?? '';
      try { _selectedDateTime = DateTime.parse(item['remind_at']); } catch (_) { _selectedDateTime = DateTime.now(); }
      _speak("Sửa việc: ${item['title']}");
    } else {
      _cleanForm();
      _speak("Thêm việc mới");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Center(child: Text(_editingId == null ? "THÊM VIỆC" : "SỬA VIỆC", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryColor))),
            const SizedBox(height: 30),

            // INPUT 1
            const Text("1. Tên công việc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22),
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.edit_note, size: 30),
                  hintText: "VD: Uống thuốc..."
              ),
            ),
            const SizedBox(height: 20),

            // INPUT 2
            const Text("2. Giờ nhắc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () => _pickDateTime(),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: _primaryColor)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.alarm, size: 30, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDateTime == null ? "BẤM CHỌN GIỜ" : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime!),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // INPUT 3
            const Text("3. Ghi chú (tùy chọn)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _descController,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.notes, size: 30),
                  hintText: "VD: Màu đỏ, sau ăn"
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
                      style: ElevatedButton.styleFrom(backgroundColor: _redColor, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Icon(Icons.delete_forever, size: 30, color: Colors.white),
                    ),
                  ),
                if (_editingId != null) const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text("LƯU LẠI", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
          ],
        ),
      ),
    );
  }
}