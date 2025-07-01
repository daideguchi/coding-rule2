#!/bin/bash

# 🚀 セッション間引き継ぎ完全自動化システム
# WORKER2 緊急革新実装
# 作成日: 2025-07-01

set -euo pipefail

# =============================================================================
# 設定・定数
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
readonly STATE_DIR="$PROJECT_ROOT/ai-agents/tmp/session-state"
readonly BACKUP_DIR="$PROJECT_ROOT/ai-agents/tmp/session-backups"
readonly LOG_FILE="$PROJECT_ROOT/logs/ai-agents/session-continuity.log"

# セッション設定
readonly PRESIDENT_SESSION="president"
readonly MULTIAGENT_SESSION="multiagent"
readonly WORKERS=("boss" "worker1" "worker2" "worker3")

# 監視間隔（効率化：リソース負荷考慮）
readonly MONITOR_INTERVAL=5  # 5秒間隔（軽量監視）
readonly BACKUP_INTERVAL=30  # 30秒間隔（定期バックアップ）
readonly HEALTH_CHECK_INTERVAL=60  # 1分間隔（ヘルスチェック）

# =============================================================================
# ログ・ユーティリティ関数
# =============================================================================

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $*" | tee -a "$LOG_FILE"
}

ensure_directory() {
    local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

# =============================================================================
# 1. 状態キャプチャシステム
# =============================================================================

capture_session_state() {
    local timestamp="${1:-$(date +%Y%m%d_%H%M%S)}"
    local state_file="$STATE_DIR/session_state_$timestamp.json"
    
    log_info "🔄 セッション状態キャプチャ開始: $timestamp"
    
    ensure_directory "$STATE_DIR"
    
    # JSON状態ファイル初期化
    cat > "$state_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "capture_version": "2.0",
    "sessions": {},
    "workers": {},
    "system_metrics": {},
    "context": {}
}
EOF

    # セッション状態キャプチャ
    capture_tmux_sessions "$state_file"
    capture_worker_contexts "$state_file"
    capture_system_metrics "$state_file"
    capture_task_contexts "$state_file"
    
    # 状態ファイル検証
    if jq empty "$state_file" 2>/dev/null; then
        log_success "✅ セッション状態キャプチャ完了: $state_file"
        echo "$state_file"
    else
        log_error "❌ 状態ファイル破損: $state_file"
        return 1
    fi
}

capture_tmux_sessions() {
    local state_file="$1"
    
    # セッション情報収集
    local sessions_info
    sessions_info=$(tmux list-sessions -F "#{session_name}:#{session_created}:#{session_windows}" 2>/dev/null || echo "")
    
    # JSON更新
    jq --arg sessions "$sessions_info" '.sessions.info = $sessions' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
    
    # 各ワーカーペインの内容キャプチャ
    for i in {0..3}; do
        local pane_content
        pane_content=$(tmux capture-pane -t "$MULTIAGENT_SESSION:0.$i" -p 2>/dev/null | tail -20 || echo "")
        jq --arg worker "worker$i" --arg content "$pane_content" '.sessions.panes[$worker] = $content' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
    done
}

capture_worker_contexts() {
    local state_file="$1"
    
    # 各ワーカーの現在の作業ディレクトリとプロセス
    for i in {0..3}; do
        local worker_id="worker$i"
        local cwd
        local active_processes
        
        # tmuxペインの作業ディレクトリ取得
        cwd=$(tmux display-message -t "$MULTIAGENT_SESSION:0.$i" -p "#{pane_current_path}" 2>/dev/null || echo "$PROJECT_ROOT")
        
        # アクティブプロセス情報
        active_processes=$(ps aux | grep -E "(claude|tmux)" | grep -v grep | wc -l || echo "0")
        
        # JSON更新
        jq --arg worker "$worker_id" --arg cwd "$cwd" --arg processes "$active_processes" \
           '.workers[$worker] = {"cwd": $cwd, "active_processes": $processes, "status": "active"}' \
           "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
    done
}

capture_system_metrics() {
    local state_file="$1"
    
    # 軽量システムメトリクス収集
    local memory_usage cpu_usage disk_usage
    
    memory_usage=$(ps -o pid,vsz,rss,comm -p $$ | awk 'NR>1 {print $2}' || echo "0")
    cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' || echo "0")
    disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    
    # JSON更新
    jq --arg memory "$memory_usage" --arg cpu "$cpu_usage" --arg disk "$disk_usage" \
       '.system_metrics = {"memory_kb": $memory, "cpu_percent": $cpu, "disk_percent": $disk}' \
       "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
}

capture_task_contexts() {
    local state_file="$1"
    
    # タスク進行状況キャプチャ
    local todo_files=()
    mapfile -t todo_files < <(find "$PROJECT_ROOT" -name "*todo*" -o -name "*task*" -type f 2>/dev/null | head -5)
    
    local tasks_summary=""
    for file in "${todo_files[@]}"; do
        if [[ -f "$file" && $(stat -f%z "$file" 2>/dev/null || echo 0) -lt 10000 ]]; then
            tasks_summary+="$(basename "$file"): $(head -3 "$file" 2>/dev/null | tr '\n' ' ')\n"
        fi
    done
    
    # JSON更新
    jq --arg tasks "$tasks_summary" '.context.tasks = $tasks' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
}

# =============================================================================
# 2. 状態復元システム
# =============================================================================

restore_session_state() {
    local state_file="$1"
    
    if [[ ! -f "$state_file" ]]; then
        log_error "❌ 状態ファイルが見つかりません: $state_file"
        return 1
    fi
    
    log_info "🔄 セッション状態復元開始: $state_file"
    
    # JSON検証
    if ! jq empty "$state_file" 2>/dev/null; then
        log_error "❌ 状態ファイルが破損しています: $state_file"
        return 1
    fi
    
    # 段階的復元
    restore_tmux_sessions "$state_file" || return 1
    restore_worker_contexts "$state_file" || return 1
    restore_system_state "$state_file" || return 1
    
    log_success "✅ セッション状態復元完了"
}

restore_tmux_sessions() {
    local state_file="$1"
    
    log_info "📱 tmuxセッション復元中..."
    
    # 既存セッション確認
    if ! tmux has-session -t "$MULTIAGENT_SESSION" 2>/dev/null; then
        log_info "🔧 multiagentセッション再作成中..."
        tmux new-session -d -s "$MULTIAGENT_SESSION"
        
        # 4分割レイアウト作成
        tmux split-window -h -t "$MULTIAGENT_SESSION"
        tmux split-window -v -t "$MULTIAGENT_SESSION:0.0"
        tmux split-window -v -t "$MULTIAGENT_SESSION:0.2"
        tmux select-layout -t "$MULTIAGENT_SESSION" tiled
    fi
    
    # ワーカーの再起動
    for i in {0..3}; do
        local worker_cwd
        worker_cwd=$(jq -r ".workers.worker$i.cwd // \"$PROJECT_ROOT\"" "$state_file")
        
        # ワーカーディレクトリ移動
        tmux send-keys -t "$MULTIAGENT_SESSION:0.$i" "cd \"$worker_cwd\"" C-m
        
        # Claude再起動（必要に応じて）
        if ! tmux capture-pane -t "$MULTIAGENT_SESSION:0.$i" -p | grep -q "Welcome to Claude Code"; then
            tmux send-keys -t "$MULTIAGENT_SESSION:0.$i" "claude --dangerously-skip-permissions" C-m
        fi
    done
}

restore_worker_contexts() {
    local state_file="$1"
    
    log_info "👥 ワーカーコンテキスト復元中..."
    
    # 各ワーカーに役割再設定
    local roles=("BOSS1" "WORKER1" "WORKER2" "WORKER3")
    for i in {0..3}; do
        local role="${roles[$i]}"
        tmux send-keys -t "$MULTIAGENT_SESSION:0.$i" "echo '🔄 ${role}として復帰しました'" C-m
    done
}

restore_system_state() {
    local state_file="$1"
    
    log_info "⚙️ システム状態復元中..."
    
    # 基本的なシステム状態確認
    local memory_usage
    memory_usage=$(jq -r '.system_metrics.memory_kb // "0"' "$state_file")
    
    if [[ "$memory_usage" -gt 100000 ]]; then
        log_info "⚠️ 高メモリ使用量検出: ${memory_usage}KB - 最適化実行"
        # メモリ最適化処理
        optimize_system_resources
    fi
}

# =============================================================================
# 3. 自動監視・復旧システム
# =============================================================================

start_session_monitor() {
    log_info "🖥️ セッション監視開始（効率化設計）"
    
    # バックグラウンドで軽量監視実行
    (
        while true; do
            monitor_session_health
            sleep "$MONITOR_INTERVAL"
        done
    ) &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "$STATE_DIR/monitor.pid"
    
    log_success "✅ セッション監視開始 (PID: $monitor_pid)"
}

monitor_session_health() {
    # 軽量ヘルスチェック（リソース負荷最小化）
    
    # 1. tmuxセッション生存確認
    if ! tmux has-session -t "$MULTIAGENT_SESSION" 2>/dev/null; then
        log_error "❌ multiagentセッション異常検出"
        auto_recover_session
        return
    fi
    
    # 2. ワーカー応答性確認（軽量）
    local unresponsive_workers=0
    for i in {0..3}; do
        if ! tmux capture-pane -t "$MULTIAGENT_SESSION:0.$i" -p | grep -q "cwd:\|$" 2>/dev/null; then
            ((unresponsive_workers++))
        fi
    done
    
    # 3. 異常時自動復旧
    if [[ "$unresponsive_workers" -gt 2 ]]; then
        log_error "❌ 複数ワーカー無応答検出 ($unresponsive_workers/4)"
        auto_recover_workers
    fi
}

auto_recover_session() {
    log_info "🔧 セッション自動復旧開始"
    
    # 最新状態を自動バックアップ
    local backup_file
    backup_file=$(capture_session_state)
    
    # セッション再構築
    if [[ -n "$backup_file" ]]; then
        restore_session_state "$backup_file"
    else
        # フォールバック：基本セッション作成
        create_basic_session
    fi
    
    log_success "✅ セッション自動復旧完了"
}

auto_recover_workers() {
    log_info "👥 ワーカー自動復旧開始"
    
    for i in {0..3}; do
        if ! tmux capture-pane -t "$MULTIAGENT_SESSION:0.$i" -p | grep -q "cwd:" 2>/dev/null; then
            log_info "🔧 ワーカー$i 復旧中..."
            tmux send-keys -t "$MULTIAGENT_SESSION:0.$i" C-c
            sleep 1
            tmux send-keys -t "$MULTIAGENT_SESSION:0.$i" "claude --dangerously-skip-permissions" C-m
        fi
    done
    
    log_success "✅ ワーカー自動復旧完了"
}

# =============================================================================
# 4. 効率的監視戦略（リソース負荷最適化）
# =============================================================================

start_efficient_monitoring() {
    log_info "📊 効率的監視システム開始"
    
    # 階層化監視戦略
    (
        # レベル1: 軽量監視（5秒間隔）
        while true; do
            quick_health_check
            sleep "$MONITOR_INTERVAL"
        done
    ) &
    
    (
        # レベル2: 定期バックアップ（30秒間隔）
        while true; do
            sleep "$BACKUP_INTERVAL"
            create_periodic_backup
        done
    ) &
    
    (
        # レベル3: 詳細ヘルスチェック（60秒間隔）
        while true; do
            sleep "$HEALTH_CHECK_INTERVAL"
            detailed_health_check
        done
    ) &
    
    log_success "✅ 効率的監視システム開始完了"
}

quick_health_check() {
    # 最軽量チェック（CPU負荷最小）
    local issues=0
    
    # tmuxプロセス存在確認
    if ! pgrep -f "tmux" >/dev/null; then
        ((issues++))
    fi
    
    # Claudeプロセス数確認
    local claude_count
    claude_count=$(pgrep -f "claude" | wc -l)
    if [[ "$claude_count" -lt 2 ]]; then
        ((issues++))
    fi
    
    # 異常時のみアクション
    if [[ "$issues" -gt 0 ]]; then
        log_error "⚠️ 軽量チェックで異常検出 (issues: $issues)"
        trigger_recovery_action
    fi
}

create_periodic_backup() {
    # 定期的な軽量バックアップ
    local backup_file="$BACKUP_DIR/auto_backup_$(date +%H%M%S).json"
    ensure_directory "$BACKUP_DIR"
    
    # 軽量状態情報のみ保存
    cat > "$backup_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "type": "periodic_backup",
    "tmux_sessions": "$(tmux list-sessions 2>/dev/null | wc -l || echo 0)",
    "claude_processes": "$(pgrep -f claude | wc -l || echo 0)",
    "project_root": "$PROJECT_ROOT"
}
EOF

    # 古いバックアップ削除（ディスク容量管理）
    find "$BACKUP_DIR" -name "auto_backup_*.json" -mmin +60 -delete 2>/dev/null
}

detailed_health_check() {
    # 詳細チェック（低頻度）
    log_info "🔍 詳細ヘルスチェック実行"
    
    # ディスク容量チェック
    local disk_usage
    disk_usage=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 90 ]]; then
        log_error "⚠️ ディスク容量不足: ${disk_usage}%"
        cleanup_old_files
    fi
    
    # プロセスメモリチェック
    local memory_usage
    memory_usage=$(ps -o pid,vsz -p $$ | awk 'NR>1 {print $2}')
    if [[ "$memory_usage" -gt 500000 ]]; then
        log_error "⚠️ 高メモリ使用量: ${memory_usage}KB"
        optimize_system_resources
    fi
}

# =============================================================================
# 5. システム最適化・メンテナンス
# =============================================================================

optimize_system_resources() {
    log_info "⚡ システムリソース最適化開始"
    
    # 一時ファイル削除
    cleanup_old_files
    
    # メモリ使用量削減
    if command -v purge >/dev/null 2>&1; then
        sudo purge 2>/dev/null || true
    fi
    
    log_success "✅ システムリソース最適化完了"
}

cleanup_old_files() {
    log_info "🧹 古いファイルクリーンアップ"
    
    # 1時間以上古い状態ファイル削除
    find "$STATE_DIR" -name "session_state_*.json" -mmin +60 -delete 2>/dev/null
    
    # 24時間以上古いログファイル圧縮
    find "$PROJECT_ROOT/logs" -name "*.log" -mtime +1 -exec gzip {} \; 2>/dev/null
    
    # 7日以上古い圧縮ログ削除
    find "$PROJECT_ROOT/logs" -name "*.log.gz" -mtime +7 -delete 2>/dev/null
}

create_basic_session() {
    log_info "🔧 基本セッション作成"
    
    # フォールバック用基本セッション
    tmux new-session -d -s "$MULTIAGENT_SESSION" || true
    tmux split-window -h -t "$MULTIAGENT_SESSION" || true
    tmux split-window -v -t "$MULTIAGENT_SESSION:0.0" || true
    tmux split-window -v -t "$MULTIAGENT_SESSION:0.2" || true
    tmux select-layout -t "$MULTIAGENT_SESSION" tiled || true
    
    log_success "✅ 基本セッション作成完了"
}

trigger_recovery_action() {
    log_info "🚨 復旧アクション実行"
    
    # 段階的復旧
    if ! tmux has-session -t "$MULTIAGENT_SESSION" 2>/dev/null; then
        create_basic_session
    fi
    
    # ワーカー復旧
    auto_recover_workers
}

# =============================================================================
# 6. メイン制御関数
# =============================================================================

start_session_continuity_engine() {
    log_info "🚀 セッション継続エンジン開始"
    
    # ディレクトリ初期化
    ensure_directory "$STATE_DIR"
    ensure_directory "$BACKUP_DIR"
    ensure_directory "$(dirname "$LOG_FILE")"
    
    # 初期状態キャプチャ
    local initial_state
    initial_state=$(capture_session_state "initial_$(date +%Y%m%d_%H%M%S)")
    
    # 効率的監視開始
    start_efficient_monitoring
    
    log_success "✅ セッション継続エンジン開始完了"
    echo "状態ファイル: $initial_state"
    echo "ログファイル: $LOG_FILE"
}

stop_session_continuity_engine() {
    log_info "🛑 セッション継続エンジン停止"
    
    # 監視プロセス停止
    if [[ -f "$STATE_DIR/monitor.pid" ]]; then
        local monitor_pid
        monitor_pid=$(cat "$STATE_DIR/monitor.pid")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid" 2>/dev/null || true
        fi
        rm -f "$STATE_DIR/monitor.pid"
    fi
    
    # 最終状態バックアップ
    capture_session_state "final_$(date +%Y%m%d_%H%M%S)"
    
    log_success "✅ セッション継続エンジン停止完了"
}

# =============================================================================
# 7. CLI インターフェース
# =============================================================================

show_usage() {
    cat << EOF
🚀 セッション継続エンジン v2.0

使用方法:
    $0 start                    - エンジン開始
    $0 stop                     - エンジン停止
    $0 capture [TIMESTAMP]      - 状態キャプチャ
    $0 restore STATE_FILE       - 状態復元
    $0 monitor                  - 監視状況確認
    $0 cleanup                  - クリーンアップ実行

例:
    $0 start
    $0 capture
    $0 restore /path/to/state.json
EOF
}

main() {
    local command="${1:-}"
    
    case "$command" in
        "start")
            start_session_continuity_engine
            ;;
        "stop")
            stop_session_continuity_engine
            ;;
        "capture")
            local timestamp="${2:-$(date +%Y%m%d_%H%M%S)}"
            capture_session_state "$timestamp"
            ;;
        "restore")
            local state_file="${2:-}"
            if [[ -z "$state_file" ]]; then
                log_error "❌ 状態ファイルを指定してください"
                exit 1
            fi
            restore_session_state "$state_file"
            ;;
        "monitor")
            if [[ -f "$STATE_DIR/monitor.pid" ]]; then
                local monitor_pid
                monitor_pid=$(cat "$STATE_DIR/monitor.pid")
                if kill -0 "$monitor_pid" 2>/dev/null; then
                    echo "✅ 監視プロセス稼働中 (PID: $monitor_pid)"
                else
                    echo "❌ 監視プロセス停止中"
                fi
            else
                echo "❌ 監視プロセス未開始"
            fi
            ;;
        "cleanup")
            cleanup_old_files
            optimize_system_resources
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "❌ 無効なコマンド: $command"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト直接実行時
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi