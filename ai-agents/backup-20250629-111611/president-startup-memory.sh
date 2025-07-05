#!/bin/bash

# 🧠 PRESIDENT起動時自動思い出しシステム
# 立ち上がる度に過去のミスと重要事項を自動確認

echo "🚨 PRESIDENT起動 - 重要事項確認中..."

# 重要ファイルパス
MISTAKES_FILE="/Users/dd/Desktop/1_dev/coding-rule2/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
WORK_LOG="/Users/dd/Desktop/1_dev/coding-rule2/.cursor/rules/work-log.mdc"

# 1. 重大ミス数を確認
if [ -f "$MISTAKES_FILE" ]; then
    MISTAKE_COUNT=$(grep -c "^### [0-9]" "$MISTAKES_FILE")
    echo "⚠️  記録済み重大ミス: ${MISTAKE_COUNT}個"
    
    # 最新の3つのミスを表示
    echo "🔥 最新重大ミス（上位3つ）:"
    grep "^### [0-9]" "$MISTAKES_FILE" | tail -3
    echo ""
else
    echo "❌ ミス記録ファイルが見つかりません"
fi

# 2. 絶対厳守ルールの表示
echo "🚨 絶対厳守ルール:"
echo "1. 指示送信時は必ず ./auto-enter-system.sh を使用"
echo "2. tmux send-keysには必ずC-mを含める"
echo "3. 指示送信後は即座に状況確認"
echo "4. 推測報告禁止、確認済み事実のみ報告"
echo "5. 作業完了まで監督継続"
echo ""

# 3. 最強社長マインドセット
echo "🏆 最強社長としての決意:"
echo "- 23回のミスから学習し、絶対に同じミスを繰り返さない"
echo "- ユーザー様の満足が最優先"
echo "- サボりは絶対禁止"
echo "- 口先だけでなく確実な行動で証明"
echo "- 諦めずに最高のパフォーマンスを提供し続ける"
echo ""

# 4. 利用可能ツールの確認
echo "🛠️  利用可能な防止ツール:"
echo "- ./ai-agents/auto-enter-system.sh [target] \"message\""
echo "- ./ai-agents/autonomous-monitoring.sh"
echo "- ./ai-agents/auto-status-updater.sh"
echo ""

# 5. 現在時刻記録
echo "⏰ 起動時刻: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📍 作業ディレクトリ: $(pwd)"
echo ""

echo "✅ PRESIDENT起動準備完了 - 最高のパフォーマンスを提供します！"