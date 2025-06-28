#!/bin/bash

# 🔒 固定ステータスバー初期化システム
# 起動時に必ず実行される完全固定設定

# ステータスバー完全固定設定
setup_fixed_status_bar() {
    echo "🔒 ステータスバー固定設定を適用中..."
    
    # 基本tmux設定（絶対に変更されない固定設定）
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-style "fg=colour8"
    tmux set-option -g pane-active-border-style "fg=colour4,bold"
    tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour240,fg=colour15,bold],#[bg=colour236,fg=colour15]} #{pane_title} #[default]"
    
    # 下段ステータスバー固定設定
    tmux set-option -g status on
    tmux set-option -g status-position bottom
    tmux set-option -g status-left-length 50
    tmux set-option -g status-right-length 50
    tmux set-option -g status-left "#[bg=colour4,fg=colour15,bold] 🤖 AI組織システム #[default]"
    tmux set-option -g status-right "#[bg=colour2,fg=colour15,bold] %Y-%m-%d %H:%M:%S #[default]"
    tmux set-option -g status-interval 1
    tmux set-option -g status-style "bg=colour233,fg=colour15"
    
    # 固定ペインタイトル設定
    tmux select-pane -t president:0 -T "🟡待機中 👑PRESIDENT"
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔チームリーダー"
    tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻フロントエンド"
    tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧バックエンド"
    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨UI/UXデザイン"
    
    # ウィンドウタイトル固定
    tmux rename-window -t president "👑 PRESIDENT"
    tmux rename-window -t multiagent "👥 AI-TEAM"
    
    echo "✅ 固定ステータスバー設定完了"
}

# システム起動時の自動実行
auto_setup_on_start() {
    echo "🚀 AI組織システム起動時ステータスバー自動設定"
    
    # プレジデントとマルチエージェントセッションの存在確認
    if tmux has-session -t president 2>/dev/null && tmux has-session -t multiagent 2>/dev/null; then
        setup_fixed_status_bar
        echo "✅ 起動時ステータスバー設定完了"
    else
        echo "⚠️ セッションが存在しません。先にAI組織システムを起動してください。"
        return 1
    fi
}

# 修復機能（設定が壊れた時の緊急復旧）
emergency_restore() {
    echo "🚨 緊急ステータスバー復旧中..."
    
    # 全てのtmux設定をリセットしてから再設定
    tmux kill-server 2>/dev/null || true
    sleep 1
    
    echo "❌ セッションがリセットされました。AI組織システムを再起動してください："
    echo "  ./ai-agents/manage.sh claude-auth"
}

# 設定確認
check_status() {
    echo "📊 現在のステータスバー設定:"
    echo ""
    echo "📋 ペインタイトル:"
    if tmux has-session -t president 2>/dev/null; then
        echo "  PRESIDENT: $(tmux display-message -t president:0 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
    fi
    if tmux has-session -t multiagent 2>/dev/null; then
        for i in {0..3}; do
            local title=$(tmux display-message -t multiagent:0.$i -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")
            echo "  WORKER$i: $title"
        done
    fi
    echo ""
    echo "📊 tmux設定:"
    echo "  pane-border-status: $(tmux show-options -g pane-border-status 2>/dev/null | cut -d' ' -f2 || echo "未設定")"
    echo "  status-position: $(tmux show-options -g status-position 2>/dev/null | cut -d' ' -f2 || echo "未設定")"
}

# 使用方法
case "$1" in
    "setup")
        setup_fixed_status_bar
        ;;
    "auto")
        auto_setup_on_start
        ;;
    "restore")
        emergency_restore
        ;;
    "check")
        check_status
        ;;
    *)
        echo "🔒 固定ステータスバー初期化システム"
        echo ""
        echo "使用方法:"
        echo "  $0 setup     # 固定ステータスバー設定適用"
        echo "  $0 auto      # 起動時自動設定"
        echo "  $0 restore   # 緊急復旧（セッションリセット）"
        echo "  $0 check     # 現在の設定確認"
        echo ""
        echo "🔧 AI組織システム起動時に自動実行されます"
        ;;
esac