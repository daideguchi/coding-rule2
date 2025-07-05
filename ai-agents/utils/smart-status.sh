#!/bin/bash

# 高精度ステータス表示システム
# 具体的で分かりやすい作業状態を表示

SESSION="multiagent"

# 関数: 具体的なステータスを判定
get_detailed_status() {
    local worker_id=$1
    local content=$(tmux capture-pane -t $SESSION:0.$worker_id -p 2>/dev/null)
    
    # 複数行にまたがるパターンも検出（改行を空白に置換）
    local content_oneline=$(echo "$content" | tr '\n' ' ')
    
    # 具体的な作業パターンを検出（🔵を🟢に統一）
    if echo "$content" | grep -q "Stewing"; then
        echo "🟢熟考中"
    elif echo "$content" | grep -q "Brewing"; then
        echo "🟢作業中"
    elif echo "$content" | grep -q "Doing"; then
        echo "🟢作業中"
    elif echo "$content" | grep -q "Documenting"; then
        echo "🟢文書作成中"
    elif echo "$content" | grep -q "Puttering"; then
        echo "🟢作業中"
    elif echo "$content" | grep -q "Architecting"; then
        echo "🟢設計中"
    elif echo "$content" | grep -q "Guiding"; then
        echo "🟢ガイド作成中"
    elif echo "$content" | grep -q "Organizing"; then
        echo "🟢整理中"
    elif echo "$content" | grep -q "Planning"; then
        echo "🟢計画中"
    elif echo "$content" | grep -q "Divining"; then
        echo "🟢調査中"
    elif echo "$content" | grep -q "Exploring"; then
        echo "🟢探索中"
    elif echo "$content" | grep -q "Polishing"; then
        echo "🟢仕上げ中"
    elif echo "$content" | grep -q "Envisioning"; then
        echo "🟢構想中"
    elif echo "$content" | grep -q "Searching"; then
        echo "🟢検索中"
    elif echo "$content" | grep -q "Imagining"; then
        echo "🟢構想中"
    elif echo "$content" | grep -q "Cerebrating"; then
        echo "🟢考察中"
    elif echo "$content" | grep -q "Unfurling"; then
        echo "🟢展開中"
    elif echo "$content" | grep -q "Harmonizing"; then
        echo "🟢調整中"
    elif echo "$content" | grep -q "Meandering"; then
        echo "🟢思索中"
    elif echo "$content" | grep -q "Tinkering"; then
        echo "🟢調整中"
    elif echo "$content" | grep -q "Calculating"; then
        echo "🟢計算中"
    elif echo "$content" | grep -q "Considering"; then
        echo "🟢検討中"
    elif echo "$content" | grep -q "Imagining"; then
        echo "🟢構想中"
    elif echo "$content" | grep -q "Documenting"; then
        echo "🟢文書作成中"
    elif echo "$content" | grep -q "completed\|完了\|finished"; then
        echo "✅完了"
    elif echo "$content" | grep -q "> Try"; then
        echo "🟡待機中"
    elif echo "$content" | grep -q "> "; then
        echo "🟡待機中"
    else
        echo "🟡待機中"
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
    
    # 変更検知用の前回状況保存
    local status_changed=false
    local status_report=""
    
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
        
        # 役割表示（2025-06-29 実際の作業内容に基づき修正）
        case $i in
            0) role="👔 管理・統括" ;;
            1) role="📚 ドキュメント" ;;
            2) role="⚙️ システム開発" ;;
            3) role="🎨 UI/UX" ;;
        esac
        
        # 現在の処理状況を取得
        current_task=""
        if [ "$detailed_status" = "🟢作業中" ] || [ "$detailed_status" = "🟢熟考中" ] || [ "$detailed_status" = "🟢文書作成中" ] || [ "$detailed_status" = "🟢設計中" ] || [ "$detailed_status" = "🟢整理中" ] || [ "$detailed_status" = "🟢計画中" ] || [ "$detailed_status" = "🟢調査中" ] || [ "$detailed_status" = "🟢探索中" ] || [ "$detailed_status" = "🟢仕上げ中" ] || [ "$detailed_status" = "🟢構想中" ] || [ "$detailed_status" = "🟢検索中" ] || [ "$detailed_status" = "🟢考察中" ] || [ "$detailed_status" = "🟢展開中" ]; then
            # 作業中の場合は具体的な処理内容を追加
            case $i in
                0) current_task="システム統合作業中" ;;
                1) current_task="フロントエンド確認中" ;;
                2) current_task="バックエンド処理中" ;;
                3) current_task="UI/UX設計中" ;;
            esac
        fi
        
        # タイトル設定（型: 🟢作業中 役職 現在の処理状況）
        if [ -n "$current_task" ]; then
            title="$detailed_status $role $current_task"
        else
            title="$detailed_status $role"
        fi
        tmux select-pane -t $SESSION:0.$i -T "$title"
        
        echo "  → WORKER$i: $detailed_status $([ -n "$active_indicator" ] && echo "(アクティブ)" || echo "")"
        
        # ステータス変更の記録
        if [ "$detailed_status" != "🟡待機中" ]; then
            status_changed=true
            status_report="$status_report\n  WORKER$i: $detailed_status"
        fi
    done
    
    # 変更があった場合のみ報告
    if [ "$status_changed" = true ]; then
        echo ""
        echo "📢 作業状況変更検知:"
        echo -e "$status_report"
        echo ""
    fi
    
    echo "✅ 高精度ステータス更新完了"
}

# 関数: ステータス確認
check_status() {
    echo "📊 現在の詳細ステータス ($(date '+%H:%M:%S'))"
    echo "================================================"
    for i in {0..3}; do
        detailed_status=$(get_detailed_status $i)
        case $i in
            0) echo "👔 管理・統括: $detailed_status" ;;
            1) echo "📚 ドキュメント: $detailed_status" ;;
            2) echo "⚙️ システム開発: $detailed_status" ;;
            3) echo "🎨 UI/UX: $detailed_status" ;;
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