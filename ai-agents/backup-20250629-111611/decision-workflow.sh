#!/bin/bash

# AI組織意思決定ワークフロー
# 標準化された意思決定プロセスを実行

WORKFLOW_LOG="./ai-agents/logs/decision-workflow.log"
PERMISSION_MANAGER="./ai-agents/permission-manager.sh"

# ログ記録
log_workflow() {
    local step="$1"
    local status="$2"
    local details="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $step: $status - $details" >> "$WORKFLOW_LOG"
}

# 重要操作の意思決定フロー
critical_operation_workflow() {
    local operation="$1"
    local details="$2"
    
    echo "=== 重要操作意思決定フロー開始 ==="
    echo "操作: $operation"
    echo "詳細: $details"
    echo ""
    
    log_workflow "CRITICAL_WORKFLOW_START" "INITIATED" "$operation - $details"
    
    # ステップ1: 権限チェック
    echo "ステップ1: 権限チェック..."
    if ! $PERMISSION_MANAGER check-permission "$operation" "president"; then
        log_workflow "PERMISSION_CHECK" "FAILED" "Insufficient permissions"
        return 1
    fi
    log_workflow "PERMISSION_CHECK" "PASSED" "President has required permissions"
    
    # ステップ2: 全ワーカー状況確認
    echo "ステップ2: 全ワーカー状況確認..."
    if ! $PERMISSION_MANAGER check-workers; then
        log_workflow "WORKER_CHECK" "FAILED" "Not all workers ready"
        echo "エラー: 全ワーカーが準備完了していません"
        return 1
    fi
    log_workflow "WORKER_CHECK" "PASSED" "All workers ready"
    
    # ステップ3: ワーカー意見収集
    echo "ステップ3: ワーカー意見収集..."
    collect_worker_opinions "$operation" "$details"
    
    # ステップ4: BOSS判断要請
    echo "ステップ4: BOSS判断要請..."
    request_boss_decision "$operation" "$details"
    
    # ステップ5: 最終承認確認
    echo "ステップ5: 最終承認確認..."
    echo "プレジデントとして最終承認しますか？ (y/n)"
    read -r approval
    
    if [[ "$approval" == "y" || "$approval" == "Y" ]]; then
        log_workflow "FINAL_APPROVAL" "APPROVED" "President approved $operation"
        echo "承認されました。操作を実行します。"
        return 0
    else
        log_workflow "FINAL_APPROVAL" "REJECTED" "President rejected $operation"
        echo "操作が拒否されました。"
        return 1
    fi
}

# ワーカー意見収集
collect_worker_opinions() {
    local operation="$1"
    local details="$2"
    
    echo "=== ワーカー意見収集 ==="
    
    for i in {1..3}; do
        echo "Worker$i に意見を要請中..."
        tmux send-keys -t multiagent:0.$i ">Worker$i として、以下の操作について意見を述べてください: $operation ($details)" C-m
        log_workflow "WORKER_OPINION_REQUEST" "SENT" "Worker$i opinion requested"
        
        # 応答待ち時間
        sleep 2
    done
    
    echo "全ワーカーに意見要請を送信しました。"
    echo "各ワーカーの応答を確認してください。"
}

# BOSS判断要請
request_boss_decision() {
    local operation="$1"
    local details="$2"
    
    echo "=== BOSS判断要請 ==="
    
    local boss_instruction=">BOSS1として、以下について総合判断してください:
    
操作: $operation
詳細: $details

全ワーカーの意見を確認し、この操作を実行すべきか判断してください。
ただし、実行はせず、判断結果のみを報告してください。"
    
    tmux send-keys -t multiagent:0.0 "$boss_instruction" C-m
    log_workflow "BOSS_DECISION_REQUEST" "SENT" "Boss decision requested for $operation"
    
    echo "BOSS1に判断要請を送信しました。"
    echo "判断結果を待機してください。"
}

# 一般タスクの意思決定フロー
general_task_workflow() {
    local task="$1"
    local assignment="$2"
    
    echo "=== 一般タスク意思決定フロー ==="
    echo "タスク: $task"
    echo "割り当て: $assignment"
    
    log_workflow "GENERAL_TASK_START" "INITIATED" "$task - $assignment"
    
    # 権限チェック
    if ! $PERMISSION_MANAGER check-permission "task_assignment" "president"; then
        log_workflow "TASK_PERMISSION" "FAILED" "Insufficient permissions for task assignment"
        return 1
    fi
    
    # BOSS経由でタスク割り当て
    local task_instruction=">BOSS1として、以下のタスクをワーカーに割り当ててください:
    
タスク: $task
詳細: $assignment

適切なワーカーを選択し、明確な指示を出してください。"
    
    tmux send-keys -t multiagent:0.0 "$task_instruction" C-m
    log_workflow "TASK_ASSIGNMENT" "SENT" "Task assigned via BOSS1"
    
    echo "BOSS1経由でタスクを割り当てました。"
    return 0
}

# 組織状況監視
monitor_organization() {
    echo "=== 組織状況監視 ==="
    
    # permission-manager.shを使用して状況確認
    $PERMISSION_MANAGER status
    
    # 最近のワークフローログ
    echo ""
    echo "最近のワークフロー:"
    tail -10 "$WORKFLOW_LOG" 2>/dev/null || echo "ワークフローログなし"
}

# 緊急事態対応
emergency_response() {
    local reason="$1"
    
    echo "=== 緊急事態対応 ==="
    echo "理由: $reason"
    
    log_workflow "EMERGENCY_RESPONSE" "ACTIVATED" "$reason"
    
    # 緊急停止実行
    $PERMISSION_MANAGER emergency-stop "$reason"
    
    echo "緊急停止を実行しました。"
    echo "原因を調査し、適切な対処を行ってください。"
}

# メイン処理
case "$1" in
    "critical")
        critical_operation_workflow "$2" "$3"
        ;;
    "task")
        general_task_workflow "$2" "$3"
        ;;
    "monitor")
        monitor_organization
        ;;
    "emergency")
        emergency_response "$2"
        ;;
    *)
        echo "Usage: $0 {critical|task|monitor|emergency}"
        echo "  critical OP DETAILS  - Execute critical operation workflow"
        echo "  task TASK ASSIGNMENT - Execute general task workflow"
        echo "  monitor             - Monitor organization status"
        echo "  emergency REASON    - Emergency response"
        exit 1
        ;;
esac