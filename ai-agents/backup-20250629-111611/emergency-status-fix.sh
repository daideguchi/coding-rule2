#!/bin/bash

# 緊急ステータスバー修正スクリプト
# バグった設定をリセットしてシンプルな表示に戻す

echo "🚨 緊急ステータスバー修正開始..."

# tmux設定をリセット
echo "📋 tmux設定をリセット中..."

# 問題のある複雑な設定を削除
tmux set-option -g pane-border-format ''
tmux set-option -g message-command-style ''
tmux set-option -g message-style ''

# シンプルなステータス表示に戻す
tmux set-option -g status on
tmux set-option -g status-position bottom
tmux set-option -g status-style 'bg=default,fg=default'
tmux set-option -g status-left ''
tmux set-option -g status-right '🟡待機中 👔チームリーダー'
tmux set-option -g status-right-length 50

# ペインボーダーをシンプルに
tmux set-option -g pane-border-style 'fg=colour240'
tmux set-option -g pane-active-border-style 'fg=colour39'

# ウィンドウリストをシンプルに
tmux set-option -g window-status-format ' #I:#W '
tmux set-option -g window-status-current-format ' #I:#W '
tmux set-option -g window-status-style 'fg=colour240'
tmux set-option -g window-status-current-style 'fg=colour39,bold'

echo "✅ ステータスバー設定をシンプルに修正完了"
echo "🔄 tmux設定を再読み込み中..."

# 設定を即座に適用
tmux source-file ~/.tmux.conf 2>/dev/null || echo "tmux設定ファイルが見つかりません（正常）"

echo "🎯 修正完了: シンプルな 🟡待機中 👔チームリーダー 形式に復元しました"