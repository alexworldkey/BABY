# 宝宝英语启蒙 App（Baby English）

面向 3 岁幼儿的英语启蒙 Android 应用，当前版本实现第一个核心栏目：

**🍎 水果英文认知（Fruit Cognition）**

## 功能一览

| 模块 | 说明 |
|------|------|
| 水果卡片网格 | 2x2 大网格，点击弹跳动画 + 发音 + 详情弹窗 |
| 详情弹窗 | 大图 + 英文名 + [再听一遍 🔊] / [小手试读 🎤] |
| 跟读识别 | speech_to_text 宽容匹配，答对彩带庆祝，超时温和鼓励 |
| Where is 小游戏 | 听音辨图，点对彩带+夸奖，点错摇摆+鼓励 |
| 家长关卡 | 长按 3 秒 + 算术题双重防误触 |

## 快速开始

### 方式一：本地运行（需要 Flutter SDK ≥ 3.24）
```bash
# 1. 安装 Flutter：https://docs.flutter.dev/get-started/install
flutter doctor   # 确认 Android toolchain 就绪

# 2. 进入项目
cd BabyEnglishApp

# 3. 安装依赖
flutter pub get

# 4. 连接安卓手机（开启 USB 调试）或启动模拟器
flutter run

# 5. 打包 APK
flutter build apk --debug
```

### 方式二：GitHub Actions 自动编译（无需本地环境）
1. 把整个 `BabyEnglishApp` 文件夹推到 GitHub 仓库
2. 打开仓库 Actions 页面 → 选择 **构建宝宝英语启蒙 APK**
3. 运行完成后，在运行详情页底部 **Artifacts** 下载 `baby-english-debug-apk`
4. 把 APK 传到手机安装即可

## 素材替换指南（重要）

> App 内置**素材回退机制**：图片/音频缺失时自动显示图标和文字，**不会崩溃**。
> **音频素材已内置生成**（见下），图片素材未内置（缺失时自动显示大图标+文字）。

### ✅ 已内置：全部语音 MP3（edge-tts 生成）

以下音频已用微软神经语音（en-US-AnaNeural 童声）生成好，**无需再准备**：

| 分类 | 文件 | 内容 |
|------|------|------|
| 水果发音 | `assets/audio/fruits/{id}.mp3` ×4 | Apple / Lemon / Orange / Strawberry |
| 夸奖配音 | `assets/audio/praise/great_job.mp3` | "Great job! Well done!" |
| 鼓励配音 | `assets/audio/praise/nice_try.mp3` | "Nice try! Let's say it together." |
| 重试配音 | `assets/audio/praise/try_again.mp3` | "Try again! You can do it!" |
| 游戏提问 | `assets/audio/game/{id}_where.mp3` ×4 | "Where is the apple?" 等 |

想换语音/语速？改 `tools/generate_audio.py` 顶部的 `VOICE`（如 `en-US-AriaNeural` 清晰女声、`en-US-GuyNeural` 男声）和 `RATE`（如 `-10%` 放慢），然后运行：
```bash
python tools/generate_audio.py
```

### ✅ 已内置：全部图片素材（真实照片）

以下 4 张图片使用**真实水果照片**（已去除水印、统一 600×600），**无需再准备**：

| 水果 | 路径 | 说明 |
|------|------|------|
| 苹果 | `assets/images/fruits/apple.png` | 真实苹果照片 |
| 柠檬 | `assets/images/fruits/lemon.png` | 真实柠檬照片 |
| 橙子 | `assets/images/fruits/orange.png` | 真实橙子照片 |
| 草莓 | `assets/images/fruits/strawberry.png` | 真实草莓照片 |

如需换图：准备同名 `{id}.jpg` 后运行 `tools/process_real_images.py`（自动去水印+缩放+转 PNG）。

### 1. 水果图片（替换或新增）
| 文件 | 路径 | 推荐规格 |
|------|------|----------|
| 苹果 | `assets/images/fruits/apple.png` | 600×600方形 |
| 柠檬 | `assets/images/fruits/lemon.png` | 同上 |
| 橙子 | `assets/images/fruits/orange.png` | 同上 |
| 草莓 | `assets/images/fruits/strawberry.png` | 同上 |

要求：命名必须与水果 id 一致（`{id}.png`），透明或纯色背景均可。

### 2. 水果发音（AI 配音 MP3）

> ⚠️ 已内置：`apple/lemon/orange/strawberry.mp3` 均已生成（见上方表格）。
> 如对音色不满意，重新运行 `tools/generate_audio.py` 即可覆盖。

| 文件 | 路径 |
|------|------|
| 苹果 | `assets/audio/fruits/apple.mp3` |
| 柠檬 | `assets/audio/fruits/lemon.mp3` |
| 橙子 | `assets/audio/fruits/orange.mp3` |
| 草莓 | `assets/audio/fruits/strawberry.mp3` |

要求：清晰、缓慢、童声或标准美音，`.mp3` 格式，命名 `{id}.mp3`。

### 3. 夸奖 / 提示配音（可选，缺失自动用系统音效）

> ⚠️ 已内置：`great_job.mp3` / `nice_try.mp3` / `try_again.mp3` 均已生成。

| 场景 | 路径 |
|------|------|
| 答对夸奖 "Great job!" | `assets/audio/praise/great_job.mp3` |
| 没听清 "Nice try! Let's say it together" | `assets/audio/praise/nice_try.mp3` |
| 点错 "Try again!" | `assets/audio/praise/try_again.mp3` |

### 4. 游戏提问语音（可选，缺失自动回退水果发音）

> ⚠️ 已内置：4 个 `{id}_where.mp3` 均已生成。

| 场景 | 路径 |
|------|------|
| Where is the Apple? | `assets/audio/game/apple_where.mp3` |
| Where is the Lemon? | `assets/audio/game/lemon_where.mp3` |
| ... | 依次类推 |

## 新增水果（扩展教程）

打开 `lib/services/fruit_data.dart`，在 `all` 列表里加一行：

```dart
FruitModel(
  id: 'grape',                              // 文件名前缀
  englishName: 'Grape',                     // 英文名
  chineseName: '葡萄',                      // 中文名
  imagePath: 'assets/images/fruits/grape.png', // 放入图片
  audioPath: 'assets/audio/fruits/grape.mp3',  // 放入音频
  fallbackColor: Color(0xFF9B59B6),         // 素材缺失回退底色
  fallbackIcon: Icons.circle,               // 素材缺失回退图标
)
```

然后准备对应的 PNG/MP3 即可，网格和游戏会自动适配。

## Android 权限说明

`AndroidManifest.xml` 已配置：
- **`RECORD_AUDIO`**：跟读语音识别必需，首次点击 [小手试读] 时系统会弹授权框
- `INTERNET`：部分安卓设备系统语音引擎需要联网

> iOS 版如需支持，还需在 `Info.plist` 加 `NSMicrophoneUsageDescription`。

## 项目结构

```
lib/
├── main.dart                    # 入口
├── theme/app_theme.dart         # 儿童安全配色主题
├── models/fruit_model.dart      # 水果数据模型
├── services/
│   ├── fruit_data.dart          # 模拟数据服务（4 种水果）
│   ├── asset_guard.dart         # 素材存在性探测（回退机制核心）
│   ├── audio_service.dart       # 音频播放封装
│   └── speech_service.dart      # 语音识别封装
├── widgets/
│   ├── fruit_card.dart          # 水果大卡片（弹跳动画）
│   └── parent_gate.dart         # 家长关卡（长按 3 秒）
└── screens/
    ├── home_screen.dart         # 水果网格主页
    ├── fruit_detail_sheet.dart  # 详情弹窗（跟读核心）
    └── where_is_game_screen.dart# Where is 听音辨图游戏
```
