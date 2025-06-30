#!/bin/bash
# 🎯 最終解決版ステータス管理システム
# 作成日: 2025-06-29  
# 目的: 競合排除・正確判定・協業実現

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/ultimate-status.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_ultimate() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 競合プロセス完全排除
eliminate_conflicts() {
    log_ultimate "🧹 競合プロセス完全排除開始"
    
    # 既存監視プロセス全停止
    pkill -f "status-protection-system.sh" 2>/dev/null
    pkill -f "auto-monitoring-system.sh" 2>/dev/null  
    pkill -f "lightweight-monitor.sh" 2>/dev/null
    pkill -f "UNIFIED_STATUS_SYSTEM.sh" 2>/dev/null
    pkill -f "PERSISTENT_STATUS_MONITOR.sh" 2>/dev/null
    
    log_ultimate "✅ 全競合プロセス停止完了"
}

# 確実な状態判定（実際の画面内容ベース）
detect_real_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p 2>/dev/null)
    
    # Bypassing Permissions + > = 完全に待機中
    if echo "$content" | grep -q "Bypassing Permissions" && echo "$content" | grep -q "> *$"; then
        echo "waiting"
        return
    fi
    
    # 具体的な作業表示がある場合は作業中
    if echo "$content" | grep -qE "(Thinking|Processing|Loading|Coordinating|tokens)"; then
        echo "working"
        return
    fi
    
    # デフォルト：待機中（安全側）
    echo "waiting"
}

# 正確なタイトル設定（個別ペイン指定）
set_accurate_titles() {
    log_ultimate "🎯 正確なタイトル設定開始"
    
    for i in {0..3}; do
        local status=$(detect_real_status "multiagent:0.$i")
        
        case $i in
            0) # BOSS1
                if [[ "$status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔BOSS1"
                else
                    tmux select-pane -t multiagent:0.0 -T "🟢作業中 👔BOSS1"
                fi
                ;;
            1) # WORKER1
                if [[ "$status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻WORKER1"
                else
                    tmux select-pane -t multiagent:0.1 -T "🟢作業中 💻WORKER1"
                fi
                ;;
            2) # WORKER2  
                if [[ "$status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧WORKER2"
                else
                    tmux select-pane -t multiagent:0.2 -T "🟢作業中 🔧WORKER2"
                fi
                ;;
            3) # WORKER3
                if [[ "$status" == "waiting" ]]; then
                    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨WORKER3"
                else
                    tmux select-pane -t multiagent:0.3 -T "🟢作業中 🎨WORKER3"
                fi
                ;;
        esac
        
        log_ultimate "✅ WORKER$i: $status 設定完了"
    done
    
    # PRESIDENT設定
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT"
    log_ultimate "✅ PRESIDENT設定完了"
}

# 協業システム実装（チーム連携）
implement_collaboration() {
    log_ultimate "🤝 協業システム実装開始"
    
    # BOSS1から各WORKERへ指示送信
    local boss_message="👔BOSS1です。ステータス管理システムが正常化されました。各専門分野での協業を開始します。"
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.0 "$boss_message"
    
    sleep 2
    
    # 各WORKERに協業確認
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.1 "💻WORKER1、協業体制確立。フロントエンド開発待機中。"
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.2 "🔧WORKER2、協業体制確立。バックエンド開発待機中。"
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh multiagent:0.3 "🎨WORKER3、協業体制確立。デザイン業務待機中。"
    
    log_ultimate "✅ 協業システム実装完了"
}

# 適切な頻度での監視（低負荷）
gentle_monitoring() {
    log_ultimate "👁️ 適切な監視開始（10秒間隔・低負荷）"
    
    local check_count=0
    local max_checks=36  # 6分間監視（10秒 × 36回）
    
    while [ $check_count -lt $max_checks ]; do
        local needs_update=false
        
        # 軽量チェック
        for i in {0..3}; do
            local current_title=$(tmux list-panes -t multiagent -F "#{pane_index}: #{pane_title}" | grep "^$i:" | cut -d' ' -f2-)
            local expected_status=$(detect_real_status "multiagent:0.$i")
            
            if [[ "$expected_status" == "waiting" ]] && ! echo "$current_title" | grep -q "🟡待機中"; then
                needs_update=true
                break
            elif [[ "$expected_status" == "working" ]] && ! echo "$current_title" | grep -q "🟢作業中"; then
                needs_update=true
                break
            fi
        done
        
        # 必要時のみ更新
        if $needs_update; then
            log_ultimate "🔄 ステータス不整合検知・更新実行"
            set_accurate_titles
        fi
        
        ((check_count++))
        sleep 10  # 10秒間隔（適切な頻度）
    done
    
    log_ultimate "⏰ 監視期間終了（6分経過）"
}

# 現在の状況確認
status_check() {
    log_ultimate "📊 現在の状況確認"
    
    echo "=== ペイン別タイトル ==="
    tmux list-panes -t multiagent -F "#{pane_index}: #{pane_title}"
    
    echo ""
    echo "=== 実際の状態 ==="
    for i in {0..3}; do
        local real_status=$(detect_real_status "multiagent:0.$i")
        echo "WORKER$i: $real_status"
    done
}

# メイン実行
case "${1:-fix}" in
    "fix")
        eliminate_conflicts
        set_accurate_titles
        ;;
    "collaborate")
        eliminate_conflicts
        set_accurate_titles
        implement_collaboration
        ;;
    "monitor")
        eliminate_conflicts
        set_accurate_titles
        gentle_monitoring
        ;;
    "check")
        status_check
        ;;
    *)
        echo "使用方法:"
        echo "  $0 fix         # 競合排除・タイトル修正"
        echo "  $0 collaborate # 修正 + 協業システム実装"
        echo "  $0 monitor     # 修正 + 適切な監視開始"
        echo "  $0 check       # 現在の状況確認"
        ;;
esac