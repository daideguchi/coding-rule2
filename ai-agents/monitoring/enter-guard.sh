#!/bin/bash
# Enter押し忘れ検知・自動修正システム

MULTIAGENT_SESSION="multiagent"
CHECK_INTERVAL=2

monitor_enter_execution() {
    while true; do
        # BOSS1ペインのプロンプト状態確認
        if tmux has-session -t "$MULTIAGENT_SESSION" 2>/dev/null; then
            local boss1_content=$(tmux capture-pane -t "$MULTIAGENT_SESSION:0.0" -p 2>/dev/null)
            
            # ">" プロンプトで停止している場合
            if echo "$boss1_content" | tail -1 | grep -q "^>" 2>/dev/null; then
                echo "[$(date '+%H:%M:%S')] 🚨 Enter押し忘れ検知 - 自動修正実行"
                
                # 自動Enter実行
                tmux send-keys -t "$MULTIAGENT_SESSION:0.0" C-m
                
                echo "[$(date '+%H:%M:%S')] ✅ Enter自動実行完了"
                
                # アラート記録
                echo "[ENTER_GUARD] 自動修正実行: $(date)" >> "$BASE_DIR/logs/enter-prevention.log"
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# バックグラウンド実行
monitor_enter_execution &
echo $! > "$BASE_DIR/logs/enter-guard.pid"
