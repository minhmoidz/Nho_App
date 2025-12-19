import 'package:flutter/material.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/constants/font_size_provider.dart';
import 'package:nhoapp/widgets/app_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chatbot/screens/voice_chat_screen.dart';
import '../login/auth_service.dart';
import '../profile/update_profile.dart';
import '../profile/profile_api_service.dart';
import 'dialog/about_dialog.dart';
import 'dialog/terms_dialog.dart';
import 'dialog/privacy_dialog.dart';
import 'dialog/faq_dialog.dart';
import 'dialog/contact_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  
  bool _notificationEnabled = true;
  bool _soundEnabled = true;
  bool _isLoading = false;
  String _appVersion = '';
  
  // Font size settings
  int _fontSizeIndex = 1; // 0: Nhỏ, 1: Vừa, 2: Lớn, 3: Rất lớn
  final List<String> _fontSizeLabels = ['Nhỏ', 'Vừa', 'Lớn', 'Rất lớn'];
  final List<double> _fontSizeValues = [0.85, 1.0, 1.15, 1.3];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _fontSizeIndex = prefs.getInt('font_size_index') ?? 1;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
    setState(() => _notificationEnabled = value);
  }

  Future<void> _saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _saveFontSizeSetting(int index) async {
    // Cập nhật Provider để áp dụng toàn app
    final fontProvider = Provider.of<FontSizeProvider>(context, listen: false);
    await fontProvider.setFontSize(index);
    setState(() => _fontSizeIndex = index);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển cỡ chữ sang "${_fontSizeLabels[index]}"'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFontSizeDialog() {
    int tempIndex = _fontSizeIndex;
    final fontProvider = Provider.of<FontSizeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final sampleSize = 16.0 * _fontSizeValues[tempIndex];
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.text_fields, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Cỡ chữ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kéo thanh trượt để chọn cỡ chữ phù hợp:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Preview text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _fontSizeLabels[tempIndex],
                        style: TextStyle(
                          fontSize: sampleSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ví dụ văn bản mẫu',
                        style: TextStyle(
                          fontSize: sampleSize * 0.9,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Slider with labels
                Row(
                  children: [
                    Icon(Icons.text_fields, size: 18, color: Colors.grey[600]),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                          tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
                          activeTickMarkColor: Colors.white,
                          inactiveTickMarkColor: AppColors.primary.withOpacity(0.4),
                          valueIndicatorColor: AppColors.primary,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: tempIndex.toDouble(),
                          min: 0,
                          max: (_fontSizeLabels.length - 1).toDouble(),
                          divisions: _fontSizeLabels.length - 1,
                          label: _fontSizeLabels[tempIndex],
                          onChanged: (value) {
                            setDialogState(() {
                              tempIndex = value.round();
                            });
                          },
                        ),
                      ),
                    ),
                    Icon(Icons.text_fields, size: 28, color: AppColors.primary),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Labels under slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nhỏ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Vừa', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Lớn', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Rất lớn', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveFontSizeSetting(tempIndex);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Áp dụng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Hủy", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: NhoAppBar(title: "Cài đặt"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Tài khoản'),
                  _buildSettingsCard([
                    _buildNavigationItem(
                      icon: Icons.person_outline,
                      title: 'Chỉnh sửa hồ sơ',
                      onTap: () async {
                        final profile = await ProfileApiService.getProfile();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateProfileScreen(user: profile),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.lock_outline,
                      title: 'Đổi mật khẩu',
                      onTap: () => _showChangePasswordDialog(),
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.notifications_outlined,
                      title: 'Thông báo',
                      value: _notificationEnabled,
                      onChanged: _saveNotificationSetting,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.volume_up_outlined,
                      title: 'Âm thanh',
                      value: _soundEnabled,
                      onChanged: _saveSoundSetting,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Hiển thị'),
                  _buildSettingsCard([
                    _buildFontSizeItem(),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Trợ lý AI'),
                  _buildSettingsCard([
                    _buildNavigationItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Lịch sử trò chuyện',
                      onTap: () => _goToChatHistory(),
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.delete_outline,
                      title: 'Xóa lịch sử chat',
                      titleColor: Colors.orange,
                      onTap: () => _showClearChatHistoryDialog(),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Ứng dụng'),
                  _buildSettingsCard([
                    _buildNavigationItem(
                      icon: Icons.info_outline,
                      title: 'Về chúng tôi',
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.description_outlined,
                      title: 'Điều khoản sử dụng',
                      onTap: () => _showTermsDialog(),
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Chính sách bảo mật',
                      onTap: () => _showPrivacyDialog(),
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.help_outline,
                      title: 'Câu hỏi thường gặp',
                      onTap: () => _showFAQDialog(),
                    ),
                    _buildDivider(),
                    _buildNavigationItem(
                      icon: Icons.mail_outline,
                      title: 'Liên hệ hỗ trợ',
                      onTap: () => _showContactDialog(),
                    ),
                    _buildDivider(),
                    _buildVersionItem(),
                  ]),

                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.secondary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.smartphone, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Phiên bản ứng dụng',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            'v$_appVersion',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeItem() {
    return InkWell(
      onTap: _showFontSizeDialog,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.text_fields, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cỡ chữ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _fontSizeLabels[_fontSizeIndex],
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fontSizeLabels[_fontSizeIndex],
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.grey[200]);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng đang phát triển'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _goToChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? conversationId = prefs.getString('LAST_CHAT_ID');
    
    if (conversationId == null || conversationId.isEmpty) {
      conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('LAST_CHAT_ID', conversationId);
    }
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(conversationId: conversationId!),
      ),
    );
  }

  void _showClearChatHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa lịch sử chat'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('LAST_CHAT_ID');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa lịch sử chat'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AboutDialogWidget(),
    );
  }


  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const TermsDialogWidget(),
    );
  }


  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const PrivacyDialogWidget(),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const FAQDialogWidget(),
    );
  }



  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ContactDialogWidget(),
    );
  }

}
