import 'package:speech_to_text/speech_to_text.dart';

/// 语音识别服务（speech_service.dart）
///
/// 封装 speech_to_text，用于幼儿跟读识别。
/// 设计原则：
/// - 全程温和：任何失败都不抛异常、不显示错误，由调用方播放鼓励语音；
/// - 宽容匹配：识别文本转小写后，只要"包含"目标单词即判定通过
///   （幼儿发音模糊，比如 "appo"、"a pple" 都可能被系统识别成近似词）。
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();

  bool _initialized = false;

  /// 初始化识别引擎（首次使用会请求麦克风权限）
  ///
  /// 返回 true 表示可用。任何失败（无权限 / 无识别引擎）
  /// 都温和返回 false，绝不抛出异常。
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _stt.initialize(
        onStatus: (status) {
          // 状态变化回调：'listening' / 'done' / 'notListening'
        },
        onError: (error) {
          // 识别错误回调：如 'error_no_match'，这里静默处理，
          // 由超时逻辑统一给出温柔提示
        },
      );
      return _initialized;
    } catch (_) {
      return false;
    }
  }

  /// 开始监听幼儿跟读
  ///
  /// [onPartial] 实时回调：每次识别到部分词就调用，
  /// 用于实现"说到一半就判定成功"的即时反馈。
  /// [onFinal] 结束回调：本段监听自然结束后调用。
  /// 注意：由于幼儿语速和识别引擎特性，主要依赖 onPartial 做宽容匹配。
  Future<void> listen({
    required void Function(String recognizedText) onPartial,
    required void Function() onFinal,
  }) async {
    if (!_initialized) return;
    try {
      await _stt.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          if (result.finalResult) {
            onFinal();
          } else {
            onPartial(text);
          }
        },
        // speech_to_text 7.x 通过 SpeechListenOptions 传参（旧的顶层参数已弃用）：
        // - localeId：固定英语识别，避免中英混识
        // - listenMode.dictation：连续听写模式，适合短句跟读
        // - partialResults: true：实时返回部分结果（宽容匹配依赖）
        // - cancelOnError: false：识别出错不自动停止，留给超时逻辑统一处理
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      // 静默失败，交给调用方的超时逻辑统一处理
    }
  }

  /// 停止监听（判定成功 / 超时后调用）
  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}
