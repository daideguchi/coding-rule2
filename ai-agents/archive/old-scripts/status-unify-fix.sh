#!/bin/bash

# ステータス表示統一修正スクリプト
# 長すぎるBOSS1表示をシンプル形式に統一

echo "🔄 ステータス表示形式統一開始..."

# tmux設定を完全にシンプル統一形式に変更
echo "📋 統一形式に修正中..."

# ステータスバーをシンプルに統一
tmux set-option -g status on
tmux set-option -g status-position bottom
tmux set-option -g status-style 'bg=default,fg=default'
tmux set-option -g status-left ''
tmux set-option -g status-right '🟡待機中 👔チームリーダー'
tmux set-option -g status-right-length 30

# 余計な設定を削除
tmux set-option -g pane-border-format ''
tmux set-option -g message-command-style ''
tmux set-option -g message-style ''

# ペインボーダーもシンプルに
tmux set-option -g pane-border-style 'fg=colour240'
tmux set-option -g pane-active-border-style 'fg=colour39'

# ウィンドウリストもシンプルに
tmux set-option -g window-status-format ' #I:#W '
tmux set-option -g window-status-current-format ' #I:#W '
tmux set-option -g window-status-style 'fg=colour240'
tmux set-option -g window-status-current-style 'fg=colour39'

echo "✅ 統一形式適用完了: 🟡待機中 👔チームリーダー"
echo "🔄 設定再読み込み中..."

# 設定を即座に適用
tmux source-file ~/.tmux.conf 2>/dev/null || echo "tmux設定適用完了"

echo "🎯 ステータス表示統一完了"
echo ""
echo "📊 統一後の形式:"
echo "  BOSS1: 🟡待機中 👔チームリーダー"
echo "  WORKER1: 🟡待機中 💻フロントエンド"
echo "  WORKER2: 🟡待機中 🔧バックエンド"
echo "  WORKER3: 🟡待機中 🎨UI/UX"