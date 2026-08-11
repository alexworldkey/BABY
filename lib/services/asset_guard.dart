import 'package:flutter/services.dart' show rootBundle;

/// 素材守卫（AssetGuard）
///
/// 核心职责：在渲染 / 播放前探测素材文件是否真实存在于打包资源中。
/// 因为 Flutter 的 asset 在打包前无法用 File 直接判断存在性，
/// 这里通过 rootBundle.load() 捕获异常的方式判断，保证：
/// - 图片缺失 → 卡片回退为大图标 + 文字（见 fruit_card.dart）
/// - 音频缺失 → 播放系统"叮"提示音，不崩溃（见 audio_service.dart）
///
/// 用法：await AssetGuard.exists('assets/images/fruits/apple.png')
class AssetGuard {
  /// 检查某个 asset 是否存在于应用资源中
  ///
  /// [path] 必须是 pubspec.yaml assets 声明过的路径。
  /// 返回 true 表示存在；false 表示缺失（会走回退逻辑）。
  static Future<bool> exists(String path) async {
    if (path.isEmpty) return false;
    try {
      // 尝试完整加载字节；只要没有抛异常，就说明资源存在
      final data = await rootBundle.load(path);
      return data.lengthInBytes > 0;
    } catch (_) {
      // 任何异常（找不到文件 / 路径未声明）都视为缺失
      return false;
    }
  }
}
