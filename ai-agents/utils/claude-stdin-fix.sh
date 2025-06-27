#!/bin/bash
# 🔧 Claude Code stdin エラー修正スクリプト
# "Raw mode is not supported on the current process.stdin" エラーの解決

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

# 方法1: 疑似ターミナル (PTY) を使用した起動
start_claude_with_pty() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 疑似ターミナル (PTY) を使用してClaude Code起動中..."
    
    # script コマンドを使用して PTY を作成
    tmux send-keys -t "${session_name}:${pane_id}" "script -q /dev/null claude --dangerously-skip-permissions" C-m
    
    # 1秒後に「2」を送信
    sleep 1
    tmux send-keys -t "${session_name}:${pane_id}" "2" C-m
    
    log_success "✅ PTY経由でClaude Code起動コマンド送信完了"
}

# 方法2: ターミナル設定を調整した起動
start_claude_with_terminal_config() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 ターミナル設定調整でClaude Code起動中..."
    
    # 環境変数を設定してClaude Codeを起動
    tmux send-keys -t "${session_name}:${pane_id}" "TERM=xterm-256color FORCE_COLOR=1 claude --dangerously-skip-permissions" C-m
    
    # 0.5秒後に「2」を送信
    sleep 0.5
    tmux send-keys -t "${session_name}:${pane_id}" "2" C-m
    
    log_success "✅ ターミナル設定調整でClaude Code起動コマンド送信完了"
}

# 方法3: socat を使用したパイプライン起動
start_claude_with_socat() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 socat を使用してClaude Code起動中..."
    
    if command -v socat &> /dev/null; then
        # socatでパイプラインを作成
        tmux send-keys -t "${session_name}:${pane_id}" "echo '2' | socat - EXEC:'claude --dangerously-skip-permissions',pty,raw,echo=0" C-m
        log_success "✅ socat経由でClaude Code起動コマンド送信完了"
    else
        log_error "❌ socat コマンドが見つかりません"
        return 1
    fi
}

# 方法4: stdbuf を使用したバッファリング調整
start_claude_with_stdbuf() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 stdbuf を使用してClaude Code起動中..."
    
    # stdbufでバッファリングを調整
    tmux send-keys -t "${session_name}:${pane_id}" "echo '2' | stdbuf -i0 -o0 -e0 claude --dangerously-skip-permissions" C-m
    
    log_success "✅ stdbuf経由でClaude Code起動コマンド送信完了"
}

# 方法5: unbuffer を使用した起動
start_claude_with_unbuffer() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 unbuffer を使用してClaude Code起動中..."
    
    if command -v unbuffer &> /dev/null; then
        # unbufferでバッファリングを無効化
        tmux send-keys -t "${session_name}:${pane_id}" "echo '2' | unbuffer claude --dangerously-skip-permissions" C-m
        log_success "✅ unbuffer経由でClaude Code起動コマンド送信完了"
    else
        log_error "❌ unbuffer コマンドが見つかりません（expect パッケージをインストールしてください）"
        return 1
    fi
}

# 方法6: tmux split-window を使用したサブシェル起動
start_claude_with_subshell() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 tmux サブシェルでClaude Code起動中..."
    
    # 新しいペインを作成してClaude Codeを起動
    tmux split-window -t "${session_name}:${pane_id}" -c "$(pwd)"
    local new_pane=$(tmux display-message -t "${session_name}" -p "#{pane_id}")
    
    # 新しいペインでClaude Codeを起動
    tmux send-keys -t "${session_name}:${new_pane}" "claude --dangerously-skip-permissions" C-m
    
    # 0.5秒後に「2」を送信
    sleep 0.5
    tmux send-keys -t "${session_name}:${new_pane}" "2" C-m
    
    # 元のペインを閉じて、新しいペインをメインにする
    tmux kill-pane -t "${session_name}:${pane_id}"
    
    log_success "✅ サブシェル経由でClaude Code起動完了"
}

# 統合自動化（複数手法を順次試行）
start_claude_auto_fallback() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🚀 Claude Code 統合自動化起動中（複数手法フォールバック）..."
    
    # 方法1: PTY を試行
    log_info "1️⃣ PTY方法を試行中..."
    start_claude_with_pty "$session_name" "$pane_id"
    sleep 3
    
    # 起動確認
    screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
    if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
        log_success "✅ PTY方法で起動成功"
        return 0
    fi
    
    # エラーが表示されている場合は次の方法を試行
    if echo "$screen_content" | grep -q "Raw mode is not supported\|Error:" 2>/dev/null; then
        log_warn "⚠️ PTY方法失敗、ターミナル設定調整方法を試行..."
        tmux send-keys -t "${session_name}:${pane_id}" C-c  # 現在のプロセスを停止
        sleep 1
        
        # 方法2: ターミナル設定調整を試行
        start_claude_with_terminal_config "$session_name" "$pane_id"
        sleep 3
        
        screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
        if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
            log_success "✅ ターミナル設定調整方法で起動成功"
            return 0
        fi
    fi
    
    # さらにエラーの場合は stdbuf を試行
    if echo "$screen_content" | grep -q "Raw mode is not supported\|Error:" 2>/dev/null; then
        log_warn "⚠️ ターミナル設定調整方法失敗、stdbuf方法を試行..."
        tmux send-keys -t "${session_name}:${pane_id}" C-c
        sleep 1
        
        # 方法4: stdbuf を試行
        start_claude_with_stdbuf "$session_name" "$pane_id"
        sleep 3
        
        screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
        if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
            log_success "✅ stdbuf方法で起動成功"
            return 0
        fi
    fi
    
    log_error "❌ 全ての自動化方法が失敗しました"
    return 1
}

# Claude Code起動状況確認
check_claude_status() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔍 Claude Code起動状況確認中..."
    
    screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
    
    if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
        log_success "✅ Claude Code正常起動中"
        return 0
    elif echo "$screen_content" | grep -q "Raw mode is not supported" 2>/dev/null; then
        log_error "❌ stdin Raw mode エラー検出"
        return 1
    elif echo "$screen_content" | grep -q "Error:" 2>/dev/null; then
        log_error "❌ その他のエラー検出"
        return 1
    else
        log_warn "⚠️ Claude Code起動状況不明"
        return 2
    fi
}

# メイン処理
main() {
    case "${1:-help}" in
        "pty")
            start_claude_with_pty "$2" "$3"
            ;;
        "terminal")
            start_claude_with_terminal_config "$2" "$3"
            ;;
        "socat")
            start_claude_with_socat "$2" "$3"
            ;;
        "stdbuf")
            start_claude_with_stdbuf "$2" "$3"
            ;;
        "unbuffer")
            start_claude_with_unbuffer "$2" "$3"
            ;;
        "subshell")
            start_claude_with_subshell "$2" "$3"
            ;;
        "auto")
            start_claude_auto_fallback "$2" "$3"
            ;;
        "check")
            check_claude_status "$2" "$3"
            ;;
        "help"|*)
            echo "🔧 Claude Code stdin エラー修正スクリプト"
            echo "=========================================="
            echo ""
            echo "使用方法:"
            echo "  ./ai-agents/claude-stdin-fix.sh [方法] [session] [pane]"
            echo ""
            echo "修正方法:"
            echo "  pty [session] [pane]       # 疑似ターミナル使用"
            echo "  terminal [session] [pane]  # ターミナル設定調整"
            echo "  socat [session] [pane]     # socat パイプライン"
            echo "  stdbuf [session] [pane]    # バッファリング調整"
            echo "  unbuffer [session] [pane]  # unbuffer 使用"
            echo "  subshell [session] [pane]  # tmux サブシェル"
            echo "  auto [session] [pane]      # 自動フォールバック（推奨）"
            echo "  check [session] [pane]     # 起動状況確認"
            echo ""
            echo "例:"
            echo "  ./ai-agents/claude-stdin-fix.sh auto president 0"
            echo "  ./ai-agents/claude-stdin-fix.sh pty multiagent 0.1"
            echo "  ./ai-agents/claude-stdin-fix.sh check president 0"
            echo ""
            echo "📋 Raw mode エラーが発生した場合の対処順序:"
            echo "  1. auto 方法で自動修正試行"
            echo "  2. 手動で pty → terminal → stdbuf の順で試行"
            echo "  3. check で起動状況確認"
            echo ""
            ;;
    esac
}

# スクリプト実行
main "$@" 