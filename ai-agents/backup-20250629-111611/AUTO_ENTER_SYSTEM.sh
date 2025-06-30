#!/bin/bash
# 🔥 自動エンター送信システム
# プロンプト放置を確実に防ぐ

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/auto-enter.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_enter() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# プロンプト放置検知
detect_prompt_stuck() {
    local target="$1"
    local worker_name="$2"
    
    local content=$(tmux capture-pane -t "$target" -p)
    local input_field=$(echo "$content" | grep -A 2 "╭─" | grep "│" | grep -v "╰" | tail -1)
    
    # 入力フィールドに文字があり、かつBypassingがある = 放置状態
    if echo "$input_field" | grep -q "│ > [^[:space:]]" && echo "$content" | grep -q "Bypassing Permissions"; then
        log_enter "🚨 $worker_name プロンプト放置検知: $input_field"
        return 0
    fi
    
    return 1
}

# 自動ダブルエンター送信
auto_double_enter() {
    local target="$1"
    local worker_name="$2"
    
    log_enter "⚡ $worker_name 自動ダブルエンター実行"
    
    # 1回目のエンター
    tmux send-keys -t "$target" "" C-m
    log_enter "✅ $worker_name 1回目エンター送信"
    
    sleep 1
    
    # 2回目のエンター  
    tmux send-keys -t "$target" "" C-m
    log_enter "✅ $worker_name 2回目エンター送信"
    
    sleep 2
    
    # 結果確認
    local after_content=$(tmux capture-pane -t "$target" -p)
    if echo "$after_content" | grep -q "Bypassing Permissions" && ! echo "$after_content" | grep -A 2 "╭─" | grep "│" | grep -q "> [^[:space:]]"; then
        log_enter "✅ $worker_name プロンプト解消成功"
        return 0
    else
        log_enter "⚠️ $worker_name プロンプト解消要再試行"
        return 1
    fi
}

# 継続的監視・自動修正システム
continuous_prompt_monitoring() {
    log_enter "🔄 継続的プロンプト監視開始"
    
    while true; do
        # 全WORKERをチェック
        for i in {0..3}; do
            local worker_name=""
            case $i in
                0) worker_name="BOSS1" ;;
                1) worker_name="WORKER1" ;;
                2) worker_name="WORKER2" ;;
                3) worker_name="WORKER3" ;;
            esac
            
            local target="multiagent:0.$i"
            
            # プロンプト放置チェック
            if detect_prompt_stuck "$target" "$worker_name"; then
                # 最大3回まで自動修正試行
                local attempt=1
                while [ $attempt -le 3 ]; do
                    log_enter "🔧 $worker_name 修正試行 $attempt/3"
                    
                    if auto_double_enter "$target" "$worker_name"; then
                        break
                    fi
                    
                    ((attempt++))
                    sleep 2
                done
                
                if [ $attempt -gt 3 ]; then
                    log_enter "❌ $worker_name 自動修正失敗 - 手動確認必要"
                fi
            fi
        done
        
        # PRESDENTもチェック
        if detect_prompt_stuck "president" "PRESIDENT"; then
            auto_double_enter "president" "PRESIDENT"
        fi
        
        sleep 10  # 10秒間隔で監視
    done
}

# メッセージ送信時の自動エンター付与
send_message_with_auto_enter() {
    local target="$1"
    local message="$2"
    local worker_name="$3"
    
    log_enter "📤 $worker_name メッセージ送信+自動エンター"
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message" C-m
    log_enter "✅ メッセージ送信: $message"
    
    sleep 1
    
    # 自動ダブルエンター
    tmux send-keys -t "$target" "" C-m
    sleep 1
    tmux send-keys -t "$target" "" C-m
    
    log_enter "✅ $worker_name 自動ダブルエンター完了"
}

# 緊急プロンプト解消
emergency_prompt_clear() {
    log_enter "🚨 緊急プロンプト解消実行"
    
    for i in {0..3}; do
        local worker_name="WORKER$i"
        local target="multiagent:0.$i"
        
        # 強制的にダブルエンター
        tmux send-keys -t "$target" "" C-m
        tmux send-keys -t "$target" "" C-m
        
        log_enter "⚡ $worker_name 緊急エンター送信"
    done
    
    # PRESIDENT
    tmux send-keys -t president "" C-m
    tmux send-keys -t president "" C-m
    log_enter "⚡ PRESIDENT 緊急エンター送信"
}

# メイン実行
case "${1:-monitor}" in
    "monitor")
        continuous_prompt_monitoring &
        echo $! > "/tmp/auto_enter.pid"
        log_enter "🚀 自動エンター監視開始（PID: $!）"
        ;;
    "send")
        send_message_with_auto_enter "$2" "$3" "$4"
        ;;
    "emergency")
        emergency_prompt_clear
        ;;
    "stop")
        if [ -f "/tmp/auto_enter.pid" ]; then
            kill $(cat "/tmp/auto_enter.pid") 2>/dev/null
            rm -f "/tmp/auto_enter.pid"
            log_enter "🛑 自動エンター監視停止"
        fi
        ;;
    *)
        echo "使用方法:"
        echo "  $0 monitor                           # 監視開始"
        echo "  $0 send [target] [message] [name]    # 自動エンター付きメッセージ送信"
        echo "  $0 emergency                         # 緊急プロンプト解消"
        echo "  $0 stop                              # 監視停止"
        ;;
esac