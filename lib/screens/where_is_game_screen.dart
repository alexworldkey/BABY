import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/fruit_model.dart';
import '../services/asset_guard.dart';
import '../services/audio_service.dart';
import '../services/fruit_data.dart';
import '../theme/app_theme.dart';

/// "Where is...?" 听音辨图小游戏（where_is_game_screen.dart）
///
/// 规则：
/// 1. 系统播放提问语音："Where is the Apple?"
/// 2. 屏幕随机展示 2~3 张大水果卡片（其中一张是目标）
/// 3. 点对 → 满屏彩带 + 夸奖配音 → 1 秒后自动下一题
/// 4. 点错 → 被点卡片左右摆动（Wiggle） + 温和提示 "Try again!"，不扣分
class WhereIsGameScreen extends StatefulWidget {
  const WhereIsGameScreen({super.key});

  @override
  State<WhereIsGameScreen> createState() => _WhereIsGameScreenState();
}

class _WhereIsGameScreenState extends State<WhereIsGameScreen> {
  final AudioService _audio = AudioService.instance;
  final Random _rng = Random();

  /// 彩带控制器（答对庆祝）
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  /// 当前题目：目标水果 + 干扰卡片
  late FruitModel _target;
  late List<FruitModel> _options;

  /// 答题状态
  bool _answered = false; // 本题是否已答对（答对后锁屏 1 秒）
  int _score = 0; // 答对数（简单计分，不给压力）

  /// 点错的卡片 id（用于触发 Wiggle 动画）
  String? _wiggleId;

  /// 下一题延迟计时器
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _nextTimer?.cancel();
    _audio.stop();
    super.dispose();
  }

  /// 生成新一题：随机目标 + 2~3 张卡片
  void _newRound() {
    const all = FruitData.all;
    // 随机选 2~3 张干扰卡（数量 2~3，加上目标共 3~4 张）
    final pool = List<FruitModel>.from(all);
    final targetIdx = _rng.nextInt(pool.length);
    final target = pool.removeAt(targetIdx);

    // 打乱剩余，取前 (2 或 3) 张
    pool.shuffle(_rng);
    final distractCount = 2 + _rng.nextInt(2); // 2 或 3
    final options = <FruitModel>[target, ...pool.take(distractCount)]..shuffle(_rng);

    setState(() {
      _target = target;
      _options = options;
      _answered = false;
      _wiggleId = null;
    });

    // 播放提问语音
    _ask();
  }

  /// 播放提问："Where is the Apple?"
  void _ask() {
    // 播放前先停掉上一段
    _audio.stop();
    // 延迟 300ms 让页面先渲染卡片，再提问（幼儿先看到图再听到问题）
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _audio.playWhereIs(_target.id);
    });
  }

  /// 点击卡片
  void _onCardTap(FruitModel fruit) {
    if (_answered) return; // 已答对，等待下一题

    if (fruit.id == _target.id) {
      // ============ 答对 ============
      _answered = true;
      setState(() => _score++);
      // 满屏彩带爆星
      _confetti.play();
      // 夸奖配音
      _audio.playPraise();
      // 1 秒后自动下一题
      _nextTimer?.cancel();
      _nextTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) _newRound();
      });
    } else {
      // ============ 点错：Wiggle + 温和提示，不扣分 ============
      setState(() => _wiggleId = fruit.id);
      _audio.playTryAgain();
      // 2 秒后清除摇摆状态，允许再点
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wiggleId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '哪里是…？ $_score ⭐',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  // ---- 提问文字（大字） ----
                  Animate(
                    key: ValueKey(_target.id), // 换题时重新播放入场动画
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 300)),
                      SlideEffect(
                        begin: Offset(0, -0.3),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                      ),
                    ],
                    child: Text(
                      'Where is the ${_target.englishName}?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.coral,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '👆 点一点正确的水果吧',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkLight,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // ---- 2x2 大卡片网格（4 张以内） ----
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final fruit = _options[index];
                        final isWiggle = _wiggleId == fruit.id;
                        return _GameCard(
                          fruit: fruit,
                          isWiggle: isWiggle,
                          onTap: () => _onCardTap(fruit),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // ---- 彩带层 ----
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.9,
                  emissionFrequency: 0.08,
                  numberOfParticles: 50,
                  gravity: 0.15,
                  shouldLoop: false,
                  colors: const [
                    AppTheme.coral,
                    AppTheme.warmYellow,
                    AppTheme.mintGreen,
                    AppTheme.skyBlue,
                    AppTheme.softPink,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 游戏卡片：答错时左右摇摆（Wiggle）
class _GameCard extends StatefulWidget {
  final FruitModel fruit;
  final bool isWiggle;
  final VoidCallback onTap;

  const _GameCard({
    required this.fruit,
    required this.isWiggle,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool? _imageExists;

  @override
  void initState() {
    super.initState();
    AssetGuard.exists(widget.fruit.imagePath).then((ok) {
      if (mounted) setState(() => _imageExists = ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fruit;
    final showImage = _imageExists == true;

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: showImage ? Colors.white : f.fallbackColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: f.fallbackColor.withValues(alpha: 0.55),
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: showImage
                      ? Image.asset(
                          f.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(f.fallbackIcon, size: 72, color: f.fallbackColor),
                        )
                      : Icon(f.fallbackIcon, size: 72, color: f.fallbackColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  f.englishName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 点错时左右摇摆动画（Wiggle）
    if (widget.isWiggle) {
      // 用正弦位移模拟左右摆动：v 从 0 到 1，sin(v*pi*4) 来回摆动 4 次
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
        builder: (context, v, child) {
          final dx = sin(v * pi * 4) * 14;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: card,
      );
    }

    return card;
  }
}
