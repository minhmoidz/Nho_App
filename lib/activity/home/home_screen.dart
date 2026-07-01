import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhoapp/activity/home/reminder/reminder_screen.dart';
import 'package:nhoapp/activity/home/diary/create_diary_screen.dart';
import 'package:nhoapp/activity/home/sos/sos_screen.dart';
import 'package:nhoapp/constants/app_colors.dart';
import '../chatbot/screens/voice_chat_screen.dart';
import '../knowledge/screen/knowledge_screen.dart';
import '../login/auth_service.dart';
import '../notification/notifications_page.dart';
import '../profile/profile_screen.dart';
import '../game/screen/brain_training_screen.dart';
import '../testing/new.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_top_bar.dart';
import 'health/health_diary_screen.dart';
import 'memory/memory_screen.dart';
import 'ocr_screen/ocr_screen.dart';
import 'prescription/prescription_list_screen.dart';
import 'prescription/prescription_model.dart';
import 'prescription/prescription_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  final AuthService _authService = AuthService();
  String _userName = 'Ông Minh';
  String _userInitials = 'OM';
  bool _isLoadingProfile = true;
  List<Prescription> _prescriptions = [];
  bool _isLoadingPrescriptions = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prescriptions = await PrescriptionStorage.getPrescriptions();
    if (mounted) {
      setState(() {
        _prescriptions = prescriptions;
        _isLoadingPrescriptions = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await _authService.getToken();
      if (token != null && mounted) {
        setState(() {
          _userName = 'Ông Minh';
          _userInitials = 'OM';
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _onBottomNavTap(int index) => setState(() => _tabIndex = index);
  void _goToProfileFromAvatar() => setState(() => _tabIndex = 3);
  void _goToNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! ';
    if (hour < 18) return 'Chào buổi chiều! ';
    return 'Chào buổi tối! ';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdayNames = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    return '${weekdayNames[now.weekday % 7]}, ${DateFormat('dd/MM/yyyy').format(now)}';
  }

  void _showSOSConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Gọi khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        content: const Text('Bạn có muốn gọi cho người thân khẩn cấp không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SOSPage()));
            },
            child: const Text('Gọi ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(
              appName: 'An Tâm App',
              userName: _userName,
              onAvatarTap: _goToProfileFromAvatar,
              onNotificationTap: _goToNotifications,
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildHomeTab(),
                  KnowledgeScreen(),
                  BrainTrainingScreen(),
                  UserProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _tabIndex,
        onItemSelected: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HERO SECTION =====
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${_getGreeting()}$_userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getCurrentDate(),
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== NÚT GỌI KHẨN CẤP =====
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSOSConfirmationDialog(context),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.phone_in_talk_rounded, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Gọi khẩn cấp',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== TỦ THUỐC =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tủ thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionListScreen()));
                    _loadPrescriptions();
                  },
                  child: const Row(
                    children: [
                      Text('Xem tất cả', style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF3B82F6), size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card tủ thuốc
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: _isLoadingPrescriptions
                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                : _prescriptions.isEmpty
                    ? Column(children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: Icon(Icons.medication_outlined, size: 36, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 14),
                        Text('Chưa có thuốc nào trong tủ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionListScreen()));
                            _loadPrescriptions();
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('Thêm thuốc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 4,
                            shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                          ),
                        ),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.medication, color: Color(0xFF3B82F6), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Đang có ${_prescriptions.length} loại thuốc', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 3),
                            Text('Mới nhất: ${_prescriptions.first.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ])),
                        ]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionListScreen()));
                              _loadPrescriptions();
                            },
                            icon: const Icon(Icons.folder_special, color: Colors.white, size: 18),
                            label: const Text('Mở tủ thuốc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 4,
                              shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                            ),
                          ),
                        ),
                      ]),
          ),

          const SizedBox(height: 24),

          // ===== TRỢ LÝ AI =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Tính năng AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onBottomNavTap(2),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.support_agent_rounded, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Trợ lý Sức khỏe AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Hỏi đáp y tế, dinh dưỡng & sức khỏe', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  ]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== CÔNG CỤ HỖ TRỢ =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Công cụ hỗ trợ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildToolCard(icon: Icons.camera_alt_rounded, label: 'Đọc chữ\ntừ ảnh', color: const Color(0xFF8B5CF6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScreen()))),
                _buildToolCard(icon: Icons.book_rounded, label: 'Nhật ký\ntừ ảnh', color: const Color(0xFFF59E0B), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDiaryScreen()))),
                _buildToolCard(icon: Icons.medication_outlined, label: 'Tủ thuốc', color: const Color(0xFF3B82F6), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionListScreen())); _loadPrescriptions(); }),
                _buildToolCard(icon: Icons.notifications_active_rounded, label: 'Nhắc\nnhở', color: const Color(0xFF10B981), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()))),
                _buildToolCard(icon: Icons.favorite_rounded, label: 'Sức khỏe\nhàng ngày', color: const Color(0xFFEF4444), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen()))),
                _buildToolCard(icon: Icons.photo_library_rounded, label: 'Kỷ niệm\ncủa tôi', color: const Color(0xFFEC4899), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryPage()))),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildToolCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700, height: 1.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}