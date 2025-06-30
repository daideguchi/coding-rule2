#!/bin/bash
# 宣言忘れ防止・自動リマインダーシステム

DECLARATION_LOG="$BASE_DIR/logs/declaration-reminders.log"
REMINDER_INTERVAL=180  # 3分間隔

monitor_declaration_requirement() {
    local last_reminder=0
    
    while true; do
        local current_time=$(date +%s)
        
        # 3分間隔でリマインダー
        if (( current_time - last_reminder >= REMINDER_INTERVAL )); then
            echo "[$(date '+%H:%M:%S')] 🔔 宣言リマインダー: 作業開始・段階変更時は必ず宣言実行" >> "$DECLARATION_LOG"
            
            # tmuxペインタイトルにリマインダー表示
            if tmux has-session -t multiagent 2>/dev/null; then
                for pane in {0..3}; do
                    tmux select-pane -t "multiagent:0.$pane" -T "リマインダー:宣言必須" 2>/dev/null
                done
                
                # 3秒後に元のタイトルに戻す
                sleep 3
                tmux select-pane -t "multiagent:0.0" -T "BOSS1:チームリーダー" 2>/dev/null
                tmux select-pane -t "multiagent:0.1" -T "WORKER1:フロントエンド" 2>/dev/null
                tmux select-pane -t "multiagent:0.2" -T "WORKER2:バックエンド" 2>/dev/null
                tmux select-pane -t "multiagent:0.3" -T "WORKER3:品質監視" 2>/dev/null
            fi
            
            last_reminder=$current_time
        fi
        
        sleep 30
    done
}

# バックグラウンド実行
monitor_declaration_requirement &
echo $! > "$BASE_DIR/logs/declaration-guard.pid"
