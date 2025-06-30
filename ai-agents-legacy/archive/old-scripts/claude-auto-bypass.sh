#!/bin/bash
# 🤖 Claude Code 自動 Bypass Permissions スクリプト
# Claude Code起動時の「2. Yes, I accept」を自動選択

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

# expectを使った自動化（macOS対応）
auto_bypass_with_expect() {
    if command -v expect &> /dev/null; then
        log_info "🔧 expect を使用した自動化を実行中..."
        
        expect << 'EOF'
#!/usr/bin/expect -f
set timeout 30

# Claude Code起動
spawn claude --dangerously-skip-permissions

# Bypass Permissions mode の選択待ち
expect {
    "❯ 1. No, exit" {
        send "2\r"
        exp_continue
    }
    "2. Yes, I accept" {
        send "2\r"
        exp_continue
    }
    timeout {
        puts "タイムアウト: 30秒以内に応答がありませんでした"
        exit 1
    }
    eof {
        puts "Claude Code が正常に起動しました"
        exit 0
    }
}

# Claude Code の完全起動を待機
expect {
    "Welcome to Claude Code" {
        puts "Claude Code 起動完了"
        exit 0
    }
    "cwd:" {
        puts "Claude Code 起動完了"
        exit 0
    }
    timeout {
        puts "Claude Code 起動タイムアウト"
        exit 1
    }
}
EOF
        
        if [ $? -eq 0 ]; then
            log_success "✅ expect による自動化成功"
            return 0
        else
            log_error "❌ expect による自動化失敗"
            return 1
        fi
    else
        log_error "❌ expect コマンドが見つかりません"
        return 1
    fi
}

# パイプを使った自動化（バックアップ手法）
auto_bypass_with_pipe() {
    log_info "🔧 パイプを使用した自動化を実行中..."
    
    # 複数の「2」を送信して確実にする
    {
        sleep 0.5; echo "2"
        sleep 1; echo "2"  
        sleep 2; echo "2"
        sleep 3; echo "2"
    } | claude --dangerously-skip-permissions
    
    if [ $? -eq 0 ]; then
        log_success "✅ パイプによる自動化成功"
        return 0
    else
        log_error "❌ パイプによる自動化失敗"
        return 1
    fi
}

# バックグラウンドプロセスでの自動化
auto_bypass_with_background() {
    log_info "🔧 バックグラウンドプロセスによる自動化を実行中..."
    
    # バックグラウンドで自動応答プロセスを開始
    {
        for i in {1..10}; do
            sleep 0.5
            echo "2"
        done
    } &
    
    local bg_pid=$!
    
    # Claude Code起動
    claude --dangerously-skip-permissions
    local claude_exit_code=$?
    
    # バックグラウンドプロセス停止
    kill $bg_pid 2>/dev/null || true
    
    if [ $claude_exit_code -eq 0 ]; then
        log_success "✅ バックグラウンドプロセスによる自動化成功"
        return 0
    else
        log_error "❌ バックグラウンドプロセスによる自動化失敗"
        return 1
    fi
}

# tmuxセッション内での自動化
auto_bypass_in_tmux() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🔧 tmuxセッション内での自動化を実行中... (${session_name}:${pane_id})"
    
    # Claude Code起動コマンドを送信（stdin無効化）
    tmux send-keys -t "${session_name}:${pane_id}" "claude --dangerously-skip-permissions < /dev/null" C-m
    
    # 0.5秒後に「2」を送信（Bypass Permissions自動選択）
    sleep 0.5
    tmux send-keys -t "${session_name}:${pane_id}" "2" C-m
    
    # さらに保険として1秒後にもう一度「2」を送信
    sleep 1
    tmux send-keys -t "${session_name}:${pane_id}" "2" C-m
    
    # Claude Code起動完了を検知（最大30秒）
    for i in {1..60}; do
        screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
        
        if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
            log_success "✅ tmuxセッション内での自動化成功 (${i}/60秒)"
            return 0
        fi
        
        sleep 0.5
    done
    
    log_error "❌ tmuxセッション内での自動化タイムアウト（30秒）"
    return 1
}

# 高度な自動化（複数手法の組み合わせ）
auto_bypass_advanced() {
    local session_name=${1:-"claude-auto"}
    local pane_id=${2:-"0"}
    
    log_info "🚀 高度な自動化システム起動中..."
    
    # Claude Code起動コマンドを送信（stdin無効化）
    tmux send-keys -t "${session_name}:${pane_id}" "claude --dangerously-skip-permissions < /dev/null" C-m
    
    # バックグラウンドで継続的に「2」を送信するプロセス開始
    {
        for i in {1..60}; do  # 30秒間継続
            sleep 0.5
            
            # 画面内容を取得
            screen_content=$(tmux capture-pane -t "${session_name}:${pane_id}" -p 2>/dev/null || echo "")
            
            # Bypass Permissions画面を検知したら「2」を送信
            if echo "$screen_content" | grep -q "Yes, I accept\|Bypass Permissions" 2>/dev/null; then
                tmux send-keys -t "${session_name}:${pane_id}" "2" C-m
                log_success "✅ Bypass Permissions 自動選択実行 (${i}/60)"
            fi
            
            # Claude Code起動完了を検知
            if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
                log_success "✅ Claude Code起動完了検知 (${i}/60秒)"
                break
            fi
        done
        
        if [ $i -eq 60 ]; then
            log_error "❌ 高度な自動化タイムアウト（30秒）"
        fi
    } &
    
    local auto_pid=$!
    
    # 一定時間後にバックグラウンドプロセスを停止
    {
        sleep 35
        kill $auto_pid 2>/dev/null || true
    } &
    
    log_success "✅ 高度な自動化システム起動完了"
    echo "📊 動作状況："
    echo "  - Bypass Permissions 自動検知・選択"
    echo "  - Claude Code 起動完了自動検知"
    echo "  - 最大30秒間の継続監視"
}

# メイン処理
main() {
    case "${1:-help}" in
        "expect")
            auto_bypass_with_expect
            ;;
        "pipe")
            auto_bypass_with_pipe
            ;;
        "background")
            auto_bypass_with_background
            ;;
        "tmux")
            auto_bypass_in_tmux "$2" "$3"
            ;;
        "advanced")
            auto_bypass_advanced "$2" "$3"
            ;;
        "test")
            log_info "🧪 全手法テスト実行中..."
            echo "1. expect手法テスト:"
            auto_bypass_with_expect
            echo ""
            echo "2. パイプ手法テスト:"
            auto_bypass_with_pipe
            echo ""
            ;;
        "help"|*)
            echo "🤖 Claude Code 自動 Bypass Permissions スクリプト"
            echo "================================================="
            echo ""
            echo "使用方法:"
            echo "  ./ai-agents/claude-auto-bypass.sh [オプション]"
            echo ""
            echo "オプション:"
            echo "  expect                    # expect を使用した自動化"
            echo "  pipe                      # パイプ を使用した自動化"
            echo "  background                # バックグラウンドプロセス自動化"
            echo "  tmux [session] [pane]     # tmuxセッション内での自動化"
            echo "  advanced [session] [pane] # 高度な自動化（推奨）"
            echo "  test                      # 全手法テスト"
            echo ""
            echo "例:"
            echo "  ./ai-agents/claude-auto-bypass.sh advanced president 0"
            echo "  ./ai-agents/claude-auto-bypass.sh tmux multiagent 0.1"
            echo ""
            ;;
    esac
}

# スクリプト実行
main "$@" 