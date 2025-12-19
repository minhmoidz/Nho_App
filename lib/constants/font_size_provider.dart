import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  double _scaleFactor = 1.0;
  int _fontSizeIndex = 1;
  
  final List<String> fontSizeLabels = ['Nhỏ', 'Vừa', 'Lớn', 'Rất lớn'];
  final List<double> fontSizeValues = [0.85, 1.0, 1.15, 1.3];

  double get scaleFactor => _scaleFactor;
  int get fontSizeIndex => _fontSizeIndex;

  FontSizeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeIndex = prefs.getInt('font_size_index') ?? 1;
    _scaleFactor = prefs.getDouble('font_scale_factor') ?? 1.0;
    notifyListeners();
  }

  Future<void> setFontSize(int index) async {
    if (index < 0 || index >= fontSizeValues.length) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('font_size_index', index);
    await prefs.setDouble('font_scale_factor', fontSizeValues[index]);
    
    _fontSizeIndex = index;
    _scaleFactor = fontSizeValues[index];
    notifyListeners();
  }

  /// Tính fontSize dựa trên base size và scale factor
  double scaledFontSize(double baseSize) {
    return baseSize * _scaleFactor;
  }
  
  /// TextStyle với fontSize đã scale
  TextStyle scaledTextStyle({
    double fontSize = 14,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize * _scaleFactor,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontFamily: fontFamily,
    );
  }
}

/// Extension để dễ dàng scale font size
extension FontSizeExtension on double {
  double scaled(FontSizeProvider provider) => this * provider.scaleFactor;
}
