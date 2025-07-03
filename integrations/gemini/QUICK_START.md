# ⚡ Claude-Gemini対話 クイックスタート

## 🚀 30秒でテスト

```bash
# 1. Gemini CLIインストール
npm install -g @google/gemini-cli

# 2. 動作テスト
echo "こんにちは" | npx @google/gemini-cli

# 3. 標準システムテスト
python3 claude_gemini_standard_dialogue.py test
```

## 📋 コマンド一覧

### 基本対話
```bash
# 直接CLI
echo "メッセージ" | npx @google/gemini-cli

# 標準システム
python3 claude_gemini_standard_dialogue.py "メッセージ"

# クイックスクリプト
./standard_scripts/quick_dialogue.sh "メッセージ"
```

### インタラクティブ
```bash
# 対話型セッション
python3 claude_gemini_standard_dialogue.py interactive
```

### ログ確認
```bash
# 最新ログ
ls -t dialogue_logs/ | head -5
```

## 🔧 詳細設定
完全なセットアップ手順は `/Users/dd/Desktop/1_dev/posts/coding-rule2/GEMINI_DIALOGUE_SETUP_GUIDE.md` を参照