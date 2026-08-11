import 'package:flutter/material.dart';

/// 儿童安全主题配色（app_theme.dart）
///
/// 设计规范：温暖、柔和且高对比度的儿童安全配色。
/// - 暖黄 / 薄荷绿 / 天空蓝 / 柔粉 作为场景主色
/// - 所有交互元素使用圆角 24、超大触控区域（≥100x100dp）
class AppTheme {
  // ---- 场景主色 ----
  static const Color warmYellow = Color(0xFFFFD93D); // 暖黄
  static const Color mintGreen = Color(0xFF7ED9A6); // 薄荷绿
  static const Color skyBlue = Color(0xFF6EC6FF); // 天空蓝
  static const Color softPink = Color(0xFFFFA3C8); // 柔粉
  static const Color coral = Color(0xFFFF8A65); // 珊瑚橙（强调色）

  // ---- 文字 ----
  static const Color ink = Color(0xFF2D3436); // 主文字（深灰，非纯黑更柔和）
  static const Color inkLight = Color(0xFF636E72); // 次要文字

  // ---- 背景 ----
  static const Color bg = Color(0xFFFFFBF0); // 奶油白底
  static const Color cardBg = Colors.white;

  /// 全局主题（Material 3）
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: coral,
      primary: coral,
      secondary: mintGreen,
      tertiary: skyBlue,
      surface: cardBg,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei'],
      textTheme: const TextTheme(
        // 超大标题：用于"请点一点苹果吧"等引导语
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        // 卡片英文名
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        // 按钮大字
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        // 正文
        bodyLarge: TextStyle(fontSize: 18, color: ink),
        bodyMedium: TextStyle(fontSize: 15, color: inkLight),
      ),
    );
  }
}
