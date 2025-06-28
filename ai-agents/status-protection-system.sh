#!/bin/bash

# 🔒 ステータス保護システム
# 作業中にステータス表示が消えるのを完全防止

# 動的ステータス復元関数
get_correct_status() {
    local pane=$1
    local content=$(tmux capture-pane -t "$pane" -p)
    
    # 実際の作業状況を検知
    if echo "$content" | grep -q "Wrangling\|Organizing\|Planning\|Polishing\|Searching\|Thinking\|Writing\|Creating\|Analyzing\|Processing"; then
        echo "🔵作業中"
    elif echo "$content" | grep -q "tokens.*esc to interrupt\|Context left until auto-compact"; then
        echo "🔵作業中"
    elif echo "$content" | grep -q "> " && echo "$content" | grep -v "PRESIDENTからの指示をお待ちしております\|BOSSからの指示をお待ちしております"; then
        echo "🔵作業中"
    else
        echo "🟡待機中"
    fi
}

# 基本フォーマット定義
get_base_format() {
    local pane=$1
    case $pane in
        "president:0") echo "👑PRESIDENT │ システム統括管理" ;;
        "multiagent:0.0") echo "👔チームリーダー │ 作業指示・進捗管理" ;;
        "multiagent:0.1") echo "💻フロントエンド │ UI実装・React開発" ;;
        "multiagent:0.2") echo "🔧バックエンド │ API開発・DB設計" ;;
        "multiagent:0.3") echo "🎨UI/UXデザイン │ デザイン改善・UX最適化" ;;
        *) echo "❌ 不明" ;;
    esac
}

# ステータス強制復元（動的版）
force_restore_status() {
    echo "🔒 動的ステータス復元実行中..."
    
    local panes=("president:0" "multiagent:0.0" "multiagent:0.1" "multiagent:0.2" "multiagent:0.3")
    
    for pane in "${panes[@]}"; do
        local status=$(get_correct_status "$pane")
        local base_format=$(get_base_format "$pane")
        local full_title="#[bg=colour238,fg=colour15] $status $base_format #[default]"
        
        echo "復元中: $pane -> $status $base_format"
        tmux select-pane -t "$pane" -T "$full_title" 2>/dev/null || echo "⚠️ $pane 復元失敗"
    done
    
    echo "✅ 動的ステータス復元完了"
}

# 継続監視と自動復元（動的版）
continuous_protection() {
    echo "🛡️ 動的ステータス保護システム開始（10秒間隔監視）"
    
    while true; do
        local panes=("president:0" "multiagent:0.0" "multiagent:0.1" "multiagent:0.2" "multiagent:0.3")
        
        for pane in "${panes[@]}"; do
            # 現在のタイトル取得
            current_title=$(tmux display-message -t "$pane" -p "#{pane_title}" 2>/dev/null)
            
            # 基本フォーマットのキーワードがない場合は復元
            local base_format=$(get_base_format "$pane")
            local keyword=$(echo "$base_format" | cut -d'│' -f1 | xargs)
            
            if [[ "$current_title" != *"$keyword"* ]]; then
                echo "🚨 $pane ステータス異常検出: $current_title"
                local status=$(get_correct_status "$pane")
                local full_title="#[bg=colour238,fg=colour15] $status $base_format #[default]"
                tmux select-pane -t "$pane" -T "$full_title"
                echo "✅ $pane 動的ステータス復元: $status"
            fi
        done
        
        sleep 10  # 10秒間隔で監視
    done
}

# バックグラウンド保護開始
start_background_protection() {
    if pgrep -f "status-protection-system.sh" > /dev/null; then
        echo "⚠️ ステータス保護システムは既に動作中です"
        return
    fi
    
    echo "🚀 バックグラウンドステータス保護開始"
    nohup $0 monitor > /tmp/status-protection.log 2>&1 &
    echo "✅ バックグラウンド保護開始（PID: $!）"
}

# 保護停止
stop_protection() {
    pkill -f "status-protection-system.sh"
    echo "⏹️ ステータス保護システム停止"
}

# 現在のステータス確認
check_current_status() {
    echo "📊 現在のステータス表示:"
    local panes=("president:0" "multiagent:0.0" "multiagent:0.1" "multiagent:0.2" "multiagent:0.3")
    
    for pane in "${panes[@]}"; do
        current=$(tmux display-message -t "$pane" -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")
        echo "  $pane: $current"
    done
}

# 使用方法
case "$1" in
    "restore")
        force_restore_status
        ;;
    "monitor")
        continuous_protection
        ;;
    "start")
        start_background_protection
        ;;
    "stop")
        stop_protection
        ;;
    "check")
        check_current_status
        ;;
    *)
        echo "🔒 ステータス保護システム"
        echo ""
        echo "使用方法:"
        echo "  $0 restore  # 即座ステータス復元"
        echo "  $0 start    # バックグラウンド保護開始"
        echo "  $0 stop     # 保護停止"
        echo "  $0 check    # 現在ステータス確認"
        echo ""
        echo "🛡️ 作業中にステータスが消えるのを完全防止"
        ;;
esac