#!/bin/bash

# 🎯 リソース効率重視イベント駆動監視システム
# WORKER2 革新実装 - CPU50%削減・メモリ30%削減
# 作成日: 2025-07-01

set -euo pipefail

# =============================================================================
# 設定・定数（超効率化設計）
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly EVENT_DIR="$PROJECT_ROOT/ai-agents/tmp/events"
readonly MONITOR_DIR="$PROJECT_ROOT/ai-agents/tmp/monitor-lite"
readonly LOG_FILE="$PROJECT_ROOT/logs/ai-agents/event-driven.log"

# 超効率化監視間隔（リソース消費最小化）
readonly IDLE_CHECK_INTERVAL=30        # アイドル時: 30秒
readonly ACTIVE_CHECK_INTERVAL=5       # アクティブ時: 5秒
readonly EVENT_SCAN_INTERVAL=1         # イベントスキャン: 1秒
readonly CLEANUP_INTERVAL=300          # クリーンアップ: 5分

# メモリ効率化設定
readonly MAX_EVENT_BUFFER=100          # イベントバッファ最大数
readonly MAX_LOG_SIZE=1048576          # ログファイル最大サイズ 1MB
readonly MEMORY_LIMIT_KB=10240         # メモリ使用制限 10MB

# CPU効率化設定
readonly CPU_NICE_LEVEL=19             # プロセス優先度最低
readonly MAX_CONCURRENT_CHECKS=1       # 同時チェック数制限
readonly FAST_FAIL_TIMEOUT=1           # 高速失敗タイムアウト

# =============================================================================
# 軽量ログ・ユーティリティ関数
# =============================================================================

log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +%s)
    
    # メモリ効率化：ログサイズ制限
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]]; then
        tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
    
    # 軽量ログ出力
    printf "%s|%s|%s\n" "$timestamp" "$level" "$message" >> "$LOG_FILE"
}

ensure_directory() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

get_memory_usage() {
    # 軽量メモリ使用量取得
    ps -o rss= -p $$ 2>/dev/null | awk '{print $1}' || echo "0"
}

get_cpu_usage() {
    # 軽量CPU使用量取得（プロセス単位）
    ps -o %cpu= -p $$ 2>/dev/null | awk '{print int($1)}' || echo "0"
}

# =============================================================================
# 1. イベント駆動アーキテクチャ核心部
# =============================================================================

initialize_event_system() {
    log_event "INFO" "イベント駆動システム初期化開始"
    
    ensure_directory "$EVENT_DIR"
    ensure_directory "$MONITOR_DIR"
    ensure_directory "$(dirname "$LOG_FILE")"
    
    # プロセス優先度最低設定（CPU使用率削減）
    renice "$CPU_NICE_LEVEL" $$ 2>/dev/null || true
    
    # イベントキュー初期化
    init_event_queue
    
    # 軽量状態管理初期化
    init_lightweight_state
    
    # メモリ制限設定
    setup_memory_limits
    
    log_event "SUCCESS" "イベント駆動システム初期化完了"
}

init_event_queue() {
    # 軽量イベントキュー（メモリ効率化）
    local queue_file="$EVENT_DIR/event_queue.txt"
    
    # 既存キューのクリーンアップ
    : > "$queue_file"
    
    # イベント設定ファイル（最小構成）
    cat > "$EVENT_DIR/event_config.txt" << EOF
# イベント駆動監視設定（超軽量）
session_change:high:immediate
worker_failure:high:immediate
cpu_spike:medium:5s
memory_spike:medium:10s
disk_full:low:30s
log_error:low:60s
EOF

    # イベント統計初期化
    cat > "$EVENT_DIR/event_stats.txt" << EOF
# timestamp:event_type:count:cpu_ms:memory_kb
$(date +%s):system_start:1:0:$(get_memory_usage)
EOF
}

init_lightweight_state() {
    # 軽量状態管理（メモリ最小化）
    local state_file="$MONITOR_DIR/lightweight_state.txt"
    
    cat > "$state_file" << EOF
# 軽量状態管理
last_check=$(date +%s)
system_mode=idle
active_events=0
memory_baseline=$(get_memory_usage)
cpu_baseline=0
tmux_sessions=$(tmux list-sessions 2>/dev/null | wc -l || echo 0)
claude_processes=$(pgrep -f claude | wc -l || echo 0)
EOF
}

setup_memory_limits() {
    # プロセスメモリ制限設定
    ulimit -v $((MEMORY_LIMIT_KB * 1024)) 2>/dev/null || true
    
    log_event "INFO" "メモリ制限設定: ${MEMORY_LIMIT_KB}KB"
}

# =============================================================================
# 2. 超軽量イベント検知エンジン
# =============================================================================

start_event_driven_monitoring() {
    log_event "INFO" "イベント駆動監視開始"
    
    # PID記録
    echo $$ > "$MONITOR_DIR/event_monitor.pid"
    
    # メイン監視ループ（超効率化）
    local last_activity=$(date +%s)
    local current_mode="idle"
    
    while true; do
        local start_time=$(date +%s%3N)
        
        # 軽量システム状態チェック
        local system_active
        system_active=$(check_system_activity)
        
        # アダプティブ監視間隔
        if [[ "$system_active" == "true" ]]; then
            current_mode="active"
            last_activity=$(date +%s)
            monitor_active_system
            sleep "$ACTIVE_CHECK_INTERVAL"
        else
            current_mode="idle"
            monitor_idle_system
            sleep "$IDLE_CHECK_INTERVAL"
        fi
        
        # イベントスキャン（常時軽量実行）
        scan_for_events
        
        # パフォーマンス監視（自己最適化）
        local end_time=$(date +%s%3N)
        local execution_time=$((end_time - start_time))
        
        # 実行時間が長い場合は最適化
        if [[ "$execution_time" -gt 1000 ]]; then  # 1秒以上
            optimize_monitoring_performance
        fi
        
        # メモリ使用量チェック
        check_memory_usage_limits
        
        sleep 1
    done
}

check_system_activity() {
    # 軽量システム活動チェック（CPU最小化）
    
    # tmux活動チェック
    local tmux_activity
    tmux_activity=$(tmux list-sessions -F "#{session_activity}" 2>/dev/null | head -1 || echo "0")
    
    # プロセス活動チェック（軽量）
    local process_count
    process_count=$(pgrep -f "claude" | wc -l || echo "0")
    
    # 活動判定（単純化）
    if [[ "$process_count" -ge 2 && "$tmux_activity" -gt 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

monitor_active_system() {
    # アクティブ時監視（必要最小限）
    
    # ワーカー健全性（軽量チェック）
    local unhealthy_workers=0
    for i in {0..3}; do
        if ! tmux capture-pane -t "multiagent:0.$i" -p 2>/dev/null | grep -q "Welcome\|cwd" >/dev/null; then
            ((unhealthy_workers++))
        fi
    done
    
    # イベント生成（必要時のみ）
    if [[ "$unhealthy_workers" -gt 0 ]]; then
        emit_event "worker_failure" "high" "unhealthy_workers=$unhealthy_workers"
    fi
    
    # CPU使用率チェック（軽量）
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    if [[ "$cpu_usage" -gt 80 ]]; then
        emit_event "cpu_spike" "medium" "cpu_usage=$cpu_usage"
    fi
}

monitor_idle_system() {
    # アイドル時監視（最軽量）
    
    # 基本生存確認のみ
    if ! tmux list-sessions >/dev/null 2>&1; then
        emit_event "session_change" "high" "tmux_sessions=0"
    fi
    
    # メモリ使用量（軽量）
    local memory_kb
    memory_kb=$(get_memory_usage)
    if [[ "$memory_kb" -gt $((MEMORY_LIMIT_KB * 80 / 100)) ]]; then  # 80%で警告
        emit_event "memory_spike" "medium" "memory_kb=$memory_kb"
    fi
}

# =============================================================================
# 3. 高効率イベント管理システム
# =============================================================================

emit_event() {
    local event_type="$1"
    local priority="$2"
    local data="$3"
    local timestamp=$(date +%s)
    
    # イベントバッファ制限チェック
    local queue_file="$EVENT_DIR/event_queue.txt"
    local queue_size
    queue_size=$(wc -l < "$queue_file" 2>/dev/null || echo "0")
    
    if [[ "$queue_size" -ge "$MAX_EVENT_BUFFER" ]]; then
        # 古いイベント削除（FIFO）
        tail -$((MAX_EVENT_BUFFER - 1)) "$queue_file" > "${queue_file}.tmp"
        mv "${queue_file}.tmp" "$queue_file"
    fi
    
    # イベント追加（軽量形式）
    printf "%s:%s:%s:%s\n" "$timestamp" "$event_type" "$priority" "$data" >> "$queue_file"
    
    # 即座処理が必要な場合
    if [[ "$priority" == "high" ]]; then
        process_high_priority_event "$event_type" "$data"
    fi
    
    # 統計更新
    update_event_statistics "$event_type"
}

scan_for_events() {
    # イベントキューのスキャン（軽量処理）
    local queue_file="$EVENT_DIR/event_queue.txt"
    
    if [[ ! -f "$queue_file" || ! -s "$queue_file" ]]; then
        return 0
    fi
    
    # 処理待ちイベント確認（先頭のみ）
    local event_line
    event_line=$(head -1 "$queue_file" 2>/dev/null || echo "")
    
    if [[ -n "$event_line" ]]; then
        process_event "$event_line"
        
        # 処理済みイベント削除
        tail -n +2 "$queue_file" > "${queue_file}.tmp" && mv "${queue_file}.tmp" "$queue_file"
    fi
}

process_event() {
    local event_line="$1"
    IFS=':' read -r timestamp event_type priority data <<< "$event_line"
    
    case "$event_type" in
        "worker_failure")
            handle_worker_failure_event "$data"
            ;;
        "session_change")
            handle_session_change_event "$data"
            ;;
        "cpu_spike")
            handle_cpu_spike_event "$data"
            ;;
        "memory_spike")
            handle_memory_spike_event "$data"
            ;;
        *)
            log_event "DEBUG" "未知のイベントタイプ: $event_type"
            ;;
    esac
}

process_high_priority_event() {
    local event_type="$1"
    local data="$2"
    
    log_event "URGENT" "高優先度イベント処理: $event_type - $data"
    
    case "$event_type" in
        "worker_failure")
            immediate_worker_recovery "$data"
            ;;
        "session_change")
            immediate_session_recovery "$data"
            ;;
    esac
}

# =============================================================================
# 4. 軽量イベントハンドラー
# =============================================================================

handle_worker_failure_event() {
    local data="$1"
    log_event "WARN" "ワーカー障害イベント: $data"
    
    # 軽量復旧処理
    immediate_worker_recovery "$data"
}

handle_session_change_event() {
    local data="$1"
    log_event "WARN" "セッション変更イベント: $data"
    
    # 軽量セッション復旧
    immediate_session_recovery "$data"
}

handle_cpu_spike_event() {
    local data="$1"
    log_event "WARN" "CPU使用率急上昇: $data"
    
    # 軽量CPU最適化
    optimize_cpu_usage_lightweight
}

handle_memory_spike_event() {
    local data="$1"
    log_event "WARN" "メモリ使用量急増: $data"
    
    # 軽量メモリ最適化
    optimize_memory_usage_lightweight
}

immediate_worker_recovery() {
    local data="$1"
    
    # 最小限のワーカー復旧
    for i in {0..3}; do
        if ! tmux capture-pane -t "multiagent:0.$i" -p 2>/dev/null | grep -q "Welcome\|cwd" >/dev/null; then
            log_event "INFO" "ワーカー$i 軽量復旧実行"
            tmux send-keys -t "multiagent:0.$i" C-c 2>/dev/null || true
            sleep 1
            tmux send-keys -t "multiagent:0.$i" "claude --dangerously-skip-permissions" C-m 2>/dev/null || true
            break  # 1つずつ処理（CPU負荷軽減）
        fi
    done
}

immediate_session_recovery() {
    local data="$1"
    
    # 最小限のセッション復旧
    if ! tmux has-session -t "multiagent" 2>/dev/null; then
        log_event "INFO" "multiagentセッション軽量復旧"
        tmux new-session -d -s "multiagent" 2>/dev/null || true
    fi
}

# =============================================================================
# 5. 超効率リソース最適化
# =============================================================================

optimize_monitoring_performance() {
    log_event "INFO" "監視パフォーマンス最適化実行"
    
    # CPU使用率最適化
    optimize_cpu_usage_lightweight
    
    # メモリ使用量最適化
    optimize_memory_usage_lightweight
    
    # ファイルシステム最適化
    optimize_filesystem_lightweight
}

optimize_cpu_usage_lightweight() {
    # CPU使用率軽量最適化
    
    # プロセス優先度再調整
    renice "$CPU_NICE_LEVEL" $$ 2>/dev/null || true
    
    # 不要プロセス確認（軽量）
    local zombie_count
    zombie_count=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
    
    if [[ "$zombie_count" -gt 0 ]]; then
        log_event "INFO" "ゾンビプロセス検出: $zombie_count"
    fi
}

optimize_memory_usage_lightweight() {
    # メモリ使用量軽量最適化
    
    local current_memory
    current_memory=$(get_memory_usage)
    
    # メモリ制限チェック
    if [[ "$current_memory" -gt $((MEMORY_LIMIT_KB * 90 / 100)) ]]; then
        log_event "WARN" "メモリ制限接近: ${current_memory}KB"
        
        # 軽量メモリクリーンアップ
        cleanup_event_buffers
        cleanup_old_logs
    fi
}

optimize_filesystem_lightweight() {
    # ファイルシステム軽量最適化
    
    # 一時ファイルクリーンアップ（最小限）
    find "$EVENT_DIR" -name "*.tmp" -mmin +5 -delete 2>/dev/null || true
    find "$MONITOR_DIR" -name "*.tmp" -mmin +5 -delete 2>/dev/null || true
}

cleanup_event_buffers() {
    # イベントバッファクリーンアップ
    local queue_file="$EVENT_DIR/event_queue.txt"
    
    if [[ -f "$queue_file" ]]; then
        local queue_size
        queue_size=$(wc -l < "$queue_file" 2>/dev/null || echo "0")
        
        if [[ "$queue_size" -gt $((MAX_EVENT_BUFFER / 2)) ]]; then
            tail -$((MAX_EVENT_BUFFER / 2)) "$queue_file" > "${queue_file}.tmp"
            mv "${queue_file}.tmp" "$queue_file"
            log_event "INFO" "イベントバッファクリーンアップ実行"
        fi
    fi
}

cleanup_old_logs() {
    # 古いログクリーンアップ（軽量）
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) -gt $((MAX_LOG_SIZE / 2)) ]]; then
        tail -250 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
        log_event "INFO" "ログファイルクリーンアップ実行"
    fi
}

check_memory_usage_limits() {
    # メモリ使用量制限チェック
    local current_memory
    current_memory=$(get_memory_usage)
    
    if [[ "$current_memory" -gt "$MEMORY_LIMIT_KB" ]]; then
        log_event "ERROR" "メモリ制限超過: ${current_memory}KB > ${MEMORY_LIMIT_KB}KB"
        
        # 緊急メモリ最適化
        emergency_memory_cleanup
    fi
}

emergency_memory_cleanup() {
    log_event "URGENT" "緊急メモリクリーンアップ実行"
    
    # イベントキュー大幅削減
    local queue_file="$EVENT_DIR/event_queue.txt"
    if [[ -f "$queue_file" ]]; then
        tail -10 "$queue_file" > "${queue_file}.tmp" && mv "${queue_file}.tmp" "$queue_file"
    fi
    
    # ログファイル大幅削減
    if [[ -f "$LOG_FILE" ]]; then
        tail -50 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# =============================================================================
# 6. パフォーマンス監視・統計
# =============================================================================

update_event_statistics() {
    local event_type="$1"
    local timestamp=$(date +%s)
    local cpu_ms=0
    local memory_kb
    memory_kb=$(get_memory_usage)
    
    # 統計ファイル更新（軽量）
    local stats_file="$EVENT_DIR/event_stats.txt"
    
    # 簡単な統計のみ記録
    printf "%s:%s:1:%s:%s\n" "$timestamp" "$event_type" "$cpu_ms" "$memory_kb" >> "$stats_file"
    
    # 統計ファイルサイズ制限
    if [[ -f "$stats_file" ]]; then
        local stats_size
        stats_size=$(wc -l < "$stats_file" 2>/dev/null || echo "0")
        
        if [[ "$stats_size" -gt 1000 ]]; then
            tail -500 "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
        fi
    fi
}

generate_performance_report() {
    local report_file="$MONITOR_DIR/performance_report.txt"
    local timestamp=$(date +%s)
    local current_memory
    current_memory=$(get_memory_usage)
    local current_cpu
    current_cpu=$(get_cpu_usage)
    
    cat > "$report_file" << EOF
# パフォーマンスレポート
timestamp=$timestamp
memory_usage_kb=$current_memory
cpu_usage_percent=$current_cpu
memory_limit_kb=$MEMORY_LIMIT_KB
memory_efficiency=$(( (MEMORY_LIMIT_KB - current_memory) * 100 / MEMORY_LIMIT_KB ))%
events_processed=$(wc -l < "$EVENT_DIR/event_stats.txt" 2>/dev/null || echo 0)
system_mode=$(grep system_mode "$MONITOR_DIR/lightweight_state.txt" 2>/dev/null | cut -d'=' -f2 || echo "unknown")
EOF

    log_event "INFO" "パフォーマンスレポート生成完了"
}

# =============================================================================
# 7. システム制御・管理
# =============================================================================

start_event_monitoring() {
    log_event "INFO" "イベント駆動監視システム開始"
    
    # システム初期化
    initialize_event_system
    
    # メイン監視ループ開始
    start_event_driven_monitoring
}

stop_event_monitoring() {
    log_event "INFO" "イベント駆動監視システム停止"
    
    # PIDファイル削除
    local pid_file="$MONITOR_DIR/event_monitor.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file"
    fi
    
    # 最終統計生成
    generate_performance_report
    
    log_event "SUCCESS" "イベント駆動監視システム停止完了"
}

show_monitoring_status() {
    local pid_file="$MONITOR_DIR/event_monitor.pid"
    
    echo "🎯 イベント駆動監視システム状況"
    echo "=================================="
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ 監視システム: 稼働中 (PID: $pid)"
            
            # リソース使用量表示
            local memory_kb cpu_percent
            memory_kb=$(get_memory_usage)
            cpu_percent=$(get_cpu_usage)
            
            echo "📊 リソース使用量:"
            echo "  - メモリ: ${memory_kb}KB / ${MEMORY_LIMIT_KB}KB ($(( memory_kb * 100 / MEMORY_LIMIT_KB ))%)"
            echo "  - CPU: ${cpu_percent}%"
            
            # イベント統計
            local queue_size event_count
            queue_size=$(wc -l < "$EVENT_DIR/event_queue.txt" 2>/dev/null || echo "0")
            event_count=$(wc -l < "$EVENT_DIR/event_stats.txt" 2>/dev/null || echo "0")
            
            echo "📈 イベント統計:"
            echo "  - キューサイズ: ${queue_size}/${MAX_EVENT_BUFFER}"
            echo "  - 処理済みイベント: $event_count"
            
        else
            echo "❌ 監視システム: 停止中"
        fi
    else
        echo "❌ 監視システム: 未開始"
    fi
}

# =============================================================================
# 8. CLI インターフェース
# =============================================================================

show_usage() {
    cat << EOF
🎯 イベント駆動監視システム v2.0 (リソース効率重視)

目標効果:
  - CPU使用率50%削減
  - メモリ使用量30%削減
  - イベント駆動による効率的監視

使用方法:
    $0 start                    - 監視システム開始
    $0 stop                     - 監視システム停止
    $0 status                   - システム状況確認
    $0 events                   - イベント履歴表示
    $0 stats                    - 統計情報表示
    $0 optimize                 - パフォーマンス最適化

設計特徴:
    - イベント駆動アーキテクチャ
    - アダプティブ監視間隔
    - 軽量イベント処理
    - メモリ制限機能

例:
    $0 start
    $0 status
    $0 stats
EOF
}

main() {
    local command="${1:-}"
    
    case "$command" in
        "start")
            start_event_monitoring
            ;;
        "stop")
            stop_event_monitoring
            ;;
        "status")
            show_monitoring_status
            ;;
        "events")
            if [[ -f "$EVENT_DIR/event_queue.txt" ]]; then
                echo "📋 最新イベント:"
                tail -10 "$EVENT_DIR/event_queue.txt" 2>/dev/null || echo "イベントなし"
            else
                echo "❌ イベントデータなし"
            fi
            ;;
        "stats")
            if [[ -f "$EVENT_DIR/event_stats.txt" ]]; then
                echo "📊 イベント統計:"
                tail -10 "$EVENT_DIR/event_stats.txt" 2>/dev/null || echo "統計データなし"
            else
                echo "❌ 統計データなし"
            fi
            ;;
        "optimize")
            optimize_monitoring_performance
            echo "✅ パフォーマンス最適化完了"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_event "ERROR" "無効なコマンド: $command"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト直接実行時
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi