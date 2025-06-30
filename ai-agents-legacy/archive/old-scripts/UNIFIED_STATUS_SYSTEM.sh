#!/bin/bash
# 🔥 統一ステータス管理システム - 協業対応版
# 作成日: 2025-06-29
# 目的: ステータス混乱を完全排除し、真の協業システムを構築

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/unified-status.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_unified() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 🚨 緊急問題: ステータス混乱の根本原因分析
analyze_status_chaos() {
    log_unified "🔍 ステータス混乱の根本原因分析開始"
    
    # 全ワーカーの現在状況を詳細確認
    for i in {0..3}; do
        log_unified "=== WORKER$i 詳細分析 ==="
        
        # 現在のタイトル
        local current_title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        log_unified "現在のタイトル: $current_title"
        
        # 画面内容の最終行
        local last_line=$(tmux capture-pane -t "multiagent:0.$i" -p | tail -1 2>/dev/null || echo "ERROR")
        log_unified "最終行内容: $last_line"
        
        # Bypassing Permissions確認
        local bp_status=$(tmux capture-pane -t "multiagent:0.$i" -p | grep "Bypassing Permissions" | wc -l)
        log_unified "Bypassing Permissions行数: $bp_status"
        
        # プロンプト状態確認
        local prompt_check=$(tmux capture-pane -t "multiagent:0.$i" -p | grep -E "(> |>\s*$)" | wc -l)
        log_unified "プロンプト待ち状態: $prompt_check"
        
        log_unified "---"
    done
}

# 🎯 正確なステータス判定（完全修正版）
detect_accurate_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
    
    # 最終行のプロンプト状態を確認
    local last_line=$(echo "$content" | tail -1)
    
    # 確実な待機中判定: プロンプト「>」で終わっている
    if echo "$last_line" | grep -E "> *$" >/dev/null; then
        echo "waiting"
        return
    fi
    
    # 確実な作業中判定: 具体的な処理表示
    if echo "$content" | grep -qE "(Coordinating.*tokens|· .*tokens|Loading|Processing|Computing|Thinking)"; then
        if echo "$content" | grep -q "tokens"; then
            echo "thinking"
        elif echo "$content" | grep -q "Coordinating"; then
            echo "coordinating"
        else
            echo "processing"
        fi
        return
    fi
    
    # デフォルト: 安全に待機中判定
    echo "waiting"
}

# 🔧 統一ステータス設定（絶対に混乱させない）
unified_status_set() {
    log_unified "🔧 統一ステータス設定開始"
    
    # PRESIDENT（常に🟢作業中）
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ AI組織統括管理中"
    log_unified "✅ PRESIDENT設定完了: 🟢作業中"
    
    # 各ワーカーの確実な判定と設定
    for i in {0..3}; do
        local accurate_status=$(detect_accurate_status "multiagent:0.$i")
        
        case $i in
            0) # BOSS1
                if [[ "$accurate_status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 👔BOSS1 │ チーム指示待ち"
                    log_unified "✅ BOSS1設定完了: 🟡待機中"
                else
                    case $accurate_status in
                        "thinking")
                            tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ 思考・回答生成中"
                            log_unified "✅ BOSS1設定完了: 🟢作業中（思考中）"
                            ;;
                        *)
                            tmux select-pane -t multiagent:0.$i -T "🟢作業中 👔BOSS1 │ チーム管理中"
                            log_unified "✅ BOSS1設定完了: 🟢作業中（管理中）"
                            ;;
                    esac
                fi
                ;;
            1) # WORKER1
                if [[ "$accurate_status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 💻WORKER1 │ フロントエンド開発待機"
                    log_unified "✅ WORKER1設定完了: 🟡待機中"
                else
                    tmux select-pane -t multiagent:0.$i -T "🟢作業中 💻WORKER1 │ フロント開発中"
                    log_unified "✅ WORKER1設定完了: 🟢作業中"
                fi
                ;;
            2) # WORKER2
                if [[ "$accurate_status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 🔧WORKER2 │ バックエンド開発待機"
                    log_unified "✅ WORKER2設定完了: 🟡待機中"
                else
                    tmux select-pane -t multiagent:0.$i -T "🟢作業中 🔧WORKER2 │ バック開発中"
                    log_unified "✅ WORKER2設定完了: 🟢作業中"
                fi
                ;;
            3) # WORKER3
                if [[ "$accurate_status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.$i -T "🟡待機中 🎨WORKER3 │ デザイン業務待機"
                    log_unified "✅ WORKER3設定完了: 🟡待機中"
                else
                    tmux select-pane -t multiagent:0.$i -T "🟢作業中 🎨WORKER3 │ デザイン業務中"
                    log_unified "✅ WORKER3設定完了: 🟢作業中"
                fi
                ;;
        esac
    done
    
    log_unified "🎯 統一ステータス設定完了"
}

# 🤝 協業システム構築
build_collaboration_system() {
    log_unified "🤝 協業システム構築開始"
    
    # 1. BOSS1に協業指示を送信
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.0 "👔BOSS1です。協業システム構築中。各WORKERとの連携体制を確立し、効率的なチーム運営を開始します。ステータス管理を徹底し、PRESDENTに状況報告します。"
    
    # 2. WORKER1に役職確認
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.1 "💻WORKER1です。フロントエンド開発専門として、BOSS1の指示に従い、チーム協業を行います。現在待機中、指示お待ちしております。"
    
    # 3. WORKER2に役職確認
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.2 "🔧WORKER2です。バックエンド開発専門として、BOSS1の指示に従い、チーム協業を行います。現在待機中、指示お待ちしております。"
    
    # 4. WORKER3に役職確認
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.3 "🎨WORKER3です。UI/UXデザイン専門として、BOSS1の指示に従い、チーム協業を行います。現在待機中、指示お待ちしております。"
    
    log_unified "✅ 協業システム構築完了"
}

# 🔄 永続的協業監視システム
permanent_collaboration_monitor() {
    log_unified "🔄 永続的協業監視システム開始"
    
    while true; do
        # ステータス混乱検知
        local chaos_detected=false
        
        for i in {0..3}; do
            local current_title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "")
            
            # 🔵の混入チェック
            if echo "$current_title" | grep -q "🔵"; then
                log_unified "🚨 🔵混入検知 WORKER$i: $current_title"
                chaos_detected=true
            fi
            
            # 不正な作業中表示チェック（実際は待機中なのに🟢表示）
            if echo "$current_title" | grep -q "🟢作業中"; then
                local actual_status=$(detect_accurate_status "multiagent:0.$i")
                if [[ "$actual_status" == "waiting" ]]; then
                    log_unified "🚨 不正作業中表示検知 WORKER$i: 実際は待機中"
                    chaos_detected=true
                fi
            fi
        done
        
        # 混乱が検知された場合は即座修正
        if $chaos_detected; then
            log_unified "🔧 ステータス混乱修正実行"
            unified_status_set
            log_unified "✅ ステータス混乱修正完了"
        fi
        
        sleep 3  # 3秒間隔で監視
    done
}

# メイン実行
case "${1:-fix}" in
    "analyze")
        analyze_status_chaos
        ;;
    "fix")
        analyze_status_chaos
        unified_status_set
        ;;
    "collaborate")
        unified_status_set
        build_collaboration_system
        ;;
    "monitor")
        unified_status_set
        permanent_collaboration_monitor
        ;;
    *)
        echo "使用方法:"
        echo "  $0 analyze      # 問題分析"
        echo "  $0 fix          # 統一修正"
        echo "  $0 collaborate  # 協業構築"
        echo "  $0 monitor      # 永続監視"
        ;;
esac