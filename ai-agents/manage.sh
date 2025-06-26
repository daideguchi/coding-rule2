#!/bin/bash
# 🤖 AI組織管理システム v2.0
# プレジデント、ボス、ワーカーの4画面AI組織システム

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

# 基本ディレクトリ設定
AGENTS_DIR="ai-agents"
LOGS_DIR="$AGENTS_DIR/logs"
SESSIONS_DIR="$AGENTS_DIR/sessions"
INSTRUCTIONS_DIR="$AGENTS_DIR/instructions"

# 必要ディレクトリの作成
init_directories() {
    mkdir -p "$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR"
    log_info "📁 ディレクトリ構造を初期化しました"
}

# セッションファイルの作成
create_session() {
    local role=$1
    local session_file="$SESSIONS_DIR/${role}_session.json"
    local timestamp=$(date -Iseconds)
    
    cat > "$session_file" << EOF
{
  "role": "$role",
  "session_id": "$(uuidgen 2>/dev/null || echo "session_$(date +%s)")",
  "start_time": "$timestamp",
  "status": "active",
  "messages": [],
  "context": {
    "current_task": null,
    "priority": "normal",
    "dependencies": []
  }
}
EOF
    
    log_success "📝 ${role} セッションを作成しました: $session_file"
}

# AI役割の対話システム
start_ai_chat() {
    local role=$1
    local instruction_file="$INSTRUCTIONS_DIR/${role}.md"
    local session_file="$SESSIONS_DIR/${role}_session.json"
    local log_file="$LOGS_DIR/${role}.log"
    
    if [ ! -f "$instruction_file" ]; then
        log_error "❌ 指示書が見つかりません: $instruction_file"
        return 1
    fi
    
    clear
    echo "🤖 AI組織システム - ${role^^} 対話モード"
    echo "=================================================="
    echo ""
    cat "$instruction_file"
    echo ""
    echo "=================================================="
    echo "💬 対話を開始します。'exit'で終了、'help'でヘルプ"
    echo ""
    
    # ログ開始
    echo "$(date): ${role} 対話セッション開始" >> "$log_file"
    
    while true; do
        echo -n "${role^^}> "
        read -r user_input
        
        case "$user_input" in
            "exit"|"quit"|"q")
                echo "$(date): ${role} セッション終了" >> "$log_file"
                log_info "👋 ${role} セッションを終了します"
                break
                ;;
            "help"|"h")
                show_help "$role"
                ;;
            "status"|"s")
                show_status "$role"
                ;;
            "clear"|"c")
                clear
                echo "🤖 AI組織システム - ${role^^} 対話モード"
                echo "=================================================="
                ;;
            "")
                continue
                ;;
            *)
                # ユーザー入力をログに記録
                echo "$(date): USER: $user_input" >> "$log_file"
                
                # AI応答をシミュレート（実際のAI統合時はここを置き換え）
                ai_response=$(generate_ai_response "$role" "$user_input")
                echo "$(date): AI: $ai_response" >> "$log_file"
                
                echo "🤖 $ai_response"
                echo ""
                ;;
        esac
    done
}

# AI応答生成（シミュレート版）
generate_ai_response() {
    local role=$1
    local input=$2
    
    case "$role" in
        "president")
            echo "プレジデントとして承知しました。「$input」について戦略的に検討し、適切な指示をボスに伝達します。"
            ;;
        "boss")
            echo "ボスとして了解しました。「$input」の作業をワーカーに分担し、進捗を管理します。"
            ;;
        "worker")
            echo "ワーカーとして承知しました。「$input」の作業を実行し、完了次第ボスに報告します。"
            ;;
        *)
            echo "役割が不明です。適切な指示をお願いします。"
            ;;
    esac
}

# ヘルプ表示
show_help() {
    local role=$1
    echo ""
    echo "📚 ${role^^} ヘルプ"
    echo "===================="
    echo "exit/quit/q  - セッション終了"
    echo "help/h       - このヘルプを表示"
    echo "status/s     - 現在の状況を表示"
    echo "clear/c      - 画面をクリア"
    echo ""
    echo "💡 ${role} の役割に応じた指示を入力してください"
    echo ""
}

# 状況表示
show_status() {
    local role=$1
    local session_file="$SESSIONS_DIR/${role}_session.json"
    local log_file="$LOGS_DIR/${role}.log"
    
    echo ""
    echo "📊 ${role^^} 状況"
    echo "=================="
    echo "役割: $role"
    echo "セッション: $([ -f "$session_file" ] && echo "アクティブ" || echo "非アクティブ")"
    echo "ログファイル: $log_file"
    
    if [ -f "$log_file" ]; then
        echo "最新ログ:"
        tail -3 "$log_file" | sed 's/^/  /'
    fi
    echo ""
}

# 4画面起動システム（Cursor内ターミナル + tmux対応）
launch_four_screens() {
    log_info "🚀 4画面AI組織システムを起動中..."
    
    # tmuxが利用可能かチェック
    if command -v tmux &> /dev/null; then
        launch_tmux_sessions
    else
        launch_cursor_terminals
    fi
}

# tmux環境での起動（推奨）
launch_tmux_sessions() {
    log_info "📊 tmux環境でAI組織システムを起動中..."
    
    # 既存セッションの削除
    tmux kill-session -t president 2>/dev/null || true
    tmux kill-session -t multiagent 2>/dev/null || true
    
    # PRESIDENTセッション作成
    tmux new-session -d -s president -c "$(pwd)" \
        "echo '🎯 PRESIDENT セッション' && ./ai-agents/manage.sh president"
    
    # multiagentセッション作成（4ペイン）
    tmux new-session -d -s multiagent -c "$(pwd)" \
        "echo '👔 BOSS1 ペイン' && ./ai-agents/manage.sh boss"
    
    # 追加ペイン作成
    tmux split-window -t multiagent -h -c "$(pwd)" \
        "echo '👷 WORKER1 ペイン' && ./ai-agents/manage.sh worker"
    
    tmux split-window -t multiagent -v -c "$(pwd)" \
        "echo '👷 WORKER2 ペイン' && ./ai-agents/manage.sh worker"
    
    tmux select-pane -t multiagent:0.0
    tmux split-window -t multiagent -v -c "$(pwd)" \
        "echo '👷 WORKER3 ペイン' && ./ai-agents/manage.sh worker"
    
    log_success "✅ tmuxセッションを作成しました"
    echo ""
    echo "📋 セッション確認:"
    echo "  tmux attach-session -t president    # PRESIDENT画面"
    echo "  tmux attach-session -t multiagent   # 4ペイン画面"
    echo ""
    echo "🚀 Claude Code一括起動:"
    echo "  ./ai-agents/manage.sh claude-setup  # 全セッションでClaude起動"
}

# Cursor内ターミナルでの起動
launch_cursor_terminals() {
    log_info "💻 Cursor内ターミナルでAI組織システムを起動中..."
    
    # macOSの場合
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Cursorアプリケーション向けのターミナル起動
        osascript << EOF
tell application "Cursor"
    activate
end tell

tell application "System Events"
    tell process "Cursor"
        -- 新しいターミナルを開く（Cmd+Shift+\`）
        keystroke "\`" using {command down, shift down}
        delay 0.5
        
        -- PRESIDENT起動
        keystroke "echo '🎯 PRESIDENT画面' && ./ai-agents/manage.sh president"
        key code 36
        
        delay 1
        
        -- 新しいターミナル（BOSS）
        keystroke "\`" using {command down, shift down}
        delay 0.5
        keystroke "echo '👔 BOSS画面' && ./ai-agents/manage.sh boss"
        key code 36
        
        delay 1
        
        -- 新しいターミナル（WORKER1）
        keystroke "\`" using {command down, shift down}
        delay 0.5
        keystroke "echo '👷 WORKER1画面' && ./ai-agents/manage.sh worker"
        key code 36
        
        delay 1
        
        -- 新しいターミナル（WORKER2）
        keystroke "\`" using {command down, shift down}
        delay 0.5
        keystroke "echo '👷 WORKER2画面' && ./ai-agents/manage.sh worker"
        key code 36
    end tell
end tell
EOF
        log_success "✅ Cursor内ターミナルを起動しました"
        
    # Linuxの場合
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # gnome-terminalまたはxtermを使用
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --tab --title="PRESIDENT" -- bash -c "cd $(pwd) && echo '🎯 PRESIDENT画面' && ./ai-agents/manage.sh president; exec bash" &
            gnome-terminal --tab --title="BOSS" -- bash -c "cd $(pwd) && echo '👔 BOSS画面' && ./ai-agents/manage.sh boss; exec bash" &
            gnome-terminal --tab --title="WORKER1" -- bash -c "cd $(pwd) && echo '👷 WORKER1画面' && ./ai-agents/manage.sh worker; exec bash" &
            gnome-terminal --tab --title="WORKER2" -- bash -c "cd $(pwd) && echo '👷 WORKER2画面' && ./ai-agents/manage.sh worker; exec bash" &
            log_success "✅ 4画面を起動しました（Linux gnome-terminal）"
        elif command -v xterm &> /dev/null; then
            xterm -T "PRESIDENT" -e "cd $(pwd) && echo '🎯 PRESIDENT画面' && ./ai-agents/manage.sh president" &
            xterm -T "BOSS" -e "cd $(pwd) && echo '👔 BOSS画面' && ./ai-agents/manage.sh boss" &
            xterm -T "WORKER1" -e "cd $(pwd) && echo '👷 WORKER1画面' && ./ai-agents/manage.sh worker" &
            xterm -T "WORKER2" -e "cd $(pwd) && echo '👷 WORKER2画面' && ./ai-agents/manage.sh worker" &
            log_success "✅ 4画面を起動しました（Linux xterm）"
        else
            log_error "❌ 対応するターミナルエミュレータが見つかりません"
            return 1
        fi
    else
        log_warn "⚠️  このOSでは自動4画面起動をサポートしていません"
        echo "手動で以下のコマンドを4つの別ターミナルで実行してください："
        echo "  ./ai-agents/manage.sh president"
        echo "  ./ai-agents/manage.sh boss"
        echo "  ./ai-agents/manage.sh worker"
        echo "  ./ai-agents/manage.sh worker"
    fi
}

# システム状況確認
system_status() {
    echo "🤖 AI組織システム状況"
    echo "======================"
    echo ""
    
    # ディレクトリ確認
    echo "📁 ディレクトリ状況:"
    for dir in "$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR"; do
        if [ -d "$dir" ]; then
            echo "  ✅ $dir"
        else
            echo "  ❌ $dir (未作成)"
        fi
    done
    echo ""
    
    # 指示書確認
    echo "📋 指示書状況:"
    for role in president boss worker; do
        local file="$INSTRUCTIONS_DIR/${role}.md"
        if [ -f "$file" ]; then
            echo "  ✅ $role ($file)"
        else
            echo "  ❌ $role ($file 未作成)"
        fi
    done
    echo ""
    
    # アクティブセッション確認
    echo "💬 アクティブセッション:"
    if [ -d "$SESSIONS_DIR" ] && [ "$(ls -A $SESSIONS_DIR 2>/dev/null)" ]; then
        ls -la "$SESSIONS_DIR"/*.json 2>/dev/null | sed 's/^/  /' || echo "  なし"
    else
        echo "  なし"
    fi
    echo ""
    
    # ログファイル確認
    echo "📊 ログファイル:"
    if [ -d "$LOGS_DIR" ] && [ "$(ls -A $LOGS_DIR 2>/dev/null)" ]; then
        ls -la "$LOGS_DIR"/*.log 2>/dev/null | sed 's/^/  /' || echo "  なし"
    else
        echo "  なし"
    fi
}

# Claude Code一括起動
setup_claude_code() {
    log_info "🚀 Claude Code一括起動システム..."
    
    # agent-send.shを使用
    if [ -f "./ai-agents/agent-send.sh" ]; then
        chmod +x "./ai-agents/agent-send.sh"
        "./ai-agents/agent-send.sh" --claude-setup
    else
        log_error "❌ agent-send.shが見つかりません"
        return 1
    fi
}

# デモ実行
run_demo() {
    log_info "🎬 Hello World デモ実行..."
    
    # agent-send.shを使用
    if [ -f "./ai-agents/agent-send.sh" ]; then
        chmod +x "./ai-agents/agent-send.sh"
        "./ai-agents/agent-send.sh" --demo
    else
        log_error "❌ agent-send.shが見つかりません"
        return 1
    fi
}

# メイン処理
main() {
    case "${1:-help}" in
        "president"|"boss"|"worker")
            init_directories
            create_session "$1"
            start_ai_chat "$1"
            ;;
        "start"|"launch")
            init_directories
            launch_four_screens
            ;;
        "claude-setup")
            setup_claude_code
            ;;
        "demo")
            run_demo
            ;;
        "status")
            system_status
            ;;
        "init")
            init_directories
            log_success "🎉 AI組織システムを初期化しました"
            ;;
        "clean"|"clear")
            rm -rf "$SESSIONS_DIR"/*.json 2>/dev/null || true
            rm -rf "$LOGS_DIR"/*.log 2>/dev/null || true
            log_success "🧹 セッションとログをクリアしました"
            ;;
        "help"|*)
            echo "🤖 AI組織管理システム v2.0"
            echo "=========================="
            echo ""
            echo "使用方法:"
            echo "  ./ai-agents/manage.sh [コマンド]"
            echo ""
            echo "コマンド:"
            echo "  president      プレジデント対話モード開始"
            echo "  boss           ボス対話モード開始"
            echo "  worker         ワーカー対話モード開始"
            echo "  start          4画面AI組織システム起動"
            echo "  launch         4画面AI組織システム起動（startと同じ）"
            echo "  claude-setup   Claude Code一括起動"
            echo "  demo           Hello Worldデモ実行"
            echo "  status         システム状況確認"
            echo "  init           システム初期化"
            echo "  clean          セッション・ログクリア"
            echo "  clear          セッション・ログクリア（cleanと同じ）"
            echo "  help           このヘルプを表示"
            echo ""
            echo "🚀 推奨使用方法:"
            echo "  1. ./ai-agents/manage.sh start        # 4画面起動"
            echo "  2. ./ai-agents/manage.sh claude-setup # Claude一括起動"
            echo "  3. ./ai-agents/manage.sh demo         # デモ実行"
            echo ""
            ;;
    esac
}

# スクリプト実行
main "$@"
