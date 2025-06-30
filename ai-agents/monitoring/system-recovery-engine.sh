#!/bin/bash
# AI最強組織システム復旧エンジン
# システム落ち・クラッシュからの自動復帰システム

BASE_DIR="/Users/dd/Desktop/1_dev/coding-rule2"
RECOVERY_LOG="$BASE_DIR/logs/system-recovery.log"
STATE_FILE="$BASE_DIR/logs/system-state.json"
BACKUP_DIR="$BASE_DIR/logs/recovery-backups"

echo "🚨 AI最強組織システム復旧エンジン起動 - $(date)" >> "$RECOVERY_LOG"

# システム状態の自動保存
save_system_state() {
    echo "[$(date '+%H:%M:%S')] 💾 システム状態保存開始" >> "$RECOVERY_LOG"
    
    local state_data=$(cat <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "sessions": {
        "multiagent": "$(tmux has-session -t multiagent 2>/dev/null && echo 'active' || echo 'inactive')",
        "president": "$(tmux has-session -t president 2>/dev/null && echo 'active' || echo 'inactive')"
    },
    "workers": {
        "boss": "$(tmux list-panes -t multiagent:0 2>/dev/null | grep '^0:' && echo 'active' || echo 'inactive')",
        "worker1": "$(tmux list-panes -t multiagent:0 2>/dev/null | grep '^1:' && echo 'active' || echo 'inactive')",
        "worker2": "$(tmux list-panes -t multiagent:0 2>/dev/null | grep '^2:' && echo 'active' || echo 'inactive')",
        "worker3": "$(tmux list-panes -t multiagent:0 2>/dev/null | grep '^3:' && echo 'active' || echo 'inactive')"
    },
    "processes": {
        "balanced_auto": "$(pgrep -f balanced-auto-system && echo 'running' || echo 'stopped')",
        "declaration_enforcement": "$(pgrep -f declaration-enforcement && echo 'running' || echo 'stopped')"
    },
    "last_commands": [
        "$(tmux capture-pane -t multiagent:0.0 -p 2>/dev/null | tail -1 || echo 'none')",
        "$(tmux capture-pane -t multiagent:0.1 -p 2>/dev/null | tail -1 || echo 'none')",
        "$(tmux capture-pane -t multiagent:0.2 -p 2>/dev/null | tail -1 || echo 'none')",
        "$(tmux capture-pane -t multiagent:0.3 -p 2>/dev/null | tail -1 || echo 'none')"
    ]
}
EOF
    )
    
    echo "$state_data" > "$STATE_FILE"
    echo "[$(date '+%H:%M:%S')] ✅ システム状態保存完了" >> "$RECOVERY_LOG"
}

# システム復旧の実行
recover_system() {
    echo "[$(date '+%H:%M:%S')] 🔧 システム復旧開始" >> "$RECOVERY_LOG"
    
    # 1. tmuxセッション復旧
    if ! tmux has-session -t multiagent 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] 🚀 multiagentセッション復旧中" >> "$RECOVERY_LOG"
        cd "$BASE_DIR" && ./ai-agents/manage.sh claude-auth &
        sleep 10
    fi
    
    # 2. ワーカー起動状況確認・復旧
    for i in {0..3}; do
        if ! tmux list-panes -t "multiagent:0" 2>/dev/null | grep -q "^$i:"; then
            echo "[$(date '+%H:%M:%S')] 🔧 WORKER$i復旧中" >> "$RECOVERY_LOG"
            tmux send-keys -t "multiagent:0.$i" "claude --dangerously-skip-permissions" C-m 2>/dev/null
        fi
    done
    
    # 3. ステータスバー復旧
    if [ -f "$BASE_DIR/ai-agents/scripts/automation/core/auto-status-detection.sh" ]; then
        echo "[$(date '+%H:%M:%S')] 📊 ステータスバー復旧中" >> "$RECOVERY_LOG"
        cd "$BASE_DIR" && ./ai-agents/scripts/automation/core/auto-status-detection.sh update
    fi
    
    # 4. 自動化システム復旧
    if ! pgrep -f balanced-auto-system >/dev/null; then
        echo "[$(date '+%H:%M:%S')] ⚖️ バランス自動化システム復旧中" >> "$RECOVERY_LOG"
        cd "$BASE_DIR" && ./ai-agents/monitoring/balanced-auto-system.sh start
    fi
    
    # 5. BOSS1への復旧完了通知
    tmux send-keys -t multiagent:0.0 "> システム復旧完了！AI最強組織として再起動しました。" C-m 2>/dev/null
    
    echo "[$(date '+%H:%M:%S')] ✅ システム復旧完了" >> "$RECOVERY_LOG"
}

# システム健全性チェック
health_check() {
    local issues=0
    
    echo "[$(date '+%H:%M:%S')] 🔍 システム健全性チェック開始" >> "$RECOVERY_LOG"
    
    # tmuxセッション確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] ❌ multiagentセッション停止" >> "$RECOVERY_LOG"
        ((issues++))
    fi
    
    # ワーカー確認
    for i in {0..3}; do
        if ! tmux list-panes -t "multiagent:0" 2>/dev/null | grep -q "^$i:"; then
            echo "[$(date '+%H:%M:%S')] ❌ WORKER$i停止" >> "$RECOVERY_LOG"
            ((issues++))
        fi
    done
    
    # 自動化システム確認
    if ! pgrep -f balanced-auto-system >/dev/null; then
        echo "[$(date '+%H:%M:%S')] ❌ バランス自動化システム停止" >> "$RECOVERY_LOG"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] ✅ システム健全性: 正常" >> "$RECOVERY_LOG"
        return 0
    else
        echo "[$(date '+%H:%M:%S')] 🚨 システム健全性: 問題検出($issues個)" >> "$RECOVERY_LOG"
        return 1
    fi
}

# 自動監視・復旧ループ
auto_recovery_loop() {
    while true; do
        # 定期的な状態保存
        save_system_state
        
        # 健全性チェック
        if ! health_check; then
            echo "[$(date '+%H:%M:%S')] 🚨 システム問題検出 - 自動復旧開始" >> "$RECOVERY_LOG"
            recover_system
        fi
        
        # 5分間隔で監視
        sleep 300
    done
}

# 緊急復旧（即座実行）
emergency_recovery() {
    echo "[$(date '+%H:%M:%S')] 🚨 緊急復旧実行" >> "$RECOVERY_LOG"
    
    # プロセス整理
    pkill -f "auto.*monitor" 2>/dev/null
    pkill -f "declaration.*enforcement" 2>/dev/null
    
    # システム復旧
    recover_system
    
    # 状態保存
    save_system_state
    
    echo "[$(date '+%H:%M:%S')] ✅ 緊急復旧完了" >> "$RECOVERY_LOG"
}

# バックアップ作成
create_backup() {
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/system-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    echo "[$(date '+%H:%M:%S')] 💾 システムバックアップ作成中" >> "$RECOVERY_LOG"
    
    cd "$BASE_DIR" && tar -czf "$backup_file" \
        ai-agents/configs/ \
        ai-agents/monitoring/ \
        ai-agents/scripts/ \
        logs/system-state.json \
        .cursor/rules/ 2>/dev/null
    
    echo "[$(date '+%H:%M:%S')] ✅ バックアップ作成完了: $backup_file" >> "$RECOVERY_LOG"
}

# メイン実行
case "${1:-start}" in
    "start")
        echo "🚀 AI最強組織システム復旧エンジン開始"
        create_backup
        auto_recovery_loop &
        echo $! > "$BASE_DIR/logs/recovery-engine.pid"
        echo "📊 監視開始: PID $(cat $BASE_DIR/logs/recovery-engine.pid)"
        ;;
    "stop")
        if [ -f "$BASE_DIR/logs/recovery-engine.pid" ]; then
            kill "$(cat $BASE_DIR/logs/recovery-engine.pid)" 2>/dev/null
            rm -f "$BASE_DIR/logs/recovery-engine.pid"
            echo "🛑 システム復旧エンジン停止"
        fi
        ;;
    "emergency")
        emergency_recovery
        ;;
    "check")
        health_check && echo "✅ システム正常" || echo "❌ システム問題あり"
        ;;
    "backup")
        create_backup
        ;;
    *)
        echo "使用法: $0 {start|stop|emergency|check|backup}"
        exit 1
        ;;
esac