#!/bin/bash

# AI組織ガバナンス：番号付き報告システム
# 各ワーカーからの報告を番号付きで管理し、追跡可能にする

REPORT_LOG="/tmp/ai-agents-reports.log"
PROGRESS_LOG="/tmp/ai-agents-progress.log"

# 報告受信機能
receive_report() {
    local worker_id=$1
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] [$worker_id] $message" >> "$REPORT_LOG"
    
    # 進捗状況を更新
    case $worker_id in
        0) echo "BOSS: $message" > "/tmp/worker_0_status.txt" ;;
        1) echo "WORKER1: $message" > "/tmp/worker_1_status.txt" ;;
        2) echo "WORKER2: $message" > "/tmp/worker_2_status.txt" ;;
        3) echo "WORKER3: $message" > "/tmp/worker_3_status.txt" ;;
    esac
    
    echo "✅ [$worker_id] 報告受信: $message"
}

# 進捗状況表示
show_progress() {
    echo "🏢 AI組織進捗状況 ($(date '+%H:%M:%S'))"
    echo "============================================"
    
    for i in {0..3}; do
        if [ -f "/tmp/worker_${i}_status.txt" ]; then
            cat "/tmp/worker_${i}_status.txt"
        else
            case $i in
                0) echo "BOSS: 待機中" ;;
                1) echo "WORKER1: 待機中" ;;
                2) echo "WORKER2: 待機中" ;;
                3) echo "WORKER3: 待機中" ;;
            esac
        fi
    done
    echo "============================================"
}

# 最新報告表示
show_recent_reports() {
    echo "📋 最新報告 (直近10件)"
    echo "============================================"
    if [ -f "$REPORT_LOG" ]; then
        tail -10 "$REPORT_LOG"
    else
        echo "報告なし"
    fi
    echo "============================================"
}

# メイン処理
case "$1" in
    "report")
        receive_report "$2" "$3"
        ;;
    "progress")
        show_progress
        ;;
    "recent")
        show_recent_reports
        ;;
    "init")
        echo "🏢 AI組織報告システム初期化"
        > "$REPORT_LOG"
        > "$PROGRESS_LOG"
        for i in {0..3}; do
            rm -f "/tmp/worker_${i}_status.txt"
        done
        echo "✅ 初期化完了"
        ;;
    *)
        echo "使用方法:"
        echo "  $0 report [worker_id] [message]  # 報告受信"
        echo "  $0 progress                      # 進捗表示"
        echo "  $0 recent                        # 最新報告表示" 
        echo "  $0 init                          # システム初期化"
        ;;
esac