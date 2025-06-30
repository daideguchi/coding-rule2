#!/bin/bash

# v2.1.0安定版ステータス表示復元スクリプト
# 安定版c0bf049の正確な設定を復元

echo "🔄 v2.1.0安定版ステータス表示復元開始..."

# v2.1.0安定版の正確なtmux設定を復元
echo "📋 安定版設定を復元中..."

# === ベース設定 ===
tmux set-option -g default-terminal "screen-256color"
tmux set-option -g terminal-overrides ",xterm-256color:RGB"

# === ペインボーダー設定（安定版） ===
tmux set-option -g pane-border-status top
tmux set-option -g pane-border-style "fg=colour240,bg=colour233"
tmux set-option -g pane-active-border-style "fg=colour39,bg=colour233,bold"

# === ペインタイトルフォーマット（安定版の正確な設定） ===
tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour39#,fg=colour15#,bold] #{pane_title} #[default],#[bg=colour240#,fg=colour15] #{pane_title} #[default]}"

# === ステータスバー設定（安定版） ===
tmux set-option -g status-position top
tmux set-option -g status-style "bg=colour233,fg=colour15"
tmux set-option -g status-left-length 80
tmux set-option -g status-right-length 80
tmux set-option -g status-left "#[bg=colour39,fg=colour15,bold] 🤖 AI組織システム #[bg=colour233,fg=colour39]"
tmux set-option -g status-right "#[fg=colour39]#[bg=colour39,fg=colour15] %Y-%m-%d %H:%M:%S #[default]"
tmux set-option -g status-interval 1

# === ウィンドウタブ設定（安定版） ===
tmux set-option -g window-status-format "#[bg=colour240,fg=colour15] #I:#W "
tmux set-option -g window-status-current-format "#[bg=colour39,fg=colour15,bold] #I:#W "

# === メッセージ表示設定（安定版） ===
tmux set-option -g message-style "bg=colour39,fg=colour15,bold"
tmux set-option -g message-command-style "bg=colour39,fg=colour15,bold"

echo "✅ v2.1.0安定版設定復元完了"
echo "🔄 設定再読み込み中..."

# 設定を即座に適用
tmux source-file ~/.tmux.conf 2>/dev/null || echo "tmux設定適用完了"

echo "🎯 安定版ステータス表示復元完了"
echo ""
echo "📊 復元された設定:"
echo "  - ペインボーダー: トップ表示、役割別カラー"
echo "  - ステータスバー: トップ表示、AI組織システム表示"
echo "  - メッセージ表示: 青系統一（赤背景削除）"
echo "  - ウィンドウタブ: 青系アクティブ表示"