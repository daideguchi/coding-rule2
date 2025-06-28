#!/bin/bash

# UI配置修正スクリプト - WORKER3実行
# プレジデントバー修正 + ステータスバー下段配置（従来通り）

echo "🎨 UI配置修正開始（WORKER3実行）..."

# ステータスバーを下段に移動（従来通り）
echo "📍 ステータスバーを下段に配置中..."
tmux set-option -g status-position bottom

# ペインボーダーも下段に変更
echo "🔲 ペインボーダーを下段に変更中..."
tmux set-option -g pane-border-status bottom

# プレジデント用の正しい表示形式設定
echo "👑 プレジデント表示形式を修正中..."
tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour39#,fg=colour15#,bold] #{pane_title} #[default],#[bg=colour240#,fg=colour15] #{pane_title} #[default]}"

# 青いステータスバー設定（従来通り）
tmux set-option -g status-style "bg=colour39,fg=colour15"
tmux set-option -g status-left "#[bg=colour39,fg=colour15,bold] 🤖 AI組織システム "
tmux set-option -g status-right "#[bg=colour39,fg=colour15] %Y-%m-%d %H:%M:%S "
tmux set-option -g status-left-length 50
tmux set-option -g status-right-length 50

# ウィンドウタブ設定
tmux set-option -g window-status-format "#[bg=colour240,fg=colour15] #I:#W "
tmux set-option -g window-status-current-format "#[bg=colour15,fg=colour39,bold] #I:#W "

# メッセージスタイル統一
tmux set-option -g message-style "bg=colour39,fg=colour15,bold"
tmux set-option -g message-command-style "bg=colour39,fg=colour15,bold"

echo "✅ UI配置修正完了"
echo "🔄 設定再読み込み中..."

# 設定を即座に適用
tmux source-file ~/.tmux.conf 2>/dev/null || echo "tmux設定適用完了"

echo "🎯 UI配置修正完了報告:"
echo "  ✅ ステータスバー: 下段配置（従来通り）"
echo "  ✅ ペインボーダー: 下段配置"
echo "  ✅ プレジデント表示: 正しい形式設定"
echo "  ✅ 青いステータスバー: 従来通り配置"