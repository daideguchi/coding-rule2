#!/bin/bash
# 🚀 自動実行監視システム v3.0 - Phase 1復旧版
# 継続的改善システム準拠・システム自動化特化

set -euo pipefail

# ================================================================================
# 🎯 Phase 1: 自動実行監視システム完全復旧
# ================================================================================

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# 🔥 自動実行監視機能（復旧版）
start_auto_execute_monitor() {
    log_info "🚀 自動実行監視機能開始（AI組織システム自動化特化）"
    
    # セッション存在確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "❌ multiagentセッションが存在しません。先に起動してください:"
        echo "  ./ai-agents/manage.sh start"
        return 1
    fi
    
    log_info "🔍 システム自動化ワーカーの指示監視を開始します..."
    echo "📋 監視対象（システム自動化特化）:"
    echo "  👔 BOSS1 │ チームリーダー・タスク分割・分担管理 (multiagent:0.0)"
    echo "  🔧 WORKER1 │ システム自動化・監視エンジニア (multiagent:0.1)" 
    echo "  🚀 WORKER2 │ 統合・運用エンジニア (multiagent:0.2)"
    echo "  📊 WORKER3 │ 品質保証・監視エンジニア (multiagent:0.3)"
    echo ""
    echo "💡 動作: 指示メッセージ検出時に即座に自動実行（Enterキー送信）"
    echo "🛑 停止: Ctrl+C または stop_auto_execute_monitor"
    echo ""
    
    # ログディレクトリ作成
    mkdir -p /tmp/ai-agents
    
    # バックグラウンドで自動実行監視を開始
    nohup bash -c '
        exec > /tmp/ai-agents/auto-execute-monitor.log 2>&1
        echo "$(date): 自動実行監視開始（システム自動化特化版）"
        
        # 各ワーカーの前回の画面内容を保存
        declare -A prev_content
        for worker_id in {0..3}; do
            prev_content[$worker_id]=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
        done
        
        while true; do
            for worker_id in {0..3}; do
                # 現在の画面内容を取得
                current_content=$(tmux capture-pane -t multiagent:0.$worker_id -p 2>/dev/null || echo "")
                
                # 前回と比較して新しい指示が入力されたかチェック
                if [ "$current_content" != "${prev_content[$worker_id]}" ]; then
                    # 新しい内容をチェック
                    new_lines=$(echo "$current_content" | tail -5)
                    
                    # 🎯 システム自動化特化の指示検出パターン
                    should_execute=false
                    
                    # パターン1: 「>」プロンプトに文字が入力されている
                    if echo "$new_lines" | grep -qE "^> .+" 2>/dev/null; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン1検出: プロンプト入力"
                    fi
                    
                    # パターン2: システム自動化関連の指示メッセージを検出
                    if echo "$current_content" | grep -qE "(監視|自動化|システム|統合|運用|品質|指示を送信|タスクを|作業を|実行して)" 2>/dev/null; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン2検出: システム自動化指示"
                    fi
                    
                    # パターン3: 入力待ち状態での新しいコンテンツ
                    if echo "$current_content" | tail -1 | grep -qE "^>" 2>/dev/null && [ ${#current_content} -gt ${#prev_content[$worker_id]} ]; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン3検出: 入力待ち状態変化"
                    fi
                    
                    # パターン4: Bypassing Permissions状態の検出と自動突破
                    if echo "$current_content" | grep -qE "Bypassing Permissions" 2>/dev/null; then
                        should_execute=true
                        echo "$(date): WORKER${worker_id} パターン4検出: Bypassing Permissions自動突破"
                    fi
                    
                    if [ "$should_execute" = true ]; then
                        echo "$(date): WORKER${worker_id} 新しい指示検出 - 自動実行開始"
                        
                        # ✅ システム自動化特化のステータス更新
                        case $worker_id in
                            0) tmux select-pane -t multiagent:0.0 -T "👔 BOSS1 │ チームリーダー・タスク分割・分担管理 │ 🟢 作業中" ;;
                            1) tmux select-pane -t multiagent:0.1 -T "🔧 WORKER1 │ システム自動化・監視エンジニア │ 🟢 作業中" ;;
                            2) tmux select-pane -t multiagent:0.2 -T "🚀 WORKER2 │ 統合・運用エンジニア │ 🟢 作業中" ;;
                            3) tmux select-pane -t multiagent:0.3 -T "📊 WORKER3 │ 品質保証・監視エンジニア │ 🟢 作業中" ;;
                        esac
                        
                        # 🎯 確実なEnterキー送信（複数回試行・システム自動化最適化）
                        echo "$(date): WORKER${worker_id} Enterキー送信開始"
                        
                        # 方法1: 通常のEnterキー送信
                        tmux send-keys -t multiagent:0.$worker_id C-m
                        sleep 0.3
                        
                        # 方法2: 確実性のため再度送信
                        tmux send-keys -t multiagent:0.$worker_id ""
                        tmux send-keys -t multiagent:0.$worker_id C-m
                        sleep 0.3
                        
                        # 方法3: 強制的な改行送信
                        tmux send-keys -t multiagent:0.$worker_id Enter
                        
                        echo "$(date): WORKER${worker_id} Enterキー送信完了"
                        
                        # 5秒後にステータスを待機中に戻す
                        sleep 5
                        case $worker_id in
                            0) tmux select-pane -t multiagent:0.0 -T "👔 BOSS1 │ チームリーダー・タスク分割・分担管理 │ 🟡 待機中" ;;
                            1) tmux select-pane -t multiagent:0.1 -T "🔧 WORKER1 │ システム自動化・監視エンジニア │ 🟡 待機中" ;;
                            2) tmux select-pane -t multiagent:0.2 -T "🚀 WORKER2 │ 統合・運用エンジニア │ 🟡 待機中" ;;
                            3) tmux select-pane -t multiagent:0.3 -T "📊 WORKER3 │ 品質保証・監視エンジニア │ 🟡 待機中" ;;
                        esac
                    fi
                    
                    # 前回の内容を更新
                    prev_content[$worker_id]="$current_content"
                fi
            done
            
            # 0.5秒間隔で効率的監視（システム自動化最適化）
            sleep 0.5
        done
    ' &
    
    local AUTO_EXECUTE_PID=$!
    echo $AUTO_EXECUTE_PID > /tmp/ai-agents/auto-execute-monitor.pid
    
    log_success "✅ 自動実行監視機能が開始されました（PID: ${AUTO_EXECUTE_PID}）"
    echo ""
    echo "📋 監視ログ確認:"
    echo "  tail -f /tmp/ai-agents/auto-execute-monitor.log"
    echo ""
    echo "🛑 停止方法:"
    echo "  kill ${AUTO_EXECUTE_PID}"
    echo "  または ./ai-agents/AUTO_EXECUTE_MONITOR_SYSTEM.sh stop"
    echo ""
}

# 🛑 自動実行監視停止機能
stop_auto_execute_monitor() {
    log_info "🛑 自動実行監視停止中..."
    
    if [ -f /tmp/ai-agents/auto-execute-monitor.pid ]; then
        local AUTO_EXECUTE_PID=$(cat /tmp/ai-agents/auto-execute-monitor.pid)
        if kill ${AUTO_EXECUTE_PID} 2>/dev/null; then
            log_success "✅ 自動実行監視を停止しました（PID: ${AUTO_EXECUTE_PID}）"
            rm -f /tmp/ai-agents/auto-execute-monitor.pid
        else
            log_warn "⚠️ プロセス（PID: ${AUTO_EXECUTE_PID}）は既に停止しています"
        fi
    else
        log_warn "⚠️ 自動実行監視は開始されていません"
    fi
    echo ""
}

# 📊 監視ステータス確認機能
check_auto_execute_status() {
    log_info "📊 自動実行監視ステータス確認"
    
    if [ -f /tmp/ai-agents/auto-execute-monitor.pid ]; then
        local AUTO_EXECUTE_PID=$(cat /tmp/ai-agents/auto-execute-monitor.pid)
        if kill -0 ${AUTO_EXECUTE_PID} 2>/dev/null; then
            log_success "✅ 自動実行監視は稼働中です（PID: ${AUTO_EXECUTE_PID}）"
            echo "📋 ログ確認: tail -f /tmp/ai-agents/auto-execute-monitor.log"
        else
            log_error "❌ 自動実行監視プロセスが停止しています（PID: ${AUTO_EXECUTE_PID}）"
            rm -f /tmp/ai-agents/auto-execute-monitor.pid
        fi
    else
        log_warn "⚠️ 自動実行監視は開始されていません"
    fi
    echo ""
}

# 🔄 継続的改善システム統合
integrate_with_continuous_improvement() {
    log_info "🔄 継続的改善システムとの統合"
    
    # Phase 1-1 完了記録
    echo "$(date): Phase 1-1 自動実行監視システム復旧完了" >> /tmp/ai-agents/improvement-log.txt
    
    log_success "✅ Phase 1-1 自動実行監視システム復旧完了"
    echo ""
}

# ================================================================================
# 🎯 メイン実行部分
# ================================================================================

case "${1:-start}" in
    "start")
        start_auto_execute_monitor
        integrate_with_continuous_improvement
        ;;
    "stop")
        stop_auto_execute_monitor
        ;;
    "status")
        check_auto_execute_status
        ;;
    "restart")
        stop_auto_execute_monitor
        sleep 2
        start_auto_execute_monitor
        integrate_with_continuous_improvement
        ;;
    *)
        echo "使用法: $0 [start|stop|status|restart]"
        echo ""
        echo "  start   - 自動実行監視開始"
        echo "  stop    - 自動実行監視停止"
        echo "  status  - 監視ステータス確認"
        echo "  restart - 監視再起動"
        echo ""
        exit 1
        ;;
esac