#!/bin/bash

# 🔄 動的ステータス監視システム
# 自動的にワーカーの状態を監視し、ステータスバーを更新

# ログファイル設定
LOG_FILE="/tmp/dynamic-status-monitor.log"
PID_FILE="/tmp/dynamic-status-monitor.pid"

# ログ関数
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$LOG_FILE"
}

# プロセス管理
start_monitor() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log_info "動的ステータス監視システムは既に稼働中です"
        return 0
    fi
    
    log_info "🔄 動的ステータス監視システム開始"
    
    # バックグラウンドで監視開始
    monitor_loop &
    MONITOR_PID=$!
    echo $MONITOR_PID > "$PID_FILE"
    
    log_info "監視システムPID: $MONITOR_PID"
}

stop_monitor() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            log_info "動的ステータス監視システムを停止しました (PID: $PID)"
        fi
        rm -f "$PID_FILE"
    else
        log_info "動的ステータス監視システムは稼働していません"
    fi
}

# メイン監視ループ
monitor_loop() {
    while true; do
        check_and_update_status
        sleep 5  # 5秒間隔で監視
    done
}

# ステータスチェックと更新
check_and_update_status() {
    # 各ペインの活動状況をチェック
    for i in {0..3}; do
        local pane_target=""
        local worker_name=""
        
        case $i in
            0) pane_target="leader"; worker_name="BOSS1" ;;
            1) pane_target="1"; worker_name="WORKER1" ;;
            2) pane_target="2"; worker_name="WORKER2" ;;
            3) pane_target="3"; worker_name="WORKER3" ;;
        esac
        
        # tmuxペインの存在確認
        if tmux has-session -t multiagent 2>/dev/null && tmux list-panes -t multiagent:0 2>/dev/null | grep -q "0\.$i:"; then
            # ペインの最新出力を取得
            local recent_output
            recent_output=$(tmux capture-pane -t multiagent:0.$i -p -S -10 2>/dev/null | tail -5)
            
            # アクティビティの検出（Claude Codeの応答、入力など）
            if echo "$recent_output" | grep -qE "(Thinking|Working|Processing|claude|>|$|cwd:)" 2>/dev/null; then
                # アクティブな場合は🔵作業中に設定
                set_working_status_if_needed "$pane_target" "$worker_name"
            else
                # 非アクティブな場合は🟡待機中に設定
                set_waiting_status_if_needed "$pane_target" "$worker_name"
            fi
        fi
    done
    
    # PRESIDENTも監視
    if tmux has-session -t president 2>/dev/null; then
        local recent_output
        recent_output=$(tmux capture-pane -t president:0 -p -S -10 2>/dev/null | tail -5)
        
        if echo "$recent_output" | grep -qE "(Thinking|Working|Processing|claude|>|$|cwd:)" 2>/dev/null; then
            set_working_status_if_needed "president" "PRESIDENT"
        else
            set_waiting_status_if_needed "president" "PRESIDENT"
        fi
    fi
}

# 必要な場合のみ作業中ステータスに変更
set_working_status_if_needed() {
    local pane_target="$1"
    local worker_name="$2"
    
    # 現在のステータスを取得
    local current_title=""
    case "$pane_target" in
        "president")
            current_title=$(tmux display-message -t president:0 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "leader")
            current_title=$(tmux display-message -t multiagent:0.0 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "1")
            current_title=$(tmux display-message -t multiagent:0.1 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "2")
            current_title=$(tmux display-message -t multiagent:0.2 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "3")
            current_title=$(tmux display-message -t multiagent:0.3 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
    esac
    
    # 既に🔵作業中でない場合のみ変更
    if [[ "$current_title" != *"🔵作業中"* ]]; then
        ./ai-agents/scripts/automation/core/fixed-status-bar-init.sh work "$pane_target" "$worker_name" >/dev/null 2>&1
    fi
}

# 必要な場合のみ待機中ステータスに変更
set_waiting_status_if_needed() {
    local pane_target="$1"
    local worker_name="$2"
    
    # 現在のステータスを取得
    local current_title=""
    case "$pane_target" in
        "president")
            current_title=$(tmux display-message -t president:0 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "leader")
            current_title=$(tmux display-message -t multiagent:0.0 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "1")
            current_title=$(tmux display-message -t multiagent:0.1 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "2")
            current_title=$(tmux display-message -t multiagent:0.2 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
        "3")
            current_title=$(tmux display-message -t multiagent:0.3 -p "#{pane_title}" 2>/dev/null || echo "")
            ;;
    esac
    
    # 既に🟡待機中でない場合のみ変更
    if [[ "$current_title" != *"🟡待機中"* ]]; then
        ./ai-agents/scripts/automation/core/fixed-status-bar-init.sh wait "$pane_target" "$worker_name" >/dev/null 2>&1
    fi
}

# ステータス確認
status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log_info "動的ステータス監視システム: 稼働中 (PID: $(cat $PID_FILE))"
    else
        log_info "動的ステータス監視システム: 停止中"
    fi
    
    # 現在のステータスバー状況も表示
    ./ai-agents/scripts/automation/core/fixed-status-bar-init.sh check
}

# 使用方法
case "$1" in
    "start")
        start_monitor
        ;;
    "stop")
        stop_monitor
        ;;
    "restart")
        stop_monitor
        sleep 1
        start_monitor
        ;;
    "status")
        status
        ;;
    *)
        echo "🔄 動的ステータス監視システム"
        echo ""
        echo "使用方法:"
        echo "  $0 start    # 監視開始"
        echo "  $0 stop     # 監視停止"
        echo "  $0 restart  # 監視再起動"
        echo "  $0 status   # 状況確認"
        echo ""
        echo "機能:"
        echo "  - 5秒間隔でワーカーの活動を監視"
        echo "  - アクティブ時に🔵作業中に自動変更"
        echo "  - 非アクティブ時に🟡待機中に自動変更"
        echo "  - 重複更新を回避（効率化）"
        ;;
esac