#!/bin/bash

# 🔍 軽量バックグラウンド監視システム
# 30秒間隔でワーカー状況をPRESIDENTに報告

MONITOR_PID_FILE="/tmp/lightweight_monitor.pid"
STATUS_FILE="/tmp/worker_status_report.txt"
LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/logs/lightweight-monitor.log"

# 監視ループ（バックグラウンド実行）
monitor_loop() {
    echo "🔍 軽量監視システム開始 $(date)" >> "$LOG_FILE"
    
    while true; do
        check_and_report
        sleep 30  # 30秒間隔
    done
}

# ワーカー状況確認と報告
check_and_report() {
    local timestamp=$(date '+%H:%M:%S')
    local report="【$timestamp】ワーカー状況報告:\n"
    local issues_found=0
    
    for i in {0..3}; do
        local capture=$(tmux capture-pane -t multiagent:0.$i -p | tail -3)
        local worker_name=""
        
        case $i in
            0) worker_name="BOSS1" ;;
            1) worker_name="WORKER1" ;;
            2) worker_name="WORKER2" ;;
            3) worker_name="WORKER3" ;;
        esac
        
        # 状況判定（Bypassing Permissionsは正常状態）
        if echo "$capture" | grep -q "^>$"; then
            report+="\n⚠️  $worker_name: プロンプト待機状態"
            issues_found=1
        elif [ -z "$(echo "$capture" | tr -d '[:space:]')" ]; then
            report+="\n❓ $worker_name: 空白状態"
            issues_found=1
        else
            # 役職表示チェック
            if echo "$capture" | grep -q -E "(👔|💻|🔧|🎨|待機中)"; then
                report+="\n✅ $worker_name: 正常稼働"
            else
                report+="\n⚠️  $worker_name: 役職表示なし"
                issues_found=1
            fi
        fi
    done
    
    # 問題があった場合のみ報告ファイルに記録
    if [ $issues_found -eq 1 ]; then
        echo -e "$report" > "$STATUS_FILE"
        echo "$(date) - 問題検出" >> "$LOG_FILE"
    else
        # 正常時は軽い記録のみ
        echo "$(date '+%H:%M:%S') - 全員正常" > "$STATUS_FILE"
    fi
}

# 監視開始
start_monitor() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local existing_pid=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$existing_pid" 2>/dev/null; then
            echo "⚠️  監視システムは既に動作中です (PID: $existing_pid)"
            return
        fi
    fi
    
    echo "🚀 軽量監視システム開始中..."
    monitor_loop &
    echo $! > "$MONITOR_PID_FILE"
    echo "✅ 監視システム開始 (PID: $!)"
}

# 監視停止
stop_monitor() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local pid=$(cat "$MONITOR_PID_FILE")
        if kill "$pid" 2>/dev/null; then
            echo "⏹️  監視システム停止 (PID: $pid)"
        fi
        rm -f "$MONITOR_PID_FILE"
    else
        echo "❌ 監視システムは動作していません"
    fi
}

# 最新レポート表示
show_report() {
    if [ -f "$STATUS_FILE" ]; then
        echo "📊 最新ワーカー状況:"
        cat "$STATUS_FILE"
    else
        echo "❓ まだレポートがありません"
    fi
}

# 使用方法
case "$1" in
    "start")
        start_monitor
        ;;
    "stop")
        stop_monitor
        ;;
    "status")
        show_report
        ;;
    "check")
        check_and_report
        show_report
        ;;
    *)
        echo "使用方法: $0 {start|stop|status|check}"
        echo "  start  - 監視開始"
        echo "  stop   - 監視停止" 
        echo "  status - 最新レポート表示"
        echo "  check  - 即座確認"
        ;;
esac