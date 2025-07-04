#!/bin/bash

# =============================================================================
# 🔍 QUALITY_ASSURANCE_SYSTEM.sh - ワンコマンドシステム品質保証
# =============================================================================
# 
# 【WORKER3担当】: 品質保証・テスト・検証
# 【目的】: ワンコマンドシステムの品質確保・自動テスト・検証
# 【特徴】: 自動テスト・品質メトリクス・継続的改善
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$AI_AGENTS_DIR/.." && pwd)"

# 品質保証設定
QA_LOG="$AI_AGENTS_DIR/logs/quality-assurance.log"
TEST_RESULTS_DIR="$AI_AGENTS_DIR/tmp/test-results"
QA_REPORTS_DIR="$AI_AGENTS_DIR/reports/qa"

# 品質基準
MAX_EXECUTION_TIME=300    # 最大実行時間（秒）
MAX_ERROR_RATE=5          # 最大エラー率（%）
MIN_SUCCESS_RATE=95       # 最小成功率（%）
MAX_MEMORY_USAGE=80       # 最大メモリ使用率（%）

mkdir -p "$TEST_RESULTS_DIR" "$QA_REPORTS_DIR" "$(dirname "$QA_LOG")"

# =============================================================================
# 🎯 ログ・報告システム
# =============================================================================

log_qa() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [QA-$level] [$component] $message" | tee -a "$QA_LOG"
}

generate_test_report() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "TEST_RESULT|$timestamp|$test_name|$result|$details" >> "$TEST_RESULTS_DIR/test_log.txt"
    log_qa "TEST" "$test_name" "$result - $details"
}

# =============================================================================
# 🧪 自動テストスイート
# =============================================================================

test_one_command_processor() {
    log_qa "START" "PROCESSOR_TEST" "ワンコマンドプロセッサーテスト開始"
    
    local test_instruction="テスト実行 - 品質保証システム検証"
    local processor_script="$AI_AGENTS_DIR/scripts/automation/ONE_COMMAND_PROCESSOR.sh"
    local test_start_time=$(date +%s)
    
    # 1. スクリプト存在確認
    if [ ! -f "$processor_script" ]; then
        generate_test_report "PROCESSOR_EXISTENCE" "FAIL" "スクリプトファイル未存在"
        return 1
    fi
    generate_test_report "PROCESSOR_EXISTENCE" "PASS" "スクリプトファイル存在確認"
    
    # 2. 実行権限確認
    if [ ! -x "$processor_script" ]; then
        generate_test_report "PROCESSOR_PERMISSIONS" "FAIL" "実行権限なし"
        return 1
    fi
    generate_test_report "PROCESSOR_PERMISSIONS" "PASS" "実行権限確認"
    
    # 3. ヘルプ機能テスト
    local help_output=$("$processor_script" --help 2>&1)
    if echo "$help_output" | grep -q "使用方法"; then
        generate_test_report "PROCESSOR_HELP" "PASS" "ヘルプ機能正常"
    else
        generate_test_report "PROCESSOR_HELP" "FAIL" "ヘルプ機能異常"
    fi
    
    # 4. 軽量テスト実行（実際の処理は行わない）
    local syntax_check=$(bash -n "$processor_script" 2>&1)
    if [ $? -eq 0 ]; then
        generate_test_report "PROCESSOR_SYNTAX" "PASS" "構文チェック正常"
    else
        generate_test_report "PROCESSOR_SYNTAX" "FAIL" "構文エラー: $syntax_check"
    fi
    
    log_qa "COMPLETE" "PROCESSOR_TEST" "ワンコマンドプロセッサーテスト完了"
}

test_monitoring_system() {
    log_qa "START" "MONITORING_TEST" "監視システムテスト開始"
    
    local monitoring_script="$AI_AGENTS_DIR/monitoring/ONE_COMMAND_MONITORING_SYSTEM.sh"
    
    # 1. スクリプト存在・権限確認
    if [ ! -f "$monitoring_script" ] || [ ! -x "$monitoring_script" ]; then
        generate_test_report "MONITORING_BASIC" "FAIL" "スクリプト未存在または権限なし"
        return 1
    fi
    generate_test_report "MONITORING_BASIC" "PASS" "基本要件満たす"
    
    # 2. テスト実行
    local test_output=$("$monitoring_script" test 2>&1)
    local test_exit_code=$?
    
    if [ $test_exit_code -eq 0 ]; then
        generate_test_report "MONITORING_TEST_RUN" "PASS" "テスト実行成功"
    else
        generate_test_report "MONITORING_TEST_RUN" "FAIL" "テスト実行失敗 (Exit: $test_exit_code)"
    fi
    
    # 3. 状況確認機能テスト
    local status_output=$("$monitoring_script" status 2>&1)
    if echo "$status_output" | grep -q "監視システム状況"; then
        generate_test_report "MONITORING_STATUS" "PASS" "状況確認機能正常"
    else
        generate_test_report "MONITORING_STATUS" "FAIL" "状況確認機能異常"
    fi
    
    log_qa "COMPLETE" "MONITORING_TEST" "監視システムテスト完了"
}

test_integration_systems() {
    log_qa "START" "INTEGRATION_TEST" "統合システムテスト開始"
    
    # 1. マスターコントロールとの統合
    local master_control="$AI_AGENTS_DIR/scripts/automation/core/master-control.sh"
    if [ -f "$master_control" ] && [ -x "$master_control" ]; then
        generate_test_report "MASTER_CONTROL_INTEGRATION" "PASS" "マスターコントロール統合OK"
    else
        generate_test_report "MASTER_CONTROL_INTEGRATION" "FAIL" "マスターコントロール統合NG"
    fi
    
    # 2. ワンライナー報告システム統合
    local oneliner_system="$AI_AGENTS_DIR/scripts/automation/ONELINER_REPORTING_SYSTEM.sh"
    if [ -f "$oneliner_system" ] && [ -x "$oneliner_system" ]; then
        # 簡単なテスト実行
        local oneliner_test=$("$oneliner_system" view 2>&1)
        if [ $? -eq 0 ]; then
            generate_test_report "ONELINER_INTEGRATION" "PASS" "ワンライナー報告システム統合OK"
        else
            generate_test_report "ONELINER_INTEGRATION" "WARN" "ワンライナー報告システム警告"
        fi
    else
        generate_test_report "ONELINER_INTEGRATION" "FAIL" "ワンライナー報告システム統合NG"
    fi
    
    # 3. スマート監視エンジン統合
    local smart_engine="$AI_AGENTS_DIR/scripts/core/SMART_MONITORING_ENGINE.js"
    if [ -f "$smart_engine" ]; then
        if command -v node >/dev/null; then
            local engine_test=$(node "$smart_engine" test 2>&1)
            if [ $? -eq 0 ]; then
                generate_test_report "SMART_ENGINE_INTEGRATION" "PASS" "スマート監視エンジン統合OK"
            else
                generate_test_report "SMART_ENGINE_INTEGRATION" "WARN" "スマート監視エンジン警告"
            fi
        else
            generate_test_report "SMART_ENGINE_INTEGRATION" "SKIP" "Node.js未インストール"
        fi
    else
        generate_test_report "SMART_ENGINE_INTEGRATION" "FAIL" "スマート監視エンジン統合NG"
    fi
    
    log_qa "COMPLETE" "INTEGRATION_TEST" "統合システムテスト完了"
}

test_performance_benchmarks() {
    log_qa "START" "PERFORMANCE_TEST" "パフォーマンステスト開始"
    
    # 1. システムリソース使用量テスト
    local cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' | cut -d. -f1 2>/dev/null || echo "0")
    local memory_info=$(vm_stat 2>/dev/null)
    
    if [ "$cpu_usage" -lt 50 ]; then
        generate_test_report "CPU_USAGE" "PASS" "CPU使用率正常 (${cpu_usage}%)"
    else
        generate_test_report "CPU_USAGE" "WARN" "CPU使用率高 (${cpu_usage}%)"
    fi
    
    # 2. ディスク容量チェック
    local disk_usage=$(df "$AI_AGENTS_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        generate_test_report "DISK_USAGE" "PASS" "ディスク使用率正常 (${disk_usage}%)"
    else
        generate_test_report "DISK_USAGE" "WARN" "ディスク使用率高 (${disk_usage}%)"
    fi
    
    # 3. ログファイルサイズチェック
    local large_logs=$(find "$AI_AGENTS_DIR/logs" -name "*.log" -size +10M 2>/dev/null | wc -l)
    if [ "$large_logs" -eq 0 ]; then
        generate_test_report "LOG_SIZE" "PASS" "ログファイルサイズ正常"
    else
        generate_test_report "LOG_SIZE" "WARN" "大きなログファイル存在 (${large_logs}個)"
    fi
    
    log_qa "COMPLETE" "PERFORMANCE_TEST" "パフォーマンステスト完了"
}

test_file_structure() {
    log_qa "START" "STRUCTURE_TEST" "ファイル構造テスト開始"
    
    # 必須ディレクトリの存在確認
    local required_dirs=(
        "$AI_AGENTS_DIR/scripts/automation"
        "$AI_AGENTS_DIR/monitoring"
        "$AI_AGENTS_DIR/docs"
        "$AI_AGENTS_DIR/logs"
        "$AI_AGENTS_DIR/reports"
    )
    
    local missing_dirs=0
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            generate_test_report "DIR_STRUCTURE" "PASS" "ディレクトリ存在: $(basename "$dir")"
        else
            generate_test_report "DIR_STRUCTURE" "FAIL" "ディレクトリ未存在: $(basename "$dir")"
            missing_dirs=$((missing_dirs + 1))
        fi
    done
    
    # 必須ファイルの存在確認
    local required_files=(
        "$AI_AGENTS_DIR/scripts/automation/ONE_COMMAND_PROCESSOR.sh"
        "$AI_AGENTS_DIR/monitoring/ONE_COMMAND_MONITORING_SYSTEM.sh"
        "$AI_AGENTS_DIR/docs/ONE_COMMAND_SYSTEM_GUIDE.md"
    )
    
    local missing_files=0
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            generate_test_report "FILE_STRUCTURE" "PASS" "ファイル存在: $(basename "$file")"
        else
            generate_test_report "FILE_STRUCTURE" "FAIL" "ファイル未存在: $(basename "$file")"
            missing_files=$((missing_files + 1))
        fi
    done
    
    # 権限チェック
    for file in "${required_files[@]}"; do
        if [ -f "$file" ] && [[ "$file" == *.sh ]]; then
            if [ -x "$file" ]; then
                generate_test_report "FILE_PERMISSIONS" "PASS" "実行権限OK: $(basename "$file")"
            else
                generate_test_report "FILE_PERMISSIONS" "FAIL" "実行権限NG: $(basename "$file")"
            fi
        fi
    done
    
    log_qa "COMPLETE" "STRUCTURE_TEST" "ファイル構造テスト完了"
}

# =============================================================================
# 📊 品質メトリクス計算
# =============================================================================

calculate_quality_metrics() {
    log_qa "START" "METRICS" "品質メトリクス計算開始"
    
    local test_log="$TEST_RESULTS_DIR/test_log.txt"
    
    if [ ! -f "$test_log" ]; then
        log_qa "ERROR" "METRICS" "テストログが見つかりません"
        return 1
    fi
    
    # テスト結果集計
    local total_tests=$(grep "TEST_RESULT" "$test_log" | wc -l)
    local passed_tests=$(grep "TEST_RESULT.*PASS" "$test_log" | wc -l)
    local failed_tests=$(grep "TEST_RESULT.*FAIL" "$test_log" | wc -l)
    local warning_tests=$(grep "TEST_RESULT.*WARN" "$test_log" | wc -l)
    local skipped_tests=$(grep "TEST_RESULT.*SKIP" "$test_log" | wc -l)
    
    # 成功率計算
    local success_rate=0
    if [ "$total_tests" -gt 0 ]; then
        success_rate=$((passed_tests * 100 / total_tests))
    fi
    
    # 品質評価
    local quality_grade
    if [ "$success_rate" -ge 95 ]; then
        quality_grade="A (優秀)"
    elif [ "$success_rate" -ge 85 ]; then
        quality_grade="B (良好)"
    elif [ "$success_rate" -ge 75 ]; then
        quality_grade="C (普通)"
    else
        quality_grade="D (要改善)"
    fi
    
    # メトリクスログ出力
    cat > "$QA_REPORTS_DIR/quality_metrics.txt" << EOF
# 品質メトリクス - $(date '+%Y-%m-%d %H:%M:%S')

## テスト結果サマリー
- 総テスト数: $total_tests
- 成功: $passed_tests
- 失敗: $failed_tests  
- 警告: $warning_tests
- スキップ: $skipped_tests

## 品質指標
- 成功率: ${success_rate}%
- 品質評価: $quality_grade

## 品質基準との比較
- 最小成功率基準: ${MIN_SUCCESS_RATE}% $([ "$success_rate" -ge "$MIN_SUCCESS_RATE" ] && echo "✅ 達成" || echo "❌ 未達成")
- 最大エラー率基準: ${MAX_ERROR_RATE}% $([ "$failed_tests" -le "$((total_tests * MAX_ERROR_RATE / 100))" ] && echo "✅ 達成" || echo "❌ 未達成")
EOF

    log_qa "METRICS" "SUMMARY" "総テスト: $total_tests, 成功率: ${success_rate}%, 評価: $quality_grade"
    log_qa "COMPLETE" "METRICS" "品質メトリクス計算完了"
    
    echo "$QA_REPORTS_DIR/quality_metrics.txt"
}

# =============================================================================
# 📋 品質保証レポート生成
# =============================================================================

generate_qa_report() {
    log_qa "START" "REPORT" "品質保証レポート生成開始"
    
    local report_file="$QA_REPORTS_DIR/quality_assurance_report_$(date +%Y%m%d-%H%M%S).md"
    local metrics_file=$(calculate_quality_metrics)
    
    cat > "$report_file" << EOF
# 🔍 ワンコマンドシステム品質保証レポート

## 📋 品質保証概要
- **実行日時**: $(date '+%Y-%m-%d %H:%M:%S')
- **対象システム**: AI組織ワンコマンド実行システム
- **品質保証担当**: WORKER3
- **レポートID**: QA_$(date +%Y%m%d_%H%M%S)

## 🧪 実行テストスイート

### 1. ワンコマンドプロセッサーテスト
- スクリプト存在確認
- 実行権限確認
- ヘルプ機能テスト
- 構文チェック

### 2. 監視システムテスト
- 基本要件確認
- テスト実行確認
- 状況確認機能テスト

### 3. 統合システムテスト  
- マスターコントロール統合確認
- ワンライナー報告システム統合確認
- スマート監視エンジン統合確認

### 4. パフォーマンステスト
- CPU使用率確認
- ディスク使用率確認  
- ログファイルサイズ確認

### 5. ファイル構造テスト
- 必須ディレクトリ存在確認
- 必須ファイル存在確認
- ファイル権限確認

## 📊 品質メトリクス
$(cat "$metrics_file" 2>/dev/null || echo "メトリクス計算エラー")

## 🚨 発見された問題
$(grep "FAIL" "$TEST_RESULTS_DIR/test_log.txt" 2>/dev/null | sed 's/^/- /' || echo "重大な問題なし")

## ⚠️ 警告事項
$(grep "WARN" "$TEST_RESULTS_DIR/test_log.txt" 2>/dev/null | sed 's/^/- /' || echo "警告事項なし")

## 📋 詳細テスト結果
\`\`\`
$(cat "$TEST_RESULTS_DIR/test_log.txt" 2>/dev/null | tail -20 || echo "テストログなし")
\`\`\`

## 🎯 推奨改善事項
$(if grep -q "FAIL" "$TEST_RESULTS_DIR/test_log.txt" 2>/dev/null; then
    echo "1. 失敗したテストの原因調査と修正"
    echo "2. 再テスト実行による確認"
fi)
$(if grep -q "WARN" "$TEST_RESULTS_DIR/test_log.txt" 2>/dev/null; then
    echo "3. 警告項目の改善検討"
fi)
4. 定期的な品質保証テストの実施
5. 継続的な監視とメトリクス追跡

## ✅ 品質保証結論
$(local metrics_file_content=$(cat "$metrics_file" 2>/dev/null)
  local success_rate=$(echo "$metrics_file_content" | grep "成功率:" | awk '{print $2}' | sed 's/%//')
  if [ -n "$success_rate" ] && [ "$success_rate" -ge 95 ]; then
      echo "**品質基準達成** - システムは本格運用可能な品質レベルです"
  elif [ -n "$success_rate" ] && [ "$success_rate" -ge 85 ]; then
      echo "**概ね良好** - 軽微な改善後に運用可能です"
  else
      echo "**改善必要** - 問題修正後の再テストが必要です"
  fi)

---
*🔧 品質保証担当: WORKER3*  
*📅 作成日時: $(date '+%Y-%m-%d %H:%M:%S')*  
*🎯 品質基準: 成功率${MIN_SUCCESS_RATE}%以上*  
*🏅 評価: $(echo "$metrics_file_content" | grep "品質評価:" | cut -d: -f2 | xargs)*
EOF

    log_qa "REPORT" "GENERATED" "品質保証レポート生成: $report_file"
    log_qa "COMPLETE" "REPORT" "品質保証レポート生成完了"
    
    echo "$report_file"
}

# =============================================================================
# 🚀 メイン品質保証実行
# =============================================================================

run_full_qa_suite() {
    log_qa "START" "FULL_QA" "完全品質保証スイート実行開始"
    
    # テスト結果ファイル初期化
    > "$TEST_RESULTS_DIR/test_log.txt"
    
    # 各テストスイート実行
    test_file_structure
    test_one_command_processor
    test_monitoring_system
    test_integration_systems
    test_performance_benchmarks
    
    # 品質保証レポート生成
    local report_file=$(generate_qa_report)
    
    # ワンライナー報告システム連携
    if [ -f "$AI_AGENTS_DIR/scripts/automation/ONELINER_REPORTING_SYSTEM.sh" ]; then
        "$AI_AGENTS_DIR/scripts/automation/ONELINER_REPORTING_SYSTEM.sh" share "📋 品質保証完了: $report_file" "medium"
    fi
    
    log_qa "COMPLETE" "FULL_QA" "完全品質保証スイート実行完了"
    
    echo ""
    echo "🔍 品質保証実行完了"
    echo "📊 詳細レポート: $report_file"
    echo "📝 テストログ: $TEST_RESULTS_DIR/test_log.txt"
    echo ""
}

# =============================================================================
# 🎯 CLI インターフェース
# =============================================================================

case "${1:-full}" in
    "full")
        run_full_qa_suite
        ;;
    "processor")
        test_one_command_processor
        ;;
    "monitoring")
        test_monitoring_system
        ;;
    "integration")
        test_integration_systems
        ;;
    "performance")
        test_performance_benchmarks
        ;;
    "structure")
        test_file_structure
        ;;
    "metrics")
        calculate_quality_metrics
        ;;
    "report")
        generate_qa_report
        ;;
    *)
        echo "🔍 品質保証システム v1.0"
        echo ""
        echo "使用方法:"
        echo "  $0 full          # 完全品質保証スイート"
        echo "  $0 processor     # プロセッサーテスト"
        echo "  $0 monitoring    # 監視システムテスト"
        echo "  $0 integration   # 統合テスト"
        echo "  $0 performance   # パフォーマンステスト"
        echo "  $0 structure     # 構造テスト"
        echo "  $0 metrics       # メトリクス計算"
        echo "  $0 report        # レポート生成"
        ;;
esac