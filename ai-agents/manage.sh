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
TMP_DIR="$AGENTS_DIR/tmp"

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

# AI役割の対話システム（実際のClaude Code使用）
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
    local role_upper=$(echo "$role" | tr '[:lower:]' '[:upper:]')
    echo "🤖 AI組織システム - ${role_upper} 対話モード"
    echo "=================================================="
    echo ""
    cat "$instruction_file"
    echo ""
    echo "=================================================="
    echo "💬 Claude Code起動中...（自動認証・権限スキップ）"
    echo ""
    
    # ログ開始
    echo "$(date): ${role} Claude Code セッション開始" >> "$log_file"
    
    # Claude Codeを直接起動（権限スキップ）
    claude --dangerously-skip-permissions
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
    echo "🤖 AI組織管理システム v2.0"
    echo "=========================="
    echo ""
    echo "使用方法:"
    echo "  ./ai-agents/manage.sh [コマンド]"
    echo ""
    echo "🚀 推奨コマンド:"
    echo "  quick-start         4画面AI組織システム起動（全自動）"
    echo "  attach-multiagent   4ワーカー自動起動＋アタッチ（参照リポジトリ準拠）"
    echo "  attach-president    PRESIDENT自動起動＋アタッチ"
    echo ""
    echo "基本コマンド:"
    echo "  start               tmuxセッション作成"
    echo "  clean               セッション削除"
    echo "  claude-setup        Claude Code一括起動"
    echo "  status              システム状況確認"
    echo ""
    echo "🔥 参照リポジトリ準拠の使用法:"
    echo "  1. ./ai-agents/manage.sh quick-start        # セッション作成"
    echo "  2. ./ai-agents/manage.sh attach-multiagent  # 4ワーカー自動起動"
    echo "  3. ./ai-agents/manage.sh attach-president   # PRESIDENT自動起動"
    echo "  または:"
    echo "  tmux attach-session -t multiagent           # 手動アタッチ"
    echo "  tmux attach-session -t president            # 手動アタッチ"
    echo ""
}

# 状況表示
show_status() {
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
    
    # PRESIDENTセッション作成（永続化）
    tmux new-session -d -s president -c "$(pwd)"
    tmux send-keys -t president "echo '🎯 PRESIDENT セッション - 対話開始準備完了'" C-m
    tmux send-keys -t president "echo 'プレジデントモード開始: ./ai-agents/manage.sh president'" C-m
    
    # multiagentセッション作成（4ペイン）
    tmux new-session -d -s multiagent -c "$(pwd)"
    tmux send-keys -t multiagent "echo '👔 BOSS1 ペイン - 対話開始準備完了'" C-m
    tmux send-keys -t multiagent "echo 'ボスモード開始: ./ai-agents/manage.sh boss'" C-m
    
    # 追加ペイン作成
    tmux split-window -t multiagent -h -c "$(pwd)"
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER1 ペイン - 対話開始準備完了'" C-m
    tmux send-keys -t multiagent:0.1 "echo 'ワーカーモード開始: ./ai-agents/manage.sh worker'" C-m
    
    tmux split-window -t multiagent:0.1 -v -c "$(pwd)"
    tmux send-keys -t multiagent:0.2 "echo '👷 WORKER2 ペイン - 対話開始準備完了'" C-m
    tmux send-keys -t multiagent:0.2 "echo 'ワーカーモード開始: ./ai-agents/manage.sh worker'" C-m
    
    tmux select-pane -t multiagent:0.0
    tmux split-window -t multiagent:0.0 -v -c "$(pwd)"
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER3 ペイン - 対話開始準備完了'" C-m
    tmux send-keys -t multiagent:0.1 "echo 'ワーカーモード開始: ./ai-agents/manage.sh worker'" C-m
    
    # レイアウト調整
    tmux select-layout -t multiagent tiled
    
    log_success "✅ tmuxセッションを作成しました"
    echo ""
    echo "📋 セッション確認:"
    echo "  tmux attach-session -t president    # PRESIDENT画面"
    echo "  tmux attach-session -t multiagent   # 4ペイン画面"
    echo ""
    echo "🚀 AI対話開始方法:"
    echo "  各ペインで以下のコマンドを実行:"
    echo "  • PRESIDENT画面: ./ai-agents/manage.sh president"
    echo "  • BOSS画面: ./ai-agents/manage.sh boss"
    echo "  • WORKER画面: ./ai-agents/manage.sh worker"
    echo ""
    echo "🔥 Claude Code一括起動:"
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

# 簡単4画面起動（ユーザー要求対応）
quick_start() {
    log_info "🚀 簡単4画面AI組織システム起動中..."
    
    # 既存セッションの削除
    tmux kill-session -t president 2>/dev/null || true
    tmux kill-session -t multiagent 2>/dev/null || true
    
    # PRESIDENTセッション（Claude Code自動起動）
    tmux new-session -d -s president -c "$(pwd)"
    tmux send-keys -t president "clear" C-m
    tmux send-keys -t president "echo '🎯 PRESIDENT セッション - Claude Code自動起動中...'" C-m
    tmux send-keys -t president "sleep 2" C-m
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    # multiagentセッション（4ペインClaude Code自動起動）
    tmux new-session -d -s multiagent -c "$(pwd)"
    
    # BOSS1ペイン
    tmux send-keys -t multiagent "clear" C-m
    tmux send-keys -t multiagent "echo '👔 BOSS1 ペイン - Claude Code自動起動中...'" C-m
    tmux send-keys -t multiagent "sleep 3" C-m
    tmux send-keys -t multiagent "claude --dangerously-skip-permissions" C-m
    
    # WORKER1ペイン
    tmux split-window -t multiagent -h -c "$(pwd)"
    tmux send-keys -t multiagent:0.1 "clear" C-m
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER1 ペイン - Claude Code自動起動中...'" C-m
    tmux send-keys -t multiagent:0.1 "sleep 4" C-m
    tmux send-keys -t multiagent:0.1 "claude --dangerously-skip-permissions" C-m
    
    # WORKER2ペイン
    tmux split-window -t multiagent:0.1 -v -c "$(pwd)"
    tmux send-keys -t multiagent:0.2 "clear" C-m
    tmux send-keys -t multiagent:0.2 "echo '👷 WORKER2 ペイン - Claude Code自動起動中...'" C-m
    tmux send-keys -t multiagent:0.2 "sleep 5" C-m
    tmux send-keys -t multiagent:0.2 "claude --dangerously-skip-permissions" C-m
    
    # WORKER3ペイン
    tmux select-pane -t multiagent:0.0
    tmux split-window -t multiagent:0.0 -v -c "$(pwd)"
    tmux send-keys -t multiagent:0.1 "clear" C-m
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER3 ペイン - Claude Code自動起動中...'" C-m
    tmux send-keys -t multiagent:0.1 "sleep 6" C-m
    tmux send-keys -t multiagent:0.1 "claude --dangerously-skip-permissions" C-m
    
    # レイアウト最適化
    tmux select-layout -t multiagent tiled
    
    log_success "✅ 4画面AI組織システム起動完了"
    echo ""
    echo "🎯 次の手順で使用開始:"
    echo ""
    echo "【ターミナル1】プレジデント画面:"
    echo "  tmux attach-session -t president"
    echo ""
    echo "【ターミナル2】ワーカー4画面:"
    echo "  tmux attach-session -t multiagent"
    echo ""
    echo "💡 使用方法:"
    echo "  1. ターミナル1（president）で指示開始:"
    echo "     'あなたはpresidentです。指示書に従って'"
    echo ""
    echo "  2. ターミナル2（multiagent）で各AIの作業確認"
    echo ""
    echo "  3. 実際のClaude Code AIが階層組織で動作"
    echo ""
    echo "🔧 システム確認:"
    echo "  tmux list-sessions  # セッション一覧確認"
}

# multiagentセッション自動起動アタッチ（参照リポジトリ対応）
attach_multiagent() {
    log_info "🚀 multiagentセッション自動起動アタッチ中..."
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    # Cursor内で新しいターミナルを開く（macOS対応）
    log_info "🖥️ Cursor内で新ターミナル起動中..."
    
    # 新しいターミナルタブを開く
    if command -v osascript &> /dev/null; then
        # macOSの場合：Cmd+Shift+T で新しいターミナル
        osascript -e 'tell application "System Events" to keystroke "t" using {command down, shift down}' &
        sleep 2
    fi
    
    # 4つのペインでClaude Code自動起動（参照リポジトリ準拠）
    log_info "🤖 4ワーカー自動起動中..."
    
    # ペイン0.0: boss1
    tmux send-keys -t multiagent:0.0 "echo '👔 BOSS1 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.0 "claude --dangerously-skip-permissions" C-m
    
    # ペイン0.1: worker1  
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER1 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.1 "claude --dangerously-skip-permissions" C-m
    
    # ペイン0.2: worker2
    tmux send-keys -t multiagent:0.2 "echo '👷 WORKER2 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.2 "claude --dangerously-skip-permissions" C-m
    
    # ペイン0.3: worker3
    tmux send-keys -t multiagent:0.3 "echo '👷 WORKER3 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.3 "claude --dangerously-skip-permissions" C-m
    
    sleep 1
    log_success "✅ 4ワーカー自動起動完了"
    
    # セッションにアタッチ
    tmux attach-session -t multiagent
}

# presidentセッション自動起動アタッチ
attach_president() {
    log_info "🎯 presidentセッション自動起動アタッチ中..."
    
    # セッション存在確認
    if ! tmux has-session -t president 2>/dev/null; then
        log_error "❌ presidentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh quick-start"
        return 1
    fi
    
    # Claude Code自動起動
    tmux send-keys -t president "echo '🎯 PRESIDENT - Claude Code起動中...'" C-m
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    sleep 1
    log_success "✅ PRESIDENT自動起動完了"
    
    # セッションにアタッチ
    tmux attach-session -t president
}

# 初期化関数
init_dirs() {
    # 必要なディレクトリを作成
    mkdir -p "$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR" "$TMP_DIR"
    
    # ログディレクトリ内のサブディレクトリ作成
    mkdir -p "$LOGS_DIR/ai-agents" "$LOGS_DIR/system"
}

# 正確なClaude Code起動手順（参照リポジトリ準拠）
setup_claude_correct_flow() {
    log_info "🎯 正確なClaude Code起動手順"
    echo ""
    echo "📋 手順1: PRESIDENTセッション起動"
    
    # セッション存在確認（なければ自動作成）
    if ! tmux has-session -t president 2>/dev/null; then
        log_warn "⚠️ tmuxセッションが存在しません。自動作成します..."
        launch_tmux_sessions
        sleep 1
        log_success "✅ tmuxセッション自動作成完了"
    fi
    
    # PRESIDENT起動（権限スキップ）
    log_info "👑 PRESIDENT起動中..."
    tmux send-keys -t president 'claude --dangerously-skip-permissions' C-m
    
    # 起動待機
    sleep 3
    
    # 自動的に初期メッセージを送信
    log_info "📋 指示書読み込み中..."
    tmux send-keys -t president 'あなたはpresidentです。指示書に従って' C-m
    
    # さらに少し待機してから4画面を背景で起動
    sleep 2
    log_info "🚀 4画面を背景で自動起動コマンド送信中..."
    tmux send-keys -t president 'nohup ./ai-agents/manage.sh attach-multiagent > /dev/null 2>&1 &' C-m
    
    echo ""
    echo "✅ 自動化完了！以下が実行されました:"
    echo "  1. PRESIDENTにClaude Code起動"
    echo "  2. 初期メッセージ「あなたはpresidentです。指示書に従って」送信"
    echo "  3. Cursor内新ターミナルで4画面自動起動コマンド送信"
    echo ""
    echo "📋 指示書の場所:"
    echo "  ./ai-agents/instructions/president.md"
    echo ""
    echo "📊 確認方法:"
    echo "  tmux attach-session -t president    # PRESIDENT画面"
    echo "  tmux attach-session -t multiagent   # 4画面確認"
    echo ""
    
    # PRESIDENTセッションに自動アタッチ
    log_success "✅ PRESIDENT起動完了 - セッションに接続します"
    sleep 1
    tmux attach-session -t president
}

# 手動4画面起動（バックアップ用）
manual_multiagent_start() {
    log_info "🔧 手動4画面起動（バックアップ用）"
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    log_info "👥 手動4画面起動中..."
    
    # 権限スキップで起動
    for i in {0..3}; do 
        tmux send-keys -t multiagent:0.$i 'claude --dangerously-skip-permissions' C-m
        sleep 0.5
    done
    
    log_success "✅ 手動4画面起動完了"
    echo ""
}

# メイン処理（参照リポジトリ準拠）
main() {
    init_dirs
    
    case "${1:-help}" in
        # 🚀 参照リポジトリ準拠の基本コマンド
        "start")
            # tmuxセッション作成のみ
            log_info "🚀 tmuxセッション作成中..."
            launch_tmux_sessions
            echo ""
            echo "📋 次のステップ（参照リポジトリ準拠）:"
            echo "  1. ./ai-agents/manage.sh claude-auth     # PRESIDENT認証"
            echo "  2. ./ai-agents/manage.sh multiagent-start # multiagent起動"
            echo ""
            ;;
        "claude-auth")
            # PRESIDENT認証（段階1）
            setup_claude_correct_flow
            ;;
        "auto")
            # 🚀 ワンコマンド起動（全自動）
            log_info "🚀 AI組織システム全自動起動中..."
            setup_claude_correct_flow
            ;;
        "multiagent-start")
            # multiagent一括起動（段階2）
            manual_multiagent_start
            ;;
        "president")  
            # PRESIDENT画面アタッチ
            if tmux has-session -t president 2>/dev/null; then
                tmux attach-session -t president
            else
                log_error "❌ presidentセッションが存在しません。先に './ai-agents/manage.sh start' を実行してください"
            fi
            ;;
        "multiagent")
            # multiagent画面アタッチ
            if tmux has-session -t multiagent 2>/dev/null; then
                tmux attach-session -t multiagent
            else
                log_error "❌ multiagentセッションが存在しません。先に './ai-agents/manage.sh start' を実行してください"
            fi
            ;;
        "clean")
            # セッション削除
            clean_sessions
            ;;
        # 🔧 詳細コマンド（必要時のみ）
        "quick-start")
            quick_start
            ;;
        "claude-setup")
            setup_claude_code
            ;;
        "status")
            system_status
            ;;
        "help"|"--help"|"-h"|*)
            echo "🤖 AI組織システム - 起動方法"
            echo "============================"
            echo ""
            echo "🚀 簡単起動（推奨）:"
            echo "  ./ai-agents/manage.sh auto               # ワンコマンド全自動起動"
            echo ""
            echo "🔧 詳細起動（必要時のみ）:"
            echo "  1. ./ai-agents/manage.sh start           # tmuxセッション作成のみ"
            echo "  2. ./ai-agents/manage.sh claude-auth     # PRESIDENT起動（自動セッション作成対応）"
            echo ""
            echo "📋 PRESIDENTに送信するコマンド:"
            echo "  for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude --dangerously-skip-permissions' C-m; done"
            echo ""
            echo "📊 セッション操作:"
            echo "  ./ai-agents/manage.sh president          # PRESIDENT画面"
            echo "  ./ai-agents/manage.sh multiagent         # 4画面確認"
            echo "  ./ai-agents/manage.sh clean              # セッション削除"
            echo ""
            echo "💡 参照リポジトリ:"
            echo "  https://github.com/Akira-Papa/Claude-Code-Communication"
            echo ""
            ;;
    esac
}

# スクリプト実行
main "$@"
