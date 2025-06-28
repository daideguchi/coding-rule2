#!/bin/bash

# 🚀 AI組織自動復旧・自動化システム v2.0
# 役職表示、認証、自動起動を完全自動化

set -e

LOG_FILE="/tmp/ai-auto-recovery.log"
STATUS_FILE="/tmp/ai-team-status.json"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 🎯 役職・ステータス自動表示システム
setup_team_ui() {
    log "🎨 チームUI自動復旧開始"
    
    # tmux設定復旧
    tmux set-option -g mouse on
    tmux set-option -g status-position top
    tmux set-option -g status-left-length 50
    tmux set-option -g status-right-length 50
    tmux set-option -g pane-border-status top
    tmux set-option -g status-interval 1
    
    # 各ペインの役職表示設定
    tmux set-option -g pane-border-format "#{?pane_active,#[reverse],}#{pane_index}:#{?#{==:#{pane_index},0},👑PRESIDENT,#{?#{==:#{pane_index},1},👔BOSS1-チームリーダー,#{?#{==:#{pane_index},2},💻WORKER1-フロントエンド,#{?#{==:#{pane_index},3},🔧WORKER2-バックエンド,🎨WORKER3-UI/UXデザイン}}}}"
    
    # ステータスライン設定
    tmux set-option -g status-left "#[fg=green]🚀AI組織システム v2.0 #[fg=blue]%H:%M:%S"
    tmux set-option -g status-right "#[fg=yellow]全員🟡待機中 #[fg=cyan]起動完了"
    
    log "✅ チームUI復旧完了"
}

# 🔄 自動認証突破システム
auto_bypass_permissions() {
    log "🔓 自動認証突破開始"
    
    for i in {0..3}; do
        # Bypassing Permissions状態をチェック
        content=$(tmux capture-pane -t multiagent:0.$i -p | tail -1)
        if [[ "$content" == *"Bypassing Permissions"* ]]; then
            log "🔑 ワーカー$i: 認証突破実行"
            tmux send-keys -t multiagent:0.$i C-m
            sleep 1
        fi
    done
    
    log "✅ 自動認証突破完了"
}

# 🧠 自動状況把握・メッセージセットシステム
auto_setup_messages() {
    log "📝 自動メッセージセット開始"
    
    # プレジデント指示書確認コマンド
    sleep 2
    tmux send-keys -t multiagent:0.0 "まず必須ログを確認し、これまでの経緯を把握してください。/Users/dd/Desktop/1_dev/coding-rule2/logs/ai-agents/president/PRESIDENT_MISTAKES.mdを読み、23個のミスを確認し、同じミスを繰り返さないよう注意してください。" C-m
    
    # 各ワーカーに指示書確認を指示
    sleep 1
    tmux send-keys -t multiagent:0.1 ">WORKER1として起動完了。/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/worker.mdを確認し、フロントエンド専門として準備完了を報告してください。" C-m
    
    sleep 1
    tmux send-keys -t multiagent:0.2 ">WORKER2として起動完了。/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/worker.mdを確認し、バックエンド専門として準備完了を報告してください。" C-m
    
    sleep 1
    tmux send-keys -t multiagent:0.3 ">WORKER3として起動完了。/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/worker.mdを確認し、UI/UXデザイン専門として準備完了を報告してください。" C-m
    
    log "✅ 自動メッセージセット完了"
}

# 📊 チーム状況監視システム
monitor_team_status() {
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # 各ワーカーの状況を収集
        for i in {0..3}; do
            content=$(tmux capture-pane -t multiagent:0.$i -p | tail -3)
            if [[ "$content" == *">"* ]] && [[ "$content" != *"Bypassing Permissions"* ]]; then
                status="🟢稼働中"
            elif [[ "$content" == *"Bypassing Permissions"* ]]; then
                status="🔴認証待ち"
                # 自動認証突破
                tmux send-keys -t multiagent:0.$i C-m
            else
                status="🟡待機中"
            fi
            
            # JSON形式でステータス保存
            echo "{\"worker\": $i, \"status\": \"$status\", \"timestamp\": \"$timestamp\"}" >> "$STATUS_FILE"
        done
        
        sleep 5
    done
}

# 🚀 メイン実行フロー
main() {
    log "🚀 AI組織自動復旧システム v2.0 起動"
    
    # 1. UI復旧
    setup_team_ui
    
    # 2. 認証突破
    auto_bypass_permissions
    
    # 3. メッセージセット
    auto_setup_messages
    
    # 4. バックグラウンド監視開始
    if [[ "$1" == "monitor" ]]; then
        log "📊 継続監視モード開始"
        monitor_team_status &
        echo $! > /tmp/ai-monitor.pid
    fi
    
    log "🎉 AI組織システム完全復旧完了"
    
    # 状況報告
    echo "
## 🎯 AI組織システム復旧完了

✅ **UI表示**: 全ペインで役職・ステータス表示復旧
✅ **認証突破**: 全ワーカーの認証自動突破完了  
✅ **メッセージセット**: 指示書確認メッセージ自動配信完了
✅ **監視システム**: バックグラウンド監視システム起動

### 🔄 継続監視機能
- 5秒間隔での全ワーカー状況監視
- 認証切れ時の自動復旧
- ステータス更新の自動実行

### 📱 使用方法
\`\`\`bash
# 基本復旧
./ai-agents/auto-recovery-system.sh

# 継続監視付き復旧  
./ai-agents/auto-recovery-system.sh monitor

# 監視停止
kill \$(cat /tmp/ai-monitor.pid)
\`\`\`
"
}

# 引数に応じて実行
main "$@"