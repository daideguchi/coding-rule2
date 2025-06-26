#!/bin/bash

# ==============================================================================
# AI組織システム - 視覚的改善スクリプト
# ==============================================================================
# 
# 概要: tmuxペインタイトルとAI組織システムの視覚的表示を改善
# 作成者: Claude Code AI
# 更新日: $(date)
#
# 使用方法:
#   ./scripts/visual-improvements.sh
#   ./scripts/visual-improvements.sh --apply-theme
#   ./scripts/visual-improvements.sh --status
# ==============================================================================

# 設定ファイル
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TMUX_CONFIG_FILE="$HOME/.tmux.conf"
BACKUP_CONFIG_FILE="$HOME/.tmux.conf.bak"

# ログ関数
log_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"  
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

# AI組織システム専用tmux設定
setup_ai_visual_theme() {
    log_info "🎨 AI組織システム視覚テーマ設定中..."
    
    # 既存のセッションに適用
    if tmux has-session -t president 2>/dev/null || tmux has-session -t multiagent 2>/dev/null; then
        apply_live_theme
    else
        log_warn "⚠️ AI組織システムのセッションが見つかりません"
        echo "先に以下のコマンドでセッションを作成してください:"
        echo "  ./ai-agents/manage.sh quick-start"
        return 1
    fi
}

# ライブテーマ適用（実行中のセッション用）
apply_live_theme() {
    log_info "🌈 ライブテーマ適用中..."
    
    # === ベース設定 ===
    tmux set-option -g default-terminal "screen-256color"
    tmux set-option -g terminal-overrides ",xterm-256color:RGB"
    
    # === ペインボーダー設定 ===
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-style "fg=colour240,bg=colour233"
    tmux set-option -g pane-active-border-style "fg=colour39,bg=colour233,bold"
    
    # === ペインタイトルフォーマット（役割別カラー） ===
    tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour39#,fg=colour15#,bold] #{pane_title} #[default],#[bg=colour240#,fg=colour15] #{pane_title} #[default]}"
    
    # === ステータスバー設定 ===
    tmux set-option -g status-position top
    tmux set-option -g status-style "bg=colour233,fg=colour15"
    tmux set-option -g status-left-length 80
    tmux set-option -g status-right-length 80
    tmux set-option -g status-left "#[bg=colour39,fg=colour15,bold] 🤖 AI組織システム #[bg=colour233,fg=colour39]"
    tmux set-option -g status-right "#[fg=colour39]#[bg=colour39,fg=colour15] %Y-%m-%d %H:%M:%S #[default]"
    tmux set-option -g status-interval 1
    
    # === ウィンドウタブ設定 ===
    tmux set-option -g window-status-format "#[bg=colour240,fg=colour15] #I:#W "
    tmux set-option -g window-status-current-format "#[bg=colour39,fg=colour15,bold] #I:#W "
    
    # === メッセージ表示設定 ===
    tmux set-option -g message-style "bg=colour39,fg=colour15,bold"
    tmux set-option -g message-command-style "bg=colour196,fg=colour15,bold"
    
    # === ペインタイトル設定（役割別） ===
    apply_role_based_titles
    
    # === ウィンドウ名設定 ===
    if tmux has-session -t president 2>/dev/null; then
        tmux rename-window -t president:0 "👑 PRESIDENT"
    fi
    
    if tmux has-session -t multiagent 2>/dev/null; then
        tmux rename-window -t multiagent:0 "👥 AI-TEAM"
    fi
    
    log_success "✅ ライブテーマ適用完了"
}

# 役割別ペインタイトル設定
apply_role_based_titles() {
    log_info "🏷️ 役割別ペインタイトル設定中..."
    
    # PRESIDENT
    if tmux has-session -t president 2>/dev/null; then
        tmux select-pane -t president:0.0 -T "👑 PRESIDENT・統括責任者 [ACTIVE]"
    fi
    
    # AI-TEAM (multiagent)
    if tmux has-session -t multiagent 2>/dev/null; then
        # 各ペインの状態を確認して動的にタイトル設定
        for i in {0..3}; do
            if tmux list-panes -t multiagent:0 -F '#{pane_index}' | grep -q "^$i$" 2>/dev/null; then
                case $i in
                    0) 
                        title="👔 BOSS・チームリーダー"
                        status=$(get_pane_status "multiagent:0.$i")
                        tmux select-pane -t multiagent:0.$i -T "$title [$status]"
                        ;;
                    1) 
                        title="💻 フロントエンド専門"
                        status=$(get_pane_status "multiagent:0.$i")
                        tmux select-pane -t multiagent:0.$i -T "$title [$status]"
                        ;;
                    2) 
                        title="🔧 バックエンド専門"
                        status=$(get_pane_status "multiagent:0.$i")
                        tmux select-pane -t multiagent:0.$i -T "$title [$status]"
                        ;;
                    3) 
                        title="🎨 UI/UX専門"
                        status=$(get_pane_status "multiagent:0.$i")
                        tmux select-pane -t multiagent:0.$i -T "$title [$status]"
                        ;;
                esac
            fi
        done
    fi
    
    log_success "✅ 役割別ペインタイトル設定完了"
}

# ペイン状態取得
get_pane_status() {
    local pane_target=$1
    local content=$(tmux capture-pane -t "$pane_target" -p 2>/dev/null || echo "")
    
    if echo "$content" | grep -q "Welcome to Claude Code" 2>/dev/null; then
        echo "READY"
    elif echo "$content" | grep -q "claude --dangerously-skip-permissions" 2>/dev/null; then
        echo "STARTING"
    elif echo "$content" | grep -q "cwd:" 2>/dev/null; then
        echo "ACTIVE"
    else
        echo "STANDBY"
    fi
}

# プログレスバー表示
update_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# 動的ステータス更新
start_dynamic_status() {
    log_info "🔄 動的ステータス更新開始..."
    
    # バックグラウンドでステータス更新
    {
        while true; do
            if tmux has-session -t president 2>/dev/null || tmux has-session -t multiagent 2>/dev/null; then
                apply_role_based_titles
                sleep 10
            else
                break
            fi
        done
    } &
    
    echo $! > /tmp/ai-visual-status-updater.pid
    log_success "✅ 動的ステータス更新開始（PID: $(cat /tmp/ai-visual-status-updater.pid)）"
}

# 動的ステータス停止
stop_dynamic_status() {
    if [ -f /tmp/ai-visual-status-updater.pid ]; then
        local pid=$(cat /tmp/ai-visual-status-updater.pid)
        kill $pid 2>/dev/null || true
        rm -f /tmp/ai-visual-status-updater.pid
        log_success "✅ 動的ステータス更新停止"
    else
        log_warn "⚠️ 動的ステータス更新プロセスが見つかりません"
    fi
}

# システム状態表示
show_system_status() {
    echo ""
    echo "🎨 AI組織システム視覚状態レポート"
    echo "=================================="
    echo ""
    
    # tmuxセッション確認
    echo "📊 tmuxセッション状態:"
    if tmux has-session -t president 2>/dev/null; then
        echo "  ✅ president セッション: 起動中"
        echo "     └── $(tmux display-message -t president -p '#{window_name}') ($(tmux list-panes -t president -F '#{pane_title}' | head -1))"
    else
        echo "  ❌ president セッション: 未起動"
    fi
    
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "  ✅ multiagent セッション: 起動中"
        echo "     └── $(tmux display-message -t multiagent -p '#{window_name}') ($(tmux list-panes -t multiagent | wc -l)ペイン)"
        
        # 各ペインの状態
        for i in {0..3}; do
            if tmux list-panes -t multiagent:0 -F '#{pane_index}' | grep -q "^$i$" 2>/dev/null; then
                local title=$(tmux display-message -t multiagent:0.$i -p '#{pane_title}')
                echo "       • ペイン$i: $title"
            fi
        done
    else
        echo "  ❌ multiagent セッション: 未起動"
    fi
    
    echo ""
    
    # 視覚設定確認
    echo "🎨 視覚設定状態:"
    if tmux show-options -g pane-border-status 2>/dev/null | grep -q "top"; then
        echo "  ✅ ペインタイトル表示: 有効"
    else
        echo "  ❌ ペインタイトル表示: 無効"
    fi
    
    if tmux show-options -g status-position 2>/dev/null | grep -q "top"; then
        echo "  ✅ ステータスバー位置: 上部"
    else
        echo "  ❌ ステータスバー位置: 下部"
    fi
    
    echo ""
    
    # 動的更新状態
    echo "🔄 動的更新状態:"
    if [ -f /tmp/ai-visual-status-updater.pid ] && kill -0 $(cat /tmp/ai-visual-status-updater.pid) 2>/dev/null; then
        echo "  ✅ 動的ステータス更新: 実行中 (PID: $(cat /tmp/ai-visual-status-updater.pid))"
    else
        echo "  ❌ 動的ステータス更新: 停止中"
    fi
    
    echo ""
}

# テーマリセット
reset_theme() {
    log_info "🔄 テーマリセット中..."
    
    # デフォルトに戻す
    tmux set-option -g pane-border-status off
    tmux set-option -g pane-border-style default
    tmux set-option -g pane-active-border-style default
    tmux set-option -g status-position bottom
    tmux set-option -g status-style default
    tmux set-option -g status-left ""
    tmux set-option -g status-right ""
    
    # 動的更新停止
    stop_dynamic_status
    
    log_success "✅ テーマリセット完了"
}

# ヘルプ表示
show_help() {
    echo "🎨 AI組織システム視覚改善スクリプト"
    echo "=================================="
    echo ""
    echo "使用方法:"
    echo "  ./scripts/visual-improvements.sh [オプション]"
    echo ""
    echo "オプション:"
    echo "  --apply-theme    視覚テーマを適用"
    echo "  --status         システム状態を表示"
    echo "  --start-dynamic  動的ステータス更新開始"
    echo "  --stop-dynamic   動的ステータス更新停止"
    echo "  --reset          テーマをリセット"
    echo "  --help           このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./scripts/visual-improvements.sh --apply-theme"
    echo "  ./scripts/visual-improvements.sh --status"
    echo ""
}

# メイン処理
main() {
    case "${1:-help}" in
        "--apply-theme")
            setup_ai_visual_theme
            start_dynamic_status
            ;;
        "--status")
            show_system_status
            ;;
        "--start-dynamic")
            start_dynamic_status
            ;;
        "--stop-dynamic")
            stop_dynamic_status
            ;;
        "--reset")
            reset_theme
            ;;
        "--help"|"help"|*)
            show_help
            ;;
    esac
}

# スクリプト実行
main "$@"