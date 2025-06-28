#!/bin/bash

# 🔒 ステータス保護システム
# 作業中にステータス表示が消えるのを完全防止

# 固定ステータス定義（絶対に変更されない）
FIXED_STATUSES=(
    "president:0:🔵作業中 👑PRESIDENT │ システム統括管理"
    "multiagent:0.0:🔵作業中 👔チームリーダー │ 作業指示・進捗管理"
    "multiagent:0.1:🔵作業中 💻フロントエンド │ UI実装・React開発"
    "multiagent:0.2:🔵作業中 🔧バックエンド │ API開発・DB設計"
    "multiagent:0.3:🔵作業中 🎨UI/UXデザイン │ デザイン改善・UX最適化"
)

# ステータス強制復元
force_restore_status() {
    echo "🔒 ステータス強制復元実行中..."
    
    for status_def in "${FIXED_STATUSES[@]}"; do
        IFS=':' read -r session pane title <<< "$status_def"
        echo "復元中: $session:$pane -> $title"
        tmux select-pane -t "$session:$pane" -T "$title" 2>/dev/null || echo "⚠️ $session:$pane 復元失敗"
    done
    
    echo "✅ ステータス強制復元完了"
}

# 継続監視と自動復元
continuous_protection() {
    echo "🛡️ ステータス保護システム開始（10秒間隔監視）"
    
    while true; do
        for status_def in "${FIXED_STATUSES[@]}"; do
            IFS=':' read -r session pane expected_title <<< "$status_def"
            
            # 現在のタイトル取得
            current_title=$(tmux display-message -t "$session:$pane" -p "#{pane_title}" 2>/dev/null)
            
            # タイトルが変更されている場合は即座復元
            if [[ "$current_title" != *"👑PRESIDENT"* ]] && [[ "$session:$pane" == "president:0" ]]; then
                echo "🚨 プレジデントステータス異常検出: $current_title"
                tmux select-pane -t president:0 -T "🔵作業中 👑PRESIDENT │ システム統括管理"
                echo "✅ プレジデントステータス復元"
            elif [[ "$current_title" != *"👔チームリーダー"* ]] && [[ "$session:$pane" == "multiagent:0.0" ]]; then
                echo "🚨 BOSS1ステータス異常検出: $current_title"
                tmux select-pane -t multiagent:0.0 -T "🔵作業中 👔チームリーダー │ 作業指示・進捗管理"
                echo "✅ BOSS1ステータス復元"
            elif [[ "$current_title" != *"💻フロントエンド"* ]] && [[ "$session:$pane" == "multiagent:0.1" ]]; then
                echo "🚨 WORKER1ステータス異常検出: $current_title"
                tmux select-pane -t multiagent:0.1 -T "🔵作業中 💻フロントエンド │ UI実装・React開発"
                echo "✅ WORKER1ステータス復元"
            elif [[ "$current_title" != *"🔧バックエンド"* ]] && [[ "$session:$pane" == "multiagent:0.2" ]]; then
                echo "🚨 WORKER2ステータス異常検出: $current_title"
                tmux select-pane -t multiagent:0.2 -T "🔵作業中 🔧バックエンド │ API開発・DB設計"
                echo "✅ WORKER2ステータス復元"
            elif [[ "$current_title" != *"🎨UI/UXデザイン"* ]] && [[ "$session:$pane" == "multiagent:0.3" ]]; then
                echo "🚨 WORKER3ステータス異常検出: $current_title"
                tmux select-pane -t multiagent:0.3 -T "🔵作業中 🎨UI/UXデザイン │ デザイン改善・UX最適化"
                echo "✅ WORKER3ステータス復元"
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
    for status_def in "${FIXED_STATUSES[@]}"; do
        IFS=':' read -r session pane expected <<< "$status_def"
        current=$(tmux display-message -t "$session:$pane" -p "#{pane_title}" 2>/dev/null || echo "❌ 接続エラー")
        echo "  $session:$pane: $current"
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