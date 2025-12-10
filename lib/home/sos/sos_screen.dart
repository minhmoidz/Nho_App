import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Gọi điện & Mở map
import 'package:geolocator/geolocator.dart'; // Lấy vị trí


class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  // Dữ liệu mẫu
  List<Map<String, String>> relatives = [
    {'name': 'Con trai cả', 'phone': '0912345678'},
    {'name': 'Con gái út', 'phone': '0987654321'},
  ];

  List<Map<String, String>> medicalContacts = [
    {'name': 'Bác sĩ Tâm', 'phone': '0909000111'},
    {'name': 'Phòng khám Đa khoa', 'phone': '0288123456'},
  ];

  // --- 1. HÀM GỌI ĐIỆN ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('Không thể thực hiện cuộc gọi: $e');
    }
  }

  // --- 2. HÀM LẤY VỊ TRÍ HIỆN TẠI ---
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Vui lòng bật GPS để sử dụng tính năng này.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Quyền truy cập vị trí bị từ chối.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Quyền vị trí bị chặn vĩnh viễn. Hãy mở cài đặt để cấp quyền.');
      return null;
    }

    // Lấy vị trí (High accuracy cho chính xác)
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // --- 3. TÍNH NĂNG: GỬI SOS KÈM VỊ TRÍ (SMS) ---
  Future<void> _sendSOSLocation() async {
    // 1. Lấy danh sách số điện thoại (Người thân + Bác sĩ)
    List<String> recipients = [];
    recipients.addAll(relatives.map((e) => e['phone']!));
    recipients.addAll(medicalContacts.map((e) => e['phone']!));

    if (recipients.isEmpty) {
      _showError('Chưa có liên hệ khẩn cấp nào để gửi tin nhắn.');
      return;
    }

    // 2. Hiển thị loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang lấy vị trí...'), duration: Duration(seconds: 1)),
    );

    // 3. Lấy tọa độ
    Position? position = await _determinePosition();
    if (position == null) return;

    // 4. Tạo link Google Maps
    String mapLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
    String message = "KHẨN CẤP! Tôi cần giúp đỡ ngay. Vị trí của tôi: $mapLink";

  }

  // --- 4. TÍNH NĂNG: TÌM BỆNH VIỆN GẦN ĐÂY ---
  Future<void> _findNearbyHospitals() async {
    // 1. Lấy vị trí hiện tại
    Position? position = await _determinePosition();
    if (position == null) return;

    // 2. Tạo URL tìm kiếm bệnh viện quanh vị trí đó
    // Query: "hospital"
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/hospital/@${position.latitude},${position.longitude},15z");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        _showError('Không thể mở bản đồ.');
      }
    } catch (e) {
      _showError('Lỗi: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _callPrimaryContact() {
    if (relatives.isNotEmpty) {
      _makePhoneCall(relatives[0]['phone']!);
    } else {
      _makePhoneCall('115');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[600],
        title: const Text('KHẨN CẤP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- NÚT GỌI CHÍNH ---
              _buildMainSOSButton(),

              const SizedBox(height: 20),

              // --- HAI NÚT TÍNH NĂNG MỚI (ROW) ---
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureButton(
                      label: 'Gửi Vị Trí\nKhẩn Cấp',
                      icon: Icons.send_to_mobile,
                      color: Colors.orange[800]!,
                      onTap: _sendSOSLocation,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildFeatureButton(
                      label: 'Tìm Bệnh Viện\nGần Nhất',
                      icon: Icons.local_hospital_outlined,
                      color: Colors.blue[700]!,
                      onTap: _findNearbyHospitals,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- CÁC DANH SÁCH CŨ ---
              _buildSectionTitle('NGƯỜI THÂN', Icons.family_restroom, Colors.blue[700]!),
              const SizedBox(height: 10),
              ...relatives.asMap().entries.map((entry) => _buildContactCard(
                  entry.value['name']!, entry.value['phone']!, Colors.blue, index: entry.key, isRelative: true)),
              _buildAddButton('Thêm người thân', () => _showAddContactDialog(true)),

              const SizedBox(height: 25),

              _buildSectionTitle('BÁC SĨ & Y TẾ', Icons.local_hospital, Colors.green[700]!),
              const SizedBox(height: 10),
              ...medicalContacts.asMap().entries.map((entry) => _buildContactCard(
                  entry.value['name']!, entry.value['phone']!, Colors.green, index: entry.key, isRelative: false)),
              _buildAddButton('Thêm bác sĩ', () => _showAddContactDialog(false)),

              const SizedBox(height: 25),
              _buildSectionTitle('SỐ KHẨN CẤP', Icons.emergency, Colors.orange[800]!),
              const SizedBox(height: 10),
              _buildEmergencyCard('113', 'CẢNH SÁT', Icons.local_police, Colors.blue[700]!),
              _buildEmergencyCard('114', 'CỨU HỎA', Icons.local_fire_department, Colors.orange[700]!),
              _buildEmergencyCard('115', 'CẤP CỨU', Icons.medical_services, Colors.red[600]!),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS MỚI & CŨ ---

  Widget _buildMainSOSButton() {
    return GestureDetector(
      onTap: _callPrimaryContact,
      child: Container(
        width: double.infinity,
        height: 200, // Thu nhỏ một chút để nhường chỗ cho nút mới
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_in_talk, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'GỌI KHẨN CẤP',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              relatives.isNotEmpty ? 'Gọi: ${relatives[0]['name']}' : 'Gọi: 115',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho nút tính năng mới
  Widget _buildFeatureButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- (GIỮ NGUYÊN CÁC WIDGET CŨ NHƯ: _buildSectionTitle, _buildContactCard, v.v...) ---
  // Để code gọn, tôi giả định bạn giữ nguyên các hàm UI cũ ở dưới đây.
  // Nếu cần tôi chép lại toàn bộ, hãy báo nhé.

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildContactCard(String name, String phone, Color color,
      {required int index, required bool isRelative}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Text(name[0], style: TextStyle(color: color))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(phone, style: TextStyle(color: Colors.grey[600])),
          ])),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () => _makePhoneCall(phone),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () => _showContactOptions(index, isRelative),
          )
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(String number, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _makePhoneCall(number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(number, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
      ),
    );
  }

  // --- LOGIC DIALOG CŨ (GIỮ NGUYÊN) ---
  void _showContactOptions(int index, bool isRelative) {
    // ... Code cũ ...
    // Để demo chạy được, tôi viết rút gọn logic xóa ở đây
    showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Xóa'), onTap: (){
        setState(() {
          if(isRelative) relatives.removeAt(index); else medicalContacts.removeAt(index);
        });
        Navigator.pop(ctx);
      })
    ]));
  }

  void _showAddContactDialog(bool isRelative) {
    // ... Code cũ ...
    // Logic thêm người dùng (bạn copy lại logic cũ vào đây nhé)
  }
}