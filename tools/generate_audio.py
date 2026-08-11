# -*- coding: utf-8 -*-
"""
生成宝宝英语启蒙 App 所需全部音频 MP3（edge-tts 微软神经语音）

生成内容：
1. assets/audio/fruits/  —— 4 个水果英文发音
2. assets/audio/praise/  —— 3 个夸奖/鼓励配音
3. assets/audio/game/    —— 4 个 "Where is..." 提问语音

语音选择：en-US-AnaNeural（童声，最适合 3 岁幼儿英语启蒙）
可替换候选：
  - en-US-AriaNeural  清晰女声
  - en-US-JennyNeural 温柔女声
  - en-US-GuyNeural   男声
"""

import asyncio
import os
import edge_tts

# 输出根目录（项目 assets）
BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

VOICE = "en-US-AnaNeural"  # 童声版
RATE = "-5%"               # 语速：幼儿可适当调慢，如 -10%

# (输出相对路径, 朗读文本)
JOBS = [
    # ---------- 水果发音 assets/audio/fruits/ ----------
    ("audio/fruits/apple.mp3", "Apple"),
    ("audio/fruits/lemon.mp3", "Lemon"),
    ("audio/fruits/orange.mp3", "Orange"),
    ("audio/fruits/strawberry.mp3", "Strawberry"),
    # ---------- 夸奖/鼓励 assets/audio/praise/ ----------
    ("audio/praise/great_job.mp3", "Great job! Well done!"),
    ("audio/praise/nice_try.mp3", "Nice try! Let's say it together."),
    ("audio/praise/try_again.mp3", "Try again! You can do it!"),
    # ---------- 游戏提问 assets/audio/game/ ----------
    ("audio/game/apple_where.mp3", "Where is the apple?"),
    ("audio/game/lemon_where.mp3", "Where is the lemon?"),
    ("audio/game/orange_where.mp3", "Where is the orange?"),
    ("audio/game/strawberry_where.mp3", "Where is the strawberry?"),
]


async def gen_one(rel_path: str, text: str) -> None:
    """生成单个 mp3"""
    out = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    try:
        comm = edge_tts.Communicate(text, VOICE, rate=RATE)
        await comm.save(out)
        size = os.path.getsize(out)
        print(f"  [OK] {rel_path}  ({size} bytes)  <- {text!r}")
    except Exception as e:  # noqa: BLE001
        print(f"  [FAIL] {rel_path}  <- {text!r}  error={e}")


async def main() -> None:
    print(f"Voice: {VOICE}  Rate: {RATE}")
    print(f"Output base: {BASE}\n")
    # 逐个生成，避免并发被限流
    for rel, text in JOBS:
        await gen_one(rel, text)
    print("\nAll done.")


if __name__ == "__main__":
    asyncio.run(main())
