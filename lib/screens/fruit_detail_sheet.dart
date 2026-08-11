import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/fruit_model.dart';
import '../services/asset_guard.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';

/// 水果详情弹窗（fruit_detail_sheet.dart）
///
/// 展示大图 + 英文单词 + 两个大按钮：
/// - [再听一遍 🔊]：重播发音
/// - [小手试读 🎤]：启动语音识别跟读，成功触发彩带庆祝
///
/// 核心交互流程（跟读）：
/// 1. 点击试读 → 初始化麦克风 → 显示脉冲波纹
/// 2. 宽容匹配：识别文本转小写，只要包含该水果单词即成功
/// 3. 成功：停止监听 → confetti 满屏彩带 + 夸奖配音 → 2 秒后自动关闭返回主页
/// 4. 超时/未识别（4 秒）：温和播放 "Nice try! Let's say it together: Apple!"
///    —— 绝不显示错误提示、绝不惩罚
class FruitDetailSheet extends StatefulWidget {
  final FruitModel fruit;

  const FruitDetailSheet({super.key, required this.fruit});

  @override
  State<FruitDetailSheet> createState() => _FruitDetailSheetState();
}

class _FruitDetailSheetState extends State<FruitDetailSheet> {
  final AudioService _audio = AudioService.instance;
  final SpeechService _speech = SpeechService.instance;

  /// 彩带控制器：答对/跟读成功时 play()
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  /// 跟读状态机
  bool _listening = false; // 是否正在监听
  bool _speechOk = false; // 是否识别成功（成功后禁止再点）
  bool _imageExists = false; // 图片素材是否存在

  /// 跟读超时计时器（4 秒）
  Timer? _listenTimer;

  /// 识别成功后 2 秒自动关闭的计时器
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    // 探测图片素材，决定展示大图还是回退图标
    AssetGuard.exists(widget.fruit.imagePath).then((ok) {
      if (mounted) setState(() => _imageExists = ok);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _listenTimer?.cancel();
    _closeTimer?.cancel();
    _speech.stop();
    _audio.stop();
    super.dispose();
  }

  // ==================== 跟读核心逻辑 ====================

  /// 点击 [小手试读 🎤]
  Future<void> _startReading() async {
    if (_listening || _speechOk) return;

    // 1. 初始化语音识别（自动请求麦克风权限）
    final ok = await _speech.initialize();
    if (!ok || !mounted) {
      // 初始化失败：温和提示，请家长检查麦克风权限，绝不显示错误
      _showSoftTip('先听一听，然后我们再说！🎧');
      return;
    }

    setState(() => _listening = true);

    // 2. 启动 4 秒超时计时：到时未识别 → 温和提示
    _listenTimer?.cancel();
    _listenTimer = Timer(const Duration(seconds: 4), _onTimeout);

    // 3. 开始监听
    await _speech.listen(
      // 宽容匹配：识别文本转小写，只要包含该单词即通过
      onPartial: (text) {
        final lower = text.toLowerCase();
        if (lower.contains(widget.fruit.matchKey)) {
          _onSuccess();
        }
      },
      onFinal: () {
        // 自然结束（未命中）：交给超时逻辑，避免重复提示
      },
    );
  }

  /// 跟读超时（4 秒未识别 / 未说清）
  void _onTimeout() {
    if (!mounted || _speechOk) return;
    _speech.stop();
    setState(() => _listening = false);
    // 温和提示 + 一起读一遍（素材缺失时静默降级）
    _audio.playNiceTry();
    _showSoftTip("Nice try! Let's say it together: ${widget.fruit.englishName}!");
    // 提示后自动重播正确发音，帮助幼儿建立声音记忆
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _audio.playFruitVoice(widget.fruit.id);
    });
  }

  /// 识别成功：停止监听 → 彩带 → 夸奖 → 2 秒后关闭返回主页
  void _onSuccess() {
    if (_speechOk) return; // 防止重复触发
    _speechOk = true;
    _listenTimer?.cancel();
    _closeTimer?.cancel();
    _speech.stop();
    setState(() {
      _listening = false;
      _speechOk = true;
    });
    // 满屏彩带爆星庆祝
    _confetti.play();
    // 夸奖配音
    _audio.playPraise();
    _showSoftTip('Great job! 🎉');
    // 2 秒后自动关闭弹窗返回主页
    _closeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// 温和提示气泡（非错误提示）
  void _showSoftTip(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 18)),
          backgroundColor: AppTheme.mintGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final f = widget.fruit;
    return Container(
      // 圆角大卡片弹窗
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        // 底部避开手势条
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---- 拖动把手 ----
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.inkLight.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              // ---- 大图区（缺失回退图标） ----
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: f.fallbackColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: _imageExists
                    ? Image.asset(
                        f.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _bigIcon(f),
                      )
                    : _bigIcon(f),
              ),
              const SizedBox(height: 14),
              // ---- 英文大字 ----
              Text(
                f.englishName,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                f.chineseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkLight,
                ),
              ),
              const SizedBox(height: 18),
              // ---- 两个大按钮 ----
              Row(
                children: [
                  // [再听一遍 🔊]
                  Expanded(
                    child: _BigButton(
                      icon: Icons.volume_up,
                      label: '再听一遍',
                      color: AppTheme.skyBlue,
                      onTap: () => _audio.playFruitVoice(f.id),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // [小手试读 🎤]（跟读中变波纹状态）
                  Expanded(
                    child: _BigButton(
                      icon: Icons.mic,
                      label: _listening ? '正在听…' : '小手试读',
                      color: AppTheme.softPink,
                      onTap: _startReading,
                      // 跟读中显示脉冲波纹动画代替文字
                      // （child 必须放最前最后一个位置）
                      child: _listening ? const _PulseWave() : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
          // ---- 彩带层（跟读成功/答对时全屏庆祝） ----
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.9,
                emissionFrequency: 0.08,
                numberOfParticles: 40,
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
    );
  }

  Widget _bigIcon(FruitModel f) {
    return Icon(f.fallbackIcon, size: 110, color: f.fallbackColor);
  }
}

/// 大号圆角按钮（幼儿专用：≥100dp 高、圆角 24、超大字）
class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// 可选：替换默认文字内容（跟读时显示波纹）
  final Widget? child;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 92,
          alignment: Alignment.center,
          child: child ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 34, color: AppTheme.ink),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// 脉冲波纹动画（监听麦克风时的呼吸波纹）
class _PulseWave extends StatefulWidget {
  const _PulseWave();

  @override
  State<_PulseWave> createState() => _PulseWaveState();
}

class _PulseWaveState extends State<_PulseWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(v, 0.5),
            _dot(v, 1.0),
            _dot(v, 0.5),
          ],
        );
      },
    );
  }

  Widget _dot(double v, double scaleFactor) {
    return Container(
      width: 14 * (0.6 + 0.4 * v * scaleFactor),
      height: 14 * (0.6 + 0.4 * v * scaleFactor),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}
