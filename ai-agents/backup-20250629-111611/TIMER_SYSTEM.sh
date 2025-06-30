#!/bin/bash
# ⏰ 30分タイマー・自動進捗報告システム

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/timer-system.log"
mkdir -p "$(dirname "$LOG_FILE")"

start_30min_timer() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏰ 30分タイマー開始" | tee -a "$LOG_FILE"
    
    # 30分 = 1800秒
    sleep 1800
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔔 30分経過！進捗報告時間" | tee -a "$LOG_FILE"
    
    # BOSS1に自動で進捗確認指示
    tmux send-keys -t multiagent:0.0 "30分経過しました。各WORKERの進捗を確認して、次の指示を出してください。" C-m
    tmux send-keys -t multiagent:0.0 "" C-m
    
    # 各WORKERに進捗報告要求
    tmux send-keys -t multiagent:0.1 "30分経過です。現在の作業進捗を報告してください。" C-m
    tmux send-keys -t multiagent:0.2 "30分経過です。現在の作業進捗を報告してください。" C-m  
    tmux send-keys -t multiagent:0.3 "30分経過です。現在の作業進捗を報告してください。" C-m
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 自動進捗報告指示送信完了" | tee -a "$LOG_FILE"
    
    # 次の30分タイマーを開始
    start_30min_timer
}

# バックグラウンドでタイマー開始
start_30min_timer &
echo $! > "/tmp/timer_30min.pid"
echo "⏰ 30分タイマー開始（PID: $!）"
