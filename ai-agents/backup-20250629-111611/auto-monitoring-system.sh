#!/bin/bash

# 🤖 完全自動監視・Enter実行システム
# 23回のミス教訓 - ワーカー停止を検出し自動修正

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/logs/auto-monitoring.log"
MONITORING_FLAG="/tmp/president_monitoring.flag"

# 監視開始フラグ
start_monitoring() {
    echo "🤖 自動監視システム開始 $(date)" | tee -a "$LOG_FILE"
    touch "$MONITORING_FLAG"
    
    while [ -f "$MONITORING_FLAG" ]; do
        check_all_workers
        sleep 5  # 5秒間隔で監視
    done
}

# 監視停止
stop_monitoring() {
    echo "⏹️  自動監視システム停止 $(date)" | tee -a "$LOG_FILE"
    rm -f "$MONITORING_FLAG"
}

# 全ワーカー状況確認
check_all_workers() {
    for i in {0..3}; do
        check_worker_status $i
    done
}

# 個別ワーカー状況確認
check_worker_status() {
    local pane_num=$1
    local capture=$(tmux capture-pane -t multiagent:0.$pane_num -p | tail -3)
    
    # ">"だけで止まっている場合の検出
    if echo "$capture" | grep -q "^>$"; then
        echo "🚨 ワーカー0.$pane_num 停止検出 - 自動修正実行 $(date)" | tee -a "$LOG_FILE"
        auto_fix_worker $pane_num
    fi
    
    # "Bypassing permissions"の検出
    if echo "$capture" | grep -q -i "bypassing"; then
        echo "🔓 ワーカー0.$pane_num Bypassing permissions検出 - 自動Enter実行 $(date)" | tee -a "$LOG_FILE"
        auto_fix_worker $pane_num
    fi
}

# 自動修正実行
auto_fix_worker() {
    local pane_num=$1
    echo "🔧 自動修正中: multiagent:0.$pane_num"
    
    # 2回のEnter実行（確実性のため）
    tmux send-keys -t multiagent:0.$pane_num C-m
    sleep 0.5
    tmux send-keys -t multiagent:0.$pane_num C-m
    
    echo "✅ 修正完了: multiagent:0.$pane_num $(date)" | tee -a "$LOG_FILE"
}

# バックグラウンド監視開始
start_background_monitoring() {
    if [ -f "$MONITORING_FLAG" ]; then
        echo "⚠️  監視システムは既に動作中です"
        return
    fi
    
    echo "🚀 バックグラウンド監視開始"
    nohup $0 monitor > /dev/null 2>&1 &
    echo "✅ バックグラウンド監視が開始されました（PID: $!）"
}

# 使用方法表示
show_usage() {
    echo "使用方法: $0 [command]"
    echo "commands:"
    echo "  start     - バックグラウンド監視開始"
    echo "  stop      - 監視停止"
    echo "  check     - 1回の状況確認"
    echo "  monitor   - 継続監視（内部使用）"
    echo "  fix [0-3] - 指定ワーカーの強制修正"
}

# メイン処理
case "$1" in
    "start")
        start_background_monitoring
        ;;
    "stop")
        stop_monitoring
        ;;
    "check")
        check_all_workers
        ;;
    "monitor")
        start_monitoring
        ;;
    "fix")
        if [ -n "$2" ] && [ "$2" -ge 0 ] && [ "$2" -le 3 ]; then
            auto_fix_worker "$2"
        else
            echo "❌ 無効なワーカー番号: $2 (0-3を指定)"
        fi
        ;;
    *)
        show_usage
        ;;
esac