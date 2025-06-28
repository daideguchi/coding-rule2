#!/bin/bash

# 🔥 最強社長専用 - Enter忘れ絶対防止システム
# 24回目のミスを絶対に防ぐ

safe_ultimate_command() {
    local command="$1"
    local target="${2:-multiagent:0.0}"
    
    echo "🔥 最強社長コマンド実行開始"
    echo "📨 指令: $command"
    echo "🎯 対象: $target"
    
    # 即座実行（Enter付き）
    tmux send-keys -t "$target" "$command" C-m
    
    echo "✅ Enter自動実行完了"
    
    # 確認
    sleep 2
    echo "📋 実行結果確認:"
    tmux capture-pane -t "$target" -p | tail -3
    
    # 自動監視
    if [ -f "./ai-agents/autonomous-monitoring.sh" ]; then
        ./ai-agents/autonomous-monitoring.sh single
    fi
    
    echo "🎯 最強社長コマンド完了"
}

# 直接実行の場合
if [ $# -gt 0 ]; then
    safe_ultimate_command "$@"
fi