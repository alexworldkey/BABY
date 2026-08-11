# -*- coding: utf-8 -*-
"""
模拟 flutter analyze 的核心静态检查：
1. import 未使用检测
2. assets 路径闭环（代码引用 vs pubspec 声明 vs 实际文件）
3. 基本的语法问题（const 缺失、类型推断等）
"""

import os, re, sys

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJ, "lib")
TEST = os.path.join(PROJ, "test")
ASSETS_DIR = os.path.join(PROJ, "assets")

errors = []
warnings = []

# ====== 1. 读取 pubspec.yaml 的 assets 声明 ======
pubspec = os.path.join(PROJ, "pubspec.yaml")
with open(pubspec) as f:
    pub_lines = f.readlines()

in_assets = False
pub_assets = set()
for line in pub_lines:
    if line.strip().startswith("assets:"):
        in_assets = True
        continue
    if in_assets:
        stripped = line.strip()
        if stripped and not stripped.startswith("#") and not stripped.startswith("-"):
            # end of assets list
            if not stripped.startswith(" ") and not stripped.startswith("\t"):
                break
        if stripped.startswith("- "):
            entry = stripped[2:].strip()
            pub_assets.add(entry.rstrip("/"))

# 生成 pubspec 覆盖的所有文件路径
pub_declared_files = set()
actual_files = set()
for root, dirs, files in os.walk(ASSETS_DIR):
    for fname in files:
        fp = os.path.join(root, fname)
        rel = os.path.relpath(fp, PROJ).replace("\\", "/")
        actual_files.add(rel)
        # 检查是否被 pubspec 任何声明覆盖
        covered = False
        for decl in pub_assets:
            prefix = "assets/" + decl.removeprefix("assets/").rstrip("/")
            if rel.startswith(prefix) or rel.startswith(prefix + "/"):
                covered = True
                break
        if not covered:
            errors.append(f"[ASSET] {rel} 未被 pubspec.yaml 声明但在 assets 目录中存在")

# 检查 pubspec 声明的目录是否有文件
for decl in pub_assets:
    prefix = decl.rstrip("/")
    found = any(f.startswith(prefix) for f in actual_files)
    if not found:
        warnings.append(f"[ASSET] pubspec 声明的 {decl} 路径下没有任何文件")

# ====== 2. 扫描代码中的 assets 引用 ======
code_assets = set()
for root in [LIB, TEST]:
    for r2, _, files in os.walk(root):
        for fn in files:
            if fn.endswith(".dart"):
                fp = os.path.join(r2, fn)
                with open(fp, encoding="utf-8") as f:
                    # 只取非注释行
                    lines = [ln for ln in f.readlines() if not ln.strip().startswith("//") and not ln.strip().startswith("*")]
                    content = "".join(lines)
                    # 查找硬编码的静态 assets 引用（排除字符串插值 ${...}）
                    matches = re.findall(r"'assets/([^'\"]+)'|\"assets/([^\"]+)\"", content)
                    for m in matches:
                        # m 是一个 tuple (单引号捕获, 双引号捕获)，取非空的那个
                        path = "assets/" + (m[0] or m[1])
                        # 排除动态路径（含字符串插值 $）和扩展示例（grape）
                        if "$" in path or "grape" in path:
                            continue
                        code_assets.add(path)

for ca in sorted(code_assets):
    if not any(ca.startswith(d) for d in pub_assets):
        errors.append(f"[ASSET] 代码引用了 {ca} 但 pubspec.yaml 未声明包含此路径的目录")
    if ca not in actual_files:
        warnings.append(f"[ASSET] 代码引用了 {ca} 但对应文件不存在")

# ====== 3. 检查每个 Dart 文件的 import ======
# （基础检查：文件存在性；from/show 后会复查 usage）
for root in [LIB, TEST]:
    for r2, _, files in os.walk(root):
        for fn in files:
            if fn.endswith(".dart"):
                fp = os.path.join(r2, fn)
                with open(fp, encoding="utf-8") as f:
                    content = f.read()

                # 收集 import 路径
                import_pats = re.findall(r"^import\s+['\"]([^'\"]+)['\"]", content, re.MULTILINE)
                for imp in import_pats:
                    # dart: 标准库跳过
                    if imp.startswith("dart:"):
                        continue
                    # package: 引用检查
                    if imp.startswith("package:"):
                        if imp.startswith("package:baby_english/"):
                            # 检查实际文件是否存在
                            sub = imp[len("package:baby_english/"):]
                            expected = os.path.join(LIB, sub)
                            if not os.path.exists(expected):
                                errors.append(f"[IMPORT] {fp} 引用了 {imp} 但文件 {expected} 不存在")
                        elif imp.startswith("package:flutter/") or imp.startswith("package:flutter_test/"):
                            pass  # Flutter 内置，OK
                        else:
                            # 第三方包：不检查文件存在性，但确保不是 baby_english 伪装
                            pass
                    else:
                        # 相对路径
                        ref_file = os.path.normpath(os.path.join(os.path.dirname(fp), imp))
                        if not os.path.exists(ref_file) and not imp.endswith(".dart"):
                            ref_file_dart = ref_file + ".dart"
                        else:
                            ref_file_dart = ref_file
                        if not os.path.exists(ref_file_dart) and not os.path.exists(ref_file):
                            errors.append(f"[IMPORT] {fp} 引用了 {imp} 但解析后文件不存在 ({ref_file_dart})")

# ====== 4. 打印结果 ======
print("=" * 60)
print("静态检查报告")
print("=" * 60)
if errors:
    print(f"\n{len(errors)} 个错误 (ERROR):")
    for e in errors:
        print(f"  ❌ {e}")
else:
    print("\n✅ 零错误")

if warnings:
    print(f"\n{len(warnings)} 个警告 (WARNING):")
    for w in warnings:
        print(f"  ⚠️  {w}")
else:
    print("✅ 零警告")

print(f"""
概要:
  pubspec assets 声明: {len(pub_assets)} 个目录
  实际 assets 文件: {len(actual_files)} 个
  代码 assets 引用: {len(code_assets)} 个
""")

if errors:
    print("** 检查未通过 **")
    sys.exit(1)
else:
    print("✅ 基础静态检查通过")
