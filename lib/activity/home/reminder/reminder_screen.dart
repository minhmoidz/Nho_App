import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/app_bar.dart';

// Đảm bảo bạn đã import đúng đường dẫn các file này
import 'reminder_api_service.dart';
import 'local_storage.dart';
import 'notification_helper.dart';

class ReminderScreen extends StatefulWidget {
  final String? notificationPayload;
  const ReminderScreen({Key? key, this.notificationPayload}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with WidgetsBindingObserver {
  // --- MÀU SẮC GIAO DIỆN ---
  final Color _primaryColor = const Color(0xFF0D47A1); // Xanh đậm
  final Color _accentColor = const Color(0xFFE3F2FD);  // Xanh nhạt
  final Color _redColor = const Color(0xFFD32F2F);     // Đỏ

  bool _isLoading = false;
  List<dynamic> _reminders = [];
  final FlutterTts _flutterTts = FlutterTts();

  // Controllers nhập liệu
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Biến dùng cho Modal (Thêm/Sửa)
  DateTime? _selectedDateTime;
  DateTime? _endDate;   // Ngày kết thúc (nếu chọn lặp lại)
  bool _isDaily = false; // Có lặp lại hàng ngày không?
  int? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();

    // Chạy sau khi màn hình hiện lên
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

  // --- 1. KHỞI TẠO & QUYỀN ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _checkPermissionsAndFetch() async {
    // Xin quyền cần thiết
    if (await Permission.notification.isDenied) await Permission.notification.request();
    if (await Permission.scheduleExactAlarm.isDenied) await Permission.scheduleExactAlarm.request();

    // Bắt đầu tải dữ liệu
    _loadDataOfflineFirst();
  }

  // --- 2. LOGIC TẢI DỮ LIỆU (OFFLINE FIRST) ---
  Future<void> _loadDataOfflineFirst() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // BƯỚC A: Load từ Local Storage (Hiển thị ngay lập tức)
    List<dynamic> localData = await LocalStorage.getReminders();
    if (localData.isNotEmpty) {
      setState(() {
        _reminders = _sortData(localData);
        _isLoading = false; // Tắt loading để người dùng thấy ngay
      });
      // Cài đặt báo thức dựa trên dữ liệu trong máy
      _scheduleRemindersToSystem(localData);
    }

    // BƯỚC B: Gọi API lấy dữ liệu mới nhất
    try {
      final serverData = await ReminderApiService.getReminders();
      if (serverData.isNotEmpty) {
        // Cập nhật UI
        setState(() => _reminders = _sortData(serverData));
        // Lưu đè vào Local Storage
        await LocalStorage.saveReminders(serverData);
        // Cài đặt lại báo thức theo dữ liệu mới
        _scheduleRemindersToSystem(serverData);
      }
    } catch (e) {
      debugPrint("⚠️ Mất mạng hoặc lỗi Server, dùng dữ liệu Offline.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _sortData(List<dynamic> data) {
    // Sắp xếp: Chưa làm lên đầu -> Theo thời gian
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

  // --- 3. LOGIC CÀI BÁO THỨC (CÓ LẶP LẠI) ---
  Future<void> _scheduleRemindersToSystem(List<dynamic> data) async {
    await NotificationHelper.cancelAll(); // Reset toàn bộ
    final now = DateTime.now();
    int count = 0;

    for (var item in data) {
      bool isCompleted = item['is_completed'] ?? false;

      // Lấy thông tin lặp lại (Lưu ý: API phải trả về hoặc ta lưu ở local)
      bool isDaily = item['is_daily'] ?? false;
      DateTime? endDate = DateTime.tryParse(item['end_date'] ?? '')?.toLocal();
      DateTime? remindAt = DateTime.tryParse(item['remind_at'] ?? '')?.toLocal();

      int id = item['id'];

      // Chỉ cài báo thức nếu có giờ và chưa hoàn thành (hoặc là lặp lại)
      if (remindAt != null && !isCompleted) {

        // Nếu có ngày kết thúc và đã quá ngày đó -> Không báo nữa
        if (endDate != null && now.isAfter(endDate.add(const Duration(days: 1)))) {
          continue;
        }

        // Logic cũ: Chỉ báo tương lai. Logic mới: Nếu là Daily thì luôn báo (Helper tự xử lý ngày mai)
        if (isDaily || remindAt.isAfter(now)) {
          await NotificationHelper.scheduleNotification(
            id: id,
            title: "Bác ơi! Đến giờ: ${item['title']}",
            body: item['description'] ?? "Chạm vào để nghe nội dung",
            scheduledTime: remindAt,
            isDaily: isDaily, // <--- Truyền tham số lặp lại
          );
          count++;
        }
      }
    }
    debugPrint("⏰ Đã cài đặt $count báo thức (bao gồm cả lặp lại).");
  }

  // --- 4. CÁC TÁC VỤ: LƯU / XÓA / HOÀN THÀNH ---

  Future<void> _saveReminder() async {
    // Validate
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
      // Chuẩn bị dữ liệu mở rộng để lưu
      // (Nếu API chưa hỗ trợ cột is_daily/end_date, chúng ta vẫn lưu vào LocalStorage để App chạy đúng)

      if (_editingId == null) {
        // --- THÊM MỚI ---
        await ReminderApiService.createReminder(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!,
          // Truyền thêm param nếu API hỗ trợ: isDaily: _isDaily, endDate: _endDate
        );
        _showMsg("Đã thêm việc mới");
      } else {
        // --- CẬP NHẬT ---
        // Gọi API Update
        await ReminderApiService.updateReminder(
          id: _editingId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          remindAt: _selectedDateTime!, // Dùng giờ mới chọn
          isCompleted: false,
        );

        // Cập nhật thủ công vào List Local (để UI và Logic chạy đúng ngay lập tức)
        int idx = _reminders.indexWhere((e) => e['id'] == _editingId);
        if (idx != -1) {
          _reminders[idx]['title'] = _titleController.text.trim();
          _reminders[idx]['description'] = _descController.text.trim();
          _reminders[idx]['remind_at'] = _selectedDateTime!.toIso8601String();
          _reminders[idx]['is_daily'] = _isDaily; // Lưu cờ lặp lại
          _reminders[idx]['end_date'] = _endDate?.toIso8601String();
          _reminders[idx]['is_completed'] = false;
        }

        // Lưu List mới xuống Local Storage
        await LocalStorage.saveReminders(_reminders);

        _showMsg("Đã cập nhật xong");
      }

      // Reload lại để đồng bộ Báo thức
      _cleanForm();
      _loadDataOfflineFirst();

    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg("Lỗi khi lưu: $e", isError: true);
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
      if (_editingId != null) Navigator.pop(context);
      setState(() => _isLoading = true);

      try {
        await ReminderApiService.deleteReminder(id);

        // Xóa Local & Báo thức
        _reminders.removeWhere((r) => r['id'] == id);
        await LocalStorage.saveReminders(_reminders);
        await NotificationHelper.cancel(id);

        setState(() => _isLoading = false);
        _showMsg("Đã xóa xong");
      } catch (e) {
        setState(() => _isLoading = false);
        _showMsg("Lỗi xóa: $e", isError: true);
      }
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;

    bool newStatus = !currentStatus;
    setState(() => _reminders[index]['is_completed'] = newStatus);

    // Lưu Local ngay
    await LocalStorage.saveReminders(_reminders);

    try {
      final item = _reminders[index];
      await ReminderApiService.updateReminderStatus(
        id: id,
        isCompleted: newStatus,
        currentTitle: item['title'],
        currentDescription: item['description'] ?? '',
        currentRemindAt: item['remind_at'],
      );

      // Xử lý Báo thức
      if (newStatus) {
        await NotificationHelper.cancel(id); // Xong rồi thì tắt
        _speak("Đã xong! Bác giỏi quá.");
      } else {
        // Hoàn tác -> Cài lại
        _scheduleRemindersToSystem(_reminders);
        _speak("Đã đặt lại nhắc nhở.");
      }

      setState(() => _reminders = _sortData(_reminders));

    } catch (e) {
      debugPrint("Lỗi sync: $e");
    }
  }

  // --- 5. GIAO DIỆN CHÍNH ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const NhoAppBar(title: "Nhắc nhở"),
      body: _reminders.isEmpty && !_isLoading
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadDataOfflineFirst,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: _reminders.length,
          itemBuilder: (ctx, i) => _buildElderlyCard(_reminders[i]),
        ),
      ),

      floatingActionButton: SizedBox(
        width: 75, height: 75,
        child: FloatingActionButton(
          onPressed: () => _showModal(),
          backgroundColor: AppColors.primary,
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
          Text('Chưa có việc nào', style: TextStyle(fontSize: 22, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text('Bấm dấu (+) để thêm', style: TextStyle(fontSize: 18, color: AppColors.primary)),
        ],
      ),
    );
  }

  // CARD HIỂN THỊ CÔNG VIỆC
  Widget _buildElderlyCard(dynamic item) {
    final bool isCompleted = item['is_completed'] ?? false;
    final bool isDaily = item['is_daily'] ?? false; // Lấy cờ lặp lại
    final String title = item['title'] ?? 'Không tên';
    final String desc = item['description'] ?? '';
    final DateTime? dt = DateTime.tryParse(item['remind_at'] ?? '')?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEEEEEE) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isCompleted ? Colors.transparent : Colors.blueGrey.shade200, width: 2
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
              // Checkbox To
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

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (dt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled, size: 20, color: _primaryColor),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat('HH:mm').format(dt), // Chỉ hiện giờ
                              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            if (!isDaily) ...[
                              const SizedBox(width: 5),
                              Text(" - ${DateFormat('dd/MM').format(dt)}", style: TextStyle(color: _primaryColor, fontSize: 16)),
                            ],
                            // Badge Lặp lại
                            if (isDaily)
                              Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.repeat, size: 14, color: Colors.deepOrange),
                                    Text(" Hàng ngày", style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Loa đọc
              IconButton(
                icon: const Icon(Icons.volume_up, size: 36, color: Colors.deepOrange),
                onPressed: () => _speak("Việc: $title. $desc"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. MODAL THÊM / SỬA (FORM) ---
  void _showModal({Map<String, dynamic>? item}) {
    // Reset Form
    _cleanForm();

    if (item != null) {
      // MODE SỬA: Đổ dữ liệu cũ vào
      _editingId = item['id'];
      _titleController.text = item['title'] ?? '';
      _descController.text = item['description'] ?? '';

      // Fix lỗi giờ: Parse giờ từ item vào biến _selectedDateTime
      if (item['remind_at'] != null) {
        try { _selectedDateTime = DateTime.parse(item['remind_at']); } catch (_) {}
      }

      // Load cấu hình lặp lại
      _isDaily = item['is_daily'] ?? false;
      if (item['end_date'] != null) {
        try { _endDate = DateTime.parse(item['end_date']); } catch (_) {}
      }

      _speak("Sửa việc: ${item['title']}");
    } else {
      // MODE THÊM MỚI
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 5)); // Mặc định +5p
      _speak("Thêm việc mới");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder cần thiết để update UI trong Modal (Switch, DatePicker)
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Center(child: Text(_editingId == null ? "THÊM VIỆC MỚI" : "SỬA VIỆC", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor))),
                const SizedBox(height: 30),

                // 1. TÊN VIỆC
                const Text("1. Tên công việc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.edit_note, size: 30),
                      hintText: "VD: Uống thuốc huyết áp"
                  ),
                ),
                const SizedBox(height: 20),

                // 2. CHỌN GIỜ (QUAN TRỌNG)
                const Text("2. Giờ nhắc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    // Chọn ngày
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date == null) return;

                    // Chọn giờ
                    if (!mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
                    );
                    if (time == null) return;

                    // Cập nhật State trong Modal
                    setModalState(() {
                      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
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
                          _selectedDateTime == null
                              ? "BẤM ĐỂ CHỌN GIỜ"
                              : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime!),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. TÙY CHỌN LẶP LẠI (MỚI)
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("Lặp lại hàng ngày?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Máy sẽ tự nhắc giờ này mỗi ngày"),
                        value: _isDaily,
                        activeColor: _primaryColor,
                        onChanged: (val) {
                          setModalState(() => _isDaily = val);
                        },
                      ),
                      // Nếu bật lặp lại -> Hiện tùy chọn ngày kết thúc
                      if (_isDaily) ...[
                        const Divider(),
                        ListTile(
                          title: const Text("Ngày kết thúc (Tùy chọn)", style: TextStyle(fontSize: 18)),
                          subtitle: Text(_endDate == null ? "Nhắc mãi mãi" : "Đến hết: ${DateFormat('dd/MM/yyyy').format(_endDate!)}"),
                          trailing: const Icon(Icons.calendar_month, color: Colors.blue),
                          onTap: () async {
                            final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2035),
                                helpText: "CHỌN NGÀY DỪNG UỐNG"
                            );
                            if (picked != null) {
                              setModalState(() => _endDate = picked);
                            }
                          },
                        ),
                        if (_endDate != null)
                          TextButton(
                            onPressed: () => setModalState(() => _endDate = null),
                            child: const Text("Xóa ngày kết thúc", style: TextStyle(color: Colors.red)),
                          )
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. GHI CHÚ
                const Text("4. Ghi chú (tùy chọn)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _descController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.notes, size: 30),
                      hintText: "VD: Màu đỏ, uống sau ăn"
                  ),
                ),

                const SizedBox(height: 30),

                // NÚT LƯU / XÓA
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
      ),
    );
  }

  // --- Helpers ---
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
    _endDate = null;
    _isDaily = false;
    _editingId = null;
  }
}