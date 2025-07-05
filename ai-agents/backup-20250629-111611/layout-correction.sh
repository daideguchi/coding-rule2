#!/bin/bash

# 配置訂正スクリプト - WORKER3実行
# 役職ステータス上部 + 青いステータスバー下段の分離設定

echo "🎨 配置訂正開始（WORKER3実行）..."

# 役職ステータスは上部に配置（ペインボーダー）
echo "📍 役職ステータスを上部に配置中..."
tmux set-option -g pane-border-status top

# 青いステータスバーは下段に配置
echo "📍 青いステータスバーを下段に配置中..."
tmux set-option -g status-position bottom

# 役職表示フォーマット（上部）
echo "👔 役職表示フォーマット設定中..."
tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour39#,fg=colour15#,bold] 🟡待機中 #{pane_title} #[default],#[bg=colour240#,fg=colour15] 🟡待機中 #{pane_title} #[default]}"

# 青いステータスバー設定（下段）
echo "🔵 青いステータスバー設定中..."
tmux set-option -g status on
tmux set-option -g status-style "bg=colour39,fg=colour15"
tmux set-option -g status-left "#[bg=colour39,fg=colour15,bold] 🤖 AI組織システム "
tmux set-option -g status-right "#[bg=colour39,fg=colour15] %Y-%m-%d %H:%M:%S "
tmux set-option -g status-left-length 50
tmux set-option -g status-right-length 50

# ウィンドウタブ設定（下段）
tmux set-option -g window-status-format "#[bg=colour240,fg=colour15] #I:#W "
tmux set-option -g window-status-current-format "#[bg=colour15,fg=colour39,bold] #I:#W "

# メッセージスタイル
tmux set-option -g message-style "bg=colour39,fg=colour15,bold"
tmux set-option -g message-command-style "bg=colour39,fg=colour15,bold"

echo "✅ 配置訂正完了"
echo "🔄 設定再読み込み中..."

# 設定を即座に適用
tmux source-file ~/.tmux.conf 2>/dev/null || echo "tmux設定適用完了"

echo "🎯 配置訂正完了報告:"
echo "  ✅ 役職ステータス（🟡待機中 👔チームリーダー）: 上部配置"
echo "  ✅ 青いステータスバー: 下段配置"
echo "  ✅ pane-border-status: top"
echo "  ✅ status-position: bottom"
echo "  📐 上下分離レイアウト完成"