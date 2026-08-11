import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/fruit_model.dart';
import '../services/asset_guard.dart';
import '../theme/app_theme.dart';

/// 水果大卡片（fruit_card.dart）
///
/// 幼儿 UI 规范：
/// - 圆角 24
/// - 触控区域 ≥ 100x100dp（Grid 内实际约 150x150+）
/// - 点击弹跳缩放动画（flutter_animate）
/// - 素材缺失时自动回退为大图标 + 文字（AssetGuard）
class FruitCard extends StatefulWidget {
  final FruitModel fruit;
  final VoidCallback onTap;

  const FruitCard({
    super.key,
    required this.fruit,
    required this.onTap,
  });

  @override
  State<FruitCard> createState() => _FruitCardState();
}

class _FruitCardState extends State<FruitCard>
    with SingleTickerProviderStateMixin {
  /// 是否已探测过素材存在性（避免每次重建都异步探测）
  bool? _imageExists;

  /// 弹跳动画控制器（flutter_animate 推荐用法：
  /// 外部持有 AnimationController，点击时 forward(from: 0) 重播）
  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    // 总时长 = 第一段 120ms + 第二段 220ms
    duration: const Duration(milliseconds: 340),
  );

  @override
  void initState() {
    super.initState();
    // 首次构建时异步探测图片是否存在，决定回退策略
    AssetGuard.exists(widget.fruit.imagePath).then((ok) {
      if (mounted) setState(() => _imageExists = ok);
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  /// 点击处理：重播弹跳动画 + 触发外部回调（语音/弹窗）
  void _handleTap() {
    _bounceCtrl.forward(from: 0); // 从 0 重新播放，实现"每点必弹"
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.fruit.chineseName} ${widget.fruit.englishName}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(24),
          child: Animate(
            // 手动控制模式：autoPlay 关闭，由 _bounceCtrl 驱动
            controller: _bounceCtrl,
            autoPlay: false,
            effects: const [
              // 注意：effects 列表内的多个效果是【同时播放】的，
              // 用 delay 错开形成"先缩小 → 再弹性弹回"的串联节奏
              ScaleEffect(
                begin: Offset(1, 1),
                end: Offset(0.92, 0.92),
                duration: Duration(milliseconds: 120),
                curve: Curves.easeOut,
              ),
              ScaleEffect(
                begin: Offset(0.92, 0.92),
                end: Offset(1, 1),
                duration: Duration(milliseconds: 220),
                curve: Curves.elasticOut,
                // 延迟 120ms：等第一段缩小结束后再弹回
                delay: Duration(milliseconds: 120),
              ),
            ],
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// 根据素材探测结果构建卡片内容
  Widget _buildContent() {
    final f = widget.fruit;
    final showImage = _imageExists == true;

    return Container(
      width: double.infinity,
      // 确保最小触控区域 ≥ 100x100 dp（Grid 会进一步撑大）
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: showImage ? Colors.white : f.fallbackColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: f.fallbackColor.withOpacity(0.55),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: f.fallbackColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---- 图片区：素材存在显示大图；缺失回退大图标 ----
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: showImage
                  ? Image.asset(
                      f.imagePath,
                      fit: BoxFit.contain,
                      // 图片加载失败也不崩溃，降级为图标
                      errorBuilder: (_, __, ___) => _fallbackIcon(f),
                    )
                  : _fallbackIcon(f),
            ),
          ),
          // ---- 文字区：英文大字 + 中文小字 ----
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  f.englishName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  f.chineseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 素材缺失回退图标
  Widget _fallbackIcon(FruitModel f) {
    return Icon(
      f.fallbackIcon,
      size: 76,
      color: f.fallbackColor,
    );
  }
}
