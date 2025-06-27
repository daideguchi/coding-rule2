#!/bin/bash

# 🚨 WORKER2改良: 緊急自動Enterスクリプト
# 指示送信時のみ動作・「>」プロンプト検知・トークン完全節約

set -e

# ログ関数
log_action() {
    echo "$(date '+%H:%M:%S') $1"
}

# 「>」プロンプト検知機能
check_prompt_ready() {
    local target="$1"
    local output=$(tmux capture-pane -t "$target" -p | tail -3)
    
    # 「Bypassing Permissions」または「>」プロンプト検知
    if echo "$output" | grep -q "Bypassing Permissions\|>"; then
        return 0  # 検知成功
    else
        return 1  # 検知失敗
    fi
}

# 即座Enter送信機能
send_immediate_enter() {
    local target="$1"
    log_action "🔄 $target に即座Enter送信"
    tmux send-keys -t "$target" C-m
    log_action "✅ Enter送信完了"
}

# 指示送信機能（改良版）
send_to_boss() {
    local message="$1"
    local target="multiagent:0.0"
    
    log_action "📤 BOSS1に緊急指示送信開始"
    log_action "💬 指示: $message"
    
    # 「>」検知確認
    if check_prompt_ready "$target"; then
        log_action "🎯 プロンプト準備完了検知"
    fi
    
    # 指示送信
    tmux send-keys -t "$target" "$message" C-m
    log_action "✅ BOSS1指示送信完了"
    
    # 即座終了（継続監視なし）
    log_action "🔚 スクリプト終了 - トークン節約"
}

send_to_worker() {
    local worker_id="$1"
    local message="$2"
    local target="multiagent:0.$worker_id"
    
    log_action "📤 WORKER${worker_id}に緊急指示送信開始"
    log_action "💬 指示: $message"
    
    # 「>」検知確認
    if check_prompt_ready "$target"; then
        log_action "🎯 プロンプト準備完了検知"
    fi
    
    # 指示送信
    tmux send-keys -t "$target" "$message" C-m
    log_action "✅ WORKER${worker_id}指示送信完了"
    
    # 即座終了（継続監視なし）
    log_action "🔚 スクリプト終了 - トークン節約"
}

# 緊急Enter送信機能（新機能）
emergency_enter() {
    local target_type="$1"
    
    case "$target_type" in
        "boss")
            send_immediate_enter "multiagent:0.0"
            ;;
        "worker1")
            send_immediate_enter "multiagent:0.1"
            ;;
        "worker2") 
            send_immediate_enter "multiagent:0.2"
            ;;
        "worker3")
            send_immediate_enter "multiagent:0.3"
            ;;
        "all")
            log_action "🚨 全AI緊急Enter送信開始"
            send_immediate_enter "multiagent:0.0"
            send_immediate_enter "multiagent:0.1"
            send_immediate_enter "multiagent:0.2"
            send_immediate_enter "multiagent:0.3"
            log_action "✅ 全AI緊急Enter送信完了"
            ;;
        *)
            log_action "❌ 無効な対象: $target_type"
            exit 1
            ;;
    esac
}

# メイン処理
case "$1" in
    "boss")
        send_to_boss "$2"
        ;;
    "worker1")
        send_to_worker 1 "$2"
        ;;
    "worker2")
        send_to_worker 2 "$2"
        ;;
    "worker3")
        send_to_worker 3 "$2"
        ;;
    "enter")
        # 緊急Enter送信モード
        emergency_enter "$2"
        ;;
    *)
        echo "🚨 WORKER2改良版 - 緊急自動Enterスクリプト"
        echo ""
        echo "📋 指示送信モード:"
        echo "  $0 boss \">指示内容\""
        echo "  $0 worker1 \">指示内容\""
        echo "  $0 worker2 \">指示内容\""
        echo "  $0 worker3 \">指示内容\""
        echo ""
        echo "⚡ 緊急Enterモード:"
        echo "  $0 enter boss      # BOSS1に緊急Enter"
        echo "  $0 enter worker1   # WORKER1に緊急Enter"
        echo "  $0 enter all       # 全AIに緊急Enter"
        echo ""
        echo "🎯 特徴:"
        echo "  - 「>」プロンプト自動検知"
        echo "  - 継続監視なし（トークン節約）"
        echo "  - 指示送信時のみ動作"
        echo "  - Bypassing Permissions自動解決"
        ;;
esac