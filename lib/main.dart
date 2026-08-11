import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// 宝宝英语启蒙 App 入口
///
/// 当前版本：第一核心栏目【水果英文认知 Fruit Cognition】
/// - 水果卡片网格主页（2x2 大网格）
/// - 水果详情弹窗（再听一遍 / 小手试读跟读识别）
/// - "Where is...?" 听音辨图小游戏
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabyEnglishApp());
}

class BabyEnglishApp extends StatelessWidget {
  const BabyEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '水果英语',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
