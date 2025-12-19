import 'package:flutter/material.dart';
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/constants/font_size_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chatbot/screens/voice_chat_screen.dart';
import '../login/auth_service.dart';
import '../profile/update_profile.dart';
import '../profile/profile_api_service.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Về Nhớ App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌿 Nhớ App - Người Bạn Đồng Hành Sức Khỏe',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhớ App là ứng dụng chăm sóc sức khỏe toàn diện dành riêng cho người cao tuổi, được phát triển với sứ mệnh mang đến cuộc sống khỏe mạnh, hạnh phúc và an tâm cho thế hệ bạc đầu.',
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(' Tính năng nổi bật:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildFeatureItem(' Trợ lý AI thông minh hỗ trợ 24/7'),
              _buildFeatureItem(' Nhắc nhở uống thuốc và khám bệnh định kỳ'),
              _buildFeatureItem(' Nhật ký sức khỏe và tâm trạng hàng ngày'),
              _buildFeatureItem(' Trò chơi rèn luyện trí nhớ và tư duy'),
              _buildFeatureItem(' Kho kiến thức sức khỏe đa dạng'),
              _buildFeatureItem(' Luyện tập thể dục với AI nhận diện tư thế'),
              const SizedBox(height: 16),
              Text(
                'Phiên bản: $_appVersion',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '© 2024-2025 Nhớ App Team',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Made with in Vietnam',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Điều khoản sử dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cập nhật lần cuối: 19/12/2025',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildTermSection(
                '1. Chấp nhận điều khoản',
                'Bằng việc tải xuống, cài đặt và sử dụng Nhớ App, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu trong tài liệu này. Nếu không đồng ý, vui lòng không sử dụng ứng dụng.',
              ),
              _buildTermSection(
                '2. Mục đích sử dụng',
                'Nhớ App được thiết kế để hỗ trợ người cao tuổi trong việc:\n• Quản lý sức khỏe và nhắc nhở uống thuốc\n• Ghi nhật ký tâm trạng và hoạt động hàng ngày\n• Trò chuyện với trợ lý AI về các vấn đề sức khỏe cơ bản\n• Luyện tập trí nhớ và thể chất\n\nỨng dụng KHÔNG THAY THẾ tư vấn y tế chuyên nghiệp, chẩn đoán hoặc điều trị bệnh.',
              ),
              _buildTermSection(
                '3. Trách nhiệm người dùng',
                '• Cung cấp thông tin chính xác khi đăng ký\n• Bảo mật tài khoản và không chia sẻ mật khẩu\n• Sử dụng ứng dụng đúng mục đích và hợp pháp\n• Không lạm dụng các tính năng AI hoặc tải lên nội dung vi phạm pháp luật\n• Tham khảo ý kiến bác sĩ trước khi đưa ra quyết định về sức khỏe',
              ),
              _buildTermSection(
                '4. Quyền sở hữu trí tuệ',
                'Tất cả nội dung, mã nguồn, thiết kế giao diện, logo và tài liệu trong Nhớ App thuộc quyền sở hữu của Nhớ App Team. Người dùng không được sao chép, phân phối hoặc sử dụng cho mục đích thương mại mà không có sự cho phép bằng văn bản.',
              ),
              _buildTermSection(
                '5. Giới hạn trách nhiệm',
                '• Nhớ App không chịu trách nhiệm về các quyết định y tế dựa trên thông tin từ ứng dụng\n• Không đảm bảo ứng dụng hoạt động không bị gián đoạn hoặc lỗi\n• Không chịu trách nhiệm về thiệt hại gián tiếp, ngẫu nhiên hoặc hệ quả phát sinh từ việc sử dụng ứng dụng',
              ),
              _buildTermSection(
                '6. Thay đổi điều khoản',
                'Chúng tôi có quyền cập nhật điều khoản sử dụng bất cứ lúc nào. Người dùng sẽ được thông báo qua ứng dụng về các thay đổi quan trọng. Việc tiếp tục sử dụng sau khi có thay đổi đồng nghĩa với việc chấp nhận điều khoản mới.',
              ),
              _buildTermSection(
                '7. Chấm dứt dịch vụ',
                'Chúng tôi có quyền tạm ngưng hoặc chấm dứt tài khoản của người dùng nếu phát hiện hành vi vi phạm điều khoản sử dụng hoặc pháp luật hiện hành.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chính sách bảo mật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Có hiệu lực từ: 19/12/2025',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhớ App cam kết bảo vệ quyền riêng tư và thông tin cá nhân của người dùng. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ dữ liệu của bạn.',
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildTermSection(
                '1. Thông tin chúng tôi thu thập',
                'Thông tin cá nhân:\n• Họ tên, ngày sinh, giới tính\n• Số điện thoại, email, địa chỉ\n• Ảnh đại diện (tùy chọn)\n\nThông tin sức khỏe:\n• Nhật ký sức khỏe, tâm trạng\n• Lịch uống thuốc và khám bệnh\n• Lịch sử chat với trợ lý AI\n\nThông tin kỹ thuật:\n• Loại thiết bị, phiên bản hệ điều hành\n• Địa chỉ IP, nhật ký truy cập\n• Thông tin vị trí (khi bật tính năng)',
              ),
              _buildTermSection(
                '2. Mục đích sử dụng thông tin',
                '• Cung cấp và cải thiện các tính năng của ứng dụng\n• Cá nhân hóa trải nghiệm người dùng\n• Gửi nhắc nhở và thông báo quan trọng\n• Phân tích và thống kê sử dụng ứng dụng\n• Hỗ trợ khách hàng và xử lý yêu cầu\n• Nghiên cứu và phát triển tính năng mới',
              ),
              _buildTermSection(
                '3. Bảo vệ thông tin',
                'Chúng tôi áp dụng các biện pháp bảo mật tiên tiến:\n\n Mã hóa dữ liệu:\n• Mã hóa end-to-end cho thông tin nhạy cảm\n• SSL/TLS cho mọi kết nối mạng\n\n🛡️ Kiểm soát truy cập:\n• Xác thực JWT Token\n• Phân quyền người dùng chặt chẽ\n\n💾 Lưu trữ an toàn:\n• Máy chủ được bảo vệ và sao lưu định kỳ\n• Tuân thủ các tiêu chuẩn bảo mật quốc tế',
              ),
              _buildTermSection(
                '4. Chia sẻ thông tin',
                'Chúng tôi KHÔNG bán hoặc cho thuê thông tin cá nhân của bạn.\n\nThông tin có thể được chia sẻ trong các trường hợp:\n• Khi có sự đồng ý rõ ràng từ người dùng\n• Với các nhà cung cấp dịch vụ (Google AI, server hosting) để vận hành ứng dụng\n• Khi pháp luật yêu cầu hoặc để bảo vệ quyền lợi hợp pháp',
              ),
              _buildTermSection(
                '5. Quyền của người dùng',
                'Bạn có quyền:\n• Truy cập và xem thông tin cá nhân\n• Yêu cầu chỉnh sửa hoặc cập nhật thông tin\n• Xóa tài khoản và dữ liệu liên quan\n• Rút lại sự đồng ý xử lý dữ liệu\n• Khiếu nại về việc xử lý thông tin cá nhân\n\nĐể thực hiện các quyền này, vui lòng liên hệ: privacy@nhoapp.com',
              ),
              _buildTermSection(
                '6. Cookie và công nghệ theo dõi',
                'Ứng dụng sử dụng cookie và công nghệ tương tự để:\n• Ghi nhớ phiên đăng nhập\n• Lưu trữ cài đặt người dùng\n• Phân tích hành vi sử dụng\n\nBạn có thể quản lý cookie trong cài đặt ứng dụng.',
              ),
              _buildTermSection(
                '7. Thời gian lưu trữ dữ liệu',
                '• Dữ liệu tài khoản: Cho đến khi bạn xóa tài khoản\n• Nhật ký hoạt động: 12 tháng\n• Lịch sử chat: Cho đến khi bạn xóa\n• Dữ liệu sao lưu: 30 ngày',
              ),
              _buildTermSection(
                '8. Thay đổi chính sách',
                'Chúng tôi có thể cập nhật chính sách bảo mật để phản ánh thay đổi trong thực tiễn hoặc yêu cầu pháp lý. Bạn sẽ được thông báo về các thay đổi quan trọng qua email hoặc thông báo trong ứng dụng.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu hỏi về bảo mật?',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                          ),
                          const Text(
                            'Liên hệ: privacy@nhoapp.com',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQCategory(' Bắt đầu sử dụng'),
              _buildFAQItem(
                'Làm thế nào để tạo tài khoản?',
                'Mở ứng dụng → Chọn "Đăng ký" → Điền thông tin (họ tên, số điện thoại, mật khẩu) → Xác nhận OTP → Hoàn tất!',
              ),
              _buildFAQItem(
                'Tôi quên mật khẩu thì làm sao?',
                'Tại màn hình đăng nhập → Chọn "Quên mật khẩu" → Nhập số điện thoại đã đăng ký → Nhận mã OTP → Tạo mật khẩu mới.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Trợ lý AI'),
              _buildFAQItem(
                'Làm thế nào để chat với trợ lý AI?',
                'Ở trang chủ → Nhấn vào biểu tượng "Trợ lý chat" → Bắt đầu trò chuyện bằng giọng nói hoặc gõ văn bản. Trợ lý sẽ trả lời các câu hỏi về sức khỏe, thuốc men và đời sống.',
              ),
              _buildFAQItem(
                'AI có thể làm gì?',
                '• Tư vấn sức khỏe cơ bản\n• Giải đáp thắc mắc về thuốc\n• Hỗ trợ tâm lý, trò chuyện\n• Gợi ý bài tập thể dục phù hợp\n• Nhắc nhở chăm sóc sức khỏe\n\n⚠️ Lưu ý: AI không thay thế bác sĩ!',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Nhắc nhở uống thuốc'),
              _buildFAQItem(
                'Cách đặt nhắc nhở uống thuốc?',
                'Trang chủ → "Nhắc nhở" → Nút "+" → Nhập thông tin thuốc (tên, liều lượng, giờ uống) → Chọn lịch lặp lại → Lưu. Ứng dụng sẽ thông báo đúng giờ!',
              ),
              _buildFAQItem(
                'Tôi không nghe thấy thông báo?',
                'Kiểm tra: Cài đặt → Thông báo (bật) → Âm thanh (bật) → Cài đặt điện thoại → Cho phép thông báo từ Nhớ App.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Nhật ký sức khỏe'),
              _buildFAQItem(
                'Nhật ký để làm gì?',
                'Ghi lại tâm trạng, triệu chứng, hoạt động hàng ngày để:\n• Theo dõi sức khỏe qua thời gian\n• Chia sẻ với bác sĩ khi khám\n• AI phân tích và đưa ra lời khuyên',
              ),
              _buildFAQItem(
                'Cách ghi nhật ký?',
                'Trang chủ → "Nhật ký" → Nút "+" → Chọn loại (sức khỏe/tâm trạng/ăn uống) → Viết nội dung → Thêm ảnh (tùy chọn) → Lưu.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Trò chơi trí nhớ'),
              _buildFAQItem(
                'Trò chơi có tác dụng gì?',
                'Giúp rèn luyện:\n• Trí nhớ ngắn hạn và dài hạn\n• Khả năng tập trung\n• Tư duy logic\n• Phản xạ\n\nChơi 15-20 phút mỗi ngày để não bộ luôn khỏe mạnh!',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Luyện tập thể dục'),
              _buildFAQItem(
                'AI nhận diện tư thế hoạt động thế nào?',
                'Bật camera → Chọn bài tập → AI sẽ theo dõi chuyển động qua camera và cho điểm tư thế. Đảm bảo đủ ánh sáng và đứng cách camera 1.5-2m.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Bảo mật & Quyền riêng tư'),
              _buildFAQItem(
                'Dữ liệu của tôi có an toàn không?',
                'Có! Chúng tôi:\n• Mã hóa tất cả dữ liệu nhạy cảm\n• Không chia sẻ thông tin với bên thứ ba\n• Lưu trữ trên máy chủ bảo mật\n• Tuân thủ luật bảo vệ dữ liệu cá nhân',
              ),
              _buildFAQItem(
                'Cách xóa tài khoản?',
                'Cài đặt → Tài khoản → Xóa tài khoản → Xác nhận. Tất cả dữ liệu sẽ bị xóa vĩnh viễn và không thể khôi phục.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Chi phí'),
              _buildFAQItem(
                'Ứng dụng có miễn phí không?',
                'Có! Nhớ App hoàn toàn MIỄN PHÍ, không có phí ẩn. Tất cả tính năng đều sẵn sàng cho người dùng.',
              ),
              const SizedBox(height: 16),
              _buildFAQCategory(' Hỗ trợ kỹ thuật'),
              _buildFAQItem(
                'Ứng dụng bị lỗi, tôi phải làm gì?',
                '1. Tắt và mở lại ứng dụng\n2. Kiểm tra kết nối Internet\n3. Cập nhật phiên bản mới nhất\n4. Xóa bộ nhớ cache: Cài đặt điện thoại → Ứng dụng → Nhớ App → Xóa cache\n5. Nếu vẫn lỗi: Liên hệ support@nhoapp.com',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.contact_support, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Không tìm thấy câu trả lời?\nLiên hệ: support@nhoapp.com\nHotline: 1900-1234',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Liên hệ hỗ trợ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chúng tôi luôn sẵn sàng hỗ trợ bạn!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildContactItem(Icons.phone_in_talk, 'Hotline (Miễn phí)', '0965816163', '24/7 - Tất cả các ngày'),
              const Divider(height: 24),
              _buildContactItem(Icons.email, 'Email hỗ trợ', 'doanngocchungk5@gmail.com', 'Phản hồi trong 24h'),
              const Divider(height: 24),
              _buildContactItem(Icons.bug_report, 'Báo lỗi', 'doanngocchungk5@gmail.com', 'Ưu tiên xử lý nhanh'),
              const Divider(height: 24),
              _buildContactItem(Icons.privacy_tip, 'Bảo mật & Quyền riêng tư', 'doanngocchungk5@gmail.com', 'Liên hệ về dữ liệu cá nhân'),
              const Divider(height: 24),
              _buildContactItem(Icons.language, 'Website', 'www.nhoapp.com', 'Tin tức và tài liệu'),
              const Divider(height: 24),
              _buildContactItem(Icons.facebook, 'Facebook', 'fb.com/NhoApp', 'Cộng đồng người dùng'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Văn phòng',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RIPT - PTIT\n'
                      '122 Hoàng Quốc Việt, Hà Nội\n'
                      'Việt Nam',
                      style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giờ làm việc: 8:00 - 17:30 (T2-T6)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, [String? subtitle]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
