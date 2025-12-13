import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz; // Import timezone

// --- IMPORT CÁC FILE CỦA BẠN (Đảm bảo đường dẫn đúng) ---
import 'home/home_page.dart';
import 'home/reminder/AlarmScreen.dart'; // Màn hình đọc báo thức
import 'home/reminder/notification_helper.dart'; // Helper xử lý thông báo
import 'login/auth_service.dart';
import 'login/login_page.dart';
import 'login/register_page.dart';

// [QUAN TRỌNG] Key toàn cục để điều hướng từ bất kỳ đâu (kể cả từ background)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khóa màn hình dọc (Tránh vỡ giao diện)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Khởi tạo dữ liệu Múi giờ (Bắt buộc cho báo thức)
  tz.initializeTimeZones();

  // 3. Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // 4. Khởi tạo kênh Thông báo & TTS
  // Hàm này phải chạy xong trước khi runApp để đảm bảo kênh lắng nghe đã sẵn sàng
  await NotificationHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  // [LOGIC QUAN TRỌNG NHẤT]
  // Lắng nghe sự kiện click vào thông báo hoặc sự kiện Báo thức nổ (FullScreenIntent)
  void _setupNotificationListener() {
    NotificationHelper.onNotificationClick.stream.listen((payload) {
      if (payload != null && payload.isNotEmpty) {
        debugPrint("🚀 Main: Nhận được payload báo thức: $payload");

        // Sử dụng navigatorKey để đẩy màn hình AlarmScreen đè lên mọi thứ
        // Dùng addPostFrameCallback để đảm bảo UI đã vẽ xong trước khi push
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => AlarmScreen(payload: payload),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Gắn key vào đây để điều khiển điều hướng toàn cục
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

      // Cấu hình đa ngôn ngữ (Tiếng Việt)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],

      // Logic kiểm tra đăng nhập
      home: const AuthCheck(),

      // Định nghĩa các route cơ bản
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/keycloak-login': (context) => const KeycloakLoginPlaceholder(),
      },
    );
  }
}

// --- WIDGET KIỂM TRA ĐĂNG NHẬP (GIỮ NGUYÊN) ---
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
    // Kiểm tra token/userId trong SharedPreferences
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

// --- WIDGET PLACEHOLDER (GIỮ NGUYÊN) ---
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