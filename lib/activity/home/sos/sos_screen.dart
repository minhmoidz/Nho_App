import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Thư viện gọi điện
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/app_bar.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  // Dữ liệu mẫu (sẽ mất khi tắt app, thực tế nên lưu vào database local)
  List<Map<String, String>> relatives = [
    {'name': 'Con trai cả', 'phone': '0912345678'},
    {'name': 'Con gái út', 'phone': '0987654321'},
  ];

  List<Map<String, String>> medicalContacts = [
    {'name': 'Bác sĩ Tâm', 'phone': '0909000111'},
    {'name': 'Phòng khám Đa khoa', 'phone': '0288123456'},
  ];

  // --- HÀM GỌI ĐIỆN QUAN TRỌNG ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Xóa khoảng trắng nếu có
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback: Một số máy Android đời mới có thể chặn query,
        // thử launch trực tiếp
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thực hiện cuộc gọi: $e')),
        );
      }
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
      appBar: const NhoAppBar(title: 'Khẩn cấp'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- NÚT SOS LỚN ---
              GestureDetector(
                onTap: _callPrimaryContact,
                child: Container(
                  width: double.infinity,
                  height: 240,
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_in_talk,
                          size: 80,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'GỌI KHẨN CẤP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        relatives.isNotEmpty
                            ? 'Gọi: ${relatives[0]['name']}'
                            : 'Gọi: Cấp cứu 115',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- NGƯỜI THÂN ---
              _buildSectionTitle('NGƯỜI THÂN', Icons.family_restroom, AppColors.primary),
              const SizedBox(height: 15),

              ...relatives.asMap().entries.map((entry) {
                return _buildContactCard(
                  entry.value['name']!,
                  entry.value['phone']!,
                  AppColors.primary,
                  index: entry.key,
                  isRelative: true,
                );
              }).toList(),

              _buildAddButton('Thêm người thân', () => _showAddContactDialog(true)),

              const SizedBox(height: 30),

              // --- BÁC SĨ / Y TẾ ---
              _buildSectionTitle('BÁC SĨ & PHÒNG KHÁM', Icons.local_hospital, AppColors.primary),
              const SizedBox(height: 15),

              ...medicalContacts.asMap().entries.map((entry) {
                return _buildContactCard(
                  entry.value['name']!,
                  entry.value['phone']!,
                  AppColors.primary,
                  index: entry.key,
                  isRelative: false,
                );
              }).toList(),

              _buildAddButton('Thêm bác sĩ/phòng khám', () => _showAddContactDialog(false)),

              const SizedBox(height: 30),

              // --- SỐ KHẨN CẤP ---
              _buildSectionTitle('SỐ KHẨN CẤP', Icons.emergency, AppColors.primary),
              const SizedBox(height: 15),

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

  // --- UI WIDGETS ---

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String name, String phone, Color color,
      {required int index, required bool isRelative}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar chữ cái
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Tên & SĐT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Nút gọi nhanh (Màu xanh lá) -> GỌI THẬT
          GestureDetector(
            onTap: () => _makePhoneCall(phone),
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Menu Sửa/Xóa
          GestureDetector(
            onTap: () => _showContactOptions(index, isRelative),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.transparent, // Tăng vùng bấm
              child: Icon(
                Icons.more_vert,
                color: Colors.grey[400],
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(String number, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _makePhoneCall(number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.touch_app, color: Colors.grey, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC DIALOG ---

  void _showContactOptions(int index, bool isRelative) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            _buildOptionButton('Chỉnh sửa', Icons.edit, AppColors.primary, () {
              Navigator.pop(context);
              _showEditContactDialog(index, isRelative);
            }),
            const SizedBox(height: 15),
            _buildOptionButton('Xóa liên hệ', Icons.delete, Colors.red, () {
              Navigator.pop(context);
              _confirmDelete(index, isRelative);
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index, bool isRelative) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa liên hệ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontSize: 18, color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isRelative) {
                  relatives.removeAt(index);
                } else {
                  medicalContacts.removeAt(index);
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa thành công')),
              );
            },
            child: const Text('XÓA', style: TextStyle(fontSize: 18, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(bool isRelative) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    _showInputForm(
      title: isRelative ? 'Thêm người thân' : 'Thêm bác sĩ/phòng khám',
      nameCtrl: nameCtrl,
      phoneCtrl: phoneCtrl,
      onSave: () {
        if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
          setState(() {
            final newContact = {'name': nameCtrl.text, 'phone': phoneCtrl.text};
            if (isRelative) {
              relatives.add(newContact);
            } else {
              medicalContacts.add(newContact);
            }
          });
          Navigator.pop(context);
        }
      },
    );
  }

  void _showEditContactDialog(int index, bool isRelative) {
    final contact = isRelative ? relatives[index] : medicalContacts[index];
    final nameCtrl = TextEditingController(text: contact['name']);
    final phoneCtrl = TextEditingController(text: contact['phone']);

    _showInputForm(
      title: 'Chỉnh sửa thông tin',
      nameCtrl: nameCtrl,
      phoneCtrl: phoneCtrl,
      onSave: () {
        if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
          setState(() {
            final updatedContact = {'name': nameCtrl.text, 'phone': phoneCtrl.text};
            if (isRelative) {
              relatives[index] = updatedContact;
            } else {
              medicalContacts[index] = updatedContact;
            }
          });
          Navigator.pop(context);
        }
      },
    );
  }

  void _showInputForm({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Tên gợi nhớ',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('HỦY', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('LƯU',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}