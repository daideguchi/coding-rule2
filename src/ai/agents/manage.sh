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
    
    # Claude Codeを高度な自動化で起動（stdin エラー対応）
    if [ -f "./ai-agents/claude-stdin-fix.sh" ]; then
        # stdin エラー修正スクリプトを使用
        ./ai-agents/claude-stdin-fix.sh auto "$(tmux display-message -p '#S')" "$(tmux display-message -p '#P')"
    elif [ -f "./ai-agents/claude-auto-bypass.sh" ]; then
        # 従来の自動化スクリプトを使用
        ./ai-agents/claude-auto-bypass.sh advanced "$(tmux display-message -p '#S')" "$(tmux display-message -p '#P')"
    else
        # フォールバック
        printf "2\n" | claude --dangerously-skip-permissions < /dev/null
    fi
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
    
    log_success "✅ AI組織システムのtmuxセッションを作成しました"
    echo ""
    echo "📋 【日本語対応】AI組織システム状況確認:"
    echo "  tmux attach-session -t president    # 👑 PRESIDENT画面（統括AI）"
    echo "  tmux attach-session -t multiagent   # 👥 4画面表示（BOSS+WORKER）"
    echo ""
    echo "🚀 【簡単3ステップ】AI組織システム起動方法:"
    echo "  1️⃣ ./ai-agents/manage.sh auto           # ワンコマンド起動"
    echo "  2️⃣ PRESIDENT画面でプロジェクト指示      # AIに日本語で指示"
    echo "  3️⃣ tmux attach-session -t multiagent   # 4画面でAI活動監視"
    echo ""
    echo "🎯 【Claude Code状態】全てのAIが日本語対応で起動準備完了"
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
    
    # バックグラウンドで即座メッセージ送信処理を実行
    (
        # PRESIDENT即座起動検知（0.5秒間隔でチェック）
        while ! tmux capture-pane -t president -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:"; do
            sleep 0.5
        done
        
        # PRESIDENT即座メッセージ送信
        tmux send-keys -t president "あなたはプレジデントです。./docs/reports/ai-agents/president.mdの指示書を参照して実行してください。さらに以下のコマンドで四人のワーカーを起動してください。" C-m
        sleep 0.5
        tmux send-keys -t president "for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'echo \"2\" | claude --dangerously-skip-permissions ' C-m; done" C-m
        
        # 各ワーカーの即座起動検知（並列チェック）
        for i in {0..3}; do
            (
                while ! tmux capture-pane -t multiagent:0.$i -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:"; do
                    sleep 0.5
                done
                
                # 各ワーカー即座役割設定
                case $i in
                                    0) tmux send-keys -t multiagent:0.0 "あなたはBOSS1です。./docs/reports/ai-agents/boss.mdの指示書を参照して、チームリーダーとして行動してください。日本語で応答してください。" C-m ;;
                1) tmux send-keys -t multiagent:0.1 "あなたはWORKER1です。./docs/reports/ai-agents/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" C-m ;;
                2) tmux send-keys -t multiagent:0.2 "あなたはWORKER2です。./docs/reports/ai-agents/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" C-m ;;
                3) tmux send-keys -t multiagent:0.3 "あなたはWORKER3です。./docs/reports/ai-agents/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" C-m ;;
                esac
            ) &
        done
        
        # 完了待ち
        wait
        echo "⚡ 全AI即座自動メッセージ送信完了 ($(date))" > /tmp/ai-agents-auto-setup.log
    ) &
    
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
    tmux send-keys -t multiagent:0.0 "printf '2\\n' | claude --dangerously-skip-permissions < /dev/null" C-m
    
    # ペイン0.1: worker1  
    tmux send-keys -t multiagent:0.1 "echo '👷 WORKER1 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.1 "printf '2\\n' | claude --dangerously-skip-permissions < /dev/null" C-m
    
    # ペイン0.2: worker2
    tmux send-keys -t multiagent:0.2 "echo '👷 WORKER2 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.2 "printf '2\\n' | claude --dangerously-skip-permissions < /dev/null" C-m
    
    # ペイン0.3: worker3
    tmux send-keys -t multiagent:0.3 "echo '👷 WORKER3 - Claude Code起動中...'" C-m
    tmux send-keys -t multiagent:0.3 "printf '2\\n' | claude --dangerously-skip-permissions < /dev/null" C-m
    
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
    tmux send-keys -t president "printf '2\\n' | claude --dangerously-skip-permissions < /dev/null" C-m
    
    # 自動起動完了を待つ
    sleep 3
    
    # デフォルトメッセージを自動送信（前の入力をクリア）
    tmux send-keys -t president C-c  # 前の入力をクリア
    sleep 0.1
    tmux send-keys -t president "あなたはプレジデントです。./docs/reports/ai-agents/president.mdの指示書を参照して実行してください。さらにワーカーたちを立ち上げてボスに指令を伝達して下さい。" C-m
    sleep 1
    tmux send-keys -t president "for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude --dangerously-skip-permissions ' C-m; done" C-m
    
    log_success "✅ PRESIDENT自動起動完了（デフォルトメッセージ送信済み）"
    
    # セッションにアタッチ
    tmux attach-session -t president
}

# セッション削除関数
clean_sessions() {
    log_info "🧹 AI組織システムセッション削除中..."
    
    # 既存セッションの削除
    tmux kill-session -t president 2>/dev/null || true
    tmux kill-session -t multiagent 2>/dev/null || true
    
    log_success "✅ 全セッション削除完了"
    
    # セッション確認
    echo ""
    echo "📊 現在のtmuxセッション:"
    tmux list-sessions 2>/dev/null || echo "  セッションなし"
}

# claude-auth関数（シンプル自動化）
claude_auth_function() {
    log_info "🚀 Claude Auth - シンプル自動化システム起動中..."
    
    # 既存セッション削除
    tmux kill-session -t president 2>/dev/null || true
    tmux kill-session -t multiagent 2>/dev/null || true
    
    # PRESIDENTセッション作成
    tmux new-session -d -s president -c "$(pwd)"
    tmux send-keys -t president "clear" C-m
    tmux send-keys -t president "echo '🎯 PRESIDENT セッション - Claude Code起動中...'" C-m
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    # multiagentセッション作成（4画面）
    tmux new-session -d -s multiagent -c "$(pwd)"
    tmux split-window -h -t multiagent
    tmux split-window -v -t multiagent:0.0
    tmux split-window -v -t multiagent:0.1
    tmux select-layout -t multiagent tiled
    
    log_success "✅ Claude Auth自動化システム起動完了"
    echo ""
    
    # バックグラウンド自動化処理を関数で実行
    run_claude_auth_background &
    
    echo "🎯 次のステップ:"
    echo "  1️⃣ Bypass Permissions自動選択中..."
    echo "  2️⃣ Claude Code起動検知中..."
    echo "  3️⃣ プレジデント初期メッセージ自動送信予定"
    echo ""
    echo "📋 使用方法:"
    echo "  - presidentセッション: tmux attach-session -t president"
    echo "  - multiagentセッション: tmux attach-session -t multiagent"
    echo ""
    
    # プレジデント画面に自動接続
    log_info "👑 プレジデント画面に自動接続中..."
    tmux attach-session -t president
}

# バックグラウンド自動化処理関数
run_claude_auth_background() {
    # ログファイル設定
    exec > /tmp/ai-agents-background.log 2>&1
    echo "$(date): バックグラウンド自動化開始"
    
    # 2秒待機してからBypass Permissions選択を送信
    sleep 2
    tmux send-keys -t president '2' C-m
    echo "$(date): Bypass Permissions選択送信完了"
    
    # Claude Code起動完了を検知（最大60秒）
    for i in {1..120}; do
        screen_content=$(tmux capture-pane -t president -p 2>/dev/null || echo "")
        echo "$(date): チェック${i}: ${screen_content:0:50}..."
        
        if echo "$screen_content" | grep -q "Welcome to Claude Code" 2>/dev/null; then
            echo "$(date): Claude Code起動完了を検知 (${i}/120秒)"
            
            # プレジデントメッセージ自動送信（正しいメッセージ - 前の入力をクリア）
            tmux send-keys -t president C-c  # 前の入力をクリア
            sleep 1
            echo "$(date): プレジデント初期メッセージ自動送信中..."
            tmux send-keys -t president 'あなたはプレジデントです。./docs/reports/ai-agents/president.mdの指示書を参照して実行してください。まず、以下のコマンドで4画面のワーカーを起動してください：for i in {0..3}; do tmux send-keys -t multiagent:0.$i "claude --dangerously-skip-permissions " C-m; done' C-m
            echo "$(date): プレジデント初期メッセージ自動送信完了"
            

            
            echo "✅ 自動化システム起動完了 $(date)" > /tmp/ai-agents-claude-auth.log
            echo "$(date): 自動化完了"
            break
        fi
        
        sleep 0.5
    done
    
    if [ $i -eq 120 ]; then
        echo "$(date): Claude Code起動検知タイムアウト（60秒）"
    fi
}

# 初期化関数
init_dirs() {
    # 必要なディレクトリを作成
    mkdir -p "$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR" "$TMP_DIR"
    
    # ログディレクトリ内のサブディレクトリ作成
    mkdir -p "$LOGS_DIR/ai-agents" "$LOGS_DIR/system"
}

# 半自動PRESIDENT起動（ユーザー要求対応）
setup_claude_semi_auto() {
    log_info "🎯 PRESIDENT半自動起動（tmux作成→認証手動・メッセージ自動セット）"
    
    # Step1: tmuxセッション自動作成
    log_info "📋 【Step1】tmuxセッション自動作成中..."
    launch_tmux_sessions
    sleep 1
    log_success "✅ tmuxセッション自動作成完了"
    
    echo ""
    log_info "📋 【Step2】PRESIDENT起動 - 選択肢半自動進行"
    log_info "🎯 Claude Code起動中...（認証は手動で行ってください）"
    tmux send-keys -t president 'printf "2\\n" | claude --dangerously-skip-permissions < /dev/null' C-m
    
    # テーマ選択自動化（3秒後にデフォルト選択）
    sleep 3
    log_info "🎨 テーマ選択自動化中..."
    tmux send-keys -t president C-m  # デフォルト選択（Dark mode）
    
    # 認証方法選択自動化（3秒後にClaude account選択）
    sleep 3
    log_info "🔐 認証方法選択自動化中..."
    tmux send-keys -t president C-m  # Claude account with subscription選択
    
    # API Key競合選択自動化（3秒後にNo選択）
    sleep 3
    log_info "🔑 API Key競合選択自動化中..."
    tmux send-keys -t president C-m  # No (recommended)選択
    
    # セキュリティ確認自動化（3秒後にEnter）
    sleep 3
    log_info "🛡️ セキュリティ確認自動化中..."
    tmux send-keys -t president C-m  # Press Enter to continue
    
    # ターミナル設定自動化（3秒後にYes選択）
    sleep 3
    log_info "💻 ターミナル設定自動化中..."
    tmux send-keys -t president C-m  # Yes, use recommended settings
    
    # Bypass Permissions確認自動化（3秒後に下矢印→Enter）
    sleep 3
    log_info "⚠️ Bypass Permissions確認自動化中..."
    tmux send-keys -t president Down C-m  # Yes, I accept選択
    
    # バックグラウンドでClaude Code起動を監視し、メッセージを自動セット
    {
        log_info "🔍 Claude Code起動監視開始..."
        
        # Claude Code起動完了を検知（最大30秒）
        for i in {1..60}; do
            # tmux画面の内容を取得
            screen_content=$(tmux capture-pane -t president:0 -p 2>/dev/null || echo "")
            
            # Claude Code起動完了を検知
            if echo "$screen_content" | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
                log_success "✅ Claude Code起動完了を検知 (${i}/60秒)"
                
                # 0.5秒待機してからメッセージセット
                sleep 0.5
                
                # プロンプトを一気にセット→Enter実行
                log_info "📤 プレジデントメッセージ自動送信中..."
                tmux send-keys -t president "あなたはプレジデントです。./docs/reports/ai-agents/president.mdの指示書を参照して実行してください。まず、ワーカーたちを立ち上げてボスに指令を伝達して下さい。"
                tmux send-keys -t president C-m C-m
                
                log_info "📤 ワーカー起動コマンド自動送信中..."
                tmux send-keys -t president "for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude --dangerously-skip-permissions ' C-m; done"
                tmux send-keys -t president C-m C-m
                log_success "✅ プレジデント→ワーカー指示完全自動送信完了"
                
                # ペインタイトル設定（視覚的改善・強化版）
                log_info "🎨 AI組織システム視覚的改善中..."
                
                # 高度なtmux視覚設定
                tmux set-option -g pane-border-status top
                tmux set-option -g pane-border-style "fg=colour8"
                tmux set-option -g pane-active-border-style "fg=colour4,bold"
                
                # カラフルなペインタイトルフォーマット（役割別カラー + 状態表示）
                tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour4#,fg=colour15#,bold],#[bg=colour8#,fg=colour7]} #{pane_title} #[default]"
                
                # 時刻表示付きステータスライン
                tmux set-option -g status-left-length 50
                tmux set-option -g status-right-length 50
                tmux set-option -g status-left "#[bg=colour4,fg=colour15,bold] AI組織システム #[default]"
                tmux set-option -g status-right "#[bg=colour2,fg=colour15] %H:%M:%S #[default]"
                tmux set-option -g status-interval 1
                
                # 各ペインに詳細な肩書きを設定（カラーコード + 状態表示）
                tmux select-pane -t president:0 -T "🟡待機中 👑PRESIDENT"
                tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔チームリーダー"
                tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻フロントエンド"
                tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧バックエンド"
                tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨UI/UXデザイン"
                
                # ウィンドウタイトルも設定
                tmux rename-window -t president "👑 PRESIDENT"
                tmux rename-window -t multiagent "👥 AI-TEAM"
                
                log_success "✅ AI組織システム視覚的改善完了"
                
                # 致命的欠陥修正: ワーカー役割メッセージの即座自動送信
                log_info "🔍 ワーカー役割メッセージ即座自動送信開始..."
                
                # 各ワーカーに役割メッセージを即座送信（起動済みの場合）
                for worker_id in {0..3}; do
                    # ワーカーの起動状況をチェック
                    worker_content=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
                    
                    if echo "$worker_content" | grep -q "Welcome to Claude Code\|Bypassing Permissions\|cwd:" 2>/dev/null; then
                        log_info "📤 WORKER${worker_id} 既に起動済み - 即座役割メッセージ送信"
                        
                        # 役割別メッセージ設定（肩書きに合わせて更新）
                        case $worker_id in
                            0) role_msg="あなたはBOSS・チームリーダーです。プロジェクト全体の調査結果をまとめて、具体的な改善指示をワーカーたちに出してください。./docs/reports/ai-agents/boss.md を参照して日本語で応答してください。" ;;
                            1) role_msg="あなたはフロントエンドエンジニアです。React・Vue・HTML/CSS等の技術でUI改善を実行してください。./docs/reports/ai-agents/worker.md を参照して日本語で応答してください。" ;;
                            2) role_msg="あなたはバックエンドエンジニアです。Node.js・Python・データベース等の技術でシステム改善を実行してください。./docs/reports/ai-agents/worker.md を参照して日本語で応答してください。" ;;
                            3) role_msg="あなたはUI/UXデザイナーです。デザインシステム・ユーザビリティ改善を実行してください。./docs/reports/ai-agents/worker.md を参照して日本語で応答してください。" ;;
                        esac
                        
                        # 役割メッセージを一気にセット→Enter実行
                        tmux send-keys -t multiagent:0.$worker_id "$role_msg"
                        tmux send-keys -t multiagent:0.$worker_id C-m C-m
                        log_success "✅ WORKER${worker_id} 役割メッセージ即座送信完了"
                        
                        # 送信完了をログに記録
                        echo "✅ WORKER${worker_id} 役割メッセージ即座送信完了 $(date)" >> /tmp/ai-agents-role-messages.log
                    else
                        log_warn "⚠️ WORKER${worker_id} 未起動 - 役割メッセージ送信スキップ"
                    fi
                    
                    # 連続送信の間隔を開ける
                    sleep 0.5
                done
                
                log_success "🎉 全ワーカー役割メッセージ即座送信完了！"
                
                # 起動済みワーカーへの即座タスク配布機能
                log_info "🚀 起動済みワーカーへの即座タスク配布開始..."
                
                # 各ワーカーに具体的なタスクを即座配布
                for worker_id in {0..3}; do
                    if tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null | grep -q "Welcome to Claude Code\|Please let me know" 2>/dev/null; then
                        case $worker_id in
                            0) task_msg="プロジェクト調査レポートを作成してください。cursor-rules、ai-agents、scripts等のディレクトリを分析し、改善提案をまとめてください。" ;;
                            1) task_msg="README.mdとsetup.shの内容を確認し、ユーザビリティを改善してください。わかりやすいフォーマットや視覚的改善を提案してください。" ;;
                            2) task_msg="ai-agents/manage.shの構造を分析し、パフォーマンス改善とエラーハンドリング強化を実装してください。" ;;
                            3) task_msg="tmuxペインタイトルとAI組織システムの視覚的表示を改善してください。カラー設定や見やすさを向上させてください。" ;;
                        esac
                        
                        tmux send-keys -t multiagent:0.$worker_id "$task_msg"
                        tmux send-keys -t multiagent:0.$worker_id C-m C-m
                        log_success "✅ WORKER${worker_id} 即座タスク配布完了"
                    fi
                done
                
                log_success "🎉 即座タスク配布完了 - 全ワーカー稼働中！"
                
                echo "✅ 【メッセージ完全自動送信完了】プレジデント→ワーカー指示完了" > /tmp/ai-agents-message-set.log
                log_success "✅ PRESIDENTメッセージ完全自動送信完了"
                log_info "🔍 ワーカーメッセージ自動送信システム起動中..."
                break
            fi
            
            sleep 0.5
        done
        
        if [ $i -eq 60 ]; then
            log_warn "⚠️ Claude Code起動検知タイムアウト（30秒）"
            echo "⚠️ メッセージセットできませんでした" > /tmp/ai-agents-message-set.log
        fi
    } &
    
    echo ""
    echo "📋 【動作仕様】完全自動システム:"
    echo "  1️⃣ プレジデント起動: 選択肢半自動進行"
    echo "  2️⃣ 認証: 手動（ユーザーが行う）"
    echo "  3️⃣ Claude Code立ち上がり時: メッセージ完全自動送信"
    echo "  4️⃣ ワーカー起動: 自動実行"
    echo "  5️⃣ ワーカー起動後: 各ワーカーにメッセージ完全自動送信"
    echo "  6️⃣ 4画面確認: ターミナル2で確認"
    echo ""
    echo "🔹 【次のステップ】:"
    echo "  - Claude Code認証完了後、PRESIDENTメッセージが完全自動送信されます"
    echo "  - ワーカー起動コマンドも自動実行されます"
    echo "  - ワーカー起動後、各ワーカーにメッセージが完全自動送信されます"
    echo "  - 別ターミナルで確認: tmux attach-session -t multiagent"
    echo ""
    
    # PRESIDENT画面にアタッチ
    log_info "👑 PRESIDENT画面に接続中...（認証は手動で行ってください）"
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
        tmux send-keys -t multiagent:0.$i 'printf "2\\n" | claude --dangerously-skip-permissions < /dev/null' C-m
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
            # PRESIDENT半自動起動（段階1）
            claude_auth_function
            ;;
        "auto")
            # 🚀 ワンコマンド起動（全自動）
            log_info "🚀 AI組織システム全自動起動中..."
            quick_start
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
            echo "🔧 半自動起動（推奨）:"
            echo "  ./ai-agents/manage.sh claude-auth        # ワンコマンド半自動起動（tmux作成→メッセージ自動セット）"
            echo ""
            echo "📋 【半自動システム仕様】:"
            echo "  • tmux作成: 自動"
            echo "  • プレジデント起動: 選択肢半自動進行"
            echo "  • 認証: 手動（ユーザーが行う）"
            echo "  • Claude Code立ち上がり時: メッセージ自動セット"
            echo "  • 送信: 手動（Enterキー）"
            echo "  • 4画面確認: ターミナル2で手動実行"
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
