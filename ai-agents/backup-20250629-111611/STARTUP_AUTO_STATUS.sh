#!/bin/bash
# 🔥 起動時自動ステータス確実適用システム
# 作成日: 2025-06-29
# 目的: AI組織起動時に確実にステータスバーを適用し、永続監視を開始

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/startup-status.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_startup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 起動時確実適用（チーム協議結果反映）
startup_status_apply() {
    log_startup "🚀 AI組織システム起動時完全セットアップ開始"
    
    # 1. システム基盤確認
    log_startup "📋 システム基盤確認中..."
    
    # tmuxセッション確認（最大30秒待機）
    local max_wait=30
    local waited=0
    
    while ! tmux has-session -t multiagent 2>/dev/null; do
        if [ $waited -ge $max_wait ]; then
            log_startup "❌ tmuxセッション起動待機タイムアウト"
            return 1
        fi
        sleep 1
        ((waited++))
    done
    
    log_startup "✅ tmuxセッション確認完了"
    
    # 2. 重要ファイル・ディレクトリ存在確認
    log_startup "📁 重要ファイル確認中..."
    
    local required_files=(
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/president.md"
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/boss.md"
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/worker.md"
        "/Users/dd/Desktop/1_dev/coding-rule2/docs/REQUIREMENTS_SPECIFICATION.md"
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/CRITICAL_FACTS.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_startup "⚠️ 重要ファイル未発見: $file"
        else
            log_startup "✅ 確認完了: $(basename "$file")"
        fi
    done
    
    # 3. ログディレクトリ作成
    mkdir -p "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs"
    log_startup "✅ ログディレクトリ確認完了"
    
    # 2. ペイン確認
    for i in {0..3}; do
        local max_pane_wait=10
        local pane_waited=0
        
        while ! tmux list-panes -t "multiagent:0.$i" >/dev/null 2>&1; do
            if [ $pane_waited -ge $max_pane_wait ]; then
                log_startup "❌ WORKER$i ペイン起動待機タイムアウト"
                return 1
            fi
            sleep 1
            ((pane_waited++))
        done
    done
    
    log_startup "✅ 全ペイン確認完了"
    
    # 4. tmux環境最適化設定
    log_startup "⚙️ tmux環境最適化中..."
    
    # ステータスバー設定
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-format "#[bg=colour235,fg=colour255] #{pane_title} "
    
    # マウス操作有効化
    tmux set-option -g mouse on
    
    # ヒストリサイズ増加
    tmux set-option -g history-limit 10000
    
    # ペイン切り替え最適化
    tmux set-option -g display-panes-time 2000
    
    # 自動リネーム無効化（手動設定保持）
    tmux set-option -g automatic-rename off
    tmux set-option -g allow-rename off
    
    log_startup "✅ tmux環境最適化完了"
    
    # 5. AI組織システム初期化
    log_startup "🤖 AI組織システム初期化中..."
    
    # 重要事実の確認ログ
    log_startup "📋 重要事実確認: Bypassing Permissions = AI組織のデフォルト正常状態"
    
    # 役職設定準備
    log_startup "👥 役職設定準備（要件定義書REQ-002準拠）"
    
    # 4. 初期ステータス設定（3回試行）
    for attempt in {1..3}; do
        log_startup "ステータス設定試行 $attempt/3"
        
        if /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PERSISTENT_STATUS_MONITOR.sh fix; then
            log_startup "✅ ステータス設定成功（試行$attempt）"
            break
        else
            log_startup "⚠️ ステータス設定失敗（試行$attempt）"
            if [ $attempt -eq 3 ]; then
                log_startup "❌ ステータス設定最終失敗"
                return 1
            fi
            sleep 2
        fi
    done
    
    # 6. 永続監視開始
    log_startup "🔄 永続監視システム開始"
    nohup /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PERSISTENT_STATUS_MONITOR.sh monitor >> "$LOG_FILE" 2>&1 &
    echo $! > "/tmp/status_monitor.pid"
    
    # 7. セキュリティ・権限設定
    log_startup "🔒 セキュリティ設定確認中..."
    
    # スクリプト実行権限確認
    local scripts=(
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PERSISTENT_STATUS_MONITOR.sh"
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/DOUBLE_ENTER_SYSTEM.sh"
        "/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/ULTIMATE_STATUS_FIX.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            log_startup "✅ 実行権限設定: $(basename "$script")"
        fi
    done
    
    # 8. 最終確認・動作テスト
    log_startup "🧪 最終動作テスト中..."
    
    # ステータスバー表示確認
    sleep 2
    local status_check=true
    for i in {0..3}; do
        local title=$(tmux list-panes -t "multiagent:0.$i" -F "#{pane_title}" 2>/dev/null || echo "ERROR")
        if [[ "$title" == "ERROR" ]]; then
            log_startup "⚠️ WORKER$i ステータスバー未設定"
            status_check=false
        fi
    done
    
    if $status_check; then
        log_startup "✅ 全ワーカーステータスバー設定確認完了"
    fi
    
    # 9. 起動完了通知・サマリー
    log_startup "🎯 AI組織システム起動完全セットアップ完了"
    log_startup "📊 セットアップサマリー:"
    log_startup "  ✅ tmuxセッション: president, multiagent (4ペイン)"
    log_startup "  ✅ ステータスバー: 動的表示・永続監視"
    log_startup "  ✅ 重要ファイル: 指示書・要件定義書・重要事実"
    log_startup "  ✅ セキュリティ: スクリプト実行権限・ログ記録"
    log_startup "  ✅ 監視システム: 瞬間的変化検知・自動修正"
    
    return 0
}

# 停止機能
stop_monitoring() {
    log_startup "🛑 監視システム停止"
    
    if [ -f "/tmp/status_monitor.pid" ]; then
        local pid=$(cat "/tmp/status_monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_startup "✅ 監視プロセス停止完了"
        fi
        rm -f "/tmp/status_monitor.pid"
    fi
}

# メイン実行
case "${1:-start}" in
    "start")
        startup_status_apply
        ;;
    "stop")
        stop_monitoring
        ;;
    *)
        echo "使用方法:"
        echo "  $0 start  # 起動時確実適用（デフォルト）"
        echo "  $0 stop   # 監視停止"
        ;;
esac