#!/bin/bash
# 🔄 信頼性の高い自動ステータス切り替えシステム
# 作成日: 2025-06-29
# 目的: 確実な自動状態検知と切り替え保証

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/auto-status-reliable.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_reliable() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 確実な状態検知
detect_status_reliable() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p)
    local last_line=$(echo "$content" | tail -1)
    
    # 空白行 = 待機中
    if [[ -z "$last_line" ]]; then
        echo "waiting"
        return
    fi
    
    # > プロンプト = 待機中
    if echo "$last_line" | grep -q "> *$"; then
        echo "waiting"
        return
    fi
    
    # Bypassing Permissions = 待機中
    if echo "$content" | grep -q "Bypassing Permissions" && echo "$last_line" | grep -q "> *$"; then
        echo "waiting"
        return
    fi
    
    # 具体的な作業表示 = 作業中
    if echo "$content" | grep -qE "(Processing|Loading|Thinking|⏺|了解|承知|確認|実行|開発|設計|作成)"; then
        echo "working"
        return
    fi
    
    # デフォルト: 待機中（安全側）
    echo "waiting"
}

# 役職と作業内容の更新
update_status_with_role() {
    local worker_id="$1"
    local status="$2"
    
    local role=""
    local task=""
    
    case $worker_id in
        0)
            role="👔BOSS1・チームリーダー"
            if [[ "$status" == "working" ]]; then
                task="チーム統括中"
            else
                task="チーム指示待ち"
            fi
            ;;
        1)
            role="💻WORKER1・フロントエンド"
            if [[ "$status" == "working" ]]; then
                task="フロント開発中"
            else
                task="開発待機中"
            fi
            ;;
        2)
            role="🔧WORKER2・バックエンド"
            if [[ "$status" == "working" ]]; then
                task="バック開発中"
            else
                task="開発待機中"
            fi
            ;;
        3)
            role="🎨WORKER3・デザイナー"
            if [[ "$status" == "working" ]]; then
                task="デザイン作業中"
            else
                task="デザイン待機中"
            fi
            ;;
    esac
    
    local status_icon=""
    if [[ "$status" == "working" ]]; then
        status_icon="🟢作業中"
    else
        status_icon="🟡待機中"
    fi
    
    local title="$status_icon $role │ $task"
    tmux select-pane -t "multiagent:0.$worker_id" -T "$title"
    
    log_reliable "✅ WORKER$worker_id: $title"
}

# 信頼性の高い監視ループ
reliable_monitoring_loop() {
    log_reliable "🔄 信頼性監視システム開始"
    
    while true; do
        for i in {0..3}; do
            local current_status=$(detect_status_reliable "multiagent:0.$i")
            update_status_with_role "$i" "$current_status"
        done
        
        # PRESIDENT も更新
        local president_status=$(detect_status_reliable "president")
        if [[ "$president_status" == "working" ]]; then
            tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ 組織統括中"
        else
            tmux select-pane -t president -T "🟡待機中 👑PRESIDENT │ 組織統括待機"
        fi
        
        sleep 10  # 10秒間隔で確実に更新
    done
}

# ヘルスチェック機能
health_check() {
    log_reliable "🩺 システムヘルスチェック"
    
    # tmux セッション確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_reliable "❌ multiagent セッション未発見"
        return 1
    fi
    
    if ! tmux has-session -t president 2>/dev/null; then
        log_reliable "❌ president セッション未発見"
        return 1
    fi
    
    # ペイン確認
    for i in {0..3}; do
        if ! tmux list-panes -t "multiagent:0.$i" >/dev/null 2>&1; then
            log_reliable "❌ WORKER$i ペイン未発見"
            return 1
        fi
    done
    
    log_reliable "✅ システムヘルスチェック正常"
    return 0
}

# メイン実行
case "${1:-monitor}" in
    "start"|"monitor")
        if health_check; then
            # 初期状態設定
            for i in {0..3}; do
                local initial_status=$(detect_status_reliable "multiagent:0.$i")
                update_status_with_role "$i" "$initial_status"
            done
            
            # バックグラウンドで監視開始
            reliable_monitoring_loop &
            echo $! > "/tmp/auto_status_reliable.pid"
            log_reliable "🚀 信頼性監視システム開始（PID: $!）"
        else
            log_reliable "❌ ヘルスチェック失敗 - 開始中止"
            exit 1
        fi
        ;;
    "stop")
        if [ -f "/tmp/auto_status_reliable.pid" ]; then
            kill $(cat "/tmp/auto_status_reliable.pid") 2>/dev/null
            rm -f "/tmp/auto_status_reliable.pid"
            log_reliable "🛑 信頼性監視システム停止"
        fi
        ;;
    "status")
        for i in {0..3}; do
            local current_status=$(detect_status_reliable "multiagent:0.$i")
            echo "WORKER$i: $current_status"
        done
        ;;
    *)
        echo "使用方法:"
        echo "  $0 start/monitor  # 監視開始（デフォルト）"
        echo "  $0 stop           # 監視停止"
        echo "  $0 status         # 現在状態確認"
        ;;
esac