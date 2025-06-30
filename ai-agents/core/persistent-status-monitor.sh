#!/bin/bash
# 🔥 永続的ステータス監視システム
# 作成日: 2025-06-29
# 目的: ステータスが勝手に変わることを完全防止

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/persistent-status.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 現在のステータスを記録
record_current_status() {
    log_status "=== ステータス記録開始 ==="
    
    for i in {0..3}; do
        local current_title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        log_status "WORKER$i: $current_title"
    done
    
    local president_title=$(tmux list-panes -t "president" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
    log_status "PRESIDENT: $president_title"
    
    log_status "=== ステータス記録完了 ==="
}

# シンプルで確実なステータス判定（ユーザー指摘準拠）
detect_status_and_work() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
    
    # ユーザー指摘: プロンプト欄が空欄かつ動いてないなら待機中、それ以外は作業中
    
    # 待機中判定: プロンプト欄が空欄（> で終わっている）
    if echo "$content" | tail -1 | grep -q "> *$"; then
        echo "waiting"  # 待機中
        return
    fi
    
    # 作業中判定: それ以外（何かしら動いている、入力中、処理中など）
    if echo "$content" | grep -qE "(Coordinating|· .*tokens|Thinking|Loading)"; then
        if echo "$content" | grep -q "tokens"; then
            echo "thinking"  # 思考・回答生成中
        elif echo "$content" | grep -q "Coordinating"; then
            echo "coordinating"  # 作業調整中
        else
            echo "processing"  # 処理中
        fi
    else
        echo "working"  # 作業中（デフォルト）
    fi
}

# 正しいステータスを動的設定
force_correct_status() {
    log_status "🔄 正しいステータス動的設定開始"
    
    # PRESIDENT（常に作業中）
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ AI組織統括管理中"
    
    # 各ワーカーの実際の状況を確認して設定（ユーザー指摘準拠）
    for i in {0..3}; do
        local status_work=$(detect_status_and_work "multiagent:0.$i")
        
        case $i in
            0)
                if [[ "$status_work" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 👔BOSS1 │ チーム指示待ち"
                else
                    case $status_work in
                        "thinking") tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ 思考・回答生成中" ;;
                        "coordinating") tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ 作業調整中" ;;
                        "processing") tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ 処理中" ;;
                        *) tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ チーム管理中" ;;
                    esac
                fi
                ;;
            1)
                if [[ "$status_work" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 💻WORKER1 │ フロントエンド開発待機"
                else
                    case $status_work in
                        "thinking") tmux select-pane -t multiagent:0.$i -T "🟢作業中 💻WORKER1 │ UI設計思考中" ;;
                        "coordinating") tmux select-pane -t multiagent:0.$i -T "🟢作業中 💻WORKER1 │ フロント調整中" ;;
                        *) tmux select-pane -t multiagent:0.$i -T "🟢作業中 💻WORKER1 │ フロント開発中" ;;
                    esac
                fi
                ;;
            2)
                if [[ "$status_work" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 🔧WORKER2 │ バックエンド開発待機"
                else
                    case $status_work in
                        "thinking") tmux select-pane -t multiagent:0.$i -T "🟢作業中 🔧WORKER2 │ API設計思考中" ;;
                        "coordinating") tmux select-pane -t multiagent:0.$i -T "🟢作業中 🔧WORKER2 │ バック調整中" ;;
                        *) tmux select-pane -t multiagent:0.$i -T "🟢作業中 🔧WORKER2 │ バック開発中" ;;
                    esac
                fi
                ;;
            3)
                if [[ "$status_work" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 🎨WORKER3 │ デザイン業務待機"
                else
                    case $status_work in
                        "thinking") tmux select-pane -t multiagent:0.$i -T "🟢作業中 🎨WORKER3 │ UX設計思考中" ;;
                        "coordinating") tmux select-pane -t multiagent:0.$i -T "🟢作業中 🎨WORKER3 │ デザイン調整中" ;;
                        *) tmux select-pane -t multiagent:0.$i -T "🟢作業中 🎨WORKER3 │ デザイン業務中" ;;
                    esac
                fi
                ;;
        esac
    done
    
    log_status "✅ 正しいステータス動的設定完了"
}

# 瞬間的状態変化対応の監視システム
monitor_and_fix() {
    log_status "🔄 瞬間的変化対応監視モード開始"
    
    # 前回のステータスを記録
    declare -A last_status
    
    while true; do
        local changed=false
        
        # 全ワーカーをチェック
        for i in {0..3}; do
            local current_status=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
            
            # 前回と比較
            if [[ "${last_status[$i]}" != "$current_status" ]]; then
                log_status "変化検知 WORKER$i: ${last_status[$i]} → $current_status"
                
                # 瞬間的な「🔵作業中」への変化をチェック
                if echo "$current_status" | grep -q "🔵作業中" && ! echo "$current_status" | grep -qE "(思考・回答生成中|作業調整中|処理中)"; then
                    log_status "🚨 瞬間的状態変化検知 WORKER$i: 即座修正"
                    changed=true
                fi
                
                last_status[$i]="$current_status"
            fi
        done
        
        # 変化があった場合は即座に修正
        if $changed; then
            sleep 1  # 1秒待って確定
            force_correct_status
            log_status "✅ 瞬間的変化修正完了"
        fi
        
        sleep 2  # 2秒間隔で監視（高頻度）
    done
}

# メイン実行
case "${1:-fix}" in
    "fix")
        record_current_status
        force_correct_status
        ;;
    "monitor")
        force_correct_status
        monitor_and_fix
        ;;
    "record")
        record_current_status
        ;;
    *)
        echo "使用方法:"
        echo "  $0 fix      # 1回修正"
        echo "  $0 monitor  # 永続監視"
        echo "  $0 record   # 現状記録"
        ;;
esac