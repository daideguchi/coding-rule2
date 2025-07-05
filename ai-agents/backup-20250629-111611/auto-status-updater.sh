#!/bin/bash

# 🔄 自動ステータス更新システム
# 動いている時のステータス自動切り替え

SESSION="multiagent"

# ステータス検知関数（smart-status.shから移植）
get_detailed_status() {
    local worker_id=$1
    local content=$(tmux capture-pane -t $SESSION:0.$worker_id -p)
    
    if echo "$content" | grep -q "Organizing"; then
        echo "📂整理中"
    elif echo "$content" | grep -q "Planning"; then
        echo "📋計画中"
    elif echo "$content" | grep -q "Divining"; then
        echo "🔍調査中"
    elif echo "$content" | grep -q "Exploring"; then
        echo "🗺️探索中"
    elif echo "$content" | grep -q "Polishing"; then
        echo "✨仕上げ中"
    elif echo "$content" | grep -q "Envisioning"; then
        echo "💭構想中"
    elif echo "$content" | grep -q "Searching"; then
        echo "🔎検索中"
    elif echo "$content" | grep -q "Imagining"; then
        echo "💭構想中"
    elif echo "$content" | grep -q "Cerebrating"; then
        echo "🧠考察中"
    elif echo "$content" | grep -q "Unfurling"; then
        echo "📋展開中"
    elif echo "$content" | grep -q "Wrangling"; then
        echo "🔧作業中"
    elif echo "$content" | grep -q "completed\|完了\|finished"; then
        echo "✅完了"
    elif echo "$content" | grep -q "Bypassing Permissions"; then
        echo "🟡待機中"
    elif echo "$content" | grep -q "> "; then
        echo "🟡待機中"
    else
        echo "🔵処理中"
    fi
}

# 役職定義
get_role() {
    local worker_id=$1
    case $worker_id in
        0) echo "👔チームリーダー" ;;
        1) echo "💻フロントエンド" ;;
        2) echo "🔧バックエンド" ;;
        3) echo "🎨UI/UXデザイン" ;;
    esac
}

# 全ワーカーのステータス更新
update_all_status() {
    echo "🔄 ステータス自動更新中..."
    
    for i in {0..3}; do
        local status=$(get_detailed_status $i)
        local role=$(get_role $i)
        local title="$status $role"
        
        # tmuxペインタイトル更新（WORKER3は強制修正）
        if [ $i -eq 3 ]; then
            tmux select-pane -t $SESSION:0.$i -T "🟡待機中 🎨UI/UXデザイン"
        else
            tmux select-pane -t $SESSION:0.$i -T "$title"
        fi
    done
    
    echo "✅ ステータス更新完了"
}

# 継続監視モード
continuous_monitor() {
    echo "🔄 ステータス継続監視開始..."
    while true; do
        update_all_status
        sleep 5  # 5秒間隔で更新
    done
}

# 引数で実行モード選択
case "${1:-update}" in
    "continuous"|"monitor")
        continuous_monitor
        ;;
    "update"|*)
        update_all_status
        ;;
esac