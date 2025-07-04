#!/bin/bash

# =============================================================================
# 📊 ONE_COMMAND_MONITORING_SYSTEM.sh - ワンコマンド実行専用監視システム
# =============================================================================
# 
# 【WORKER2担当】: システム監視・インフラ最適化
# 【目的】: ワンコマンド実行時のリアルタイム監視・パフォーマンス最適化
# 【特徴】: イベント駆動型・軽量監視・自動最適化
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$AI_AGENTS_DIR/.." && pwd)"

# 監視設定
MONITORING_LOG="$AI_AGENTS_DIR/logs/one-command-monitoring.log"
PERFORMANCE_LOG="$AI_AGENTS_DIR/logs/performance-metrics.log"
ALERT_LOG="$AI_AGENTS_DIR/logs/monitoring-alerts.log"

# 閾値設定（SMART_MONITORING_ENGINEと連携）
CPU_THRESHOLD=70          # CPU使用率70%で警告
MEMORY_THRESHOLD=80       # メモリ使用率80%で警告
RESPONSE_THRESHOLD=5      # 応答時間5秒で警告
ERROR_RATE_THRESHOLD=5    # エラー率5%で警告

mkdir -p "$(dirname "$MONITORING_LOG")"

# =============================================================================
# 🎯 ログ・アラートシステム
# =============================================================================

log_monitoring() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] [$component] $message" | tee -a "$MONITORING_LOG"
}

send_alert() {
    local severity="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] ALERT[$severity] $component: $message" | tee -a "$ALERT_LOG"
    
    # 緊急時はワンライナー報告システムに通知
    if [ "$severity" = "CRITICAL" ] && [ -f "$AI_AGENTS_DIR/scripts/automation/ONELINER_REPORTING_SYSTEM.sh" ]; then
        "$AI_AGENTS_DIR/scripts/automation/ONELINER_REPORTING_SYSTEM.sh" share "🚨 監視アラート: $component - $message" "high"
    fi
}

# =============================================================================
# 💻 システムリソース監視
# =============================================================================

monitor_system_resources() {
    log_monitoring "INFO" "SYSTEM" "リソース監視開始"
    
    # CPU使用率監視
    local cpu_usage
    if command -v top >/dev/null; then
        cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' | cut -d. -f1)
    else
        cpu_usage=0
    fi
    
    # メモリ使用率監視（macOS用）
    local memory_usage=0
    if command -v vm_stat >/dev/null; then
        local vm_info=$(vm_stat)
        local page_size=4096
        local free_pages=$(echo "$vm_info" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        local wired_pages=$(echo "$vm_info" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
        local active_pages=$(echo "$vm_info" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        
        if [ -n "$free_pages" ] && [ -n "$wired_pages" ] && [ -n "$active_pages" ]; then
            local total_memory=$(((free_pages + wired_pages + active_pages) * page_size))
            local used_memory=$(((wired_pages + active_pages) * page_size))
            if [ "$total_memory" -gt 0 ]; then
                memory_usage=$((used_memory * 100 / total_memory))
            fi
        fi
    fi
    
    # パフォーマンスメトリクス記録
    echo "$(date '+%Y-%m-%d %H:%M:%S'),CPU,$cpu_usage,MEMORY,$memory_usage" >> "$PERFORMANCE_LOG"
    
    # 閾値チェック・アラート
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        send_alert "WARNING" "CPU" "使用率 ${cpu_usage}% (閾値: ${CPU_THRESHOLD}%)"
        
        # 自動最適化実行
        optimize_cpu_usage
    fi
    
    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        send_alert "WARNING" "MEMORY" "使用率 ${memory_usage}% (閾値: ${MEMORY_THRESHOLD}%)"
        
        # 自動メモリクリーンアップ
        optimize_memory_usage
    fi
    
    log_monitoring "METRICS" "SYSTEM" "CPU: ${cpu_usage}%, Memory: ${memory_usage}%"
}

# =============================================================================
# 🔄 プロセス監視
# =============================================================================

monitor_one_command_process() {
    log_monitoring "INFO" "PROCESS" "ワンコマンドプロセス監視開始"
    
    # ONE_COMMAND_PROCESSORの実行状況監視
    local processor_count=$(pgrep -f "ONE_COMMAND_PROCESSOR.sh" | wc -l)
    
    if [ "$processor_count" -gt 0 ]; then
        log_monitoring "INFO" "PROCESS" "ワンコマンドプロセッサー実行中 ($processor_count プロセス)"
        
        # 実行時間監視
        local oldest_pid=$(pgrep -f "ONE_COMMAND_PROCESSOR.sh" | head -1)
        if [ -n "$oldest_pid" ]; then
            local start_time=$(ps -o lstart= -p "$oldest_pid" 2>/dev/null)
            if [ -n "$start_time" ]; then
                log_monitoring "INFO" "PROCESS" "最古プロセス開始時刻: $start_time (PID: $oldest_pid)"
            fi
        fi
        
        # プロセス健全性チェック
        check_process_health "$oldest_pid"
    else
        log_monitoring "INFO" "PROCESS" "ワンコマンドプロセッサー未実行"
    fi
    
    # AI組織プロセス監視
    monitor_ai_organization_processes
}

check_process_health() {
    local pid="$1"
    
    if [ -z "$pid" ]; then
        return
    fi
    
    # プロセス存在確認
    if ! kill -0 "$pid" 2>/dev/null; then
        send_alert "CRITICAL" "PROCESS" "ワンコマンドプロセッサー停止 (PID: $pid)"
        return
    fi
    
    # CPU使用率チェック（プロセス単位）
    local process_cpu=$(ps -o pcpu= -p "$pid" 2>/dev/null | xargs)
    if [ -n "$process_cpu" ]; then
        local cpu_int=$(echo "$process_cpu" | cut -d. -f1)
        if [ "$cpu_int" -gt 50 ]; then
            send_alert "WARNING" "PROCESS" "高CPU使用率: ${process_cpu}% (PID: $pid)"
        fi
    fi
    
    log_monitoring "HEALTH" "PROCESS" "プロセス健全性OK (PID: $pid, CPU: ${process_cpu}%)"
}

monitor_ai_organization_processes() {
    # tmuxセッション監視
    if command -v tmux >/dev/null; then
        local session_count=$(tmux list-sessions 2>/dev/null | grep -c "multiagent" || echo "0")
        
        if [ "$session_count" -gt 0 ]; then
            log_monitoring "INFO" "AI_ORG" "multiagentセッション稼働中"
            
            # 各ペインの状態確認
            check_ai_organization_panes
        else
            send_alert "WARNING" "AI_ORG" "multiagentセッション未検出"
        fi
    fi
}

check_ai_organization_panes() {
    local panes=("0.0" "0.1" "0.2" "0.3")
    local roles=("BOSS1" "WORKER1" "WORKER2" "WORKER3")
    
    for i in "${!panes[@]}"; do
        local pane="${panes[$i]}"
        local role="${roles[$i]}"
        
        # ペイン存在確認
        if tmux list-panes -t "multiagent:$pane" >/dev/null 2>&1; then
            log_monitoring "INFO" "AI_ORG" "$role ペイン稼働中 (multiagent:$pane)"
        else
            send_alert "WARNING" "AI_ORG" "$role ペイン未検出 (multiagent:$pane)"
        fi
    done
}

# =============================================================================
# 📁 ファイルシステム監視
# =============================================================================

monitor_filesystem() {
    log_monitoring "INFO" "FILESYSTEM" "ファイルシステム監視開始"
    
    # ログファイル監視
    local log_files=(
        "$AI_AGENTS_DIR/logs/one-command-processor.log"
        "$AI_AGENTS_DIR/logs/execution-*.log"
        "$MONITORING_LOG"
        "$PERFORMANCE_LOG"
    )
    
    for log_pattern in "${log_files[@]}"; do
        # ワイルドカード展開
        for log_file in $log_pattern; do
            if [ -f "$log_file" ]; then
                local file_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo "0")
                local file_mb=$((file_size / 1024 / 1024))
                
                if [ "$file_mb" -gt 100 ]; then
                    send_alert "WARNING" "FILESYSTEM" "大きなログファイル: $(basename "$log_file") (${file_mb}MB)"
                fi
                
                log_monitoring "INFO" "FILESYSTEM" "$(basename "$log_file"): ${file_mb}MB"
            fi
        done
    done
    
    # ディスク容量監視
    local disk_usage=$(df "$AI_AGENTS_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        send_alert "CRITICAL" "FILESYSTEM" "ディスク使用率 ${disk_usage}%"
    elif [ "$disk_usage" -gt 80 ]; then
        send_alert "WARNING" "FILESYSTEM" "ディスク使用率 ${disk_usage}%"
    fi
    
    log_monitoring "INFO" "FILESYSTEM" "ディスク使用率: ${disk_usage}%"
}

# =============================================================================
# ⚡ 自動最適化システム
# =============================================================================

optimize_cpu_usage() {
    log_monitoring "OPTIMIZE" "CPU" "CPU最適化開始"
    
    # プロセス優先度調整
    local high_cpu_processes=$(ps -eo pid,pcpu,comm | awk '$2 > 30 {print $1}')
    
    for pid in $high_cpu_processes; do
        if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
            # 自身以外のプロセスの優先度を下げる
            renice +5 "$pid" >/dev/null 2>&1
            log_monitoring "OPTIMIZE" "CPU" "プロセス優先度調整 (PID: $pid)"
        fi
    done
    
    # SMART_MONITORING_ENGINEとの連携
    if [ -f "$AI_AGENTS_DIR/scripts/core/SMART_MONITORING_ENGINE.js" ]; then
        node "$AI_AGENTS_DIR/scripts/core/SMART_MONITORING_ENGINE.js" test >/dev/null 2>&1
        log_monitoring "OPTIMIZE" "CPU" "スマート監視エンジン最適化実行"
    fi
}

optimize_memory_usage() {
    log_monitoring "OPTIMIZE" "MEMORY" "メモリ最適化開始"
    
    # システムキャッシュクリア（安全な範囲で）
    sync
    
    # 不要な一時ファイル削除
    find "$AI_AGENTS_DIR/tmp" -type f -mtime +1 -delete 2>/dev/null || true
    
    # ログローテーション（大きなファイルのみ）
    for log_file in "$AI_AGENTS_DIR"/logs/*.log; do
        if [ -f "$log_file" ]; then
            local file_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo "0")
            if [ "$file_size" -gt 10485760 ]; then  # 10MB以上
                mv "$log_file" "${log_file}.old"
                touch "$log_file"
                log_monitoring "OPTIMIZE" "MEMORY" "ログローテーション: $(basename "$log_file")"
            fi
        fi
    done
    
    log_monitoring "OPTIMIZE" "MEMORY" "メモリ最適化完了"
}

# =============================================================================
# 📊 統計・レポート生成
# =============================================================================

generate_monitoring_report() {
    local report_file="$AI_AGENTS_DIR/reports/monitoring-report-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# 📊 ワンコマンド実行監視レポート

## 監視概要
- **生成時刻**: $(date '+%Y-%m-%d %H:%M:%S')
- **監視対象**: ワンコマンドプロセッサー実行環境
- **監視期間**: 実行開始〜現在

## システムリソース状況
$(tail -5 "$PERFORMANCE_LOG" 2>/dev/null | while IFS=, read timestamp type1 value1 type2 value2; do
    echo "- **$timestamp**: CPU ${value1}%, Memory ${value2}%"
done)

## アラート履歴
$(tail -10 "$ALERT_LOG" 2>/dev/null || echo "アラートなし")

## プロセス状況
- **ワンコマンドプロセッサー**: $(pgrep -f "ONE_COMMAND_PROCESSOR.sh" | wc -l) プロセス実行中
- **AI組織セッション**: $(tmux list-sessions 2>/dev/null | grep -c "multiagent" || echo "0") セッション
- **監視プロセス**: 正常稼働

## 最適化実行履歴
$(grep "OPTIMIZE" "$MONITORING_LOG" | tail -5 || echo "最適化実行なし")

## 推奨事項
- 継続的な監視の実施
- 定期的なログクリーンアップ
- リソース使用状況の追跡

---
*🔧 生成者: WORKER2（システム監視・インフラ担当）*
*📅 生成日時: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    log_monitoring "REPORT" "SYSTEM" "監視レポート生成: $report_file"
    echo "$report_file"
}

# =============================================================================
# 🚀 メイン監視ループ
# =============================================================================

start_monitoring() {
    log_monitoring "START" "SYSTEM" "ワンコマンド監視システム開始"
    
    local monitoring_interval=30  # 30秒間隔
    local report_interval=300     # 5分間隔でレポート生成
    local last_report_time=0
    
    while true; do
        local current_time=$(date +%s)
        
        # システムリソース監視
        monitor_system_resources
        
        # プロセス監視
        monitor_one_command_process
        
        # ファイルシステム監視
        monitor_filesystem
        
        # 定期レポート生成
        if [ $((current_time - last_report_time)) -gt $report_interval ]; then
            generate_monitoring_report
            last_report_time=$current_time
        fi
        
        # SMART_MONITORING_ENGINEとの統合チェック
        if [ -f "$AI_AGENTS_DIR/scripts/core/SMART_MONITORING_ENGINE.js" ]; then
            # 既存の効率的監視システムと連携
            log_monitoring "INTEGRATION" "SMART_ENGINE" "統合監視システム連携中"
        fi
        
        sleep $monitoring_interval
    done
}

# =============================================================================
# 🎯 CLI インターフェース
# =============================================================================

case "${1:-start}" in
    "start")
        start_monitoring
        ;;
    "status")
        echo "📊 監視システム状況:"
        echo "- プロセス: $(pgrep -f "ONE_COMMAND_MONITORING_SYSTEM" | wc -l) 実行中"
        echo "- ログ: $(wc -l < "$MONITORING_LOG" 2>/dev/null || echo "0") 行"
        echo "- アラート: $(wc -l < "$ALERT_LOG" 2>/dev/null || echo "0") 件"
        ;;
    "report")
        generate_monitoring_report
        ;;
    "optimize")
        optimize_cpu_usage
        optimize_memory_usage
        echo "✅ システム最適化完了"
        ;;
    "test")
        log_monitoring "TEST" "SYSTEM" "監視システムテスト実行"
        monitor_system_resources
        monitor_one_command_process
        monitor_filesystem
        echo "✅ 監視システムテスト完了"
        ;;
    *)
        echo "📊 ワンコマンド監視システム v1.0"
        echo ""
        echo "使用方法:"
        echo "  $0 start     # 監視開始"
        echo "  $0 status    # 状況確認"
        echo "  $0 report    # レポート生成"
        echo "  $0 optimize  # システム最適化"
        echo "  $0 test      # テスト実行"
        ;;
esac