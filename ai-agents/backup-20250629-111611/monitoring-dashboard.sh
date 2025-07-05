#!/bin/bash

# AI組織監視ダッシュボード
# リアルタイム監視と報告システム

DASHBOARD_LOG="./ai-agents/logs/dashboard.log"
STATUS_DIR="./tmp/status"
ALERT_LOG="./ai-agents/logs/alerts.log"

# 初期化
mkdir -p "./ai-agents/logs"
mkdir -p "$STATUS_DIR"

# 時刻取得
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ログ記録
log_dashboard() {
    local level="$1"
    local message="$2"
    echo "[$(timestamp)] [$level] $message" >> "$DASHBOARD_LOG"
}

# アラート発行
send_alert() {
    local level="$1"
    local agent="$2"
    local message="$3"
    
    local alert="[$(timestamp)] ALERT[$level] $agent: $message"
    echo "$alert" >> "$ALERT_LOG"
    echo "$alert"
    
    # 重要なアラートの場合は緊急通知
    if [[ "$level" == "CRITICAL" ]]; then
        echo "🚨 CRITICAL ALERT 🚨"
        echo "$alert"
        # 必要に応じて緊急停止
        if [[ "$message" == *"unauthorized"* ]]; then
            ./ai-agents/permission-manager.sh emergency-stop "Unauthorized activity detected"
        fi
    fi
}

# エージェント状態取得
get_agent_status() {
    local pane="$1"
    local agent_name="$2"
    
    # tmuxペインの状態確認
    local pane_cmd=$(tmux list-panes -t multiagent:0.$pane -F "#{pane_current_command}" 2>/dev/null)
    local pane_active=$(tmux list-panes -t multiagent:0.$pane -F "#{?pane_active,ACTIVE,INACTIVE}" 2>/dev/null)
    
    if [[ -z "$pane_cmd" ]]; then
        echo "$agent_name: OFFLINE"
        return 1
    else
        echo "$agent_name: $pane_cmd ($pane_active)"
        return 0
    fi
}

# 全エージェント監視
monitor_all_agents() {
    echo "=== AI組織監視ダッシュボード ==="
    echo "監視時刻: $(timestamp)"
    echo ""
    
    local all_healthy=true
    
    # 各エージェントの状態確認
    echo "エージェント状態:"
    
    # BOSS (pane 0)
    if ! get_agent_status 0 "BOSS1"; then
        send_alert "HIGH" "BOSS1" "Agent offline or unresponsive"
        all_healthy=false
    fi
    
    # Workers (panes 1-3)
    for i in {1..3}; do
        if ! get_agent_status $i "WORKER$i"; then
            send_alert "MEDIUM" "WORKER$i" "Agent offline or unresponsive"
            all_healthy=false
        fi
    done
    
    echo ""
    
    # システム健全性
    if [[ "$all_healthy" == "true" ]]; then
        echo "✅ システム健全性: 良好"
        log_dashboard "INFO" "All agents healthy"
    else
        echo "⚠️  システム健全性: 問題あり"
        log_dashboard "WARNING" "Some agents unhealthy"
    fi
    
    echo ""
}

# 活動監視
monitor_activity() {
    echo "=== 活動監視 ==="
    
    # 最近の権限ログ
    echo "最近の権限活動:"
    if [[ -f "./ai-agents/logs/permissions.log" ]]; then
        tail -5 "./ai-agents/logs/permissions.log" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  権限ログなし"
    fi
    
    echo ""
    
    # 最近のワークフロー
    echo "最近のワークフロー:"
    if [[ -f "./ai-agents/logs/decision-workflow.log" ]]; then
        tail -5 "./ai-agents/logs/decision-workflow.log" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  ワークフローログなし"
    fi
    
    echo ""
}

# 不正活動検知
detect_unauthorized_activity() {
    echo "=== 不正活動検知 ==="
    
    # git操作の監視
    if [[ -f ".git/logs/HEAD" ]]; then
        local recent_git=$(tail -1 ".git/logs/HEAD" 2>/dev/null)
        if [[ -n "$recent_git" ]]; then
            local git_time=$(echo "$recent_git" | awk '{print $5}')
            local current_time=$(date +%s)
            local time_diff=$((current_time - git_time))
            
            # 5分以内のgit操作をチェック
            if [[ $time_diff -lt 300 ]]; then
                echo "⚠️  最近のGit操作検出: $recent_git"
                
                # 権限ログで承認状況確認
                if ! grep -q "APPROVAL_GRANTED.*git" "./ai-agents/logs/permissions.log" 2>/dev/null; then
                    send_alert "CRITICAL" "SYSTEM" "Unauthorized git operation detected"
                fi
            else
                echo "✅ 最近の不正Git操作なし"
            fi
        fi
    fi
    
    # 権限外操作の検知
    if [[ -f "./ai-agents/logs/permissions.log" ]]; then
        local denied_count=$(grep -c "PERMISSION_DENIED" "./ai-agents/logs/permissions.log" 2>/dev/null)
        if [[ $denied_count -gt 0 ]]; then
            echo "⚠️  権限拒否回数: $denied_count"
            if [[ $denied_count -gt 5 ]]; then
                send_alert "HIGH" "SYSTEM" "Multiple permission denials detected"
            fi
        else
            echo "✅ 権限拒否なし"
        fi
    fi
    
    echo ""
}

# パフォーマンス監視
monitor_performance() {
    echo "=== パフォーマンス監視 ==="
    
    # tmuxセッション数
    local session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    echo "アクティブセッション数: $session_count"
    
    # ログファイルサイズ
    local log_size=$(du -sh ./ai-agents/logs 2>/dev/null | awk '{print $1}')
    echo "ログサイズ: ${log_size:-0B}"
    
    # 一時ファイル数
    local tmp_files=$(find ./tmp -name "*.log" -o -name "*.json" 2>/dev/null | wc -l)
    echo "一時ファイル数: $tmp_files"
    
    echo ""
}

# アラート管理
manage_alerts() {
    echo "=== アラート管理 ==="
    
    if [[ -f "$ALERT_LOG" ]]; then
        local alert_count=$(wc -l < "$ALERT_LOG")
        echo "総アラート数: $alert_count"
        
        echo "最近のアラート:"
        tail -3 "$ALERT_LOG" | while read -r line; do
            echo "  $line"
        done
    else
        echo "アラートなし"
    fi
    
    echo ""
}

# リアルタイム監視
realtime_monitor() {
    echo "リアルタイム監視を開始します (Ctrl+C で停止)"
    echo ""
    
    while true; do
        clear
        monitor_all_agents
        monitor_activity
        detect_unauthorized_activity
        monitor_performance
        manage_alerts
        
        echo "次回更新まで30秒... (Ctrl+C で停止)"
        sleep 30
    done
}

# 詳細レポート生成
generate_report() {
    local report_file="./reports/organization-report-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "./reports"
    
    cat > "$report_file" << EOF
# AI組織監視レポート

生成日時: $(timestamp)

## システム概要
$(monitor_all_agents)

## 活動履歴
$(monitor_activity)

## セキュリティ状況
$(detect_unauthorized_activity)

## パフォーマンス
$(monitor_performance)

## アラート履歴
$(manage_alerts)

## 推奨事項
- 定期的な組織健全性チェック
- 権限管理の継続監視
- ログローテーションの実施
- 緊急時対応手順の確認

EOF

    echo "詳細レポートを生成しました: $report_file"
}

# メイン処理
case "$1" in
    "status")
        monitor_all_agents
        monitor_activity
        ;;
    "security")
        detect_unauthorized_activity
        ;;
    "performance")
        monitor_performance
        ;;
    "alerts")
        manage_alerts
        ;;
    "realtime")
        realtime_monitor
        ;;
    "report")
        generate_report
        ;;
    "full")
        monitor_all_agents
        monitor_activity
        detect_unauthorized_activity
        monitor_performance
        manage_alerts
        ;;
    *)
        echo "Usage: $0 {status|security|performance|alerts|realtime|report|full}"
        echo "  status      - Agent status check"
        echo "  security    - Security monitoring"
        echo "  performance - Performance monitoring"
        echo "  alerts      - Alert management"
        echo "  realtime    - Real-time monitoring"
        echo "  report      - Generate detailed report"
        echo "  full        - Full dashboard view"
        exit 1
        ;;
esac