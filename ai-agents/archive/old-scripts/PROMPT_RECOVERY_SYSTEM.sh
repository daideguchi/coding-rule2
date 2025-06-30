#!/bin/bash
# 🚨 プロンプト停止復旧・再発防止システム
# 作成日: 2025-06-29
# 目的: プロンプト停止問題の自動検知・復旧・再発防止

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/prompt-recovery.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_recovery() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# プロンプト停止の詳細検知
detect_prompt_stuck() {
    local target="$1"
    local worker_name="$2"
    
    log_recovery "🔍 $worker_name プロンプト停止検知開始"
    
    # 1. 入力フィールドに未処理テキストがあるかチェック
    local input_content=$(tmux capture-pane -t "$target" -p | grep -A 2 ">" | grep -v "^>")
    
    # 2. Bypassing Permissions + 入力フィールドに文字 = 停止状態
    local bypassing_count=$(tmux capture-pane -t "$target" -p | grep -c "Bypassing Permissions")
    
    if [[ -n "$input_content" ]] && [[ "$bypassing_count" -gt 0 ]]; then
        log_recovery "🚨 $worker_name プロンプト停止検知！"
        log_recovery "   未処理入力: $input_content"
        echo "stuck"
        return 0
    fi
    
    # 3. 長時間同じ画面内容（停止の可能性）
    local current_content=$(tmux capture-pane -t "$target" -p | tail -3 | md5)
    local previous_content=""
    
    if [[ -f "/tmp/${worker_name}_last_content.md5" ]]; then
        previous_content=$(cat "/tmp/${worker_name}_last_content.md5")
    fi
    
    echo "$current_content" > "/tmp/${worker_name}_last_content.md5"
    
    if [[ "$current_content" == "$previous_content" ]] && [[ "$bypassing_count" -gt 0 ]]; then
        log_recovery "⚠️ $worker_name 同一内容継続（停止の可能性）"
        echo "potential_stuck"
        return 0
    fi
    
    echo "normal"
}

# 自動復旧実行
auto_recovery() {
    local target="$1"
    local worker_name="$2"
    
    log_recovery "🔧 $worker_name 自動復旧開始"
    
    # 復旧手順
    # 1. ペインアクティブ化
    tmux select-pane -t "$target"
    log_recovery "✅ ペインアクティブ化完了"
    
    # 2. 追加エンター送信（停止解除）
    tmux send-keys -t "$target" "" C-m
    log_recovery "✅ 復旧エンター送信完了"
    
    # 3. 3秒待機して効果確認
    sleep 3
    local recovery_check=$(detect_prompt_stuck "$target" "$worker_name")
    
    if [[ "$recovery_check" == "normal" ]]; then
        log_recovery "✅ $worker_name 復旧成功"
        return 0
    else
        log_recovery "❌ $worker_name 復旧失敗・再試行"
        
        # 強制復旧：Ctrl+C → 新指示
        tmux send-keys -t "$target" C-c
        sleep 1
        tmux send-keys -t "$target" "状況を教えてください" C-m
        log_recovery "🔄 強制復旧実行"
        return 1
    fi
}

# 再発防止策の実装
implement_prevention() {
    log_recovery "🛡️ 再発防止策実装開始"
    
    # 1. ダブルエンターシステムの強化
    cat > "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/ENHANCED_DOUBLE_ENTER.sh" << 'EOF'
#!/bin/bash
# 強化版ダブルエンターシステム
enhanced_double_enter() {
    local target="$1"
    local message="$2"
    
    echo "📤 強化版送信開始: $target"
    
    # ペインアクティブ化
    tmux select-pane -t "$target"
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message" C-m
    sleep 1
    
    # 第1回エンター
    tmux send-keys -t "$target" "" C-m
    sleep 1
    
    # 第2回エンター
    tmux send-keys -t "$target" "" C-m
    
    # 送信確認
    sleep 2
    local check_content=$(tmux capture-pane -t "$target" -p | grep ">")
    if echo "$check_content" | grep -q "$message"; then
        echo "⚠️ 送信失敗検知・追加エンター"
        tmux send-keys -t "$target" "" C-m
    fi
    
    echo "✅ 強化版送信完了"
}

# 使用例: enhanced_double_enter "multiagent:0.0" "メッセージ"
EOF
    
    chmod +x "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/ENHANCED_DOUBLE_ENTER.sh"
    log_recovery "✅ 強化版ダブルエンターシステム作成"
    
    # 2. 定期監視システム
    cat > "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_MONITOR.sh" << 'EOF'
#!/bin/bash
# プロンプト停止定期監視
monitor_all_prompts() {
    while true; do
        for i in {0..3}; do
            local status=$(bash /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_RECOVERY_SYSTEM.sh detect "multiagent:0.$i" "WORKER$i")
            
            if [[ "$status" == "stuck" ]]; then
                echo "🚨 WORKER$i 停止検知・自動復旧"
                bash /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_RECOVERY_SYSTEM.sh recover "multiagent:0.$i" "WORKER$i"
            fi
        done
        
        sleep 30  # 30秒間隔
    done
}
EOF
    
    chmod +x "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_MONITOR.sh"
    log_recovery "✅ 定期監視システム作成"
}

# 全状況記録
record_full_status() {
    log_recovery "📋 全状況詳細記録"
    
    echo "=== $(date) AI組織システム状況記録 ===" >> "$LOG_FILE"
    
    for i in {0..3}; do
        log_recovery "--- WORKER$i 詳細 ---"
        log_recovery "タイトル: $(tmux list-panes -t multiagent:0.$i -F "#{pane_title}")"
        log_recovery "最終3行:"
        tmux capture-pane -t multiagent:0.$i -p | tail -3 >> "$LOG_FILE"
        log_recovery ""
    done
}

# メイン実行
case "${1:-monitor}" in
    "detect")
        detect_prompt_stuck "$2" "$3"
        ;;
    "recover")
        auto_recovery "$2" "$3"
        ;;
    "prevent")
        implement_prevention
        ;;
    "record")
        record_full_status
        ;;
    "monitor")
        log_recovery "🔄 プロンプト監視システム開始"
        while true; do
            for i in {0..3}; do
                local worker_name=""
                case $i in
                    0) worker_name="BOSS1" ;;
                    1) worker_name="WORKER1" ;;
                    2) worker_name="WORKER2" ;;
                    3) worker_name="WORKER3" ;;
                esac
                
                local status=$(detect_prompt_stuck "multiagent:0.$i" "$worker_name")
                
                if [[ "$status" == "stuck" ]]; then
                    log_recovery "🚨 $worker_name 停止検知・自動復旧実行"
                    auto_recovery "multiagent:0.$i" "$worker_name"
                fi
            done
            
            sleep 15  # 15秒間隔監視
        done
        ;;
    *)
        echo "使用方法:"
        echo "  $0 detect [target] [name]  # 停止検知"
        echo "  $0 recover [target] [name] # 復旧実行"
        echo "  $0 prevent                 # 再発防止策実装"
        echo "  $0 record                  # 状況記録"
        echo "  $0 monitor                 # 定期監視（デフォルト）"
        ;;
esac