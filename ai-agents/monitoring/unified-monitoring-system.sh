#!/bin/bash

# =============================================================================
# 統合監視システム - WORKER3専門実装
# 品質保証・監視・ワークロード分散の包括的監視
# =============================================================================

# 設定
MONITOR_DIR="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/monitoring"
LOG_DIR="/Users/dd/Desktop/1_dev/coding-rule2/logs"
ALERT_LOG="$LOG_DIR/system-alerts.log"
HEALTH_LOG="$LOG_DIR/system-health.log"
WORKLOAD_LOG="$LOG_DIR/workload-distribution.log"

# 作業ディレクトリ作成
mkdir -p "$MONITOR_DIR" "$LOG_DIR"

# =============================================================================
# 1. システムヘルス監視
# =============================================================================
monitor_system_health() {
    echo "[$(date '+%H:%M:%S')] システムヘルス監視開始" >> "$HEALTH_LOG"
    
    # tmuxセッション監視
    local sessions=$(tmux list-sessions 2>/dev/null | wc -l)
    echo "tmuxセッション数: $sessions" >> "$HEALTH_LOG"
    
    # 重要ファイル存在確認
    local critical_files=(
        "ai-agents/instructions/worker.md"
        "ai-agents/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh"
        "ai-agents/scripts/core/SYSTEM_HEALTH_CHECK.sh"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "✅ $file 正常" >> "$HEALTH_LOG"
        else
            echo "❌ $file 欠損" >> "$HEALTH_LOG"
            echo "[ALERT] 重要ファイル欠損: $file" >> "$ALERT_LOG"
        fi
    done
}

# =============================================================================
# 2. ワークロード分散監視
# =============================================================================
monitor_workload_distribution() {
    echo "[$(date '+%H:%M:%S')] ワークロード分散監視開始" >> "$WORKLOAD_LOG"
    
    # 各ワーカーのペイン状況確認
    if tmux has-session -t multiagent 2>/dev/null; then
        local pane_count=$(tmux list-panes -t multiagent 2>/dev/null | wc -l)
        echo "アクティブペイン数: $pane_count/4" >> "$WORKLOAD_LOG"
        
        # ペインタイトル取得
        tmux list-panes -t multiagent -F "#{pane_title}" 2>/dev/null >> "$WORKLOAD_LOG"
        
        # 過負荷検知
        if [[ $pane_count -lt 3 ]]; then
            echo "[ALERT] ワーカー不足検知: $pane_count/4" >> "$ALERT_LOG"
        fi
    else
        echo "[ALERT] multiagentセッション未起動" >> "$ALERT_LOG"
    fi
}

# =============================================================================
# 3. 品質保証監視
# =============================================================================
monitor_quality_assurance() {
    local qa_log="$LOG_DIR/quality-monitoring.log"
    echo "[$(date '+%H:%M:%S')] 品質保証監視開始" >> "$qa_log"
    
    # PRESIDENT_MISTAKES.md監視
    local mistakes_file="logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    if [[ -f "$mistakes_file" ]]; then
        local mistake_count=$(grep -c "##" "$mistakes_file" 2>/dev/null || echo "0")
        echo "記録済みミス数: $mistake_count" >> "$qa_log"
        
        # 新規ミス検知（過去1分以内の更新）
        if [[ $(find "$mistakes_file" -mmin -1 2>/dev/null) ]]; then
            echo "[ALERT] 新規ミス記録検知" >> "$ALERT_LOG"
        fi
    fi
    
    # 品質チェック実行
    if [[ -f "scripts/quality-check.sh" ]]; then
        bash scripts/quality-check.sh >> "$qa_log" 2>&1
    fi
}

# =============================================================================
# 4. BOSS1負荷軽減監視
# =============================================================================
monitor_boss1_workload() {
    local boss_log="$LOG_DIR/boss1-workload.log"
    echo "[$(date '+%H:%M:%S')] BOSS1負荷監視開始" >> "$boss_log"
    
    # BOSS1ペイン監視
    if tmux has-session -t multiagent 2>/dev/null; then
        local boss1_pane=$(tmux list-panes -t multiagent -F "#{pane_index}:#{pane_title}" | grep "BOSS1" || echo "未検出")
        echo "BOSS1ペイン状況: $boss1_pane" >> "$boss_log"
        
        # 過負荷指標
        local recent_logs=$(find logs/ -name "*BOSS1*" -mmin -5 2>/dev/null | wc -l)
        if [[ $recent_logs -gt 3 ]]; then
            echo "[ALERT] BOSS1過負荷疑い: 5分間で${recent_logs}件のログ" >> "$ALERT_LOG"
            echo "WORKER3が追加タスク受入準備" >> "$boss_log"
        fi
    fi
}

# =============================================================================
# 5. 統合アラート処理
# =============================================================================
process_alerts() {
    if [[ -f "$ALERT_LOG" ]] && [[ -s "$ALERT_LOG" ]]; then
        local alert_count=$(wc -l < "$ALERT_LOG")
        echo "🚨 アクティブアラート数: $alert_count"
        
        # 重要度別アラート分類
        local critical_alerts=$(grep -c "\[ALERT\].*重要\|欠損\|未起動" "$ALERT_LOG" 2>/dev/null || echo "0")
        local workload_alerts=$(grep -c "\[ALERT\].*過負荷\|不足" "$ALERT_LOG" 2>/dev/null || echo "0")
        
        echo "📊 監視サマリー:"
        echo "  - 重要アラート: $critical_alerts件"
        echo "  - 負荷アラート: $workload_alerts件"
        
        # tmuxペインタイトル更新
        if tmux has-session -t multiagent 2>/dev/null; then
            tmux select-pane -t multiagent:0.3 -T "WORKER3:監視中(Alert:$alert_count)" 2>/dev/null
        fi
    fi
}

# =============================================================================
# メイン監視ループ
# =============================================================================
main_monitoring_loop() {
    echo "🔍 統合監視システム開始 - WORKER3専門実装"
    echo "監視対象: 品質保証・システムヘルス・ワークロード・BOSS1負荷"
    
    while true; do
        # 全監視機能実行
        monitor_system_health
        monitor_workload_distribution  
        monitor_quality_assurance
        monitor_boss1_workload
        process_alerts
        
        # 監視間隔（30秒）
        sleep 30
    done
}

# =============================================================================
# 実行部
# =============================================================================
case "${1:-monitor}" in
    "health")
        monitor_system_health
        ;;
    "workload")
        monitor_workload_distribution
        ;;
    "quality")
        monitor_quality_assurance
        ;;
    "boss1")
        monitor_boss1_workload
        ;;
    "alerts")
        process_alerts
        ;;
    "monitor"|*)
        main_monitoring_loop
        ;;
esac