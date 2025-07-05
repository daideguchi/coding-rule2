#!/bin/bash
# Claude-Gemini クイック対話スクリプト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEMINI_DIR="$(dirname "$SCRIPT_DIR")"

# 使用方法チェック
if [ $# -eq 0 ]; then
    echo "🔧 Claude-Gemini クイック対話"
    echo "使用方法: $0 'メッセージ'"
    echo "例: $0 'Kindle本のアイデアを3つ教えて'"
    exit 1
fi

# メッセージを結合
MESSAGE="$*"

echo "🚀 Geminiと対話中..."
echo "📤 送信: $MESSAGE"
echo "─────────────────────────────────────"

# 標準対話システムを実行
python3 "$GEMINI_DIR/claude_gemini_standard_dialogue.py" "$MESSAGE"

echo "─────────────────────────────────────"
echo "✅ 対話完了"