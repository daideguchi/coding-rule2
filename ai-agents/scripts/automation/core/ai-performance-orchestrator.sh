#!/bin/bash
# 🎼 AI性能オーケストレーター v1.0
# 全システム統合・自動調整・最適化指揮システム

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
ORCHESTRATOR_LOG="$PROJECT_ROOT/logs/optimization/orchestrator.log"
PERFORMANCE_CONFIG="$PROJECT_ROOT/configs/performance-settings.json"
SYSTEM_STATE="$PROJECT_ROOT/tmp/system-state.json"

mkdir -p "$(dirname "$ORCHESTRATOR_LOG")" "$(dirname "$PERFORMANCE_CONFIG")" "$(dirname "$SYSTEM_STATE")"

log_info() {
    echo -e "\033[1;36m[ORCHESTRATOR]\033[0m $(date '+%H:%M:%S') $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $(date '+%H:%M:%S') $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $(date '+%H:%M:%S') $1" | tee -a "$ORCHESTRATOR_LOG"
}

# 🎯 システム状態総合分析
comprehensive_system_analysis() {
    log_info "🎯 システム状態総合分析開始"
    
    local analysis_start=$(date +%s)
    
    # 1. AI組織システム稼働状況
    local ai_system_status="unknown"
    local active_workers=0
    local session_health="unknown"
    
    if tmux has-session -t president 2>/dev/null && tmux has-session -t multiagent 2>/dev/null; then
        ai_system_status="running"
        session_health="healthy"
        
        # アクティブワーカー数カウント
        for i in {0..3}; do
            if tmux list-panes -t multiagent:0 2>/dev/null | grep -q "0\.$i:"; then
                local activity
                activity=$(tmux capture-pane -t multiagent:0.$i -p -S -3 2>/dev/null | grep -c ">" || echo "0")
                if [ "$activity" -gt 0 ]; then
                    active_workers=$((active_workers + 1))
                fi
            fi
        done
    else
        ai_system_status="stopped"
        session_health="unhealthy"
    fi
    
    # 2. 性能最適化システム稼働確認
    local optimization_status="stopped"
    local scheduler_status="stopped"
    local memory_engine_status="stopped"
    
    [ -f /tmp/scheduler-monitor.pid ] && kill -0 $(cat /tmp/scheduler-monitor.pid) 2>/dev/null && scheduler_status="running"
    [ -f /tmp/memory-engine.pid ] && kill -0 $(cat /tmp/memory-engine.pid) 2>/dev/null && memory_engine_status="running"
    
    # 3. システムリソース状況
    local cpu_usage=0
    local memory_usage=0
    local disk_usage=0
    
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || echo "0")
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        memory_usage=$(vm_stat | awk '/Pages active/ {active=$3} /Pages free/ {free=$3} END {print int(active/(active+free)*100)}' 2>/dev/null || echo "0")
    else
        memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    fi
    
    disk_usage=$(df "$PROJECT_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    # 4. AI応答性能メトリクス収集
    local avg_response_time=0
    local performance_score=100
    
    if [ -f "$PROJECT_ROOT/logs/optimization/performance-metrics.json" ]; then
        avg_response_time=$(tail -10 "$PROJECT_ROOT/logs/optimization/performance-metrics.json" | jq -r '.duration' | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}' 2>/dev/null || echo "0")
        
        if [ "$avg_response_time" -gt 200 ]; then
            performance_score=30
        elif [ "$avg_response_time" -gt 120 ]; then
            performance_score=60
        elif [ "$avg_response_time" -gt 60 ]; then
            performance_score=80
        fi
    fi
    
    # 5. システム状態JSON生成
    local analysis_end=$(date +%s)
    local analysis_duration=$((analysis_end - analysis_start))
    
    local system_state_json
    system_state_json=$(cat <<EOF
{
    "timestamp": $analysis_end,
    "analysis_duration": $analysis_duration,
    "ai_system": {
        "status": "$ai_system_status",
        "active_workers": $active_workers,
        "session_health": "$session_health"
    },
    "optimization_systems": {
        "scheduler": "$scheduler_status",
        "memory_engine": "$memory_engine_status",
        "overall_status": "$([ "$scheduler_status" = "running" ] && [ "$memory_engine_status" = "running" ] && echo "running" || echo "partial")"
    },
    "system_resources": {
        "cpu_usage": $cpu_usage,
        "memory_usage": $memory_usage,
        "disk_usage": $disk_usage
    },
    "performance_metrics": {
        "avg_response_time": $avg_response_time,
        "performance_score": $performance_score
    },
    "optimization_needed": $([ $performance_score -lt 70 ] && echo "true" || echo "false")
}
EOF
    )
    
    echo "$system_state_json" > "$SYSTEM_STATE"
    
    log_info "📊 システム分析完了: AI稼働$ai_system_status / ワーカー${active_workers}個 / 性能スコア${performance_score}点"
    
    echo "$performance_score"
}

# 🚀 自動最適化実行エンジン
auto_optimization_engine() {
    log_info "🚀 自動最適化実行エンジン起動"
    
    local performance_score
    performance_score=$(comprehensive_system_analysis)
    
    # 性能スコアに基づく最適化戦略決定
    if [ "$performance_score" -lt 40 ]; then
        log_error "🚨 重大性能問題検出 (スコア: ${performance_score}) → 緊急最適化実行"
        execute_emergency_optimization
        
    elif [ "$performance_score" -lt 70 ]; then
        log_info "⚠️ 性能低下検出 (スコア: ${performance_score}) → 標準最適化実行"
        execute_standard_optimization
        
    else
        log_success "✅ 性能良好 (スコア: ${performance_score}) → 予防的最適化実行"
        execute_preventive_optimization
    fi
}

# 🚨 緊急最適化実行
execute_emergency_optimization() {
    log_error "🚨 緊急最適化実行開始"
    
    # 1. メモリ緊急解放
    log_info "💾 メモリ緊急解放"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/memory-optimization-engine.sh" gc
    
    # 2. AI応答最適化
    log_info "🤖 AI応答緊急最適化"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/parallel-optimization-system.sh" start
    
    # 3. 不要プロセス終了
    log_info "🔄 不要プロセス整理"
    pkill -f "STATUS.*" 2>/dev/null || true
    pkill -f "monitoring.*" 2>/dev/null || true
    
    # 4. tmuxセッション最適化
    if tmux has-session -t multiagent 2>/dev/null; then
        tmux set-option -t multiagent -g history-limit 100
        tmux set-option -t multiagent -g status-interval 15
        log_info "📺 tmux緊急最適化完了"
    fi
    
    # 5. システム再起動推奨判定
    local memory_usage
    memory_usage=$(jq -r '.system_resources.memory_usage' "$SYSTEM_STATE" 2>/dev/null || echo "100")
    
    if [ "$memory_usage" -gt 90 ]; then
        log_error "⚠️ システム再起動推奨: メモリ使用率 ${memory_usage}%"
        echo "RESTART_RECOMMENDED" > /tmp/orchestrator-action.flag
    fi
    
    log_success "✅ 緊急最適化完了"
}

# 🔧 標準最適化実行
execute_standard_optimization() {
    log_info "🔧 標準最適化実行開始"
    
    # 1. インテリジェント・タスクスケジューラー起動
    if [ ! -f /tmp/scheduler-monitor.pid ]; then
        log_info "🧠 タスクスケジューラー起動"
        "$PROJECT_ROOT/ai-agents/scripts/automation/core/intelligent-task-scheduler.sh" auto
    fi
    
    # 2. メモリ最適化エンジン起動
    if [ ! -f /tmp/memory-engine.pid ]; then
        log_info "💾 メモリエンジン起動"
        "$PROJECT_ROOT/ai-agents/scripts/automation/core/memory-optimization-engine.sh" auto
    fi
    
    # 3. 並列処理最適化
    log_info "⚡ 並列処理最適化"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/parallel-optimization-system.sh" start
    
    # 4. ステータスバー最適化
    log_info "📊 ステータスバー最適化"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/fixed-status-bar-init.sh" setup
    
    log_success "✅ 標準最適化完了"
}

# 🛡️ 予防的最適化実行
execute_preventive_optimization() {
    log_info "🛡️ 予防的最適化実行開始"
    
    # 1. 予測的キャッシュ生成
    log_info "🧠 予測的キャッシュ生成"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/intelligent-task-scheduler.sh" preload
    
    # 2. メモリ効率維持
    log_info "💾 メモリ効率維持"
    "$PROJECT_ROOT/ai-agents/scripts/automation/core/memory-optimization-engine.sh" cache
    
    # 3. システムヘルスチェック
    if [ -f "$PROJECT_ROOT/ai-agents/scripts/core/SYSTEM_HEALTH_CHECK.sh" ]; then
        log_info "🏥 システムヘルスチェック"
        "$PROJECT_ROOT/ai-agents/scripts/core/SYSTEM_HEALTH_CHECK.sh" check
    fi
    
    log_success "✅ 予防的最適化完了"
}

# 📊 リアルタイム性能ダッシュボード
performance_dashboard() {
    log_info "📊 リアルタイム性能ダッシュボード起動"
    
    while true; do
        clear
        echo "🎼 AI性能オーケストレーター v1.0 - リアルタイムダッシュボード"
        echo "=================================================================="
        echo ""
        
        # システム状態分析実行
        local performance_score
        performance_score=$(comprehensive_system_analysis)
        
        # システム状態表示
        if [ -f "$SYSTEM_STATE" ]; then
            local ai_status
            local active_workers
            local cpu_usage
            local memory_usage
            local avg_response_time
            
            ai_status=$(jq -r '.ai_system.status' "$SYSTEM_STATE" 2>/dev/null || echo "unknown")
            active_workers=$(jq -r '.ai_system.active_workers' "$SYSTEM_STATE" 2>/dev/null || echo "0")
            cpu_usage=$(jq -r '.system_resources.cpu_usage' "$SYSTEM_STATE" 2>/dev/null || echo "0")
            memory_usage=$(jq -r '.system_resources.memory_usage' "$SYSTEM_STATE" 2>/dev/null || echo "0")
            avg_response_time=$(jq -r '.performance_metrics.avg_response_time' "$SYSTEM_STATE" 2>/dev/null || echo "0")
            
            echo "🤖 AI組織システム状況:"
            echo "  ステータス: $ai_status"
            echo "  アクティブワーカー: ${active_workers}/4"
            echo ""
            echo "💻 システムリソース:"
            echo "  CPU使用率: ${cpu_usage}%"
            echo "  メモリ使用率: ${memory_usage}%"
            echo ""
            echo "⚡ 性能メトリクス:"
            echo "  平均応答時間: ${avg_response_time}秒"
            echo "  性能スコア: ${performance_score}/100"
            
            # 性能スコアに応じた表示色変更
            if [ "$performance_score" -lt 40 ]; then
                echo -e "\033[1;31m  ステータス: 緊急最適化必要\033[0m"
            elif [ "$performance_score" -lt 70 ]; then
                echo -e "\033[1;33m  ステータス: 最適化推奨\033[0m"
            else
                echo -e "\033[1;32m  ステータス: 良好\033[0m"
            fi
        fi
        
        echo ""
        echo "🔧 最適化システム状況:"
        
        if [ -f /tmp/scheduler-monitor.pid ] && kill -0 $(cat /tmp/scheduler-monitor.pid) 2>/dev/null; then
            echo -e "  タスクスケジューラー: \033[1;32m稼働中\033[0m"
        else
            echo -e "  タスクスケジューラー: \033[1;31m停止中\033[0m"
        fi
        
        if [ -f /tmp/memory-engine.pid ] && kill -0 $(cat /tmp/memory-engine.pid) 2>/dev/null; then
            echo -e "  メモリエンジン: \033[1;32m稼働中\033[0m"
        else
            echo -e "  メモリエンジン: \033[1;31m停止中\033[0m"
        fi
        
        echo ""
        echo "📝 最新ログ (最新3行):"
        tail -3 "$ORCHESTRATOR_LOG" 2>/dev/null | sed 's/^/  /' || echo "  ログなし"
        
        echo ""
        echo "🎮 操作: Ctrl+C で終了"
        
        sleep 5
    done
}

# 🔄 継続的最適化監視
continuous_optimization_monitor() {
    log_info "🔄 継続的最適化監視開始"
    
    while true; do
        auto_optimization_engine
        
        # 特殊フラグチェック
        if [ -f /tmp/orchestrator-action.flag ]; then
            local action=$(cat /tmp/orchestrator-action.flag)
            case "$action" in
                "RESTART_RECOMMENDED")
                    log_error "🚨 システム再起動推奨フラグ検出"
                    # 実際の再起動は管理者判断に委ねる
                    ;;
            esac
            rm -f /tmp/orchestrator-action.flag
        fi
        
        sleep 120  # 2分間隔で監視
    done
}

# 🎛️ 設定管理システム
manage_performance_config() {
    local action="$1"
    
    case "$action" in
        "create")
            log_info "🎛️ 性能設定ファイル作成"
            
            local config_json
            config_json=$(cat <<EOF
{
    "optimization_settings": {
        "emergency_threshold": 40,
        "standard_threshold": 70,
        "monitor_interval": 120,
        "memory_pressure_limit": 80,
        "response_time_limit": 200
    },
    "system_limits": {
        "max_workers": 4,
        "max_memory_mb": 2048,
        "max_cpu_percent": 80
    },
    "auto_actions": {
        "enable_emergency_optimization": true,
        "enable_memory_gc": true,
        "enable_process_cleanup": true
    },
    "notifications": {
        "performance_alerts": true,
        "resource_warnings": true,
        "optimization_reports": true
    }
}
EOF
            )
            
            echo "$config_json" > "$PERFORMANCE_CONFIG"
            log_success "✅ 設定ファイル作成完了: $PERFORMANCE_CONFIG"
            ;;
            
        "show")
            if [ -f "$PERFORMANCE_CONFIG" ]; then
                echo "🎛️ 現在の性能設定:"
                jq . "$PERFORMANCE_CONFIG" 2>/dev/null || cat "$PERFORMANCE_CONFIG"
            else
                log_error "❌ 設定ファイルが見つかりません"
            fi
            ;;
    esac
}

# メイン制御
case "${1:-help}" in
    "analyze")
        comprehensive_system_analysis
        ;;
        
    "optimize")
        auto_optimization_engine
        ;;
        
    "emergency")
        execute_emergency_optimization
        ;;
        
    "dashboard")
        performance_dashboard
        ;;
        
    "monitor")
        continuous_optimization_monitor
        ;;
        
    "config")
        manage_performance_config "${2:-show}"
        ;;
        
    "auto")
        log_info "🎼 AI性能オーケストレーター自動実行開始"
        
        # 設定ファイル初期化
        manage_performance_config create
        
        # 初期最適化実行
        auto_optimization_engine
        
        # 継続監視開始
        continuous_optimization_monitor &
        MONITOR_PID=$!
        echo $MONITOR_PID > /tmp/orchestrator.pid
        
        log_success "✅ オーケストレーター自動実行開始 (PID: $MONITOR_PID)"
        ;;
        
    "stop")
        if [ -f /tmp/orchestrator.pid ]; then
            local pid=$(cat /tmp/orchestrator.pid)
            kill $pid 2>/dev/null || true
            rm -f /tmp/orchestrator.pid
            log_info "🛑 オーケストレーター停止完了"
        fi
        
        # 関連システムも停止
        [ -f /tmp/scheduler-monitor.pid ] && "$PROJECT_ROOT/ai-agents/scripts/automation/core/intelligent-task-scheduler.sh" stop
        [ -f /tmp/memory-engine.pid ] && "$PROJECT_ROOT/ai-agents/scripts/automation/core/memory-optimization-engine.sh" stop
        ;;
        
    "status")
        echo "🎼 AI性能オーケストレーター ステータス"
        echo "====================================="
        
        performance_score=$(comprehensive_system_analysis)
        echo "性能スコア: ${performance_score}/100"
        
        if [ -f /tmp/orchestrator.pid ]; then
            pid=$(cat /tmp/orchestrator.pid)
            if kill -0 $pid 2>/dev/null; then
                echo "🟢 オーケストレーター: 稼働中 (PID: $pid)"
            else
                echo "🔴 オーケストレーター: 停止中"
            fi
        else
            echo "🔴 オーケストレーター: 停止中"
        fi
        ;;
        
    *)
        echo "🎼 AI性能オーケストレーター v1.0"
        echo "============================="
        echo ""
        echo "🎯 全システム統合・自動調整・最適化指揮システム"
        echo ""
        echo "使用方法:"
        echo "  $0 analyze     # システム状態総合分析"
        echo "  $0 optimize    # 自動最適化実行"
        echo "  $0 emergency   # 緊急最適化実行"
        echo "  $0 dashboard   # リアルタイム性能ダッシュボード"
        echo "  $0 monitor     # 継続的最適化監視"
        echo "  $0 config      # 設定管理"
        echo "  $0 auto        # 全自動実行"
        echo "  $0 stop        # システム停止"
        echo "  $0 status      # ステータス確認"
        echo ""
        echo "🚀 統合最適化機能:"
        echo "  • システム状態総合分析"
        echo "  • 自動最適化実行エンジン"
        echo "  • 緊急・標準・予防的最適化"
        echo "  • リアルタイム性能ダッシュボード"
        echo "  • 継続的最適化監視"
        echo "  • インテリジェント設定管理"
        echo ""
        echo "🎯 WORKER2・WORKER3 長時間処理問題を完全解決！"
        echo ""
        ;;
esac