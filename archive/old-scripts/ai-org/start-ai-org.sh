#!/bin/bash

# =============================================================================
# AI組織統合起動スクリプト - ワンコマンド完全自動化
# =============================================================================
# 
# 目的: 複雑な5ステップ手順を1コマンドに統合
# 従来: 手動認証→強制終了→再起動→別ターミナル4画面起動→手動メッセージ
# 新方式: ./start-ai-org.sh で全自動完了
#
# =============================================================================

set -euo pipefail

# カラーコード定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}==== $1 ====${NC}"
}

# プログレスバー表示
show_progress() {
    local current=$1
    local total=$2
    local step_name="$3"
    local percent=$((current * 100 / total))
    local completed=$((current * 50 / total))
    local remaining=$((50 - completed))
    
    printf "\r${CYAN}Progress [${GREEN}"
    printf "%${completed}s" | tr ' ' '='
    printf "${NC}${CYAN}"
    printf "%${remaining}s" | tr ' ' '-'
    printf "] ${percent}%% - ${step_name}${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# 致命的エラーハンドラー
fatal_error() {
    log_error "致命的エラー: $1"
    log_error "AI組織起動に失敗しました"
    exit 1
}

# 依存関係チェック
check_dependencies() {
    log_step "依存関係チェック中..."
    show_progress 1 8 "依存関係確認"
    
    # 必須コマンドの存在確認
    local required_commands=("tmux" "claude")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            fatal_error "必須コマンド '$cmd' が見つかりません"
        fi
    done
    
    # ディレクトリ構造確認
    if [[ ! -d "./ai-agents" ]]; then
        fatal_error "ai-agentsディレクトリが見つかりません"
    fi
    
    if [[ ! -f "./ai-agents/instructions/president.md" ]]; then
        fatal_error "president.md指示書が見つかりません"
    fi
    
    log_success "全ての依存関係が確認されました"
}

# 既存セッション整理
cleanup_existing_sessions() {
    log_step "既存セッション整理中..."
    show_progress 2 8 "セッション整理"
    
    # 既存のtmuxセッションをクリーンアップ
    if tmux has-session -t president 2>/dev/null; then
        log_info "既存のpresidentセッションを終了中..."
        tmux kill-session -t president
    fi
    
    if tmux has-session -t multiagent 2>/dev/null; then
        log_info "既存のmultiagentセッションを終了中..."
        tmux kill-session -t multiagent
    fi
    
    log_success "セッション整理完了"
}

# 認証プロセス自動化
auto_authentication() {
    log_step "認証プロセス自動化中..."
    show_progress 3 8 "認証処理"
    
    # 認証方法の自動検出と実行
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        log_info "API Key認証を使用"
        export CLAUDE_AUTH_METHOD="api"
    else
        log_info "Claude.ai認証を使用"
        export CLAUDE_AUTH_METHOD="web"
    fi
    
    log_success "認証設定完了"
}

# PRESIDENT セッション起動
start_president_session() {
    log_step "PRESIDENT セッション起動中..."
    show_progress 4 8 "PRESIDENT起動"
    
    # PRESIDENTセッション作成と起動
    tmux new-session -d -s president -c "$(pwd)"
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    # 起動確認（最大60秒待機）
    local timeout=60
    local elapsed=0
    
    log_info "PRESIDENT起動を確認中..."
    while [ $elapsed -lt $timeout ]; do
        if tmux capture-pane -t president -p | grep -q "Welcome to Claude"; then
            log_success "PRESIDENT起動確認完了"
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    if [ $elapsed -ge $timeout ]; then
        fatal_error "PRESIDENT起動がタイムアウトしました"
    fi
    
    # 権限設定の自動処理
    sleep 2
    tmux send-keys -t president C-m  # Bypass permissions
    sleep 1
}

# 4画面マルチエージェント構築
setup_multiagent_layout() {
    log_step "4画面マルチエージェント構築中..."
    show_progress 5 8 "マルチエージェント構築"
    
    # マルチエージェントセッション作成
    tmux new-session -d -s multiagent -c "$(pwd)"
    
    # 4分割レイアウト構築
    tmux split-window -h -t multiagent
    tmux split-window -v -t multiagent:0.0
    tmux split-window -v -t multiagent:0.1
    tmux select-layout -t multiagent tiled
    
    # 各ペインにタイトル設定
    tmux select-pane -t multiagent:0.0 -T "👔 BOSS1"
    tmux select-pane -t multiagent:0.1 -T "💻 WORKER1"
    tmux select-pane -t multiagent:0.2 -T "🔧 WORKER2"
    tmux select-pane -t multiagent:0.3 -T "🎨 WORKER3"
    
    # 各エージェント起動
    local agents=("0.0" "0.1" "0.2" "0.3")
    for pane in "${agents[@]}"; do
        tmux send-keys -t "multiagent:${pane}" "claude --dangerously-skip-permissions" C-m
        sleep 2
        tmux send-keys -t "multiagent:${pane}" C-m  # Bypass permissions
        sleep 1
    done
    
    log_success "4画面マルチエージェント構築完了"
}

# 初期メッセージ自動配信
auto_message_distribution() {
    log_step "初期メッセージ自動配信中..."
    show_progress 6 8 "メッセージ配信"
    
    # PRESIDENT起動完了確認
    local timeout=120
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if tmux capture-pane -t president -p | grep -q "How can I help you"; then
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    if [ $elapsed -ge $timeout ]; then
        log_warning "PRESIDENT完全起動確認がタイムアウト、メッセージ送信を継続"
    fi
    
    # PRESIDENTに初期指示送信
    local president_message=">あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。
【重要】ワーカーに指示を送る時は必ず文頭に「>」を付けてください。
まず最初に、以下のコマンドでワーカーたちを起動し、その後BOSS1、WORKER1、WORKER2、WORKER3の4人全員に対して、
それぞれの指示書（boss.md、worker.md）を確認するよう指示を出してください。"
    
    tmux send-keys -t president "$president_message" C-m
    sleep 2
    tmux send-keys -t president C-m  # 確実なEnter送信
    
    log_success "初期メッセージ配信完了"
}

# エージェント起動確認
verify_agents_startup() {
    log_step "全エージェント起動確認中..."
    show_progress 7 8 "起動確認"
    
    # 各エージェントの起動確認
    local agents=("president" "multiagent:0.0" "multiagent:0.1" "multiagent:0.2" "multiagent:0.3")
    local agent_names=("PRESIDENT" "BOSS1" "WORKER1" "WORKER2" "WORKER3")
    
    for i in "${!agents[@]}"; do
        local pane="${agents[$i]}"
        local name="${agent_names[$i]}"
        
        log_info "Checking ${name}..."
        
        local timeout=30
        local elapsed=0
        
        while [ $elapsed -lt $timeout ]; do
            if tmux capture-pane -t "$pane" -p | grep -E "(How can I help|>|Welcome)" > /dev/null; then
                log_success "${name} 起動確認完了"
                break
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        if [ $elapsed -ge $timeout ]; then
            log_warning "${name} 起動確認がタイムアウト（継続）"
        fi
    done
}

# 最終セットアップ
final_setup() {
    log_step "最終セットアップ中..."
    show_progress 8 8 "セットアップ完了"
    
    # UI設定とレイアウト最適化
    tmux set-option -t multiagent status on
    tmux set-option -t multiagent pane-border-status top
    tmux set-option -t multiagent pane-border-format "#{pane_title}"
    
    # PRESIDENTセッションにフォーカス
    tmux attach-session -t president \; \
        split-window -h \; \
        send-keys "tmux attach-session -t multiagent" C-m \; \
        select-pane -L
    
    log_success "AI組織完全起動完了！"
}

# メイン実行関数
main() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "🚀 AI組織統合起動システム 2.0"
    echo "=============================================="
    echo -e "${NC}"
    echo "複雑な5ステップ → シンプル1コマンド"
    echo ""
    
    # 実行確認
    read -p "AI組織を起動しますか？ [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        log_info "起動をキャンセルしました"
        exit 0
    fi
    
    # 段階的実行
    check_dependencies
    cleanup_existing_sessions
    auto_authentication
    start_president_session
    setup_multiagent_layout
    auto_message_distribution
    verify_agents_startup
    final_setup
}

# エラーハンドリング設定
trap 'fatal_error "予期しないエラーが発生しました"' ERR

# スクリプト実行
main "$@"