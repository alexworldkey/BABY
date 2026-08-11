import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/fruit_model.dart';
import '../services/audio_service.dart';
import '../services/fruit_data.dart';
import '../theme/app_theme.dart';
import '../widgets/fruit_card.dart';
import '../widgets/parent_gate.dart';
import 'fruit_detail_sheet.dart';
import 'where_is_game_screen.dart';

/// 水果卡片网格主页（home_screen.dart）
///
/// 布局：2x2 大网格（幼儿小手精准点击）
/// 顶部：互动小游戏 🎮 入口 + 家长入口（长按 3 秒）
/// 交互：点卡片 → 弹跳动画 → 播发音 → 弹详情弹窗
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 防止点击过快导致动画/语音叠加（幼儿连点保护）
  bool _busy = false;

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  /// 卡片点击：弹跳动画已在卡片内，这里负责语音 + 弹窗
  Future<void> _onFruitTap(FruitModel fruit) async {
    if (_busy) return; // 连点保护
    _busy = true;
    try {
      // 1. 播放英文发音
      await AudioService.instance.playFruitVoice(fruit.id);
      // 2. 弹出详情弹窗（内含 [再听一遍] / [小手试读]）
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FruitDetailSheet(fruit: fruit),
      );
    } finally {
      _busy = false;
    }
  }

  /// 家长入口：长按 3 秒 → 算术验证 → 进入设置
  Future<void> _openParentArea() async {
    // 长按已由 ParentGateButton 处理，这里做二次算术验证
    final ok = await showParentGateDialog(context);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('家长模式：这里后续可放音量/发音人设置'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              // ============ 顶部栏 ============
              const SizedBox(height: 10),
              Row(
                children: [
                  // 顶部悬浮"互动小游戏"入口
                  Expanded(
                    child: _GameEntryButton(
                      onTap: () {
                        AudioService.instance.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WhereIsGameScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  // 家长入口（长按 3 秒）
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: ParentGateButton(onUnlocked: _openParentArea),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ============ 标题 ============
              const Text(
                '🍎 水果英语',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '点一点水果，听一听英文！',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.inkLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // ============ 2x2 水果大网格 ============
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 2 列网格，间距 16，每卡撑满剩余空间
                    final cardHeight = (constraints.maxHeight - 16) / 2;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        // 固定每行高度，保证卡片撑满剩余空间
                        mainAxisExtent: cardHeight,
                      ),
                      itemCount: FruitData.all.length,
                      itemBuilder: (context, index) {
                        final fruit = FruitData.all[index];
                        return FruitCard(
                          fruit: fruit,
                          onTap: () => _onFruitTap(fruit),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部"互动小游戏"入口按钮（大号、显眼、幼儿可点）
class _GameEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GameEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.skyBlue.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports, color: AppTheme.ink, size: 28),
              SizedBox(width: 10),
              Text(
                '互动小游戏 🎮',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        // 入场晃动动画：让入口更活泼（flutter_animate 的 shake 扩展）
        .animate()
        .shake(duration: 600.ms, delay: 300.ms);
  }
}
