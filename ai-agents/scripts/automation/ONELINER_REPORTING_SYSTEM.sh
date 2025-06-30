#!/bin/bash

# =============================================================================
# 📝 ONELINER_REPORTING_SYSTEM.sh - ワンライナー報告システム
# =============================================================================
# 
# 【目的】: 効率的な状況報告・エラー共有プロトコル確立
# 【機能】: 簡潔報告・即時共有・トークン効率最大化
# 【設計】: Phase 2効率化強化システム
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/logs/oneliner-reports"
REPORT_LOG="$REPORTS_DIR/oneliner-reports.log"

# ディレクトリ作成
mkdir -p "$REPORTS_DIR"

# =============================================================================
# 📊 ワンライナー報告フォーマット
# =============================================================================

generate_status_oneliner() {
    local component="$1"
    local status="$2"
    local details="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] 🎯 $component: $status | $details" | tee -a "$REPORT_LOG"
}

generate_error_oneliner() {
    local component="$1"
    local error_type="$2"
    local fix_action="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] 🚨 $component: $error_type → $fix_action" | tee -a "$REPORT_LOG"
}

generate_progress_oneliner() {
    local task="$1"
    local progress="$2"
    local next_step="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] ⚡ $task: $progress% → $next_step" | tee -a "$REPORT_LOG"
}

# =============================================================================
# 🔄 自動報告システム
# =============================================================================

auto_system_report() {
    echo "📊 自動システム報告生成..." | tee -a "$REPORT_LOG"
    
    # AI組織ステータス
    local boss_status=$(tmux capture-pane -t multiagent:0.0 -p | grep -o ">" | wc -l)
    local worker1_status=$(tmux capture-pane -t multiagent:0.1 -p | grep -o ">" | wc -l)
    local worker2_status=$(tmux capture-pane -t multiagent:0.2 -p | grep -o ">" | wc -l)
    local worker3_status=$(tmux capture-pane -t multiagent:0.3 -p | grep -o ">" | wc -l)
    
    if [ "$boss_status" -eq 0 ]; then
        generate_status_oneliner "BOSS1" "ACTIVE" "処理中・応答可能"
    else
        generate_error_oneliner "BOSS1" "PROMPT停止" "Enter送信必要"
    fi
    
    # ワークロード分散状況
    local workload_balance=$(./ai-agents/scripts/core/WORKLOAD_BALANCING_SYSTEM.sh monitor 2>/dev/null | grep "正常" | wc -l)
    if [ "$workload_balance" -gt 0 ]; then
        generate_status_oneliner "負荷分散" "正常" "最適化済み"
    else
        generate_error_oneliner "負荷分散" "不均衡" "再分散実行"
    fi
}

# =============================================================================
# 📈 即時共有プロトコル
# =============================================================================

instant_share_protocol() {
    local message="$1"
    local priority="${2:-medium}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$priority" in
        "high")
            echo "🚨 [$timestamp] 緊急: $message" | tee -a "$REPORT_LOG"
            # AI組織への緊急通知
            tmux send-keys -t multiagent:0.0 "緊急報告受信：$message - 即座対応・状況確認・必要措置実行せよ。" C-m 2>/dev/null || true
            ;;
        "medium")
            echo "⚡ [$timestamp] 重要: $message" | tee -a "$REPORT_LOG"
            ;;
        "low")
            echo "📝 [$timestamp] 情報: $message" | tee -a "$REPORT_LOG"
            ;;
    esac
}

# =============================================================================
# 🎯 効率報告テンプレート
# =============================================================================

efficiency_report_template() {
    local task_name="$1"
    local start_time="$2"
    local end_time="$3"
    local result="$4"
    
    local duration=$((end_time - start_time))
    
    cat << EOF | tee -a "$REPORT_LOG"
📊 効率報告: $task_name
⏱️ 実行時間: ${duration}秒
✅ 結果: $result
📈 効率度: $(if [ "$duration" -lt 60 ]; then echo "高"; elif [ "$duration" -lt 300 ]; then echo "中"; else echo "要改善"; fi)
EOF
}

# =============================================================================
# 🎯 メイン実行部
# =============================================================================

case "${1:-}" in
    "status")
        generate_status_oneliner "$2" "$3" "$4"
        ;;
    "error")
        generate_error_oneliner "$2" "$3" "$4"
        ;;
    "progress")
        generate_progress_oneliner "$2" "$3" "$4"
        ;;
    "auto")
        auto_system_report
        ;;
    "share")
        instant_share_protocol "$2" "$3"
        ;;
    "efficiency")
        efficiency_report_template "$2" "$3" "$4" "$5"
        ;;
    "view")
        echo "📋 最新ワンライナー報告:"
        tail -20 "$REPORT_LOG"
        ;;
    *)
        echo "📝 ワンライナー報告システム v1.0"
        echo ""
        echo "使用方法:"
        echo "  $0 status [コンポーネント] [ステータス] [詳細]"
        echo "  $0 error [コンポーネント] [エラー種類] [対応アクション]"
        echo "  $0 progress [タスク] [進捗%] [次ステップ]"
        echo "  $0 auto                    # 自動システム報告"
        echo "  $0 share [メッセージ] [優先度]  # 即時共有"
        echo "  $0 efficiency [タスク] [開始時刻] [終了時刻] [結果]"
        echo "  $0 view                    # 最新報告表示"
        ;;
esac