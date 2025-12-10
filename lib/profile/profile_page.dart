import 'package:flutter/material.dart';
import '../login/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // --- MOCK DATA ---
  final Map<String, dynamic> _fakeUser = {
    "full_name": "Nguyễn Văn A",
    "username": "nguyenvana",
    "email": "nguyenvana@gmail.com",
    "phone": "+84 987 654 321",
    "gender": "Nam",
    "dob": "01/01/1995",
    "address": "Tòa nhà Bitexco, Q1, TP.HCM",
    "role": "Senior Member",
    "avatar_url": "https://ui-avatars.com/api/?name=Nguyen+Van+A&background=0D47A1&color=fff&size=150&bold=true",
  };

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn kết thúc phiên làm việc?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Hủy", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              setState(() => _isLoading = true);
              await _authService.logout();
              if (mounted) {
                setState(() => _isLoading = false);
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo: Xanh Navy đậm (Professional Blue)
    const primaryColor = Color(0xFF1565C0);
    const secondaryColor = Color(0xFFF3F4F6); // Xám rất nhạt cho nền

    return Scaffold(
      backgroundColor: secondaryColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER CÁCH ĐIỆU ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Nền Gradient phía trên
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D47A1), // Xanh đậm
                        Color(0xFF1976D2), // Xanh sáng hơn
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [

                      ],
                    ),
                  ),
                ),

                // Avatar & Info Card nằm đè lên nền xanh
                Positioned(
                  top: 100,
                  child: Column(
                    children: [
                      // Avatar có viền trắng
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(_fakeUser['avatar_url']),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fakeUser['full_name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B), // Màu than chì đậm
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          _fakeUser['role'],
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Khoảng trống để bù cho phần Stack overlap
            const SizedBox(height: 120),

            // --- PHẦN THÔNG TIN CHI TIẾT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Thông tin liên hệ"),
                  _buildModernInfoContainer([
                    _buildProfileItem(Icons.email_rounded, "Email", _fakeUser['email']),
                    _buildDivider(),
                    _buildProfileItem(Icons.phone_rounded, "Số điện thoại", _fakeUser['phone']),
                    _buildDivider(),
                    _buildProfileItem(Icons.location_on_rounded, "Địa chỉ", _fakeUser['address']),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader("Thông tin cơ bản"),
                  _buildModernInfoContainer([
                    _buildProfileItem(Icons.person_rounded, "Giới tính", _fakeUser['gender']),
                    _buildDivider(),
                    _buildProfileItem(Icons.cake_rounded, "Ngày sinh", _fakeUser['dob']),
                    _buildDivider(),
                    _buildProfileItem(Icons.fingerprint_rounded, "Username", _fakeUser['username']),
                  ]),

                  const SizedBox(height: 40),

                  // Nút Đăng xuất
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade700,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded),
                          SizedBox(width: 10),
                          Text(
                            "Đăng xuất",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS CON GIÚP UI SẠCH HƠN ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B), // Màu xám xanh chuyên nghiệp
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernInfoContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Nền xanh siêu nhạt
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22), // Xanh Royal Blue
          ),
          const SizedBox(width: 16),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E293B), // Màu đen dịu
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 76, // Thụt vào để thẳng hàng với text
    );
  }
}