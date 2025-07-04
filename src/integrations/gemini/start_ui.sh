#!/bin/bash
# Gemini Chat UI 起動スクリプト

echo "🚀 Gemini Chat UI 起動中..."
echo ""

# ディレクトリ移動
cd "$(dirname "$0")"

# Gemini CLI確認
if ! command -v npx &> /dev/null; then
    echo "❌ npm/npx が見つかりません"
    echo "Node.js をインストールしてください"
    exit 1
fi

if ! npx @google/gemini-cli --version &> /dev/null; then
    echo "⚠️  Gemini CLI が見つかりません"
    echo "インストールしますか？ (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "📦 Gemini CLI インストール中..."
        npm install -g @google/gemini-cli
    else
        echo "❌ Gemini CLI が必要です"
        exit 1
    fi
fi

echo "✅ 環境確認完了"
echo ""
echo "🌐 ブラウザで以下のURLを開いてください:"
echo "   http://localhost:8000/gemini_chat_ui.html"
echo ""
echo "🛑 停止: Ctrl+C"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# サーバー起動
python3 simple_chat_server.py