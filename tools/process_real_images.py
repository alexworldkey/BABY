# -*- coding: utf-8 -*-
"""
处理用户提供的真实水果图片素材：
1. 裁掉左下角"灵光 AI 生成"水印（裁掉底部 100px）
2. 统一缩放到 600x600 灰色底画布（与 App 卡片风格匹配）
3. 转换为 PNG 格式
"""

import os
from PIL import Image

# 用户原图位置
SRC_DIR = r"D:\下载保存"
# 项目目标位置
DST_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "images", "fruits")

# 作物映射（jpg 源文件名 -> png 目标文件名，需与 fruit_data.dart 中 id 一致）
FILES = [
    ("apple.jpg",      "apple.png"),
    ("orange.jpg",     "orange.png"),
    ("lemon.jpg",      "lemon.png"),
    ("strawberry.jpg", "strawberry.png"),
]

# 裁掉底部 100px（彻底覆盖左下角水印）
BOTTOM_CROP = 100
# 目标尺寸
TARGET = 600
# 画布背景（App 卡片背景是白色/卡片背景是 fallbackColor）
# 这里用白色，因为白色背景能容纳任何浅色水果
BG_COLOR = (255, 255, 255)


def process_image(src_name: str, dst_name: str) -> None:
    src = os.path.join(SRC_DIR, src_name)
    dst = os.path.join(DST_DIR, dst_name)

    img = Image.open(src).convert("RGB")
    orig_size = img.size

    # 1. 裁掉底部水印
    w, h = img.size
    img = img.crop((0, 0, w, h - BOTTOM_CROP))

    # 2. 等比缩放到目标尺寸
    img.thumbnail((TARGET, TARGET), Image.LANCZOS)

    # 3. 居中放到 600x600 白底画布
    canvas = Image.new("RGB", (TARGET, TARGET), BG_COLOR)
    canvas.paste(img, ((TARGET - img.width) // 2, (TARGET - img.height) // 2))

    # 4. 删除旧 PNG（如果存在）
    if os.path.exists(dst):
        os.remove(dst)

    # 5. 优化保存为 PNG
    canvas.save(dst, "PNG", optimize=True)
    new_size = os.path.getsize(dst)
    print(f"  [OK] {src_name} ({orig_size[0]}x{orig_size[1]}, {os.path.getsize(src)} bytes)")
    print(f"    -> {dst_name} (600x600, {new_size} bytes)")


def main() -> None:
    print(f"Source: {SRC_DIR}")
    print(f"Dest:   {DST_DIR}\n")
    for src, dst in FILES:
        src_path = os.path.join(SRC_DIR, src)
        if not os.path.exists(src_path):
            print(f"  [SKIP] {src} not found")
            continue
        process_image(src, dst)
    print("\nDone.")


if __name__ == "__main__":
    main()
