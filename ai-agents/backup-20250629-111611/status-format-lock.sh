#!/bin/bash

# ステータス表示形式固定スクリプト
# 統一形式を強制的に維持し、古い形式への復帰を防止

echo "🔒 ステータス表示形式を固定しています..."

# 統一形式で強制設定
tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔チームリーダー"
tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻フロントエンド"
tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧バックエンド"
tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨UI/UXデザイン"

# PRESIDENTセッションが存在する場合
if tmux has-session -t president 2>/dev/null; then
    tmux select-pane -t president:0 -T "🟢起動完了 👑PRESIDENT"
fi

echo "✅ ステータス表示形式固定完了"
echo ""
echo "📊 現在の統一形式:"
echo "  BOSS1: 🟡待機中 👔チームリーダー"
echo "  WORKER1: 🟡待機中 💻フロントエンド"
echo "  WORKER2: 🟡待機中 🔧バックエンド"
echo "  WORKER3: 🟡待機中 🎨UI/UXデザイン"
echo "  PRESIDENT: 🟢起動完了 👑PRESIDENT"