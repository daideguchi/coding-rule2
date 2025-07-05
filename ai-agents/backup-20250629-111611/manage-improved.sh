#!/bin/bash
# 🤖 AI組織管理システム v3.0 - パフォーマンス改善版
# プレジデント、ボス、ワーカーの4画面AI組織システム（高速化・エラーハンドリング強化）

set -euo pipefail

# パフォーマンス設定
export TMUX_TMPDIR="${TMPDIR:-/tmp}"
export PARALLEL_MAX_JOBS=4

# 基本ディレクトリ設定
AGENTS_DIR="ai-agents"
LOGS_DIR="$AGENTS_DIR/logs"
SESSIONS_DIR="$AGENTS_DIR/sessions"
INSTRUCTIONS_DIR="$AGENTS_DIR/instructions"
TMP_DIR="$AGENTS_DIR/tmp"

# パフォーマンス設定
DEFAULT_TIMEOUT=30
MAX_RETRIES=3
RETRY_DELAY=1

# ログレベル設定
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# 依存関係チェック
check_dependencies() {
    local missing_deps=()
    
    command -v tmux >/dev/null 2>&1 || missing_deps+=("tmux")
    command -v claude >/dev/null 2>&1 || missing_deps+=("claude")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "❌ 必要なコマンドが見つかりません: ${missing_deps[*]}"
        echo "インストール方法:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                tmux) echo "  brew install tmux" ;;
                claude) echo "  curl -fsSL https://claude.ai/install.sh | sh" ;;
            esac
        done
        return 1
    fi
    return 0
}

# エラートラップ設定
trap 'cleanup_on_error $? $LINENO' ERR
trap 'cleanup_resources' EXIT

cleanup_on_error() {
    local exit_code=$1
    local line_no=$2
    log_error "❌ エラーが発生しました (終了コード: $exit_code, 行: $line_no)"
    cleanup_resources
    exit $exit_code
}

# リソースクリーンアップ
cleanup_resources() {
    local pids
    pids=$(jobs -p 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log_warn "🧹 バックグラウンドプロセスをクリーンアップ中..."
        kill $pids 2>/dev/null || true
        wait 2>/dev/null || true
    fi
}

# 色付きログ関数（改善版）
log_debug() {
    [ "$LOG_LEVEL" = "DEBUG" ] && echo -e "\033[1;36m[DEBUG]\033[0m $1" >&2
}

log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" >&2
}

# 時間付きログ関数
log_with_time() {
    local level=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "\033[1;90m[$timestamp]\033[0m $level $*"
}

# 再試行機能付き関数実行
retry() {
    local max_attempts=$1
    local delay=$2
    shift 2
    local cmd=("$@")
    
    for ((i=1; i<=max_attempts; i++)); do
        if "${cmd[@]}"; then
            return 0
        fi
        
        if [ $i -lt $max_attempts ]; then
            log_warn "⏳ 再試行中... ($i/$max_attempts)"
            sleep "$delay"
        fi
    done
    
    log_error "❌ 最大試行回数に達しました ($max_attempts)"
    return 1
}

# 必要ディレクトリの作成（並列処理）
init_directories() {
    local dirs=("$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR" "$TMP_DIR")
    
    # 並列でディレクトリ作成
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" &
    done
    wait
    
    # サブディレクトリ作成
    mkdir -p "$LOGS_DIR/ai-agents" "$LOGS_DIR/system" &
    wait
    
    log_info "📁 ディレクトリ構造を高速初期化しました"
}

# セッションファイルの作成（最適化）
create_session() {
    local role=$1
    local session_file="$SESSIONS_DIR/${role}_session.json"
    local timestamp=$(date -Iseconds)
    local session_id
    
    # UUID生成（フォールバック付き）
    if command -v uuidgen >/dev/null 2>&1; then
        session_id=$(uuidgen)
    else
        session_id="session_$(date +%s)_$$"
    fi
    
    # JSONファイルを原子的に作成
    local temp_file="${session_file}.tmp"
    cat > "$temp_file" << EOF
{
  "role": "$role",
  "session_id": "$session_id",
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
    
    mv "$temp_file" "$session_file"
    log_success "📝 ${role} セッションを作成しました: $session_file"
}

# tmuxセッション存在確認（高速化）
check_tmux_session() {
    local session_name=$1
    tmux has-session -t "$session_name" 2>/dev/null
}

# tmuxセッション削除（エラーハンドリング強化）
kill_tmux_session() {
    local session_name=$1
    
    if check_tmux_session "$session_name"; then
        log_info "🗑️ セッション '${session_name}' を削除中..."
        if ! tmux kill-session -t "$session_name" 2>/dev/null; then
            log_warn "⚠️ セッション '${session_name}' の削除に失敗"
            return 1
        fi
        log_success "✅ セッション '${session_name}' を削除しました"
    fi
    return 0
}

# 高速化されたシステム状況確認
system_status() {
    echo "🤖 AI組織システム状況 (v3.0)"
    echo "================================"
    echo ""
    
    # 並列処理でステータス確認
    {
        # ディレクトリ確認
        echo "📁 ディレクトリ状況:"
        for dir in "$LOGS_DIR" "$SESSIONS_DIR" "$INSTRUCTIONS_DIR"; do
            if [ -d "$dir" ]; then
                echo "  ✅ $dir"
            else
                echo "  ❌ $dir (未作成)"
            fi
        done
    } &
    
    {
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
    } &
    
    {
        # tmuxセッション確認
        echo "🖥️ tmuxセッション:"
        if command -v tmux >/dev/null 2>&1; then
            tmux list-sessions 2>/dev/null | sed 's/^/  /' || echo "  セッションなし"
        else
            echo "  ❌ tmux未インストール"
        fi
    } &
    
    wait
    
    # ログファイル確認（最適化）
    echo "📊 ログファイル:"
    if [ -d "$LOGS_DIR" ]; then
        find "$LOGS_DIR" -name "*.log" -type f 2>/dev/null | 
        while read -r logfile; do
            local size=$(stat -c%s "$logfile" 2>/dev/null || echo "?")
            echo "  📄 $(basename "$logfile") (${size}バイト)"
        done | head -10 || echo "  なし"
    else
        echo "  なし"
    fi
}

# tmux環境での起動（推奨・エラーハンドリング強化）
launch_tmux_sessions() {
    log_info "🚀 tmux環境でAI組織システムを起動中..."
    
    # 依存関係チェック
    if ! check_dependencies; then
        return 1
    fi
    
    # セッション削除（エラーハンドリング強化）
    local sessions=("president" "multiagent")
    for session in "${sessions[@]}"; do
        kill_tmux_session "$session"
    done
    
    # PRESIDENTセッション作成（タイムアウト付き）
    log_info "👑 PRESIDENTセッション作成中..."
    if ! timeout 10 tmux new-session -d -s president -c "$(pwd)"; then
        log_error "❌ PRESIDENTセッションの作成に失敗"
        return 1
    fi
    
    tmux send-keys -t president "echo '🎯 PRESIDENT セッション - 対話開始準備完了'" C-m
    tmux send-keys -t president "echo 'プレジデントモード開始: ./ai-agents/manage-improved.sh president'" C-m
    
    # multiagentセッション作成（4ペイン）
    log_info "👥 multiagentセッション作成中..."
    if ! timeout 10 tmux new-session -d -s multiagent -c "$(pwd)"; then
        log_error "❌ multiagentセッションの作成に失敗"
        return 1
    fi
    
    # 初期ペイン設定
    tmux send-keys -t multiagent "echo '👔 BOSS1 ペイン - 対話開始準備完了'" C-m
    tmux send-keys -t multiagent "echo 'ボスモード開始: ./ai-agents/manage-improved.sh boss'" C-m
    
    # 追加ペイン作成（並列処理）
    {
        tmux split-window -t multiagent -h -c "$(pwd)"
        tmux send-keys -t multiagent:0.1 "echo '👷 WORKER1 ペイン - 対話開始準備完了'" C-m
        tmux send-keys -t multiagent:0.1 "echo 'ワーカーモード開始: ./ai-agents/manage-improved.sh worker'" C-m
    } &
    
    {
        tmux split-window -t multiagent:0.1 -v -c "$(pwd)"
        tmux send-keys -t multiagent:0.2 "echo '👷 WORKER2 ペイン - 対話開始準備完了'" C-m
        tmux send-keys -t multiagent:0.2 "echo 'ワーカーモード開始: ./ai-agents/manage-improved.sh worker'" C-m
    } &
    
    {
        tmux select-pane -t multiagent:0.0
        tmux split-window -t multiagent:0.0 -v -c "$(pwd)"
        tmux send-keys -t multiagent:0.1 "echo '👷 WORKER3 ペイン - 対話開始準備完了'" C-m
        tmux send-keys -t multiagent:0.1 "echo 'ワーカーモード開始: ./ai-agents/manage-improved.sh worker'" C-m
    } &
    
    wait
    
    # レイアウト調整
    tmux select-layout -t multiagent tiled
    
    # 視覚的改善
    setup_tmux_visual_improvements
    
    log_success "✅ AI組織システムのtmuxセッションを高速作成しました"
    show_usage_instructions
}

# tmux視覚的改善設定
setup_tmux_visual_improvements() {
    log_info "🎨 tmux視覚的改善設定中..."
    
    # 高度なtmux視覚設定
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-style "fg=colour8"
    tmux set-option -g pane-active-border-style "fg=colour4,bold"
    
    # カラフルなペインタイトルフォーマット
    tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour4#,fg=colour15#,bold],#[bg=colour8#,fg=colour7]} #{pane_title} #[default]"
    
    # ステータスライン設定
    tmux set-option -g status-left-length 50
    tmux set-option -g status-right-length 50
    tmux set-option -g status-left "#[bg=colour4,fg=colour15,bold] AI組織システムv3.0 #[default]"
    tmux set-option -g status-right "#[bg=colour2,fg=colour15] %H:%M:%S #[default]"
    tmux set-option -g status-interval 1
    
    # 各ペインにタイトル設定
    tmux select-pane -t president:0 -T "👑 PRESIDENT・統括責任者 [起動完了]"
    tmux select-pane -t multiagent:0.0 -T "👔 BOSS・チームリーダー [待機中]"
    tmux select-pane -t multiagent:0.1 -T "💻 フロントエンド専門 [待機中]"
    tmux select-pane -t multiagent:0.2 -T "🔧 バックエンド専門 [待機中]"
    tmux select-pane -t multiagent:0.3 -T "🎨 UI/UX専門 [待機中]"
    
    # ウィンドウタイトル設定
    tmux rename-window -t president "👑 PRESIDENT"
    tmux rename-window -t multiagent "👥 AI-TEAM"
    
    log_success "✅ tmux視覚的改善完了"
}

# 使用方法表示
show_usage_instructions() {
    echo ""
    echo "📋 【高速化版】AI組織システム使用方法:"
    echo "  tmux attach-session -t president    # 👑 PRESIDENT画面（統括AI）"
    echo "  tmux attach-session -t multiagent   # 👥 4画面表示（BOSS+WORKER）"
    echo ""
    echo "🚀 【3ステップ起動】:"
    echo "  1️⃣ ./ai-agents/manage-improved.sh auto     # ワンコマンド起動"
    echo "  2️⃣ プレジデント画面で指示開始"
    echo "  3️⃣ multiagent画面で作業監視"
    echo ""
    echo "🎯 【Claude Code状態】全AIが高速起動準備完了"
}

# 簡単4画面起動（最適化版）
quick_start() {
    log_info "🚀 高速4画面AI組織システム起動中..."
    
    # 依存関係チェック
    if ! check_dependencies; then
        return 1
    fi
    
    # セッション削除
    local sessions=("president" "multiagent")
    for session in "${sessions[@]}"; do
        kill_tmux_session "$session"
    done
    
    # 並列でセッション作成
    {
        # PRESIDENTセッション
        tmux new-session -d -s president -c "$(pwd)"
        tmux send-keys -t president "clear" C-m
        tmux send-keys -t president "echo '🎯 PRESIDENT セッション - Claude Code高速起動中...'" C-m
        tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    } &
    
    {
        # multiagentセッション
        tmux new-session -d -s multiagent -c "$(pwd)"
        
        # ペイン作成を並列化
        tmux split-window -h -t multiagent
        tmux split-window -v -t multiagent:0.0
        tmux split-window -v -t multiagent:0.1
        tmux select-layout -t multiagent tiled
        
        # 各ペインでClaude Code起動
        for i in {0..3}; do
            tmux send-keys -t multiagent:0.$i "clear" C-m
            tmux send-keys -t multiagent:0.$i "echo '🤖 WORKER$((i+1)) ペイン - Claude Code高速起動中...'" C-m
            tmux send-keys -t multiagent:0.$i "claude --dangerously-skip-permissions" C-m
        done
    } &
    
    wait
    
    # 視覚的改善
    setup_tmux_visual_improvements
    
    # バックグラウンド自動化処理（最適化）
    setup_background_automation &
    
    log_success "✅ 高速4画面AI組織システム起動完了"
    show_usage_instructions
}

# バックグラウンド自動化処理（最適化）
setup_background_automation() {
    log_debug "🔄 バックグラウンド自動化開始"
    
    # Claude Code起動待機（タイムアウト付き）
    local timeout=60
    local count=0
    
    while [ $count -lt $timeout ]; do
        if tmux capture-pane -t president -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
            log_success "✅ PRESIDENT Claude Code起動完了 (${count}秒)"
            
            # 自動メッセージ送信
            sleep 0.5
            tmux send-keys -t president "あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。" C-m
            
            # ワーカー起動確認と自動設定
            setup_worker_automation &
            break
        fi
        
        sleep 1
        ((count++))
    done
    
    if [ $count -eq $timeout ]; then
        log_warn "⚠️ PRESIDENT起動検知タイムアウト"
    fi
}

# ワーカー自動化設定
setup_worker_automation() {
    log_debug "👥 ワーカー自動化設定開始"
    
    # 各ワーカーの起動確認（並列処理）
    for i in {0..3}; do
        {
            local timeout=60
            local count=0
            
            while [ $count -lt $timeout ]; do
                if tmux capture-pane -t multiagent:0.$i -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:" 2>/dev/null; then
                    log_success "✅ WORKER$((i+1)) Claude Code起動完了"
                    
                    # 役割設定メッセージ
                    local role_msg
                    case $i in
                        0) role_msg="あなたはBOSS・チームリーダーです。./ai-agents/instructions/boss.mdを参照してください。" ;;
                        1) role_msg="あなたはフロントエンドエンジニアです。./ai-agents/instructions/worker.mdを参照してください。" ;;
                        2) role_msg="あなたはバックエンドエンジニアです。./ai-agents/instructions/worker.mdを参照してください。" ;;
                        3) role_msg="あなたはUI/UXデザイナーです。./ai-agents/instructions/worker.mdを参照してください。" ;;
                    esac
                    
                    tmux send-keys -t multiagent:0.$i "$role_msg" C-m
                    break
                fi
                
                sleep 1
                ((count++))
            done
        } &
    done
    
    wait
    log_success "✅ 全ワーカー自動化設定完了"
}

# セッション削除関数（最適化）
clean_sessions() {
    log_info "🧹 AI組織システムセッション削除中..."
    
    local sessions=("president" "multiagent")
    local failed_sessions=()
    
    # 並列でセッション削除
    for session in "${sessions[@]}"; do
        {
            if ! kill_tmux_session "$session"; then
                failed_sessions+=("$session")
            fi
        } &
    done
    
    wait
    
    if [ ${#failed_sessions[@]} -eq 0 ]; then
        log_success "✅ 全セッション削除完了"
    else
        log_warn "⚠️ 削除に失敗したセッション: ${failed_sessions[*]}"
    fi
    
    # セッション確認
    echo ""
    echo "📊 現在のtmuxセッション:"
    tmux list-sessions 2>/dev/null || echo "  セッションなし"
}

# AI役割の対話システム（最適化）
start_ai_chat() {
    local role=$1
    local instruction_file="$INSTRUCTIONS_DIR/${role}.md"
    local log_file="$LOGS_DIR/${role}.log"
    
    # ファイル存在チェック
    if [ ! -f "$instruction_file" ]; then
        log_error "❌ 指示書が見つかりません: $instruction_file"
        return 1
    fi
    
    clear
    local role_upper=$(echo "$role" | tr '[:lower:]' '[:upper:]')
    echo "🤖 AI組織システム v3.0 - ${role_upper} 対話モード"
    echo "===================================================="
    echo ""
    cat "$instruction_file"
    echo ""
    echo "===================================================="
    echo "💬 Claude Code高速起動中...（自動認証・権限スキップ）"
    echo ""
    
    # ログ記録
    log_with_time "INFO" "${role} Claude Code セッション開始" >> "$log_file"
    
    # Claude Code起動（改善版）
    if command -v claude >/dev/null 2>&1; then
        printf "2\n" | timeout 30 claude --dangerously-skip-permissions < /dev/null || {
            log_error "❌ Claude Code起動に失敗"
            return 1
        }
    else
        log_error "❌ Claude Codeが見つかりません"
        return 1
    fi
}

# ヘルプ表示（改善版）
show_help() {
    cat << 'EOF'
🤖 AI組織管理システム v3.0 - パフォーマンス改善版
================================================

🚀 基本コマンド:
  ./ai-agents/manage-improved.sh auto          # 高速全自動起動
  ./ai-agents/manage-improved.sh start         # tmuxセッション作成のみ
  ./ai-agents/manage-improved.sh clean         # セッション削除
  ./ai-agents/manage-improved.sh status        # システム状況確認

📊 セッション操作:
  ./ai-agents/manage-improved.sh president     # PRESIDENT画面接続
  ./ai-agents/manage-improved.sh multiagent    # 4画面接続

🔧 改善点:
  ✅ 並列処理によるスピード向上
  ✅ 強化されたエラーハンドリング
  ✅ 依存関係チェック
  ✅ リソース自動クリーンアップ
  ✅ タイムアウト処理
  ✅ 詳細ログ出力

🎯 使用方法:
  1. ./ai-agents/manage-improved.sh auto       # 高速起動
  2. tmux attach-session -t president         # PRESIDENT画面
  3. tmux attach-session -t multiagent        # 4画面監視

💡 パフォーマンス設定:
  export LOG_LEVEL=DEBUG                      # デバッグログ有効
  export PARALLEL_MAX_JOBS=8                  # 並列処理数変更
EOF
}

# メイン処理（最適化）
main() {
    # 初期化
    init_directories
    
    case "${1:-help}" in
        "auto")
            log_info "🚀 AI組織システム高速全自動起動"
            quick_start
            ;;
        "start")
            log_info "🚀 tmuxセッション高速作成"
            launch_tmux_sessions
            ;;
        "clean")
            clean_sessions
            ;;
        "status")
            system_status
            ;;
        "president")
            if check_tmux_session president; then
                tmux attach-session -t president
            else
                log_error "❌ presidentセッションが存在しません"
                echo "先に './ai-agents/manage-improved.sh start' を実行してください"
                exit 1
            fi
            ;;
        "multiagent")
            if check_tmux_session multiagent; then
                tmux attach-session -t multiagent
            else
                log_error "❌ multiagentセッションが存在しません"
                echo "先に './ai-agents/manage-improved.sh start' を実行してください"
                exit 1
            fi
            ;;
        "help"|"--help"|"-h"|*)
            show_help
            ;;
    esac
}

# スクリプト実行
main "$@"