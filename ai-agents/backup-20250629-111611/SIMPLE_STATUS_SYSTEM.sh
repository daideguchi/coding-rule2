#!/bin/bash
# 🎯 シンプル・確実なステータスシステム
# デフォルト待機中・明確な作業時のみ作業中

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/simple-status.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# シンプルな動作検知（保守的アプローチ）
detect_simple_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p)
    local last_lines=$(echo "$content" | tail -5)
    
    # 明確な作業中の兆候（非常に限定的）
    if echo "$last_lines" | grep -qE "(実装中|開発中|作成中|設計中|進行中|処理中)" && 
       ! echo "$last_lines" | grep -q "> *$"; then
        echo "working"
        return
    fi
    
    # デフォルト：待機中（安全第一）
    echo "waiting"
}

# 確実なタイトル設定
set_status_title() {
    local pane="$1"
    local status="$2" 
    local role="$3"
    local task="$4"
    
    local icon="🟡待機中"
    [[ "$status" == "working" ]] && icon="🟢作業中"
    
    local title="$icon $role │ $task"
    tmux select-pane -t "$pane" -T "$title"
    
    log_status "✅ $pane: $title"
}

# 他システム完全停止
stop_all_monitors() {
    log_status "🛑 全監視システム停止"
    
    pkill -f "STATUS.*monitor" 2>/dev/null
    pkill -f "auto.*status" 2>/dev/null
    pkill -f "FINAL.*monitor" 2>/dev/null
    
    rm -f /tmp/*status*.pid
    rm -f /tmp/*monitor*.pid
    
    log_status "✅ 停止完了"
}

# メイン監視（30秒間隔）
main_simple_monitoring() {
    log_status "🚀 シンプル監視開始"
    
    while true; do
        # BOSS1
        local status0=$(detect_simple_status "multiagent:0.0")
        if [[ "$status0" == "working" ]]; then
            set_status_title "multiagent:0.0" "working" "👔BOSS1・チームリーダー" "チーム指示中"
        else
            set_status_title "multiagent:0.0" "waiting" "👔BOSS1・チームリーダー" "指示待機"
        fi
        
        # WORKER1 (ルール制御)
        local status1=$(detect_simple_status "multiagent:0.1") 
        if [[ "$status1" == "working" ]]; then
            set_status_title "multiagent:0.1" "working" "⚙️WORKER1・ルール管理者" "ルール制御中"
        else
            set_status_title "multiagent:0.1" "waiting" "⚙️WORKER1・ルール管理者" "制御待機"
        fi
        
        # WORKER2 (システム監視)
        local status2=$(detect_simple_status "multiagent:0.2")
        if [[ "$status2" == "working" ]]; then
            set_status_title "multiagent:0.2" "working" "📊WORKER2・システム監視" "監視実行中"
        else
            set_status_title "multiagent:0.2" "waiting" "📊WORKER2・システム監視" "監視待機"
        fi
        
        # WORKER3 (品質管理)
        local status3=$(detect_simple_status "multiagent:0.3")
        if [[ "$status3" == "working" ]]; then
            set_status_title "multiagent:0.3" "working" "🔍WORKER3・品質管理" "品質チェック中"
        else
            set_status_title "multiagent:0.3" "waiting" "🔍WORKER3・品質管理" "管理待機"
        fi
        
        # PRESIDENT
        local pres_status=$(detect_simple_status "president")
        if [[ "$pres_status" == "working" ]]; then
            tmux select-pane -t president -T "🟢作業中 👑PRESIDENT・最高責任者 │ 組織統括中"
        else
            tmux select-pane -t president -T "🟡待機中 👑PRESIDENT・最高責任者 │ 指示待機"
        fi
        
        sleep 30  # 30秒間隔（負荷軽減）
    done
}

# 実行制御
case "${1:-start}" in
    "start")
        stop_all_monitors
        sleep 2
        main_simple_monitoring &
        echo $! > "/tmp/simple_status.pid"
        log_status "🚀 シンプル監視開始（PID: $!）"
        ;;
    "stop")
        if [ -f "/tmp/simple_status.pid" ]; then
            kill $(cat "/tmp/simple_status.pid") 2>/dev/null
            rm -f "/tmp/simple_status.pid"
            log_status "🛑 シンプル監視停止"
        fi
        ;;
    *)
        echo "使用方法: $0 [start|stop]"
        ;;
esac