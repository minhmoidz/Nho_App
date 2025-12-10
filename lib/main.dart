import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORT CÁC FILE CỦA BẠN ---
import 'home/home_page.dart';
import 'home/reminder/AlarmScreen.dart';
import 'home/reminder/notification_helper.dart';
import 'login/auth_service.dart';
import 'login/login_page.dart';
import 'login/register_page.dart';

// [MỚI] Tạo Key toàn cục để điều hướng từ notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa màn hình dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo thông báo & TTS
  await NotificationHelper.init();

  // Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
}

// [THAY ĐỔI] Chuyển MyApp thành StatefulWidget để lắng nghe thông báo
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // [MỚI] LẮNG NGHE SỰ KIỆN TỪ NOTIFICATION HELPER
    // Khi đến giờ hẹn, NotificationHelper sẽ đẩy dữ liệu vào stream này
    NotificationHelper.onNotificationClick.stream.listen((payload) {
      if (payload != null) {
        // Dùng navigatorKey để đẩy màn hình AlarmScreen đè lên tất cả
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AlarmScreen(payload: payload),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // [MỚI] Gắn key vào đây
      navigatorKey: navigatorKey,

      title: 'Nhớ App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Hỗ trợ tiếng Việt
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],

      // Màn hình khởi động
      home: const AuthCheck(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/keycloak-login': (context) => const KeycloakLoginPlaceholder(),
      },
    );
  }
}

// --- GIỮ NGUYÊN PHẦN CÒN LẠI (AuthCheck, Placeholder...) ---

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userId = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _isLoggedIn = userId != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _isLoggedIn ? const HomePage() : const LoginPage();
  }
}

class KeycloakLoginPlaceholder extends StatelessWidget {
  const KeycloakLoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Keycloak')),
      body: Center(
        child: Column(
          children: [
            const Icon(Icons.build_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Chức năng đang phát triển'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}