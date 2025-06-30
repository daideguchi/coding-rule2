#!/bin/bash

# 🤖 AI Agent Communication Script v2.0
# tmuxセッション間でのエージェント通信システム

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# 設定
LOGS_DIR="logs/ai-agents"
SEND_LOG="$LOGS_DIR/send_log.txt"
TMP_DIR="./tmp"

# 必要ディレクトリの作成
init_dirs() {
    mkdir -p "$LOGS_DIR" "$TMP_DIR"
}

# エージェント一覧
list_agents() {
    echo "🤖 利用可能なエージェント:"
    echo "========================="
    echo ""
    echo "📊 PRESIDENTセッション:"
    echo "  president    - プロジェクト統括責任者"
    echo ""
    echo "📊 multiagentセッション:"
    echo "  boss1        - チームリーダー"
    echo "  worker1      - 実行担当者A"
    echo "  worker2      - 実行担当者B"
    echo "  worker3      - 実行担当者C"
    echo ""
    echo "📋 tmuxセッション確認:"
    if command -v tmux &> /dev/null; then
        tmux list-sessions 2>/dev/null || echo "  セッションなし"
    else
        echo "  tmuxが利用できません"
    fi
}

# メッセージ送信
send_message() {
    local agent=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -z "$agent" ] || [ -z "$message" ]; then
        log_error "❌ 使用法: $0 <エージェント名> <メッセージ>"
        echo "例: $0 boss1 'Hello World プロジェクト開始'"
        return 1
    fi
    
    # ログ記録
    echo "[$timestamp] SEND to $agent: $message" >> "$SEND_LOG"
    
    # tmuxセッション確認
    if ! command -v tmux &> /dev/null; then
        log_error "❌ tmuxが利用できません"
        return 1
    fi
    
    # エージェント別送信処理
    case "$agent" in
        "president")
            send_to_president "$message"
            ;;
        "boss1")
            send_to_multiagent "0.0" "$message"
            ;;
        "worker1")
            send_to_multiagent "0.1" "$message"
            ;;
        "worker2")
            send_to_multiagent "0.2" "$message"
            ;;
        "worker3")
            send_to_multiagent "0.3" "$message"
            ;;
        *)
            log_error "❌ 不明なエージェント: $agent"
            echo "利用可能なエージェント: president, boss1, worker1, worker2, worker3"
            return 1
            ;;
    esac
    
    log_success "✅ メッセージを送信しました: $agent"
}

# PRESIDENTセッションに送信
send_to_president() {
    local message=$1
    
    if ! tmux has-session -t president 2>/dev/null; then
        log_error "❌ presidentセッションが見つかりません"
        echo "先に './ai-agents/manage.sh start' を実行してください"
        return 1
    fi
    
    # PRESIDENTセッションにメッセージ送信
    tmux send-keys -t president "$message" C-m
    
    echo "📤 PRESIDENT > $message"
}

# multiagentセッションに送信
send_to_multiagent() {
    local pane=$1
    local message=$2
    
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが見つかりません"
        echo "先に './ai-agents/manage.sh start' を実行してください"
        return 1
    fi
    
    # 指定ペインにメッセージ送信
    tmux send-keys -t "multiagent:$pane" "$message" C-m
    
    echo "📤 multiagent:$pane > $message"
}

# Claude Code一括起動
setup_claude() {
    log_info "🚀 Claude Code一括起動中..."
    
    # PRESIDENTセッション認証
    if tmux has-session -t president 2>/dev/null; then
        log_info "👑 PRESIDENT認証開始..."
        tmux send-keys -t president 'claude --dangerously-skip-permissions' C-m
        sleep 2
    fi
    
    # multiagentセッション一括起動
    if tmux has-session -t multiagent 2>/dev/null; then
        log_info "👥 multiagent一括起動..."
        for i in {0..3}; do
            tmux send-keys -t "multiagent:0.$i" 'claude --dangerously-skip-permissions' C-m
            sleep 0.5
        done
    fi
    
    log_success "✅ Claude Code一括起動完了"
    echo ""
    echo "📋 次のステップ:"
    echo "  1. Claude Codeが各セッションで自動起動（権限スキップ）"
    echo "  2. PRESIDENTで指示開始: '指示書に従って'"
}

# ログ確認
show_logs() {
    echo "📊 送信ログ"
    echo "==========="
    
    if [ -f "$SEND_LOG" ]; then
        tail -20 "$SEND_LOG"
    else
        echo "ログファイルが見つかりません: $SEND_LOG"
    fi
    
    echo ""
    echo "📁 完了ファイル状況"
    echo "=================="
    ls -la "$TMP_DIR"/worker*_done.txt 2>/dev/null || echo "完了ファイルなし"
}

# pane状況確認（Zenn記事対応）
check_pane_status() {
    echo "📊 pane状況確認"
    echo "================"
    
    if ! command -v tmux &> /dev/null; then
        echo "❌ tmuxが利用できません"
        return 1
    fi
    
    echo ""
    echo "🔍 pane ID確認:"
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "multiagentセッション:"
        tmux list-panes -t multiagent -F "#{pane_index}: #{pane_id} #{pane_current_command} #{pane_active}"
    fi
    
    if tmux has-session -t president 2>/dev/null; then
        echo "presidentセッション:"
        tmux list-panes -t president -F "#{pane_index}: #{pane_id} #{pane_current_command} #{pane_active}"
    fi
    
    echo ""
    echo "🔍 各paneの最新状況:"
    if tmux has-session -t multiagent 2>/dev/null; then
        for i in {0..3}; do
            echo "=== multiagent:0.$i ==="
            tmux capture-pane -t "multiagent:0.$i" -p 2>/dev/null | tail -5 || echo "pane無効"
        done
    fi
    
    if tmux has-session -t president 2>/dev/null; then
        echo "=== president ==="
        tmux capture-pane -t president -p 2>/dev/null | tail -5 || echo "pane無効"
    fi
}

# セッション状態確認
check_sessions() {
    echo "📊 tmuxセッション状態"
    echo "===================="
    
    if ! command -v tmux &> /dev/null; then
        echo "❌ tmuxが利用できません"
        return 1
    fi
    
    echo ""
    echo "🔍 セッション一覧:"
    tmux list-sessions 2>/dev/null || echo "セッションなし"
    
    echo ""
    echo "🔍 presidentセッション:"
    if tmux has-session -t president 2>/dev/null; then
        echo "✅ アクティブ"
        tmux list-panes -t president
    else
        echo "❌ 非アクティブ"
    fi
    
    echo ""
    echo "🔍 multiagentセッション:"
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "✅ アクティブ"
        tmux list-panes -t multiagent
    else
        echo "❌ 非アクティブ"
    fi
}

# ヘルプ表示
show_help() {
    echo "🤖 AI Agent Communication Script v2.0"
    echo "====================================="
    echo ""
    echo "使用方法:"
    echo "  ./ai-agents/agent-send.sh [コマンド] [引数...]"
    echo ""
    echo "基本コマンド:"
    echo "  <agent> <message>    指定エージェントにメッセージ送信"
    echo "  --list               利用可能なエージェント一覧"
    echo "  --claude-setup       Claude Code一括起動"
    echo "  --logs               送信ログ・完了ファイル確認"
    echo "  --status             tmuxセッション状態確認"
    echo "  --panes              pane状況・内容確認（Zenn記事対応）"
    echo "  --help               このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./ai-agents/agent-send.sh boss1 'Hello World プロジェクト開始'"
    echo "  ./ai-agents/agent-send.sh worker1 '作業完了しました'"
    echo "  ./ai-agents/agent-send.sh president '最終報告です'"
    echo ""
    echo "🚀 推奨フロー:"
    echo "  1. ./ai-agents/manage.sh start      # tmux環境起動"
    echo "  2. ./ai-agents/agent-send.sh --claude-setup  # Claude一括起動"
}

# メイン処理
main() {
    init_dirs
    
    case "${1:-help}" in
        "--list")
            list_agents
            ;;
        "--claude-setup")
            setup_claude
            ;;
        "--logs")
            show_logs
            ;;
        "--status")
            check_sessions
            ;;
        "--panes")
            check_pane_status
            ;;
        "--help"|"help")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            # メッセージ送信
            if [ $# -ge 2 ]; then
                send_message "$1" "$2"
            else
                log_error "❌ 引数が不足しています"
                show_help
            fi
            ;;
    esac
}

# スクリプト実行
main "$@" 