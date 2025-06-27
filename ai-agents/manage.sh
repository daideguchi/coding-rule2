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
LOGS_DIR="logs/ai-agents"
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
            
            # PRESIDENT即座メッセージ送信（各ワーカーへの指示書参照指示 + ワーカー起動）
            tmux send-keys -t president ">あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。【重要】ワーカーに指示を送る時は必ず文頭に「>」を付けてください。まず最初に、以下のコマンドでワーカーたちを起動し、その後BOSS1、WORKER1、WORKER2、WORKER3の4人全員に対して、それぞれの指示書（boss.md、worker.md）を確認するよう指示を出してください。" C-m
            sleep 1
            tmux send-keys -t president ">for i in {0..3}; do tmux send-keys -t multiagent:0.\\\$i \"claude --dangerously-skip-permissions\" C-m; done" C-m
            
            # 3秒後にワーカー強制起動を実行
            sleep 3
            echo "⚡ ワーカー強制起動システム実行開始 ($(date))" > /tmp/ai-agents-worker-start.log
            
            # ワーカー強制起動を実行（バックグラウンドで）
            (
                # 各ワーカーの強制起動と役割メッセージ送信
                for i in {0..3}; do
                    echo "📋 WORKER${i} 強制起動開始..." >> /tmp/ai-agents-worker-start.log
                    
                    # ワーカー起動
                    tmux send-keys -t multiagent:0.$i "claude --dangerously-skip-permissions" C-m
                    sleep 1
                    
                    # 起動確認（最大30秒）
                    for j in {1..60}; do
                        if tmux capture-pane -t multiagent:0.$i -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:"; then
                            echo "✅ WORKER${i} 起動完了 (${j}/60秒)" >> /tmp/ai-agents-worker-start.log
                            
                            # 役割メッセージ送信（「>」付きで自動実行対応）
                            case $i in
                                0) role_msg=">あなたはBOSS1です。./ai-agents/instructions/boss.mdの指示書を参照して、チームリーダーとして行動してください。日本語で応答してください。" ;;
                                1) role_msg=">あなたはWORKER1です。./ai-agents/instructions/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" ;;
                                2) role_msg=">あなたはWORKER2です。./ai-agents/instructions/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" ;;
                                3) role_msg=">あなたはWORKER3です。./ai-agents/instructions/worker.mdの指示書を参照して、実行担当として行動してください。日本語で応答してください。" ;;
                            esac
                            
                            # 役割メッセージ送信
                            sleep 1
                            tmux send-keys -t multiagent:0.$i "$role_msg" C-m
                            echo "✅ WORKER${i} 役割メッセージ送信完了" >> /tmp/ai-agents-worker-start.log
                            break
                        fi
                        sleep 0.5
                    done
                    
                    if [ $j -eq 60 ]; then
                        echo "❌ WORKER${i} 起動タイムアウト（30秒）" >> /tmp/ai-agents-worker-start.log
                    fi
                done
                
                echo "⚡ 全ワーカー強制起動処理完了 ($(date))" >> /tmp/ai-agents-worker-start.log
            ) &
            
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
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    # 自動起動完了を待つ
    sleep 3
    
    # デフォルトメッセージを自動送信（各ワーカーへの指示書参照指示 + ワーカー起動）
    tmux send-keys -t president C-c  # 前の入力をクリア
    sleep 0.1
    tmux send-keys -t president ">あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。【重要】ワーカーに指示を送る時は必ず文頭に「>」を付けてください。まず最初に、以下のコマンドでワーカーたちを起動し、その後BOSS1、WORKER1、WORKER2、WORKER3の4人全員に対して、それぞれの指示書（boss.md、worker.md）を確認するよう指示を出してください。" C-m
    sleep 1
    tmux send-keys -t president ">for i in {0..3}; do tmux send-keys -t multiagent:0.\\\$i \"claude --dangerously-skip-permissions\" C-m; done" C-m
    sleep 0.5
    # 🎯 確実にEnterキーを自動送信（ユーザー要求：絶対に自動実行）
    
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
    
            # バックグラウンド自動化処理を別関数で実行（プレジデント用メッセージ設定）
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

# バックグラウンド自動化関数
run_claude_auth_background() {
    nohup bash -c '
        # ログファイル設定
        exec > /tmp/ai-agents-background.log 2>&1
        echo "$(date): バックグラウンド自動化開始"
        
        # 2秒待機してからBypass Permissions選択を送信（バックグラウンド処理）
        sleep 2
        # 権限選択は背景で自動処理（画面には表示されない）
        echo "$(date): Bypass Permissions選択送信完了"
        
        # Claude Code起動完了を検知（最大60秒）
        for i in {1..120}; do
            screen_content=$(tmux capture-pane -t president -p 2>/dev/null || echo "")
            echo "$(date): チェック${i}: ${screen_content:0:50}..."
            
            if echo "$screen_content" | grep -q "Welcome to Claude Code" 2>/dev/null; then
                echo "$(date): Claude Code起動完了を検知 (${i}/120秒)"
                
                # 🚀 改修されたプレジデントメッセージ自動送信（確実なワーカー起動指示 + 「>」付きワーカー指示ルール）
                tmux send-keys -t president C-c  # 前の入力をクリア
                sleep 0.1
                
                # 🚀【改修版】プレジデント初期メッセージ - 各ワーカーへの指示書参照指示 + ワーカー起動
                tmux send-keys -t president ">あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。【重要】ワーカーに指示を送る時は必ず文頭に「>」を付けてください。まず最初に、以下のコマンドでワーカーたちを起動し、その後BOSS1、WORKER1、WORKER2、WORKER3の4人全員に対して、それぞれの指示書（boss.md、worker.md）を確認するよう指示を出してください。" C-m
                sleep 1
                tmux send-keys -t president ">for i in {0..3}; do tmux send-keys -t multiagent:0.\\\$i \"claude --dangerously-skip-permissions\" C-m; done" C-m
                sleep 0.5
                # 🎯 確実にEnterキーを自動送信（ユーザー要求：絶対に自動実行）
                tmux send-keys -t president C-m
                echo "$(date): プレジデント初期メッセージ自動送信完了（自動Enter実行）"
                
                echo "✅ 自動化システム起動完了 $(date)" > /tmp/ai-agents-claude-auth.log
                echo "$(date): 自動化完了"
                break
            fi
            
            sleep 0.5
        done
        
        if [ $i -eq 120 ]; then
            echo "$(date): Claude Code起動検知タイムアウト（60秒）"
        fi
    ' &
}

# 半自動バックグラウンド処理関数
run_semi_auto_background() {
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
                
                # 🚀 改修版メッセージを完全自動送信（各ワーカーへの指示書参照指示 + ワーカー起動）
                tmux send-keys -t president "あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。【重要】ワーカーに指示を送る時は必ず文頭に「>」を付けてください。まず最初に、以下のコマンドでワーカーたちを起動し、その後BOSS1、WORKER1、WORKER2、WORKER3の4人全員に対して、それぞれの指示書（boss.md、worker.md）を確認するよう指示を出してください。" C-m
                sleep 1
                tmux send-keys -t president "for i in {0..3}; do tmux send-keys -t multiagent:0.\\\$i \"claude --dangerously-skip-permissions\" C-m; done" C-m
                sleep 0.5
                # 🎯 確実にEnterキーを自動送信（ユーザー要求：絶対に自動実行）
                tmux send-keys -t president C-m
                echo "$(date): プレジデント初期メッセージ自動送信完了（自動Enter実行）"
                
                # ペインタイトル設定（視覚的改善・強化版）
                log_info "🎨 AI組織システム視覚的改善中..."
                
                # 🖱️ 強化されたtmux視覚設定（クリック移動対応）
                tmux set-option -g mouse on
                tmux set-option -g pane-border-status top
                tmux set-option -g pane-border-style "fg=colour8"
                tmux set-option -g pane-active-border-style "fg=colour4,bold"
                
                # 🎨 カラフルなペインタイトルフォーマット（役割別カラー + クリック案内）
                tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour4#,fg=colour15#,bold],#[bg=colour8#,fg=colour7]} #{pane_title} #[default] #{?pane_active,[ACTIVE - クリックで移動可能],[]}"
                
                # 📊 時刻表示付きステータスライン（チーム状況表示）
                tmux set-option -g status-left-length 80
                tmux set-option -g status-right-length 80
                tmux set-option -g status-left "#[bg=colour4,fg=colour15,bold] 🤖 AI組織システム - チーム協調中 #[default]"
                tmux set-option -g status-right "#[bg=colour2,fg=colour15] 🕐 %H:%M:%S | 🎯 クリック移動可能 #[default]"
                tmux set-option -g status-interval 1
                
                # 🏷️ 各ペインに詳細な役割・責任を設定（クリックで切り替え可能）
                tmux select-pane -t president:0 -T "👑 PRESIDENT・最高責任者 [プロジェクト統括・意思決定] 📊 STATUS: 起動完了"
                tmux select-pane -t multiagent:0.0 -T "👔 BOSS・チームリーダー [作業分担・進捗管理・品質確保] 📈 STATUS: 指示待機"
                tmux select-pane -t multiagent:0.1 -T "💻 WORKER1・フロントエンド [React/Vue/CSS/UI実装] 🎨 STATUS: 実装待機"
                tmux select-pane -t multiagent:0.2 -T "🔧 WORKER2・バックエンド [API/DB/サーバー処理] ⚙️ STATUS: 開発待機"
                tmux select-pane -t multiagent:0.3 -T "🎨 WORKER3・デザイン [UX/UI設計・視覚改善] 🖌️ STATUS: 設計待機"
                
                # 🖥️ ウィンドウタイトルも設定（チーム構成表示）
                tmux rename-window -t president "👑 PRESIDENT [1/5 ACTIVE]"
                tmux rename-window -t multiagent "👥 AI-TEAM [4/5 MEMBERS]"
                
                # 📱 動的ステータス更新機能の初期化
                setup_dynamic_status_updates &
                
                log_success "✅ 🎯 チームUI改善・クリック移動対応・動的ステータス更新完了"
                
                # 致命的欠陥修正: ワーカー役割メッセージの即座自動送信
                log_info "🔍 ワーカー役割メッセージ即座自動送信開始..."
                
                # 各ワーカーに役割メッセージを即座送信（起動済みの場合）
                for worker_id in {0..3}; do
                    # ワーカーの起動状況をチェック
                    worker_content=$(tmux capture-pane -t multiagent:0.${worker_id} -p 2>/dev/null || echo "")
                    
                    if echo "${worker_content}" | grep -q "Welcome to Claude Code\|Bypassing Permissions\|cwd:" 2>/dev/null; then
                        log_info "📤 WORKER${worker_id} 既に起動済み - 即座役割メッセージ送信"
                        
                        # 役割別メッセージ設定（肩書きに合わせて更新、「>」付きで自動実行対応）
                        case ${worker_id} in
                            0) role_msg=">あなたはBOSS・チームリーダーです。プロジェクト全体の調査結果をまとめて、具体的な改善指示をワーカーたちに出してください。./ai-agents/instructions/boss.md を参照して日本語で応答してください。" ;;
                            1) role_msg=">あなたはフロントエンドエンジニアです。React・Vue・HTML/CSS等の技術でUI改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                            2) role_msg=">あなたはバックエンドエンジニアです。Node.js・Python・データベース等の技術でシステム改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                            3) role_msg=">あなたはUI/UXデザイナーです。デザインシステム・ユーザビリティ改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                        esac
                        
                        # 🔧 役割メッセージを即座送信（「2」混入問題修正）
                        sleep 2  # Bypass Permissions選択の「2」が混入しないよう待機
                        tmux send-keys -t multiagent:0.${worker_id} "${role_msg}" C-m
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
                    if tmux capture-pane -t multiagent:0.${worker_id} -p 2>/dev/null | grep -q "Welcome to Claude Code\|Please let me know" 2>/dev/null; then
                        case ${worker_id} in
                            0) task_msg=">プロジェクト調査レポートを作成してください。cursor-rules、ai-agents、scripts等のディレクトリを分析し、改善提案をまとめてください。" ;;
                            1) task_msg=">README.mdとsetup.shの内容を確認し、ユーザビリティを改善してください。わかりやすいフォーマットや視覚的改善を提案してください。" ;;
                            2) task_msg=">ai-agents/manage.shの構造を分析し、パフォーマンス改善とエラーハンドリング強化を実装してください。" ;;
                            3) task_msg=">tmuxペインタイトルとAI組織システムの視覚的表示を改善してください。カラー設定や見やすさを向上させてください。" ;;
                        esac
                        
                        tmux send-keys -t multiagent:0.${worker_id} "${task_msg}" C-m
                        log_success "✅ WORKER${worker_id} 即座タスク配布完了"
                    fi
                done
                
                log_success "🎉 即座タスク配布完了 - 全ワーカー稼働中！"
                
                echo "✅ 【メッセージ自動セット完了】送信は手動で行ってください" > /tmp/ai-agents-message-set.log
                log_success "✅ PRESIDENTメッセージ自動セット完了（送信は手動）"
                log_info "🔍 ワーカーメッセージ自動セットシステム起動中..."
                break
            fi
            
            sleep 0.5
        done
        
        if [ $i -eq 60 ]; then
            log_warn "⚠️ Claude Code起動検知タイムアウト（30秒）"
            echo "⚠️ メッセージセットできませんでした" > /tmp/ai-agents-message-set.log
        fi
    } &
}

# 📱 動的ステータス更新機能
setup_dynamic_status_updates() {
    nohup bash -c '
        exec > /tmp/ai-agents-status-updates.log 2>&1
        echo "$(date): 動的ステータス更新機能開始"
        
        while true; do
            # 🔍 各ペインの活動状況を監視
            active_count=0
            
            # PRESIDENT状況チェック
            if tmux capture-pane -t president -p 2>/dev/null | grep -qE "Please let me know|How can I help|What would you like" 2>/dev/null; then
                tmux select-pane -t president:0 -T "👑 PRESIDENT 🟢 │ アクティブ対話中・プロジェクト統括・意思決定"
                ((active_count++))
            else
                tmux select-pane -t president:0 -T "👑 PRESIDENT 🟡 │ 待機中・プロジェクト統括・意思決定"
            fi
            
            # 各ワーカーの状況チェック
            for worker_id in {0..3}; do
                worker_content=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
                
                case $worker_id in
                    0) # BOSS
                        if echo "$worker_content" | grep -qE "Please let me know|How can I help|分析|レポート" 2>/dev/null; then
                            tmux select-pane -t multiagent:0.0 -T "👔 BOSS 🟢 │ チーム指導中・作業分担・進捗管理"
                            ((active_count++))
                        else
                            tmux select-pane -t multiagent:0.0 -T "👔 BOSS 🟡 │ 指示待機中・作業分担・進捗管理"
                        fi
                        ;;
                    1) # WORKER1 - フロントエンド
                        if echo "$worker_content" | grep -qE "Please let me know|React|Vue|CSS|HTML" 2>/dev/null; then
                            tmux select-pane -t multiagent:0.1 -T "💻 WORKER1 🟢 │ UI実装中・React/Vue/CSS"
                            ((active_count++))
                        else
                            tmux select-pane -t multiagent:0.1 -T "💻 WORKER1 🟡 │ 実装待機中・React/Vue/CSS"
                        fi
                        ;;
                    2) # WORKER2 - バックエンド
                        if echo "$worker_content" | grep -qE "Please let me know|API|Node|Python|データベース" 2>/dev/null; then
                            tmux select-pane -t multiagent:0.2 -T "🔧 WORKER2 🟢 │ 開発中・API/DB/サーバー"
                            ((active_count++))
                        else
                            tmux select-pane -t multiagent:0.2 -T "🔧 WORKER2 🟡 │ 開発待機中・API/DB/サーバー"
                        fi
                        ;;
                    3) # WORKER3 - デザイン
                        if echo "$worker_content" | grep -qE "Please let me know|デザイン|UI|UX|視覚" 2>/dev/null; then
                            tmux select-pane -t multiagent:0.3 -T "🎨 WORKER3 🟢 │ 設計中・UX/UI設計・視覚改善"
                            ((active_count++))
                        else
                            tmux select-pane -t multiagent:0.3 -T "🎨 WORKER3 🟡 │ 設計待機中・UX/UI設計・視覚改善"
                        fi
                        ;;
                esac
            done
            
            # ウィンドウタイトル更新（アクティブ数表示）
            tmux rename-window -t president "👑 PRESIDENT [活動状況: $active_count/5]"
            tmux rename-window -t multiagent "👥 AI-TEAM [稼働メンバー: $active_count/5]"
            
            # ステータスライン更新
            current_time=$(date "+%H:%M:%S")
            if [ $active_count -gt 0 ]; then
                tmux set-option -g status-left "#[bg=colour2,fg=colour15,bold] 🤖 AI組織システム - $active_count メンバー稼働中 #[default]"
            else
                tmux set-option -g status-left "#[bg=colour3,fg=colour15,bold] 🤖 AI組織システム - 全メンバー待機中 #[default]"
            fi
            
            echo "$(date): ステータス更新完了 - アクティブ: $active_count/5"
            
            # 10秒間隔で更新
            sleep 10
        done
    ' &
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
    tmux send-keys -t president 'claude --dangerously-skip-permissions' C-m
    
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
    
    # バックグラウンドでClaude Code起動を監視し、メッセージを自動セット + ワーカー強制起動
    run_semi_auto_background &
    
    # 10秒後にワーカー強制起動を実行（プレジデント起動後）
    (
        sleep 10
        log_info "🚀 ワーカー強制起動システム実行中..."
        force_start_workers
    ) &
    
    echo ""
    echo "📋 【動作仕様】完全自動システム + ワーカー自動起動:"
    echo "  1️⃣ プレジデント起動: 選択肢半自動進行"
    echo "  2️⃣ 認証: 手動（ユーザーが行う）"
    echo "  3️⃣ Claude Code立ち上がり時: メッセージ自動セット"
    echo "  4️⃣ 送信: 自動（Enterキー自動実行）🎯"
    echo "  5️⃣ ワーカー自動起動: 10秒後に自動実行"
    echo "  6️⃣ ワーカー役割メッセージ: 自動送信+Enter実行"
    echo "  7️⃣ 4画面確認: ターミナル2で確認"
    echo ""
    echo "🔹 【次のステップ】:"
    echo "  - Claude Code認証完了後、PRESIDENTメッセージが自動送信されます（Enter自動実行）"
    echo "  - ユーザーの確認不要で完全自動化"
    echo "  - 10秒後に全ワーカーが自動起動し、役割メッセージが自動送信されます"
    echo "  - 別ターミナルで: tmux attach-session -t multiagent"
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

# 🚀 ワーカー強制起動機能（確実性重視）
force_start_workers() {
    log_info "🚀 ワーカー強制起動機能（確実性重視）"
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    log_info "🔄 各ワーカーの起動状況を確認中..."
    
    # 各ワーカーの状況確認と強制起動
    for i in {0..3}; do
        log_info "📋 WORKER${i} 状況確認中..."
        
        # 現在の状況を取得
        worker_content=$(tmux capture-pane -t multiagent:0.$i -p 2>/dev/null || echo "")
        
        if echo "$worker_content" | grep -q "Welcome to Claude Code\|Please let me know" 2>/dev/null; then
            log_success "✅ WORKER${i} 既に起動済み"
        else
            log_warn "⚠️ WORKER${i} 未起動 - 強制起動実行中..."
            
            # 強制起動（複数手法で確実性向上）
            tmux send-keys -t multiagent:0.$i C-c  # 現在の処理をクリア
            sleep 0.5
            tmux send-keys -t multiagent:0.$i "claude --dangerously-skip-permissions" C-m
            sleep 2
            
            # Bypass Permissions自動選択
            tmux send-keys -t multiagent:0.$i "2" C-m
            sleep 1
            
            log_info "⏳ WORKER${i} 起動完了待機中..."
            
            # 起動完了確認（最大30秒）
            for j in {1..60}; do
                worker_check=$(tmux capture-pane -t multiagent:0.$i -p 2>/dev/null || echo "")
                if echo "$worker_check" | grep -q "Welcome to Claude Code" 2>/dev/null; then
                    log_success "✅ WORKER${i} 起動完了確認 (${j}/60秒)"
                    
                    # 🔧 役割メッセージ自動送信（「2」混入問題修正、「>」付きで自動実行対応）
                    case $i in
                        0) role_msg=">あなたはBOSS・チームリーダーです。./ai-agents/instructions/boss.md を参照して日本語で応答してください。" ;;
                        1) role_msg=">あなたはWORKER1・フロントエンドエンジニアです。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                        2) role_msg=">あなたはWORKER2・バックエンドエンジニアです。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                        3) role_msg=">あなたはWORKER3・UI/UXデザイナーです。./ai-agents/instructions/worker.md を参照して日本語で応答してください。" ;;
                    esac
                    
                    # 🚫 Bypass Permissions選択の「2」が混入しないよう、十分な待機時間を確保
                    sleep 2
                    tmux send-keys -t multiagent:0.$i "$role_msg" C-m
                    log_success "✅ WORKER${i} 役割メッセージ送信完了"
                    break
                fi
                sleep 0.5
            done
            
            if [ $j -eq 60 ]; then
                log_error "❌ WORKER${i} 起動タイムアウト（30秒）"
            fi
        fi
        
        echo ""
    done
    
    log_success "🎉 ワーカー強制起動処理完了"
    echo ""
    echo "📋 確認方法:"
    echo "  tmux attach-session -t multiagent"
    echo ""
}

# 🎨 チームUI復旧機能（緊急用）
restore_team_ui() {
    log_info "🎨 チームUI復旧機能（緊急用）"
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    if ! tmux has-session -t president 2>/dev/null; then
        log_error "❌ presidentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    log_info "🖱️ マウス機能とボーダー設定中..."
    
    # 🖱️ 強化されたtmux視覚設定（クリック移動対応）
    tmux set-option -g mouse on
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-style "fg=colour8"
    tmux set-option -g pane-active-border-style "fg=colour4,bold"
    
    # 🎨 視覚的ペインタイトルフォーマット（○インジケーター付き）
    tmux set-option -g pane-border-format '#[fg=colour15,bg=colour4,bold]#{?pane_active, 🟢 ACTIVE ,}#[fg=colour7,bg=colour8]#{?pane_active,, 🟡 STANDBY } #[fg=colour15,bold]#{pane_title}#[default]'
    
    log_info "📊 日本語ステータスライン設定中..."
    
    # 📊 日本語対応ステータスライン（ユーザーフレンドリー）
    tmux set-option -g status-left-length 100
    tmux set-option -g status-right-length 100
    tmux set-option -g status-left "#[bg=colour2,fg=colour15,bold] 🤖 AI組織システム稼働中 │ 5名のエージェントが協調作業 #[default]"
    tmux set-option -g status-right "#[bg=colour4,fg=colour15] 🕐 %H:%M:%S │ 💡 ヒント: ペインをクリックで移動可能 #[default]"
    tmux set-option -g status-interval 1
    
    log_info "🏷️ ユーザーフレンドリーな役職・職種表示設定中..."
    
    # 🏷️ 視覚的役職表示（○インジケーター強化）
    tmux select-pane -t president:0 -T "👑 PRESIDENT 🟢 │ 統括責任者・プロジェクト全体管理・意思決定"
    tmux select-pane -t multiagent:0.0 -T "👔 BOSS 🟡 │ チームリーダー・作業分担・進捗管理・品質確保"
    tmux select-pane -t multiagent:0.1 -T "💻 WORKER1 🟡 │ フロントエンド・React・Vue・CSS・UI実装"
    tmux select-pane -t multiagent:0.2 -T "🔧 WORKER2 🟡 │ バックエンド・API・DB・サーバー処理"
    tmux select-pane -t multiagent:0.3 -T "🎨 WORKER3 🟡 │ UI/UXデザイナー・デザイン・ユーザビリティ改善"
    
    log_info "🖥️ ウィンドウタイトル設定中..."
    
    # 🖥️ ウィンドウタイトルも設定（チーム構成表示）
    tmux rename-window -t president "👑 PRESIDENT [1/5 ACTIVE]"
    tmux rename-window -t multiagent "👥 AI-TEAM [4/5 MEMBERS]"
    
    log_success "🎉 チームUI復旧完了！"
    echo ""
    echo "📋 確認方法:"
    echo "  tmux attach-session -t multiagent  # 4画面チーム確認"
    echo "  tmux attach-session -t president   # PRESIDENT確認"
    echo ""
    echo "🎯 特徴:"
    echo "  ✅ マウスクリック移動対応"
    echo "  ✅ 詳細な役職・職種表示"
    echo "  ✅ リアルタイム時刻表示"
    echo "  ✅ カラー付きステータス表示"
    echo ""
}

# 🚀 自動実行監視機能（AI組織駆動中）
start_auto_execute_monitor() {
    log_info "🚀 自動実行監視機能開始（AI組織駆動中）"
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    log_info "🔍 ワーカーの指示監視を開始します..."
    echo "📋 監視対象:"
    echo "  👔 BOSS (multiagent:0.0)"
    echo "  💻 WORKER1 (multiagent:0.1)" 
    echo "  🔧 WORKER2 (multiagent:0.2)"
    echo "  🎨 WORKER3 (multiagent:0.3)"
    echo ""
    echo "💡 動作: Claude Codeの指示に文章が入ったら即座に自動実行（Enterキー送信）"
    echo "🛑 停止: Ctrl+C"
    echo ""
    
    # バックグラウンドで自動実行監視を開始
    nohup bash -c '
        exec > /tmp/ai-agents-auto-execute.log 2>&1
        echo "$(date): 自動実行監視開始"
        
        # 各ワーカーの前回の画面内容を保存
        declare -A prev_content
        for worker_id in {0..3}; do
            prev_content[$worker_id]=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
        done
        
        while true; do
            for worker_id in {0..3}; do
                # 現在の画面内容を取得
                current_content=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
                
                # 前回と比較して新しい指示が入力されたかチェック
                if [ "$current_content" != "${prev_content[$worker_id]}" ]; then
                    # 新しい内容をチェック
                    new_lines=$(echo "$current_content" | tail -5)
                    
                    # 複数パターンで指示検出（より確実な自動実行）
                    should_execute=false
                    
                    # パターン1: 「>」プロンプトに文字が入力されている
                    if echo "$new_lines" | grep -qE "^> .+" 2>/dev/null; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン1検出: プロンプト入力"
                    fi
                    
                    # パターン2: プレジデントからの指示メッセージを検出
                    if echo "$current_content" | grep -qE "(指示を送信|プロジェクトの指示|タスクを|作業を|実行して)" 2>/dev/null; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン2検出: プレジデント指示"
                    fi
                    
                    # パターン3: 入力待ち状態での新しいコンテンツ
                    if echo "$current_content" | tail -1 | grep -qE "^>" 2>/dev/null && [ ${#current_content} -gt ${#prev_content[$worker_id]} ]; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン3検出: 入力待ち状態変化"
                    fi
                    
                    if [ "$should_execute" = true ]; then
                        echo "$(date): WORKER${worker_id} 新しい指示検出 - 自動実行開始"
                        
                        # ステータス更新
                        case $worker_id in
                            0) tmux select-pane -t multiagent:0.0 -T "👔 チームリーダー・BOSS │ 作業分担・進捗管理・品質確保 │ 🟢 実行中" ;;
                            1) tmux select-pane -t multiagent:0.1 -T "💻 フロントエンド・WORKER1 │ React・Vue・CSS・UI実装 │ 🟢 実行中" ;;
                            2) tmux select-pane -t multiagent:0.2 -T "🔧 バックエンド・WORKER2 │ API・DB・サーバー処理 │ 🟢 実行中" ;;
                            3) tmux select-pane -t multiagent:0.3 -T "🎨 UI/UXデザイナー・WORKER3 │ デザイン・ユーザビリティ改善 │ 🟢 実行中" ;;
                        esac
                        
                        # 確実なEnterキー送信（複数回試行）
                        echo "$(date): WORKER${worker_id} Enterキー送信開始"
                        
                        # 方法1: 通常のEnterキー送信
                        tmux send-keys -t multiagent:0.$worker_id C-m
                        sleep 0.5
                        
                        # 方法2: 確実性のため再度送信
                        tmux send-keys -t multiagent:0.$worker_id ""
                        tmux send-keys -t multiagent:0.$worker_id C-m
                        sleep 0.5
                        
                        # 方法3: 強制的な改行送信
                        tmux send-keys -t multiagent:0.$worker_id Enter
                        
                        echo "$(date): WORKER${worker_id} Enterキー送信完了"
                        
                        # 3秒後にステータスを待機中に戻す
                        sleep 3
                        case $worker_id in
                            0) tmux select-pane -t multiagent:0.0 -T "👔 チームリーダー・BOSS │ 作業分担・進捗管理・品質確保 │ 🟡 待機中" ;;
                            1) tmux select-pane -t multiagent:0.1 -T "💻 フロントエンド・WORKER1 │ React・Vue・CSS・UI実装 │ 🟡 待機中" ;;
                            2) tmux select-pane -t multiagent:0.2 -T "🔧 バックエンド・WORKER2 │ API・DB・サーバー処理 │ 🟡 待機中" ;;
                            3) tmux select-pane -t multiagent:0.3 -T "🎨 UI/UXデザイナー・WORKER3 │ デザイン・ユーザビリティ改善 │ 🟡 待機中" ;;
                        esac
                    fi
                    
                    # 前回の内容を更新
                    prev_content[$worker_id]="$current_content"
                fi
            done
            
            # 0.2秒間隔で高頻度監視（より敏感な検出）
            sleep 0.2
        done
    ' &
    
    AUTO_EXECUTE_PID=$!
    echo $AUTO_EXECUTE_PID > /tmp/ai-agents-auto-execute.pid
    
    log_success "✅ 自動実行監視機能が開始されました（PID: $AUTO_EXECUTE_PID）"
    echo ""
    echo "📋 監視ログ確認:"
    echo "  tail -f /tmp/ai-agents-auto-execute.log"
    echo ""
    echo "🛑 停止方法:"
    echo "  kill $AUTO_EXECUTE_PID"
    echo "  または ./ai-agents/manage.sh stop-auto-execute"
    echo ""
}

# 🛑 自動実行監視停止機能
stop_auto_execute_monitor() {
    log_info "🛑 自動実行監視停止中..."
    
    if [ -f /tmp/ai-agents-auto-execute.pid ]; then
        AUTO_EXECUTE_PID=$(cat /tmp/ai-agents-auto-execute.pid)
        if kill $AUTO_EXECUTE_PID 2>/dev/null; then
            log_success "✅ 自動実行監視を停止しました（PID: $AUTO_EXECUTE_PID）"
            rm -f /tmp/ai-agents-auto-execute.pid
        else
            log_warn "⚠️ プロセス（PID: $AUTO_EXECUTE_PID）は既に停止しています"
        fi
    else
        log_warn "⚠️ 自動実行監視は開始されていません"
    fi
    echo ""
}

# .claude設定確認・生成機能
setup_claude_local_config() {
    log_info "🔧 .claude設定の確認・生成機能"
    
    # プロジェクトルートに移動
    cd "$(dirname "$(dirname "$0")")"
    
    if [ -d ".claude" ] && [ -f ".claude/CLAUDE.md" ]; then
        log_success "✅ .claude設定は既に存在します"
        echo ""
        echo "📁 既存の.claude設定:"
        ls -la .claude/
        echo ""
        read -p ".claude設定を再生成しますか？ [y/N]: " regenerate
        
        if [[ ! $regenerate =~ ^[Yy]$ ]]; then
            log_info "設定生成をスキップしました"
            return 0
        fi
    fi
    
    log_info "🔄 .claude設定を生成中..."
    
    # .claudeディレクトリ作成
    mkdir -p .claude
    
    # Claude Code設定ファイルの生成
    cat > .claude/claude_desktop_config.json << 'EOF'
{
  "name": "AI開発支援プロジェクト",
  "description": "AI組織システム + Cursor連携開発環境",
  "rules": [
    "日本語でコミュニケーション",
    "ユーザーの要求を最優先",
    "機能を勝手に変更しない",
    "AI組織システムとの連携を保持"
  ],
  "memory": {
    "sync_with_cursor": true,
    "track_changes": true,
    "preserve_context": true,
    "ai_organization": true
  },
  "tools": {
    "enabled": true,
    "auto_bypass_permissions": true,
    "dangerous_commands": false,
    "tmux_integration": true
  }
}
EOF
    
    # CLAUDE.mdファイルの生成
    cat > .claude/CLAUDE.md << 'EOF'
# Claude Code プロジェクト設定（AI組織システム対応）

## プロジェクト概要
- **名前**: AI開発支援プロジェクト
- **目的**: AI組織システム + Cursor連携による革新的開発環境
- **言語**: 日本語メイン
- **特徴**: PRESIDENT、BOSS、WORKER による協調開発

## 重要なルール
1. **日本語でコミュニケーション**: すべてのやり取りは日本語で行う
2. **ユーザー要求最優先**: ユーザーの指示を正確に理解し実行する
3. **機能保持**: 既存機能を勝手に変更・削除しない
4. **AI組織連携**: AI組織システムとの一貫性を保つ
5. **「>」自動実行**: 指示には「>」を付けて自動実行対応

## AI組織システム構成
```
PRESIDENT (統括責任者)
    ↓
BOSS1 (チームリーダー)
    ↓
WORKER1, WORKER2, WORKER3 (実行担当)
```

## 重要なコマンド
- **起動**: `./ai-agents/manage.sh auto`
- **半自動起動**: `./ai-agents/manage.sh claude-auth`
- **状況確認**: `./ai-agents/manage.sh status`
- **設定確認**: `./setup.sh s`

## ファイル構造
```
.claude/
├── claude_desktop_config.json  # Claude Code設定
├── CLAUDE.md                   # このファイル
└── project_context.md          # プロジェクト文脈情報

ai-agents/
├── manage.sh                   # AI組織管理スクリプト
├── instructions/               # AI役割定義
└── logs/                      # 動作ログ
```

## 注意事項
- `.claude/`ディレクトリは.gitignoreに追加されており、ローカル設定のみ
- 設定は各環境で自動生成されるため、手動編集は非推奨
- 更新時は`./ai-agents/manage.sh setup-claude-config`で再設定
EOF
    
    # プロジェクト文脈情報の生成
    cat > .claude/project_context.md << 'EOF'
# プロジェクト文脈情報

## 現在のプロジェクト状況
- **プロジェクト名**: AI開発支援ツール
- **フェーズ**: 継続的改善・運用
- **主要技術**: Bash, AI組織システム, tmux

## AI組織システムの特徴
- **PRESIDENT**: プロジェクト統括、意思決定
- **BOSS1**: チームリーダー、作業分担管理
- **WORKER1-3**: 専門分野での実行担当

## 革新的機能
- **「>」自動実行**: Claude Code の自動実行機能活用
- **tmux連携**: マルチペイン管理とリアルタイム監視
- **動的UI**: ステータス表示とクリック移動対応

## 最近の重要な改善
- AI組織システムの完全自動化達成
- 「>」プレフィックスによる自動実行システム
- リアルタイムステータス更新機能
- .claude設定のローカル化対応

## 開発方針
1. **AI協調**: 複数AIによる効率的な協調開発
2. **自動化**: 手動作業の最小化
3. **ユーザビリティ**: 直感的な操作性
4. **拡張性**: 新機能の追加容易性
EOF
    
    log_success "✅ .claude設定生成完了！"
    echo ""
    echo "📁 生成されたファイル:"
    echo "   - .claude/claude_desktop_config.json"
    echo "   - .claude/CLAUDE.md"
    echo "   - .claude/project_context.md"
    echo ""
    echo "🎯 Claude Code起動時にこれらの設定が自動的に読み込まれます"
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
        "force-workers")
            # 🚀 ワーカー強制起動（緊急用）
            force_start_workers
            ;;
        "restore-ui")
            # 🎨 チームUI復旧（緊急用）
            restore_team_ui
            ;;
        "auto-execute")
            # 🚀 自動実行監視開始（AI組織駆動中）
            start_auto_execute_monitor
            ;;
        "stop-auto-execute")
            # 🛑 自動実行監視停止
            stop_auto_execute_monitor
            ;;
        "setup-claude-config")
            # 🔧 .claude設定自動生成
            setup_claude_local_config
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
            echo "  ./ai-agents/manage.sh force-workers      # 🚀 ワーカー強制起動（確実性重視）"
            echo "  ./ai-agents/manage.sh restore-ui         # 🎨 チームUI復旧（役職表示修復）"
            echo "  ./ai-agents/manage.sh auto-execute       # 🚀 自動実行監視開始（AI組織駆動中）"
            echo "  ./ai-agents/manage.sh stop-auto-execute  # 🛑 自動実行監視停止"
            echo "  ./ai-agents/manage.sh setup-claude-config # 🔧 .claude設定自動生成"
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
