#!/bin/bash

# 長時間処理監視システム（トークン浪費防止）
# 30秒以上の処理を自動検出して中断

SESSION="multiagent"
TIMEOUT_THRESHOLD=30  # 30秒でタイムアウト
LOG_FILE="/tmp/timeout-monitor.log"

echo "🕐 長時間処理監視システム開始 (閾値: ${TIMEOUT_THRESHOLD}秒)"

monitor_worker() {
    local worker_id=$1
    local content=$(tmux capture-pane -t $SESSION:0.$worker_id -p 2>/dev/null | tail -5)
    
    # 処理時間を抽出 (例: "142s", "2m 3s")
    local time_info=$(echo "$content" | grep -oE '[0-9]+[sm]|[0-9]+m [0-9]+s' | tail -1)
    
    if [ -n "$time_info" ]; then
        # 秒数に変換
        local seconds=0
        if echo "$time_info" | grep -q 'm'; then
            # 分秒形式 (例: "2m 15s")
            local minutes=$(echo "$time_info" | grep -oE '[0-9]+m' | sed 's/m//')
            local secs=$(echo "$time_info" | grep -oE '[0-9]+s' | sed 's/s//')
            seconds=$((minutes * 60 + secs))
        else
            # 秒のみ (例: "142s")
            seconds=$(echo "$time_info" | sed 's/s//')
        fi
        
        if [ "$seconds" -gt "$TIMEOUT_THRESHOLD" ]; then
            echo "🚨 WORKER$worker_id: ${seconds}秒の長時間処理検出 - 緊急中断"
            echo "$(date): WORKER$worker_id TIMEOUT ${seconds}s" >> "$LOG_FILE"
            
            # 緊急中断シーケンス
            tmux send-keys -t $SESSION:0.$worker_id Escape
            sleep 1
            tmux send-keys -t $SESSION:0.$worker_id "/clear" C-m
            sleep 2
            
            case $worker_id in
                0) role="BOSS" ;;
                1) role="WORKER1" ;;
                2) role="WORKER2" ;;
                3) role="WORKER3" ;;
            esac
            
            # シンプルタスク再開
            tmux send-keys -t $SESSION:0.$worker_id ">$role: [${worker_id}] タイムアウトによりコンテキストクリア。簡単な確認作業から再開してください。" C-m
            
            # ステータス更新
            tmux select-pane -t $SESSION:0.$worker_id -T "🔄復旧中 $role"
            
            echo "✅ WORKER$worker_id: 緊急中断・復旧完了"
            return 1
        fi
    fi
    
    return 0
}

# メイン監視ループ
case "$1" in
    "check")
        echo "🔍 全ワーカー長時間処理チェック"
        for i in {0..3}; do
            monitor_worker $i
        done
        ;;
    "monitor")
        echo "🕐 連続監視モード開始（Ctrl+Cで停止）"
        while true; do
            for i in {0..3}; do
                monitor_worker $i
            done
            sleep 10  # 10秒間隔でチェック
        done
        ;;
    "log")
        echo "📋 タイムアウトログ"
        if [ -f "$LOG_FILE" ]; then
            cat "$LOG_FILE"
        else
            echo "タイムアウト記録なし"
        fi
        ;;
    *)
        echo "使用方法:"
        echo "  $0 check     # 一回チェック"
        echo "  $0 monitor   # 連続監視"
        echo "  $0 log       # ログ確認"
        ;;
esac