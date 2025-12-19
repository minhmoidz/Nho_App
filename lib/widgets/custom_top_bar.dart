import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhoapp/constants/app_colors.dart';

class CustomTopBar extends StatefulWidget {
  final String appName;
  final String? userName;
  final String? avatarUrl;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback onNotificationTap;

  const CustomTopBar({
    super.key,
    this.appName = 'Nhớ App',
    this.userName,
    this.avatarUrl,
    this.notificationCount = 0,
    this.onAvatarTap,
    required this.onNotificationTap,
  });

  @override
  State<CustomTopBar> createState() => _CustomTopBarState();
}

class _CustomTopBarState extends State<CustomTopBar> {
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Row(
          children: [
            // --- INFO SECTION ---
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ],
                ).createShader(bounds),
                child: Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    height: 1.2,
                    fontFeatures: [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ),

            // --- ACTIONS GROUP ---
            Row(
              children: [
                // Notification button với glassmorphism effect
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onNotificationTap,
                      customBorder: const CircleBorder(),
                      splashColor: Colors.blue.withOpacity(0.2),
                      highlightColor: Colors.blue.withOpacity(0.1),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              widget.notificationCount > 0
                                  ? Icons.notifications
                                  : Icons.notifications_outlined,
                              size: 24,
                              color: const Color(0xFF1E293B),
                            ),
                            if (widget.notificationCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B6B),
                                        Color(0xFFEE5A6F),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    widget.notificationCount > 99
                                        ? '99+'
                                        : '${widget.notificationCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}