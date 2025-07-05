#!/bin/bash

# 🚀 直接指示システム
# PRESIDENT → WORKER 直接コミュニケーション

# 直接指示関数
direct_command() {
    local target=$1
    local message=$2
    local priority=${3:-"normal"}
    
    if [ -z "$target" ] || [ -z "$message" ]; then
        echo "使用方法: direct_command [target] [message] [priority]"
        echo "例: direct_command worker1 'セキュリティチェックお願いします' urgent"
        return 1
    fi
    
    # ターゲット識別
    case $target in
        "boss"|"boss1"|"0")
            local pane="multiagent:0.0"
            local display_name="BOSS1"
            ;;
        "worker1"|"w1"|"1")
            local pane="multiagent:0.1"
            local display_name="WORKER1"
            ;;
        "worker2"|"w2"|"2")
            local pane="multiagent:0.2"
            local display_name="WORKER2"
            ;;
        "worker3"|"w3"|"3")
            local pane="multiagent:0.3"
            local display_name="WORKER3"
            ;;
        *)
            echo "❌ 無効なターゲット: $target"
            echo "利用可能: boss, worker1, worker2, worker3"
            return 1
            ;;
    esac
    
    # 優先度に応じた表示
    case $priority in
        "urgent")
            local prefix="🚨【緊急】"
            ;;
        "high")
            local prefix="🔥【重要】"
            ;;
        "normal")
            local prefix="💬【通常】"
            ;;
        *)
            local prefix="💬【通常】"
            ;;
    esac
    
    echo "📤 直接指示送信: $display_name"
    echo "📝 メッセージ: $message"
    echo "⚡ 優先度: $priority"
    
    # メッセージ送信（Enter2回実行）
    tmux send-keys -t "$pane" ">$prefix PRESIDENT直接指示: $message" C-m
    sleep 0.5
    tmux send-keys -t "$pane" C-m
    
    # ログ記録
    echo "$(date): PRESIDENT -> $display_name [$priority] $message" >> /tmp/direct-commands.log
    
    echo "✅ 直接指示送信完了"
}

# 並列指示関数
parallel_commands() {
    local task_description=$1
    
    if [ -z "$task_description" ]; then
        echo "使用方法: parallel_commands 'タスク説明'"
        return 1
    fi
    
    echo "🚀 並列作業開始: $task_description"
    
    # 各WORKERに専門分野に応じたタスクを同時送信
    direct_command worker1 "【並列作業1/3】$task_description - フロントエンド観点から対応お願いします" normal &
    direct_command worker2 "【並列作業2/3】$task_description - バックエンド観点から対応お願いします" normal &
    direct_command worker3 "【並列作業3/3】$task_description - UI/UX観点から対応お願いします" normal &
    
    wait
    echo "✅ 並列指示送信完了"
}

# 緊急対応システム
emergency_response() {
    local issue=$1
    
    if [ -z "$issue" ]; then
        echo "使用方法: emergency_response '緊急事項'"
        return 1
    fi
    
    echo "🚨 緊急対応モード起動"
    echo "📋 問題: $issue"
    
    # 全員に緊急通知
    direct_command boss "【緊急事態】$issue - 即座対応してください" urgent
    direct_command worker1 "【緊急事態】$issue - 専門分野から支援お願いします" urgent
    direct_command worker2 "【緊急事態】$issue - 専門分野から支援お願いします" urgent
    direct_command worker3 "【緊急事態】$issue - 専門分野から支援お願いします" urgent
    
    echo "🚨 緊急対応指示完了"
}

# 作業確認システム
check_status() {
    echo "📊 チーム状況確認中..."
    
    echo "👔 BOSS1: $(tmux display-message -t multiagent:0.0 -p "#{pane_title}")"
    echo "💻 WORKER1: $(tmux display-message -t multiagent:0.1 -p "#{pane_title}")"
    echo "🔧 WORKER2: $(tmux display-message -t multiagent:0.2 -p "#{pane_title}")"
    echo "🎨 WORKER3: $(tmux display-message -t multiagent:0.3 -p "#{pane_title}")"
    
    echo ""
    echo "📝 最近の直接指示ログ:"
    if [ -f /tmp/direct-commands.log ]; then
        tail -5 /tmp/direct-commands.log
    else
        echo "ログファイルなし"
    fi
}

# 智能タスク分散
intelligent_dispatch() {
    local task=$1
    local complexity=${2:-"medium"}
    
    if [ -z "$task" ]; then
        echo "使用方法: intelligent_dispatch 'タスク内容' [complexity]"
        echo "complexity: simple, medium, complex"
        return 1
    fi
    
    echo "🧠 インテリジェント・タスク分散"
    echo "📋 タスク: $task"
    echo "🎯 複雑度: $complexity"
    
    case $complexity in
        "simple")
            echo "🎯 単純タスク - 最適担当者に直接指示"
            direct_command worker1 "$task" normal
            ;;
        "medium")
            echo "🎯 中程度タスク - BOSS経由で分散"
            direct_command boss "$task - チームで分担してください" normal
            ;;
        "complex")
            echo "🎯 複雑タスク - 全チーム並列作業"
            parallel_commands "$task"
            ;;
        *)
            echo "❌ 無効な複雑度: $complexity"
            return 1
            ;;
    esac
    
    echo "✅ インテリジェント分散完了"
}

# 使用方法
case "$1" in
    "send"|"direct")
        direct_command "$2" "$3" "$4"
        ;;
    "parallel")
        parallel_commands "$2"
        ;;
    "emergency")
        emergency_response "$2"
        ;;
    "status"|"check")
        check_status
        ;;
    "dispatch"|"smart")
        intelligent_dispatch "$2" "$3"
        ;;
    *)
        echo "🚀 直接指示システム"
        echo ""
        echo "使用方法:"
        echo "  $0 direct [target] [message] [priority]     # 直接指示"
        echo "  $0 parallel [task]                          # 並列作業"
        echo "  $0 emergency [issue]                        # 緊急対応"
        echo "  $0 status                                   # 状況確認"
        echo "  $0 dispatch [task] [complexity]             # 智能分散"
        echo ""
        echo "例:"
        echo "  $0 direct worker1 'UIを改善してください' high"
        echo "  $0 parallel 'パフォーマンス最適化'"
        echo "  $0 emergency 'システムがダウンしています'"
        echo "  $0 dispatch '新機能実装' complex"
        ;;
esac