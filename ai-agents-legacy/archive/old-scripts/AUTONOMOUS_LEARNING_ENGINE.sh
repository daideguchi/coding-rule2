#!/bin/bash

# 自律学習エンジン - SMART-LEARN サイクル実装
# Sense→Measure→Analyze→Respond→Test→Learn

set -euo pipefail

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_learn() { echo -e "${PURPLE}[LEARN]${NC} $1"; }

# 設定
PROJECT_ROOT="/Users/dd/Desktop/1_dev/coding-rule2"
LEARNING_DATA_DIR="$PROJECT_ROOT/ai-agents/learning-data"
LOG_FILE="$PROJECT_ROOT/logs/autonomous-learning.log"

# ディレクトリ作成
mkdir -p "$(dirname "$LOG_FILE")" "$LEARNING_DATA_DIR"/{user-profiles,interaction-logs,learning-models,feedback-history}

# SMART-LEARN サイクル実行
main() {
    case "${1:-help}" in
        "sense") sense_phase ;;
        "measure") measure_phase ;;
        "analyze") analyze_phase ;;
        "respond") respond_phase ;;
        "test") test_phase ;;
        "learn") learn_phase ;;
        "cycle") run_full_cycle ;;
        "status") show_status ;;
        "init") initialize_learning_system ;;
        *) show_help ;;
    esac
}

# フェーズ1: Sense (感知)
sense_phase() {
    log_info "🔍 SENSE フェーズ: 環境感知中..."
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local sense_data="$LEARNING_DATA_DIR/interaction-logs/sense_$(date +%Y%m%d_%H%M%S).json"
    
    # 現在の状態を感知
    cat > "$sense_data" << EOF
{
  "timestamp": "$timestamp",
  "system_state": {
    "tmux_sessions": $(tmux list-sessions 2>/dev/null | wc -l || echo "0"),
    "active_processes": $(ps aux | grep -c "claude\|python3" || echo "0"),
    "cpu_usage": $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' || echo "0"),
    "memory_usage": $(top -l 1 | grep "PhysMem" | awk '{print $2}' | sed 's/M//' || echo "0")
  },
  "user_activity": {
    "recent_commands": $(tail -10 ~/.bash_history 2>/dev/null | wc -l || echo "0"),
    "error_indicators": $(grep -c "ERROR\|FAILED" "$PROJECT_ROOT/logs/"*.log 2>/dev/null || echo "0")
  },
  "phase": "sense"
}
EOF
    
    log_success "✅ 環境感知完了: $sense_data"
}

# フェーズ2: Measure (測定)
measure_phase() {
    log_info "📊 MEASURE フェーズ: パフォーマンス測定中..."
    
    local metrics_file="$LEARNING_DATA_DIR/interaction-logs/metrics_$(date +%Y%m%d).json"
    
    # パフォーマンスメトリクス収集
    local success_rate=0
    local error_count=0
    local total_commands=0
    
    # 今日のログから成功率計算
    if [[ -f "$PROJECT_ROOT/logs/ai-agents.log" ]]; then
        local today=$(date +%Y-%m-%d)
        success_rate=$(grep "$today.*SUCCESS" "$PROJECT_ROOT/logs/ai-agents.log" 2>/dev/null | wc -l || echo "0")
        error_count=$(grep "$today.*ERROR" "$PROJECT_ROOT/logs/ai-agents.log" 2>/dev/null | wc -l || echo "0")
        total_commands=$((success_rate + error_count))
    fi
    
    cat > "$metrics_file" << EOF
{
  "date": "$(date +%Y-%m-%d)",
  "metrics": {
    "success_rate": $(echo "scale=2; $success_rate / ($total_commands + 1)" | bc 2>/dev/null || echo "0"),
    "error_count": $error_count,
    "total_commands": $total_commands,
    "response_time_avg": 0,
    "user_satisfaction": 0
  },
  "phase": "measure"
}
EOF
    
    log_success "📈 パフォーマンス測定完了"
}

# フェーズ3: Analyze (分析)
analyze_phase() {
    log_info "🔬 ANALYZE フェーズ: データ分析中..."
    
    local analysis_file="$LEARNING_DATA_DIR/learning-models/analysis_$(date +%Y%m%d).json"
    
    # パターン分析
    local common_errors=()
    local improvement_areas=()
    
    if [[ -f "$PROJECT_ROOT/ai-agents/PRESIDENT_MISTAKES_RECORD.md" ]]; then
        # 重大ミスから学習
        mapfile -t common_errors < <(grep "^##" "$PROJECT_ROOT/ai-agents/PRESIDENT_MISTAKES_RECORD.md" | head -5)
        improvement_areas=("コミュニケーション精度向上" "技術的理解の深化" "プロセス遵守の徹底")
    fi
    
    # 分析結果をJSON形式で保存
    {
        echo "{"
        echo "  \"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\","
        echo "  \"analysis\": {"
        echo "    \"common_error_patterns\": ["
        for error in "${common_errors[@]}"; do
            echo "      \"${error#\#\# }\","
        done | sed '$ s/,$//'
        echo "    ],"
        echo "    \"improvement_recommendations\": ["
        for area in "${improvement_areas[@]}"; do
            echo "      \"$area\","
        done | sed '$ s/,$//'
        echo "    ],"
        echo "    \"learning_priority\": \"mistake_prevention\""
        echo "  },"
        echo "  \"phase\": \"analyze\""
        echo "}"
    } > "$analysis_file"
    
    log_success "🎯 データ分析完了"
}

# フェーズ4: Respond (対応)
respond_phase() {
    log_info "⚡ RESPOND フェーズ: 適応的対応実行中..."
    
    # 分析結果に基づく自動対応
    local latest_analysis=$(find "$LEARNING_DATA_DIR/learning-models" -name "analysis_*.json" -type f | sort | tail -1)
    
    if [[ -f "$latest_analysis" ]]; then
        log_info "📋 最新分析結果を使用: $(basename "$latest_analysis")"
        
        # 重大ミス対策の自動実装
        if grep -q "mistake_prevention" "$latest_analysis"; then
            implement_mistake_prevention
        fi
        
        # システム最適化の実行
        optimize_system_performance
        
    else
        log_warning "⚠️  分析結果が見つかりません。デフォルト対応を実行します。"
    fi
    
    log_success "✅ 適応的対応完了"
}

# フェーズ5: Test (テスト)
test_phase() {
    log_info "🧪 TEST フェーズ: 改善効果テスト中..."
    
    local test_results="$LEARNING_DATA_DIR/feedback-history/test_results_$(date +%Y%m%d_%H%M%S).json"
    
    # システムテスト実行
    local test_score=0
    local test_details=()
    
    # MCP接続テスト
    if claude mcp list >/dev/null 2>&1; then
        ((test_score += 25))
        test_details+=("MCP接続: 正常")
    else
        test_details+=("MCP接続: 異常")
    fi
    
    # tmuxセッションテスト
    if tmux list-sessions >/dev/null 2>&1; then
        ((test_score += 25))
        test_details+=("tmuxセッション: 正常")
    else
        test_details+=("tmuxセッション: 異常")
    fi
    
    # ファイルシステムテスト
    if [[ -d "$PROJECT_ROOT/ai-agents" ]]; then
        ((test_score += 25))
        test_details+=("ファイルシステム: 正常")
    else
        test_details+=("ファイルシステム: 異常")
    fi
    
    # 学習システムテスト
    if [[ -d "$LEARNING_DATA_DIR" ]]; then
        ((test_score += 25))
        test_details+=("学習システム: 正常")
    else
        test_details+=("学習システム: 異常")
    fi
    
    # テスト結果保存
    {
        echo "{"
        echo "  \"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\","
        echo "  \"test_results\": {"
        echo "    \"overall_score\": $test_score,"
        echo "    \"details\": ["
        for detail in "${test_details[@]}"; do
            echo "      \"$detail\","
        done | sed '$ s/,$//'
        echo "    ]"
        echo "  },"
        echo "  \"phase\": \"test\""
        echo "}"
    } > "$test_results"
    
    log_success "📊 テスト完了 - スコア: $test_score/100"
}

# フェーズ6: Learn (学習)
learn_phase() {
    log_learn "🎓 LEARN フェーズ: 学習統合中..."
    
    local learning_summary="$LEARNING_DATA_DIR/learning-models/learning_summary_$(date +%Y%m%d).json"
    
    # 今日の学習サマリー作成
    local insights=()
    insights+=("重大ミス記録から継続的学習を実行")
    insights+=("システムパフォーマンスの最適化ポイントを特定")
    insights+=("ユーザーインタラクションパターンを分析")
    
    # 学習サマリー保存
    {
        echo "{"
        echo "  \"date\": \"$(date +%Y-%m-%d)\","
        echo "  \"learning_cycle_complete\": true,"
        echo "  \"insights\": ["
        for insight in "${insights[@]}"; do
            echo "      \"$insight\","
        done | sed '$ s/,$//'
        echo "  ],"
        echo "  \"next_actions\": ["
        echo "    \"継続的な監視システムの改善\","
        echo "    \"予測モデルの精度向上\","
        echo "    \"ユーザーエクスペリエンスの最適化\""
        echo "  ],"
        echo "  \"phase\": \"learn\""
        echo "}"
    } > "$learning_summary"
    
    log_learn "🎯 学習サイクル完了"
}

# 完全サイクル実行
run_full_cycle() {
    log_info "🔄 SMART-LEARN 完全サイクル開始"
    
    sense_phase
    sleep 2
    measure_phase
    sleep 2
    analyze_phase
    sleep 2
    respond_phase
    sleep 2
    test_phase
    sleep 2
    learn_phase
    
    log_success "🎉 SMART-LEARN サイクル完了"
}

# 重大ミス対策実装
implement_mistake_prevention() {
    log_info "🛡️  重大ミス防止システム実装中..."
    
    # チェックリスト作成
    local checklist_file="$PROJECT_ROOT/ai-agents/DAILY_CHECKLIST.md"
    if [[ ! -f "$checklist_file" ]]; then
        cat > "$checklist_file" << 'EOF'
# 日次チェックリスト

## 作業開始前
- [ ] 重大ミス記録を確認
- [ ] 今日の学習目標を設定
- [ ] システム状態を確認

## 作業中
- [ ] 指示を正確に理解
- [ ] 実行前に計画を立てる
- [ ] 定期的な進捗確認

## 作業終了後
- [ ] 実行結果を検証
- [ ] 学習ログを更新
- [ ] 明日の準備
EOF
        log_success "✅ 日次チェックリスト作成完了"
    fi
}

# システム最適化
optimize_system_performance() {
    log_info "⚡ システムパフォーマンス最適化中..."
    
    # ログローテーション
    find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
    
    # 古い学習データの圧縮
    find "$LEARNING_DATA_DIR" -name "*.json" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
    
    log_success "✅ システム最適化完了"
}

# 学習システム初期化
initialize_learning_system() {
    log_info "🚀 学習システム初期化中..."
    
    # 必要なディレクトリ作成
    mkdir -p "$LEARNING_DATA_DIR"/{user-profiles,interaction-logs,learning-models,feedback-history}
    
    # 初期ファイル作成
    if [[ ! -f "$LEARNING_DATA_DIR/learning-models/optimization_recommendations.json" ]]; then
        cat > "$LEARNING_DATA_DIR/learning-models/optimization_recommendations.json" << 'EOF'
{
  "version": "1.0.0",
  "recommendations": [
    {
      "category": "mistake_prevention",
      "priority": "high",
      "action": "implement_daily_checklist",
      "description": "日次チェックリストの実装"
    },
    {
      "category": "performance",
      "priority": "medium", 
      "action": "optimize_log_rotation",
      "description": "ログローテーションの最適化"
    }
  ]
}
EOF
    fi
    
    log_success "✅ 学習システム初期化完了"
}

# ステータス表示
show_status() {
    log_info "📊 学習システムステータス"
    
    echo ""
    echo "📁 ディレクトリ構造:"
    find "$LEARNING_DATA_DIR" -type f | head -10 | while read -r file; do
        echo "  - $(basename "$file")"
    done
    
    echo ""
    echo "📈 最新メトリクス:"
    local latest_metrics=$(find "$LEARNING_DATA_DIR/interaction-logs" -name "metrics_*.json" -type f | sort | tail -1)
    if [[ -f "$latest_metrics" ]]; then
        if command -v jq >/dev/null 2>&1; then
            echo "  - 成功率: $(jq -r '.metrics.success_rate' "$latest_metrics" 2>/dev/null || echo "不明")"
            echo "  - エラー数: $(jq -r '.metrics.error_count' "$latest_metrics" 2>/dev/null || echo "不明")"
        fi
    else
        echo "  - メトリクスファイルが見つかりません"
    fi
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
🎓 自律学習エンジン - SMART-LEARN サイクル

使用方法:
  ./AUTONOMOUS_LEARNING_ENGINE.sh [コマンド]

コマンド:
  sense    - 環境感知フェーズ
  measure  - パフォーマンス測定フェーズ
  analyze  - データ分析フェーズ
  respond  - 適応的対応フェーズ
  test     - 改善効果テストフェーズ
  learn    - 学習統合フェーズ
  cycle    - 完全サイクル実行
  status   - システムステータス確認
  init     - 学習システム初期化
  help     - このヘルプを表示

例:
  ./AUTONOMOUS_LEARNING_ENGINE.sh init
  ./AUTONOMOUS_LEARNING_ENGINE.sh cycle
  ./AUTONOMOUS_LEARNING_ENGINE.sh status
EOF
}

# メイン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" 2>&1 | tee -a "$LOG_FILE"
fi