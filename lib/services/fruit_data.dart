import 'package:flutter/material.dart';
import '../models/fruit_model.dart';

/// 模拟数据服务（fruit_data.dart）
///
/// 预置 4 种基础水果。新增水果只需在这里加一行：
/// ```dart
/// FruitModel(
///   id: 'grape',                    // 文件名前缀，图片/音频都用它
///   englishName: 'Grape',           // 英文名
///   chineseName: '葡萄',            // 中文名
///   imagePath: 'assets/images/fruits/grape.png', // 需真实放入
///   audioPath: 'assets/audio/fruits/grape.mp3',  // 需真实放入
///   fallbackColor: Colors.purple,   // 素材缺失时的回退底色
///   fallbackIcon: Icons.circle,     // 素材缺失时的回退图标
/// )
/// ```
/// 后续可从 JSON 配置 / 云端下发动态扩展，保持模型不变即可。
class FruitData {
  /// 全部水果（当前 4 种基础款）
  static const List<FruitModel> all = [
    FruitModel(
      id: 'apple',
      englishName: 'Apple',
      chineseName: '苹果',
      imagePath: 'assets/images/fruits/apple.png',
      audioPath: 'assets/audio/fruits/apple.mp3',
      fallbackColor: Color(0xFFFF6B6B), // 暖红
      fallbackIcon: Icons.apple,
    ),
    FruitModel(
      id: 'lemon',
      englishName: 'Lemon',
      chineseName: '柠檬',
      imagePath: 'assets/images/fruits/lemon.png',
      audioPath: 'assets/audio/fruits/lemon.mp3',
      fallbackColor: Color(0xFFFFD93D), // 柠檬黄
      fallbackIcon: Icons.wb_sunny, // 圆形+黄色，贴近柠檬
    ),
    FruitModel(
      id: 'orange',
      englishName: 'Orange',
      chineseName: '橙子',
      imagePath: 'assets/images/fruits/orange.png',
      audioPath: 'assets/audio/fruits/orange.mp3',
      fallbackColor: Color(0xFFFFA500), // 橙色
      fallbackIcon: Icons.circle, // 圆形示意
    ),
    FruitModel(
      id: 'strawberry',
      englishName: 'Strawberry',
      chineseName: '草莓',
      imagePath: 'assets/images/fruits/strawberry.png',
      audioPath: 'assets/audio/fruits/strawberry.mp3',
      fallbackColor: Color(0xFFFF8FB1), // 柔粉
      fallbackIcon: Icons.favorite, // 心形示意草莓
    ),
  ];

  /// 按 id 查找水果；找不到时返回 null（调用方需处理）
  static FruitModel? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
