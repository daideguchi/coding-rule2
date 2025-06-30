#!/bin/bash

# ペイン表示の動的更新システム
# 実際の作業状態に応じてペイン表示を自動更新

SESSION="multiagent"

# 関数：実際の状態を判定（色付きアイコン）
get_actual_status() {
    local worker_id=$1
    local content=$(tmux capture-pane -t $SESSION:0.$worker_id -p 2>/dev/null | tail -10)
    
    if echo "$content" | grep -q "Divining\|Exploring\|Polishing\|Envisioning\|Searching\|Documenting\|Architecting\|Guiding\|Organizing\|Planning"; then
        echo "🟢実行中"
    elif echo "$content" | grep -q "Bypassing Permissions"; then
        echo "🟡待機中"
    elif echo "$content" | grep -q "completed\|完了\|finished"; then
        echo "✅完了"
    elif echo "$content" | grep -q "> "; then
        echo "🟡待機中"
    else
        echo "🔵処理中"
    fi
}

# 関数：ペイン表示を更新
update_pane_title() {
    local worker_id=$1
    local status=$(get_actual_status $worker_id)
    
    case $worker_id in
        0) 
            emoji="👔"
            role="チームリーダー"
            ;;
        1) 
            emoji="💻"
            role="フロントエンド"
            ;;
        2) 
            emoji="🔧"
            role="バックエンド"
            ;;
        3) 
            emoji="🎨"
            role="UI/UXデザイン"
            ;;
    esac
    
    # ステータス文頭＋役割表示（視認性重視）
    tmux select-pane -t $SESSION:0.$worker_id -T "$status $emoji$role"
}

# 関数：全ペイン更新
update_all_panes() {
    echo "🔄 ペイン表示更新中..."
    for i in {0..3}; do
        update_pane_title $i
        echo "  → WORKER$i: 更新完了"
    done
    echo "✅ 全ペイン表示更新完了"
}

# 関数：状態報告
status_report() {
    echo "📊 現在の状態 ($(date '+%H:%M:%S'))"
    echo "================================"
    for i in {0..3}; do
        status=$(get_actual_status $i)
        case $i in
            0) echo "👔 BOSS: $status" ;;
            1) echo "💻 WORKER1: $status" ;;
            2) echo "🔧 WORKER2: $status" ;;
            3) echo "🎨 WORKER3: $status" ;;
        esac
    done
    echo "================================"
}

# メイン処理
case "$1" in
    "update")
        update_all_panes
        ;;
    "status")
        status_report
        ;;
    "worker")
        if [ -n "$2" ]; then
            update_pane_title "$2"
        else
            echo "使用方法: $0 worker [worker_id]"
        fi
        ;;
    "auto")
        echo "🔄 自動更新モード開始（Ctrl+Cで停止）"
        while true; do
            update_all_panes
            sleep 5
        done
        ;;
    *)
        echo "使用方法:"
        echo "  $0 update           # 全ペイン表示更新"
        echo "  $0 status           # 現在の状態報告"
        echo "  $0 worker [id]      # 指定ワーカーのペイン更新"
        echo "  $0 auto             # 自動更新モード"
        ;;
esac