#!/bin/bash

# 高精度ステータス表示システム
# 具体的で分かりやすい作業状態を表示

SESSION="multiagent"

# 関数: 具体的なステータスを判定
get_detailed_status() {
    local worker_id=$1
    local content=$(tmux capture-pane -t $SESSION:0.$worker_id -p 2>/dev/null)
    
    # 具体的な作業パターンを検出
    if echo "$content" | grep -q "Documenting"; then
        echo "📝文書作成中"
    elif echo "$content" | grep -q "Architecting"; then
        echo "🏗️設計中"
    elif echo "$content" | grep -q "Guiding"; then
        echo "📋ガイド作成中"
    elif echo "$content" | grep -q "Organizing"; then
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

# 関数: アクティブペイン判定
is_active_pane() {
    local worker_id=$1
    local active=$(tmux display-message -t $SESSION -p "#{pane_active}")
    local current_pane=$(tmux display-message -t $SESSION:0.$worker_id -p "#{pane_active}")
    [ "$current_pane" = "1" ]
}

# 関数: ペインボーダー色設定
set_pane_border() {
    local worker_id=$1
    local is_active=$2
    
    if [ "$is_active" = "true" ]; then
        # アクティブペインは緑のボーダー
        tmux select-pane -t $SESSION:0.$worker_id -P 'fg=green,bg=black'
    else
        # 非アクティブペインは灰色のボーダー
        tmux select-pane -t $SESSION:0.$worker_id -P 'fg=white,bg=black'
    fi
}

# 関数: 完全なステータス更新
update_complete_status() {
    echo "🔄 高精度ステータス更新中..."
    
    for i in {0..3}; do
        # 具体的なステータス取得
        detailed_status=$(get_detailed_status $i)
        
        # アクティブ状態確認
        if is_active_pane $i; then
            active_indicator="🟢"
            set_pane_border $i "true"
        else
            active_indicator=""
            set_pane_border $i "false"
        fi
        
        # 役割表示
        case $i in
            0) role="👔チームリーダー" ;;
            1) role="💻フロントエンド" ;;
            2) role="🔧バックエンド" ;;
            3) role="🎨UI/UXデザイン" ;;
        esac
        
        # タイトル設定（ステータス文頭、アクティブ表示付き）
        title="$detailed_status $active_indicator$role"
        tmux select-pane -t $SESSION:0.$i -T "$title"
        
        echo "  → WORKER$i: $detailed_status $([ -n "$active_indicator" ] && echo "(アクティブ)" || echo "")"
    done
    echo "✅ 高精度ステータス更新完了"
}

# 関数: ステータス確認
check_status() {
    echo "📊 現在の詳細ステータス ($(date '+%H:%M:%S'))"
    echo "================================================"
    for i in {0..3}; do
        detailed_status=$(get_detailed_status $i)
        case $i in
            0) echo "👔 チームリーダー: $detailed_status" ;;
            1) echo "💻 フロントエンド: $detailed_status" ;;
            2) echo "🔧 バックエンド: $detailed_status" ;;
            3) echo "🎨 UI/UXデザイン: $detailed_status" ;;
        esac
    done
    echo "================================================"
}

# メイン処理
case "$1" in
    "update")
        update_complete_status
        ;;
    "check")
        check_status
        ;;
    "monitor")
        echo "🕐 高精度ステータス連続監視開始（Ctrl+Cで停止）"
        while true; do
            update_complete_status
            sleep 5
        done
        ;;
    *)
        echo "使用方法:"
        echo "  $0 update    # 完全ステータス更新"
        echo "  $0 check     # 詳細ステータス確認"
        echo "  $0 monitor   # 連続監視"
        ;;
esac