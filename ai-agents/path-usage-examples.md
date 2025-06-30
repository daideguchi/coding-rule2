# 🔧 パス管理システム使用例

## 📁 推奨パターン（相対パス）

```bash
# ✅ 推奨：相対パス使用
cat ./logs/ai-agents/president/PRESIDENT_MISTAKES.md
cat ./.cursor/rules/work-log.mdc
cat ./ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md

# ✅ 推奨：環境変数使用
source ./ai-agents/env-setup.sh
cat "$PRESIDENT_MISTAKES"
cat "$CURSOR_WORK_LOG"
```

## ❌ 非推奨パターン（固定パス）

```bash
# ❌ 環境依存：絶対パス
cat /Users/dd/Desktop/1_dev/coding-rule2/logs/ai-agents/president/PRESIDENT_MISTAKES.md

# ❌ 硬直：ユーザー名固定
cat /Users/specific-user/project/file.md
```

## 🔧 環境検出パターン

```bash
# プロジェクトルート検出
if [ -f "./.cursor/rules/globals.mdc" ]; then
    echo "✅ プロジェクトルートで実行中"
    PROJECT_ROOT="$(pwd)"
else
    echo "❌ プロジェクトルートに移動してください"
    exit 1
fi
```

## 🚀 動的パス構築

```python
import os
import pathlib

# Python例
project_root = pathlib.Path(__file__).parent.parent
mistakes_file = project_root / "logs" / "ai-agents" / "president" / "PRESIDENT_MISTAKES.md"

if mistakes_file.exists():
    print(f"✅ {mistakes_file}")
else:
    print(f"❌ File not found: {mistakes_file}")
```

## 📊 移植性チェックリスト

- [ ] 絶対パス使用禁止
- [ ] 相対パス優先使用
- [ ] 環境変数活用
- [ ] プロジェクトルート自動検出
- [ ] 異なる環境での動作確認
