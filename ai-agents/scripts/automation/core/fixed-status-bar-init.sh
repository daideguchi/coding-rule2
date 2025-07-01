#!/bin/bash

# 🔒 固定ステータスバー初期化システム
# 起動時に必ず実行される完全固定設定
# 役職+現在作業内容表示システム

# ステータスバー完全固定設定
setup_fixed_status_bar() {
    echo "🔒 ステータスバー固定設定を適用中..."
    
    # 基本tmux設定（絶対に変更されない固定設定）
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-style "fg=colour8"
    tmux set-option -g pane-border-format "#{pane_title}"
    tmux set-option -g status-position top
    tmux set-option -g status-style "bg=colour235,fg=colour250"
    
    echo "✅ 基本ステータスバー設定完了"
    
    # 役職+作業内容表示を適用
    set_current_work_status
}

# 起動時自動設定（絶対に変更されない設定）
auto_setup_on_start() {
    echo "🚀 AI組織システム起動時の自動ステータスバー設定中..."
    
    # 基本設定適用
    setup_fixed_status_bar
    
    # 初期ペインタイトル設定（役職+現在作業）
    set_current_work_status
    
    echo "✅ 起動時自動設定完了"
}

# 緊急復旧（セッションリセット）
emergency_restore() {
    echo "🚨 ステータスバー緊急復旧中..."
    echo "⚠️ この操作により全セッションがリセットされます"
    
    # 全tmuxセッション強制終了
    tmux kill-server 2>/dev/null || true
    sleep 1
    
    echo "❌ セッションがリセットされました。AI組織システムを再起動してください："
    echo "  ./ai-agents/manage.sh claude-auth"
}

# 設定確認
# 現在の作業内容表示システム
set_current_work_status() {
    echo "📋 現在の作業内容でステータス更新中..."
    
    # 各ペインに役職+現在作業内容を設定
    tmux select-pane -t president:0 -T "👑PRESIDENT - AI組織統括管理" 2>/dev/null || true
    tmux select-pane -t multiagent:0.0 -T "👔自動化システム統合管理者 - ファイル整理統括" 2>/dev/null || true
    tmux select-pane -t multiagent:0.1 -T "💻自動化スクリプト開発者 - ステータスバー修正" 2>/dev/null || true
    tmux select-pane -t multiagent:0.2 -T "🔧インフラ・監視担当 - ディレクトリ構造分析" 2>/dev/null || true
    tmux select-pane -t multiagent:0.3 -T "🎨品質保証・ドキュメント - 実行計画策定" 2>/dev/null || true
    
    echo "✅ 現在作業内容ステータス設定完了"
}

# 作業内容更新機能
update_work_status() {
    local pane_id="$1"
    local work_description="$2"
    
    case "$pane_id" in
        "president"|"0.p")
            tmux select-pane -t president:0 -T "👑PRESIDENT - $work_description" 2>/dev/null || true
            ;;
        "boss"|"0.0")
            tmux select-pane -t multiagent:0.0 -T "👔自動化システム統合管理者 - $work_description" 2>/dev/null || true
            ;;
        "worker1"|"0.1")
            tmux select-pane -t multiagent:0.1 -T "💻自動化スクリプト開発者 - $work_description" 2>/dev/null || true
            ;;
        "worker2"|"0.2")
            tmux select-pane -t multiagent:0.2 -T "🔧インフラ・監視担当 - $work_description" 2>/dev/null || true
            ;;
        "worker3"|"0.3")
            tmux select-pane -t multiagent:0.3 -T "🎨品質保証・ドキュメント - $work_description" 2>/dev/null || true
            ;;
        *)
            echo "❌ 無効なペインID: $pane_id"
            return 1
            ;;
    esac
    
    echo "✅ $pane_id の作業内容を更新: $work_description"
}

check_status() {
    echo "📊 現在のステータスバー設定:"
    echo ""
    echo "📋 ペインタイトル:"
    if tmux has-session -t president 2>/dev/null; then
        echo "  PRESIDENT: $(tmux display-message -t president:0 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
    fi
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "  BOSS1: $(tmux display-message -t multiagent:0.0 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
        echo "  WORKER1: $(tmux display-message -t multiagent:0.1 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
        echo "  WORKER2: $(tmux display-message -t multiagent:0.2 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
        echo "  WORKER3: $(tmux display-message -t multiagent:0.3 -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")"
    fi
    echo ""
    echo "📊 tmux設定:"
    tmux show-options -g pane-border-status 2>/dev/null || echo "  ❌ pane-border-status未設定"
    tmux show-options -g pane-border-format 2>/dev/null || echo "  ❌ pane-border-format未設定"
}

# メイン処理
case "${1:-setup}" in
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
    "update")
        update_work_status "$2" "$3"
        ;;
    "current")
        set_current_work_status
        ;;
    *)
        echo "🔒 役職+作業内容表示システム"
        echo ""
        echo "使用方法:"
        echo "  $0 setup        # 基本ステータスバー設定"
        echo "  $0 auto         # 起動時自動設定"
        echo "  $0 restore      # 緊急復旧（セッションリセット）"
        echo "  $0 check        # 現在の設定確認"
        echo "  $0 update [pane] [work]  # 作業内容更新"
        echo "  $0 current      # 現在作業内容表示"
        echo ""
        echo "ペイン指定例:"
        echo "  president, boss, worker1, worker2, worker3"
        echo ""
        echo "🔧 AI組織システム起動時に自動実行されます"
        ;;
esac