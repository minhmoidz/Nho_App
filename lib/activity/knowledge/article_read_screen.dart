import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:gioapp/constants/app_colors.dart';

class ArticleReadScreen extends StatefulWidget {
  final String url;

  const ArticleReadScreen({super.key, required this.url});

  @override
  State<ArticleReadScreen> createState() => _ArticleReadScreenState();
}

class _ArticleReadScreenState extends State<ArticleReadScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // Biến để hiển thị vòng xoay khi đang tải trang

  @override
  void initState() {
    super.initState();

    // Cấu hình WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đọc báo", style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.secondary,
        actions: [
          // Nút tải lại trang nếu bị lỗi mạng
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. Nội dung trang web
          WebViewWidget(controller: _controller),

          // 2. Vòng xoay Loading (Hiện ra khi chưa tải xong)
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
        ],
      ),
    );
  }
}