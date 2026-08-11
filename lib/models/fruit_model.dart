import 'package:flutter/material.dart';

/// 水果数据模型
///
/// 设计要点：
/// 1. 纯数据类，不依赖 Flutter 渲染逻辑，方便后续接入 JSON 配置或数据库；
/// 2. 每个字段都有明确的 asset 路径约定，素材缺失时由
///    [AssetGuard]（见 services/asset_guard.dart）负责回退；
/// 3. [fallbackColor] / [fallbackIcon] 用于素材缺失时的回退显示，
///    保证卡片永远有鲜亮外观、应用绝不崩溃。
class FruitModel {
  /// 唯一标识，同时是图片/音频的文件名（如 apple）
  final String id;

  /// 英文名（首字母大写，用于展示与跟读匹配）
  final String englishName;

  /// 中文名
  final String chineseName;

  /// 图片路径：assets/images/fruits/{id}.png
  final String imagePath;

  /// 发音路径：assets/audio/fruits/{id}.mp3
  final String audioPath;

  /// 素材缺失时的回退底色（鲜艳糖果色）
  final Color fallbackColor;

  /// 素材缺失时的回退图标（幼儿友好的大图标）
  final IconData fallbackIcon;

  const FruitModel({
    required this.id,
    required this.englishName,
    required this.chineseName,
    required this.imagePath,
    required this.audioPath,
    required this.fallbackColor,
    required this.fallbackIcon,
  });

  /// 小写英文名，跟读匹配时统一转小写再比较
  String get matchKey => englishName.toLowerCase();
}
