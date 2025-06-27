#!/bin/bash

# AI組織権限管理システム
# 重要操作の承認フローを管理

LOG_DIR="./ai-agents/logs"
PERMISSION_LOG="$LOG_DIR/permissions.log"
STATUS_FILE="./tmp/organization-status.json"

# ログディレクトリ作成
mkdir -p "$LOG_DIR"
mkdir -p "./tmp"

# 現在時刻取得
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ログ記録
log_action() {
    local action="$1"
    local agent="$2"
    local details="$3"
    echo "[$(timestamp)] $agent: $action - $details" >> "$PERMISSION_LOG"
}

# 組織状況初期化
init_organization_status() {
    cat > "$STATUS_FILE" << EOF
{
    "workers": {
        "worker1": {"status": "idle", "task": "", "completion": false},
        "worker2": {"status": "idle", "task": "", "completion": false},
        "worker3": {"status": "idle", "task": "", "completion": false}
    },
    "boss": {"status": "idle", "current_project": ""},
    "president": {"status": "active", "last_command": ""},
    "critical_operations": {
        "git_push": {"approved": false, "requestor": "", "timestamp": ""},
        "system_change": {"approved": false, "requestor": "", "timestamp": ""}
    }
}
EOF
}

# ワーカー状況確認
check_all_workers_ready() {
    local all_ready=true
    
    # tmuxペインの状態確認
    for i in {1..3}; do
        local pane_cmd=$(tmux list-panes -t multiagent:0.$i -F "#{pane_current_command}" 2>/dev/null)
        if [[ "$pane_cmd" != "node" ]]; then
            echo "Worker$i is not ready (status: $pane_cmd)"
            all_ready=false
        fi
    done
    
    if [[ "$all_ready" == "true" ]]; then
        echo "All workers are ready"
        return 0
    else
        echo "Not all workers are ready"
        return 1
    fi
}

# 権限チェック
check_permission() {
    local operation="$1"
    local requestor="$2"
    
    case "$operation" in
        "git_push"|"git_commit"|"system_change")
            if [[ "$requestor" != "president" ]]; then
                log_action "PERMISSION_DENIED" "$requestor" "Unauthorized $operation attempt"
                echo "ERROR: $operation requires president approval"
                return 1
            fi
            ;;
        "task_assignment")
            if [[ "$requestor" != "president" && "$requestor" != "boss" ]]; then
                log_action "PERMISSION_DENIED" "$requestor" "Unauthorized task assignment"
                echo "ERROR: Task assignment requires boss or president role"
                return 1
            fi
            ;;
    esac
    
    log_action "PERMISSION_GRANTED" "$requestor" "$operation authorized"
    return 0
}

# 重要操作承認要請
request_critical_approval() {
    local operation="$1"
    local requestor="$2"
    local details="$3"
    
    echo "=== CRITICAL OPERATION APPROVAL REQUEST ==="
    echo "Operation: $operation"
    echo "Requestor: $requestor"
    echo "Details: $details"
    echo "Time: $(timestamp)"
    echo ""
    
    # 全ワーカーの状態確認
    echo "Checking all workers status..."
    if ! check_all_workers_ready; then
        echo "REJECTED: Not all workers are ready"
        log_action "APPROVAL_REJECTED" "$requestor" "$operation - Workers not ready"
        return 1
    fi
    
    # 承認プロセス
    echo "All workers ready. Proceeding with approval process..."
    log_action "APPROVAL_REQUESTED" "$requestor" "$operation - $details"
    
    return 0
}

# 組織状況報告
report_organization_status() {
    echo "=== AI ORGANIZATION STATUS ==="
    echo "Time: $(timestamp)"
    echo ""
    
    echo "TMUX Sessions:"
    tmux list-panes -t multiagent:0 -F "Pane #{pane_index}: #{pane_current_command}" 2>/dev/null || echo "No active sessions"
    echo ""
    
    echo "Recent Permissions:"
    tail -5 "$PERMISSION_LOG" 2>/dev/null || echo "No permission logs"
    echo ""
}

# 緊急停止
emergency_stop() {
    local reason="$1"
    
    echo "=== EMERGENCY STOP ACTIVATED ==="
    echo "Reason: $reason"
    echo "Time: $(timestamp)"
    
    # 全エージェントに停止信号
    for i in {0..3}; do
        tmux send-keys -t multiagent:0.$i C-c 2>/dev/null
    done
    
    log_action "EMERGENCY_STOP" "system" "$reason"
}

# メイン処理
case "$1" in
    "init")
        init_organization_status
        echo "Organization status initialized"
        ;;
    "check-permission")
        check_permission "$2" "$3"
        ;;
    "request-approval")
        request_critical_approval "$2" "$3" "$4"
        ;;
    "status")
        report_organization_status
        ;;
    "emergency-stop")
        emergency_stop "$2"
        ;;
    "check-workers")
        check_all_workers_ready
        ;;
    *)
        echo "Usage: $0 {init|check-permission|request-approval|status|emergency-stop|check-workers}"
        echo "  init                 - Initialize organization status"
        echo "  check-permission OP AGENT - Check if AGENT can perform OP"
        echo "  request-approval OP AGENT DETAILS - Request approval for critical operation"
        echo "  status               - Show organization status"
        echo "  emergency-stop REASON - Emergency stop all agents"
        echo "  check-workers        - Check if all workers are ready"
        exit 1
        ;;
esac