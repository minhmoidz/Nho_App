import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'activity/home/home_screen.dart';
import 'activity/home/reminder/AlarmScreen.dart';
import 'activity/home/reminder/notification_helper.dart';
import 'activity/login/login_page.dart';
import 'activity/login/register_page.dart';
import 'activity/settings/settings_screen.dart';
import 'constants/font_size_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nhoapp/widgets/splash_screen.dart';
import 'package:nhoapp/activity/onboarding/onboarding_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Khóa màn hình dọc (tùy chọn, thường app mobile hay dùng)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();

  // Khởi tạo thông báo & TTS
  await NotificationHelper.init();

  // Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => FontSizeProvider(),
      child: const MyApp(),
    ),
  );
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
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return MaterialApp(
          // Gắn key vào đây để điều khiển điều hướng toàn cục
          navigatorKey: navigatorKey,

          title: 'Nhớ App',
          debugShowCheckedModeBanner: false,

          // Áp dụng text scale factor toàn app
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(fontProvider.scaleFactor),
              ),
              child: child!,
            );
          },

          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            fontFamily: 'Montserrat',
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
          home: const SplashScreen(),

          // Định nghĩa các route cơ bản
          routes: {
            '/login': (context) => const LoginPage(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}


