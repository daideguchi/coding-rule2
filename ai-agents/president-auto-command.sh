#!/bin/bash

# 🤖 PRESIDENT完全自動指示送信システム
# 23回のミス教訓 - 手動操作を排除し完全自動化

# 指示送信の完全自動化（宣言確認付き）
send_auto_instruction() {
    local target=$1
    local message=$2
    
    # 宣言確認
    if ! /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/president-declaration-system.sh check; then
        echo "🚨 宣言なしの作業は禁止されています！"
        echo "実行してください: ./ai-agents/president-declaration-system.sh declare"
        return 1
    fi
    
    if [ -z "$target" ] || [ -z "$message" ]; then
        echo "❌ 使用方法: send_auto_instruction [target] \"message\""
        return 1
    fi
    
    echo "🤖 完全自動指示送信開始: $target"
    echo "💬 メッセージ: $message"
    
    # auto-enter-system.shを使用して確実な送信
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/auto-enter-system.sh "$target" "$message"
    
    # 送信後の自動監視開始
    echo "🔍 自動監視システム起動中..."
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/auto-monitoring-system.sh start
    
    # 3秒後に状況確認
    sleep 3
    echo "📊 送信後状況確認:"
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/auto-monitoring-system.sh check
    
    echo "✅ 完全自動指示送信完了"
}

# BOSS1への自動指示送信（最重要）
boss_auto() {
    local message=$1
    if [ -z "$message" ]; then
        echo "❌ 使用方法: $0 boss \"指示内容\""
        return 1
    fi
    
    echo "👔 BOSS1への完全自動指示送信"
    send_auto_instruction "boss" "$message"
}

# 全ワーカーへの自動指示送信
all_auto() {
    local message=$1
    if [ -z "$message" ]; then
        echo "❌ 使用方法: $0 all \"指示内容\""
        return 1
    fi
    
    echo "🎯 全ワーカーへの完全自動指示送信"
    send_auto_instruction "all" "$message"
}

# 緊急修正（Enter強制実行）
emergency_fix() {
    echo "🚨 緊急修正実行 - 全ワーカーのEnter強制実行"
    for i in {0..3}; do
        echo "修正中: multiagent:0.$i"
        tmux send-keys -t multiagent:0.$i C-m
        sleep 0.5
        tmux send-keys -t multiagent:0.$i C-m
        sleep 0.5
    done
    echo "✅ 緊急修正完了"
}

# 使用方法表示
show_usage() {
    echo "🤖 PRESIDENT完全自動指示送信システム"
    echo "使用方法: $0 [command] [message]"
    echo ""
    echo "commands:"
    echo "  boss \"指示\"     - BOSS1への自動指示送信"
    echo "  all \"指示\"      - 全ワーカーへの自動指示送信"
    echo "  worker1 \"指示\"  - WORKER1への自動指示送信"
    echo "  worker2 \"指示\"  - WORKER2への自動指示送信"
    echo "  worker3 \"指示\"  - WORKER3への自動指示送信"
    echo "  emergency       - 緊急修正（Enter強制実行）"
    echo "  status          - 全ワーカー状況確認"
    echo ""
    echo "例: $0 boss \"プロジェクト状況を確認してください\""
}

# メイン処理
case "$1" in
    "boss")
        boss_auto "$2"
        ;;
    "all")
        all_auto "$2"
        ;;
    "worker1")
        send_auto_instruction "worker1" "$2"
        ;;
    "worker2")
        send_auto_instruction "worker2" "$2"
        ;;
    "worker3")
        send_auto_instruction "worker3" "$2"
        ;;
    "emergency")
        emergency_fix
        ;;
    "status")
        /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/auto-monitoring-system.sh check
        ;;
    *)
        show_usage
        ;;
esac