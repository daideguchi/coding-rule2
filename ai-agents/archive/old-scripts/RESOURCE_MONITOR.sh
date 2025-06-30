#!/bin/bash
# 🛡️ リソース監視・自動停止システム
# 作成日: 2025-06-29
# 目的: 永続監視システムの負荷軽減と自動停止機能

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/resource-monitor.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_resource() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 現在実行中の監視プロセス確認
check_monitoring_processes() {
    log_resource "🔍 監視プロセス確認中..."
    
    # 実行中の監視プロセスを検索
    local unified_pids=$(pgrep -f "UNIFIED_STATUS_SYSTEM.sh monitor" 2>/dev/null || echo "")
    local persistent_pids=$(pgrep -f "PERSISTENT_STATUS_MONITOR.sh monitor" 2>/dev/null || echo "")
    local startup_pids=$(pgrep -f "STARTUP_AUTO_STATUS.sh" 2>/dev/null || echo "")
    
    local total_count=0
    
    if [[ -n "$unified_pids" ]]; then
        log_resource "📊 UNIFIED_STATUS_SYSTEM監視プロセス: $unified_pids"
        total_count=$((total_count + $(echo "$unified_pids" | wc -w)))
    fi
    
    if [[ -n "$persistent_pids" ]]; then
        log_resource "📊 PERSISTENT_STATUS_MONITOR監視プロセス: $persistent_pids"
        total_count=$((total_count + $(echo "$persistent_pids" | wc -w)))
    fi
    
    if [[ -n "$startup_pids" ]]; then
        log_resource "📊 STARTUP_AUTO_STATUS監視プロセス: $startup_pids"
        total_count=$((total_count + $(echo "$startup_pids" | wc -w)))
    fi
    
    log_resource "📈 総監視プロセス数: $total_count"
    echo "$total_count"
}

# CPU・メモリ使用率チェック
check_system_resources() {
    log_resource "🔧 システムリソースチェック中..."
    
    # CPU使用率取得（macOS対応）
    local cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
    log_resource "💻 CPU使用率: ${cpu_usage}%"
    
    # メモリ使用率取得（macOS対応）
    local memory_info=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);')
    log_resource "💾 メモリ情報:"
    log_resource "$memory_info"
    
    # 高負荷判定（CPU 80%以上で警告）
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log_resource "⚠️ CPU高負荷検知: ${cpu_usage}%"
        return 1
    fi
    
    return 0
}

# 緊急停止機能
emergency_stop() {
    log_resource "🚨 緊急停止実行開始"
    
    # 全ての監視プロセスを停止
    pkill -f "UNIFIED_STATUS_SYSTEM.sh monitor" 2>/dev/null
    pkill -f "PERSISTENT_STATUS_MONITOR.sh monitor" 2>/dev/null
    pkill -f "STARTUP_AUTO_STATUS.sh" 2>/dev/null
    
    # PIDファイルのクリーンアップ
    rm -f "/tmp/status_monitor.pid"
    rm -f "/tmp/unified_monitor.pid"
    rm -f "/tmp/persistent_monitor.pid"
    
    log_resource "✅ 全監視プロセス停止完了"
    
    # 最終ステータス設定（一度だけ）
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/UNIFIED_STATUS_SYSTEM.sh fix >/dev/null 2>&1
    
    log_resource "✅ 緊急停止完了"
}

# 安全監視モード（低頻度・低負荷）
safe_monitoring_mode() {
    log_resource "🔒 安全監視モード開始（低負荷・低頻度）"
    
    local check_count=0
    local max_checks=120  # 10分間監視（5秒 × 120回）
    
    while [ $check_count -lt $max_checks ]; do
        # システムリソースチェック
        if ! check_system_resources; then
            log_resource "⚠️ システム高負荷のため監視停止"
            emergency_stop
            return 1
        fi
        
        # 軽量なステータスチェック（5秒間隔）
        local status_chaos=false
        for i in {0..3}; do
            local current_title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "")
            if echo "$current_title" | grep -q "🔵"; then
                status_chaos=true
                break
            fi
        done
        
        # 混乱検知時のみ修正
        if $status_chaos; then
            log_resource "🔧 ステータス混乱検知・修正実行"
            /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/UNIFIED_STATUS_SYSTEM.sh fix >/dev/null 2>&1
        fi
        
        ((check_count++))
        sleep 5  # 5秒間隔（低負荷）
    done
    
    log_resource "⏰ 監視時間終了（10分経過）・自動停止"
    emergency_stop
}

# ヘルス監視とタイムアウト管理
health_monitoring_with_timeout() {
    log_resource "🩺 ヘルス監視・タイムアウト管理開始"
    
    local start_time=$(date +%s)
    local max_duration=600  # 10分間の最大監視時間
    local health_check_interval=30  # 30秒間隔でヘルスチェック
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # タイムアウトチェック
        if [ $elapsed -ge $max_duration ]; then
            log_resource "⏰ 監視タイムアウト（10分経過）・自動停止"
            emergency_stop
            return 0
        fi
        
        # プロセス数チェック
        local process_count=$(check_monitoring_processes)
        if [ "$process_count" -gt 3 ]; then
            log_resource "⚠️ 監視プロセス過多（$process_count個）・緊急停止"
            emergency_stop
            return 0
        fi
        
        # システムリソースチェック
        if ! check_system_resources; then
            log_resource "⚠️ システム高負荷・緊急停止"
            emergency_stop
            return 0
        fi
        
        sleep $health_check_interval
    done
}

# 現在の状況確認
status_check() {
    log_resource "📊 現在の監視状況"
    
    local process_count=$(check_monitoring_processes)
    check_system_resources
    
    # 現在のステータスバー状況
    log_resource "📋 現在のステータスバー:"
    for i in {0..3}; do
        local title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        log_resource "  WORKER$i: $title"
    done
    
    if [ "$process_count" -eq 0 ]; then
        log_resource "✅ 監視プロセスなし・正常状態"
    elif [ "$process_count" -le 2 ]; then
        log_resource "⚠️ 適正監視プロセス数（$process_count個）"
    else
        log_resource "⚠️ 監視プロセス過多（$process_count個）・要注意"
    fi
}

# メイン実行
case "${1:-status}" in
    "stop")
        emergency_stop
        ;;
    "safe")
        safe_monitoring_mode
        ;;
    "health")
        health_monitoring_with_timeout &
        echo $! > "/tmp/resource_monitor.pid"
        log_resource "🩺 ヘルス監視をバックグラウンド開始（PID: $!）"
        ;;
    "status")
        status_check
        ;;
    *)
        echo "使用方法:"
        echo "  $0 stop    # 緊急停止（全監視プロセス終了）"
        echo "  $0 safe    # 安全監視モード（低負荷・10分限定）"
        echo "  $0 health  # ヘルス監視（バックグラウンド・自動停止）"
        echo "  $0 status  # 現在の状況確認"
        ;;
esac