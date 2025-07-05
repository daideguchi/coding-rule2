#!/bin/bash
# 🏆 最終版ステータス監視システム
# 競合を排除した確実なシステム

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/status-final.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_final() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 他の監視システムを完全停止
stop_all_other_monitors() {
    log_final "🛑 他の監視システム完全停止"
    
    # 実行中の監視プロセス全停止
    pkill -f "STATUS.*monitor" 2>/dev/null
    pkill -f "ULTIMATE.*monitor" 2>/dev/null
    pkill -f "auto.*status" 2>/dev/null
    
    # PIDファイル削除
    rm -f /tmp/*status*.pid
    rm -f /tmp/*monitor*.pid
    
    log_final "✅ 他システム停止完了"
}

# 確実な状態検知
detect_actual_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p)
    local last_line=$(echo "$content" | tail -1)
    
    # 作業中の確実な兆候
    if echo "$content" | grep -qE "(⏺|了解|承知|開始|実装|設計|作成)"; then
        echo "working"
        return
    fi
    
    # 空白または > = 待機中
    if [[ -z "$last_line" ]] || echo "$last_line" | grep -q "> *$"; then
        echo "waiting"
        return
    fi
    
    # デフォルト：待機中
    echo "waiting"
}

# 個別ペインへの確実なタイトル設定
set_individual_title() {
    local pane_id="$1"
    local status="$2"
    local role="$3"
    local task="$4"
    
    local status_icon=""
    if [[ "$status" == "working" ]]; then
        status_icon="🟢作業中"
    else
        status_icon="🟡待機中"
    fi
    
    local title="$status_icon $role │ $task"
    tmux select-pane -t "$pane_id" -T "$title"
    
    log_final "✅ $pane_id: $title"
}

# メイン監視ループ
main_monitoring_loop() {
    log_final "🔄 最終版監視システム開始"
    
    while true; do
        # WORKER0 (BOSS1)
        local status0=$(detect_actual_status "multiagent:0.0")
        if [[ "$status0" == "working" ]]; then
            set_individual_title "multiagent:0.0" "working" "👔BOSS1・チームリーダー" "開発指示中"
        else
            set_individual_title "multiagent:0.0" "waiting" "👔BOSS1・チームリーダー" "開発指示待ち"
        fi
        
        # WORKER1 (FE)
        local status1=$(detect_actual_status "multiagent:0.1")
        if [[ "$status1" == "working" ]]; then
            set_individual_title "multiagent:0.1" "working" "💻WORKER1・FEエンジニア" "フロント開発中"
        else
            set_individual_title "multiagent:0.1" "waiting" "💻WORKER1・FEエンジニア" "フロント開発待機"
        fi
        
        # WORKER2 (BE)
        local status2=$(detect_actual_status "multiagent:0.2")
        if [[ "$status2" == "working" ]]; then
            set_individual_title "multiagent:0.2" "working" "🔧WORKER2・BEエンジニア" "バック開発中"
        else
            set_individual_title "multiagent:0.2" "waiting" "🔧WORKER2・BEエンジニア" "バック開発待機"
        fi
        
        # WORKER3 (Designer)
        local status3=$(detect_actual_status "multiagent:0.3")
        if [[ "$status3" == "working" ]]; then
            set_individual_title "multiagent:0.3" "working" "🎨WORKER3・UI/UXデザイナー" "デザイン中"
        else
            set_individual_title "multiagent:0.3" "waiting" "🎨WORKER3・UI/UXデザイナー" "デザイン待機"
        fi
        
        # PRESIDENT
        local president_status=$(detect_actual_status "president")
        if [[ "$president_status" == "working" ]]; then
            tmux select-pane -t president -T "🟢作業中 👑PRESIDENT・最高責任者 │ 組織統括中"
        else
            tmux select-pane -t president -T "🟡待機中 👑PRESIDENT・最高責任者 │ 指示待ち"
        fi
        
        sleep 15  # 15秒間隔で更新
    done
}

# メイン実行
case "${1:-start}" in
    "start")
        stop_all_other_monitors
        main_monitoring_loop &
        echo $! > "/tmp/status_final.pid"
        log_final "🚀 最終版監視システム開始（PID: $!）"
        ;;
    "stop")
        if [ -f "/tmp/status_final.pid" ]; then
            kill $(cat "/tmp/status_final.pid") 2>/dev/null
            rm -f "/tmp/status_final.pid"
            log_final "🛑 最終版監視システム停止"
        fi
        ;;
    *)
        echo "使用方法:"
        echo "  $0 start  # 監視開始"
        echo "  $0 stop   # 監視停止"
        ;;
esac