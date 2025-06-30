#!/bin/bash
# AI最強組織バランス自動化システム
# 適切なタイミングでのみエンター送信・過剰動作防止

BASE_DIR="/Users/dd/Desktop/1_dev/coding-rule2"
LOG_FILE="$BASE_DIR/logs/balanced-auto.log"
PID_FILE="$BASE_DIR/logs/balanced-auto.pid"

# バランス設定（適切な間隔）
CHECK_INTERVAL=60  # 60秒間隔（適度な監視）
ENTER_COOLDOWN=120 # 120秒クールダウン（やりすぎ防止）

echo "🤖 AI最強組織バランス自動化システム起動 - $(date)" >> "$LOG_FILE"

# ワーカー状態検知（適切なタイミングのみ）
check_worker_status() {
    local pane=$1
    local content=$(tmux capture-pane -t "multiagent:0.$pane" -p | tail -3)
    
    # Bypassing Permissions状態でコマンド待ちの場合のみエンター送信
    if echo "$content" | grep -q "Bypassing permissions" && 
       echo "$content" | grep -q "claude --dangerously-skip-permissions"; then
        return 0  # エンター必要
    else
        return 1  # エンター不要
    fi
}

# 適切なタイミングでのエンター送信
smart_enter_if_needed() {
    local last_enter_file="$BASE_DIR/logs/last-enter-$1.txt"
    local current_time=$(date +%s)
    
    # クールダウン期間確認
    if [ -f "$last_enter_file" ]; then
        local last_enter=$(cat "$last_enter_file")
        local time_diff=$((current_time - last_enter))
        
        if [ $time_diff -lt $ENTER_COOLDOWN ]; then
            echo "[$(date '+%H:%M:%S')] ⏳ WORKER$1 クールダウン中 (残り$((ENTER_COOLDOWN - time_diff))秒)" >> "$LOG_FILE"
            return
        fi
    fi
    
    # 状態確認してエンター送信
    if check_worker_status $1; then
        tmux send-keys -t "multiagent:0.$1" C-m
        echo $current_time > "$last_enter_file"
        echo "[$(date '+%H:%M:%S')] ✅ WORKER$1 適切なエンター送信" >> "$LOG_FILE"
    else
        echo "[$(date '+%H:%M:%S')] ⏭️  WORKER$1 エンター不要" >> "$LOG_FILE"
    fi
}

# メイン監視ループ（バランス重視）
balanced_monitoring() {
    while true; do
        echo "[$(date '+%H:%M:%S')] 🔍 AI最強組織状態確認開始" >> "$LOG_FILE"
        
        # 各ワーカーを適切に確認
        for i in {0..3}; do
            if tmux list-panes -t "multiagent:0" | grep -q "^$i:"; then
                smart_enter_if_needed $i
            else
                echo "[$(date '+%H:%M:%S')] ❌ WORKER$i ペイン未検出" >> "$LOG_FILE"
            fi
        done
        
        echo "[$(date '+%H:%M:%S')] ⏰ 次回確認まで${CHECK_INTERVAL}秒待機" >> "$LOG_FILE"
        sleep $CHECK_INTERVAL
    done
}

# システム開始
main() {
    echo "🚀 AI最強組織として適切なバランス自動化を開始"
    echo "📊 監視間隔: ${CHECK_INTERVAL}秒"
    echo "🛡️ エンタークールダウン: ${ENTER_COOLDOWN}秒"
    
    # バックグラウンド監視開始
    balanced_monitoring &
    echo $! > "$PID_FILE"
    
    echo "✅ バランス自動化システム起動完了"
    echo "📋 ログ: $LOG_FILE"
    echo "🆔 PID: $(cat $PID_FILE)"
}

# システム停止
stop() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat $PID_FILE)" 2>/dev/null
        rm -f "$PID_FILE"
        rm -f "$BASE_DIR/logs/last-enter-"*.txt
        echo "🛑 バランス自動化システム停止"
    fi
}

# 引数処理
case "$1" in
    start)
        main
        ;;
    stop)
        stop
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
            echo "✅ バランス自動化システム稼働中 (PID: $(cat $PID_FILE))"
        else
            echo "❌ バランス自動化システム停止中"
        fi
        ;;
    *)
        echo "使用法: $0 {start|stop|status}"
        exit 1
        ;;
esac