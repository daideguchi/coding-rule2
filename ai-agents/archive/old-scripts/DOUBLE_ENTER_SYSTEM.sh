#!/bin/bash
# 🔥 ダブルエンターシステム - 確実なエンター送信
# 作成日: 2025-06-29
# 目的: Bypassing Permissions問題を完全解決

double_enter_send() {
    local target="$1"
    local message="$2"
    
    echo "📤 メッセージ送信開始: $target"
    
    # 1. メッセージ送信
    tmux send-keys -t "$target" "$message" C-m
    echo "✅ メッセージ送信完了"
    
    # 2. 第1回エンター（1秒後）
    sleep 1
    tmux send-keys -t "$target" "" C-m
    echo "✅ 第1回エンター送信完了"
    
    # 3. 第2回エンター（さらに1秒後）
    sleep 1
    tmux send-keys -t "$target" "" C-m
    echo "✅ 第2回エンター送信完了"
    
    echo "🎯 ダブルエンター送信完全完了: $target"
}

# 全ワーカーにダブルエンター実行
double_enter_all_workers() {
    echo "🚀 全ワーカーダブルエンター実行開始"
    
    for i in {0..3}; do
        echo "--- WORKER$i 処理開始 ---"
        tmux send-keys -t multiagent:0.$i "" C-m
        sleep 1
        tmux send-keys -t multiagent:0.$i "" C-m
        echo "✅ WORKER$i ダブルエンター完了"
    done
    
    echo "🎯 全ワーカーダブルエンター実行完了"
}

# 実行
if [[ "$1" == "all" ]]; then
    double_enter_all_workers
elif [[ -n "$1" && -n "$2" ]]; then
    double_enter_send "$1" "$2"
else
    echo "使用方法:"
    echo "  $0 all                    # 全ワーカーにダブルエンター"
    echo "  $0 [target] [message]     # 特定ターゲットにメッセージ+ダブルエンター"
fi