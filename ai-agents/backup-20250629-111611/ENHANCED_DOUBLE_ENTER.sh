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
