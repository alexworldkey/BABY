import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 家长关卡（parent_gate.dart）
///
/// 防误触设计：设置/退出入口需要**持续按住 3 秒**才会弹开。
/// 幼儿小手乱点不会触发；只有家长刻意长按 3 秒才能进入。
///
/// 用法：
/// ```dart
/// ParentGateButton(
///   onUnlocked: () { Navigator.push(... 设置页); },
/// )
/// ```
class ParentGateButton extends StatefulWidget {
  final VoidCallback onUnlocked;

  const ParentGateButton({super.key, required this.onUnlocked});

  @override
  State<ParentGateButton> createState() => _ParentGateButtonState();
}

class _ParentGateButtonState extends State<ParentGateButton> {
  /// 持续按住 3 秒的计时器
  Timer? _holdTimer;

  void _startHold() {
    _holdTimer?.cancel();
    // 3 秒后触发回调（中途抬手会被取消）
    _holdTimer = Timer(const Duration(seconds: 3), _onHoldComplete);
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _onHoldComplete() {
    // 计时触发后清空防止 dispose 后再次调用
    _holdTimer = null;
    widget.onUnlocked();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '家长入口（长按三秒）',
      button: true,
      child: GestureDetector(
        // 按下启动 3 秒计时，松开/取消则放弃
        onLongPressStart: (_) => _startHold(),
        onLongPressEnd: (_) => _cancelHold(),
        onLongPressCancel: _cancelHold,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.inkLight.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline,
            color: AppTheme.inkLight,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// 家长验证弹窗：确认进入设置
///
/// 为避免幼儿误触已解锁的弹窗，再补一道"家长算术题"：
/// 3 岁幼儿做不出加法，只有家长能通过。
///
/// 返回 true 表示验证通过。
Future<bool> showParentGateDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _ParentDialog(),
  );
  return confirmed == true;
}

class _ParentDialog extends StatefulWidget {
  const _ParentDialog();

  @override
  State<_ParentDialog> createState() => _ParentDialogState();
}

class _ParentDialogState extends State<_ParentDialog> {
  final TextEditingController _answer = TextEditingController();
  static const int _a = 3, _b = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        '👨‍👩‍👧 家长验证',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('为避免宝宝误触，请回答一道算术题：'),
          const SizedBox(height: 14),
          // 注：_a/_b 是 static const，所以字符串插值在编译期是常量，可以 const Text
          const Text(
            '$_a + $_b = ?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _answer,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '输入答案',
              filled: true,
              fillColor: AppTheme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final ok = int.tryParse(_answer.text.trim()) == _a + _b;
            Navigator.pop(context, ok);
          },
          child: const Text('进入'),
        ),
      ],
    );
  }
}
