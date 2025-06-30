#!/bin/bash
# 🎯 シンプル・非干渉ステータス修正
# 作成日: 2025-06-29
# 目的: 監視による干渉を排除し、一度だけ確実に修正

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/simple-fix.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_simple() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 一度だけの確実なステータス設定（監視なし）
one_time_status_fix() {
    log_simple "🎯 一度だけステータス修正開始（監視干渉なし）"
    
    # PRESIDENT設定
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ AI組織統括管理中"
    log_simple "✅ PRESIDENT設定完了"
    
    # 各ワーカーの実際の状況確認（一度だけ）
    for i in {0..3}; do
        local content=$(tmux capture-pane -t "multiagent:0.$i" -p 2>/dev/null || echo "")
        local last_line=$(echo "$content" | tail -1)
        
        # シンプル判定: 空白行または > で終わっている、またはBypassingがある場合は待機中
        if [[ -z "$last_line" ]] || echo "$last_line" | grep -q "> *$" || echo "$content" | grep -q "Bypassing Permissions"; then
            # 待機中
            case $i in
                0) tmux select-pane -t multiagent:0.$i -T "🟡待機中 👔BOSS1 │ チーム指示待ち" ;;
                1) tmux select-pane -t multiagent:0.$i -T "🟡待機中 💻WORKER1 │ フロントエンド開発待機" ;;
                2) tmux select-pane -t multiagent:0.$i -T "🟡待機中 🔧WORKER2 │ バックエンド開発待機" ;;
                3) tmux select-pane -t multiagent:0.$i -T "🟡待機中 🎨WORKER3 │ デザイン業務待機" ;;
            esac
            log_simple "✅ WORKER$i: 🟡待機中設定"
        else
            # 作業中
            case $i in
                0) tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ チーム管理中" ;;
                1) tmux select-pane -t multiagent:0.$i -T "🟢作業中 💻WORKER1 │ フロント開発中" ;;
                2) tmux select-pane -t multiagent:0.$i -T "🟢作業中 🔧WORKER2 │ バック開発中" ;;
                3) tmux select-pane -t multiagent:0.$i -T "🟢作業中 🎨WORKER3 │ デザイン業務中" ;;
            esac
            log_simple "✅ WORKER$i: 🟢作業中設定"
        fi
    done
    
    log_simple "🎯 一度だけステータス修正完了"
    
    # 設定確認
    log_simple "📋 設定確認:"
    for i in {0..3}; do
        local title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        log_simple "  WORKER$i: $title"
    done
}

# 現在の状況確認のみ（変更なし）
check_current_status() {
    log_simple "📊 現在の状況確認（変更なし）"
    
    local president_title=$(tmux list-panes -t "president" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
    log_simple "PRESIDENT: $president_title"
    
    for i in {0..3}; do
        local title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        local content=$(tmux capture-pane -t "multiagent:0.$i" -p 2>/dev/null | tail -1)
        log_simple "WORKER$i: $title"
        log_simple "  最終行: $content"
    done
}

# メイン実行
case "${1:-fix}" in
    "fix")
        one_time_status_fix
        ;;
    "check")
        check_current_status
        ;;
    *)
        echo "使用方法:"
        echo "  $0 fix    # 一度だけステータス修正（デフォルト）"
        echo "  $0 check  # 現在の状況確認のみ"
        ;;
esac