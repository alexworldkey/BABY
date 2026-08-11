import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import 'asset_guard.dart';

/// 音频服务（audio_service.dart）
///
/// 统一封装 audioplayers，职责：
/// 1. 播放水果发音 / 夸奖配音 / 游戏提问语音；
/// 2. 素材缺失时自动回退为系统"叮"提示音，绝不崩溃、绝不静默失败。
///
/// 【素材替换说明】
/// - 水果发音：assets/audio/fruits/{id}.mp3（如 apple.mp3）
/// - 夸奖配音：assets/audio/praise/{name}.mp3
///   已预留：great_job.mp3（答对）、nice_try.mp3（没听清时的温柔提示）、
///   try_again.mp3（点错重试）、where_is.mp3 由代码动态拼接，可不放
/// - 游戏提问：assets/audio/game/{id}_where.mp3（如 apple_where.mp3）
class AudioService {
  AudioService._() {
    // 短音效场景：播放结束后保持 stop 状态，方便快速重播
    // （release 模式在部分 Android 设备上重播前需重新 setSource，可能延迟）
    _player.setReleaseMode(ReleaseMode.stop);
  }

  /// 全局单例（App 生命周期内复用同一个播放器）
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// 播放水果英文发音（如 assets/audio/fruits/apple.mp3）
  ///
  /// [fruitId] 对应 FruitModel.id。
  /// 文件缺失时自动回退系统提示音。
  Future<void> playFruitVoice(String fruitId) {
    return _playWithFallback('assets/audio/fruits/$fruitId.mp3');
  }

  /// 播放夸奖配音（答对 / 跟读成功）
  Future<void> playPraise() {
    return _playWithFallback('assets/audio/praise/great_job.mp3');
  }

  /// 播放"没听清，一起读一遍"的温柔提示音
  Future<void> playNiceTry() {
    return _playWithFallback('assets/audio/praise/nice_try.mp3');
  }

  /// 播放"再试一次"提示音（听音辨图点错时）
  Future<void> playTryAgain() {
    return _playWithFallback('assets/audio/praise/try_again.mp3');
  }

  /// 播放游戏提问语音：Where is the Apple?
  ///
  /// [fruitId] 对应要问的水果。
  /// 若已放置 {fruitId}_where.mp3 则播放；
  /// 否则回退播放该水果的发音（App 仍可正常教学）。
  Future<void> playWhereIs(String fruitId) async {
    final wherePath = 'assets/audio/game/${fruitId}_where.mp3';
    if (await AssetGuard.exists(wherePath)) {
      await _player.stop();
      await _player.play(AssetSource('audio/game/${fruitId}_where.mp3'));
    } else {
      // 回退：直接播水果发音 + 系统提示音示意"提问"
      await SystemSound.play(SystemSoundType.alert);
      await playFruitVoice(fruitId);
    }
  }

  /// 核心播放方法：带缺失回退
  Future<void> _playWithFallback(String assetPath) async {
    // 从完整 asset 路径中截取相对路径（AssetSource 需要相对 assets/ 的路径）
    // 例如 'assets/audio/fruits/apple.mp3' -> 'audio/fruits/apple.mp3'
    final relative = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;

    if (await AssetGuard.exists(assetPath)) {
      try {
        await _player.stop(); // 停止上一段，避免叠加
        await _player.play(AssetSource(relative));
      } catch (_) {
        // 播放异常：回退系统提示音，不崩溃
        await SystemSound.play(SystemSoundType.alert);
      }
    } else {
      // 素材缺失：回退系统提示音
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// 停止当前播放（页面切换时调用，防止串音）
  Future<void> stop() => _player.stop();

  /// 释放资源（App 退出时）
  Future<void> dispose() => _player.dispose();
}
