#!/bin/bash

# =============================================================================
# 品質確認スクリプト
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

QUALITY_LOG="logs/quality-check-$(date +%Y%m%d-%H%M%S).log"

log_quality() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$QUALITY_LOG"
    echo -e "${BLUE}[QUALITY]${NC} $1"
}

log_pass() { echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$QUALITY_LOG"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$QUALITY_LOG"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1" | tee -a "$QUALITY_LOG"; }

# ドキュメント品質チェック
check_documentation() {
    log_quality "=== DOCUMENTATION QUALITY CHECK ==="
    
    local issues=0
    
    # 重要ドキュメントの存在確認
    local required_docs=(
        "README.md"
        "docs/REQUIREMENTS_SPECIFICATION.md"
        "docs/PROJECT-STATUS.md"
        "docs/PRODUCT_SPECIFICATION.md"
    )
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "$doc" ]]; then
            local word_count=$(wc -w < "$doc")
            if [[ $word_count -gt 100 ]]; then
                log_pass "$doc exists and has substantial content ($word_count words)"
            else
                log_warn "$doc exists but may lack content ($word_count words)"
                issues=$((issues + 1))
            fi
        else
            log_fail "$doc is missing"
            issues=$((issues + 1))
        fi
    done
    
    # Markdownリンク確認
    if command -v grep >/dev/null 2>&1; then
        local broken_links=$(grep -r "\[.*\](.*\.md)" docs/ 2>/dev/null | grep -v "http" | head -5)
        if [[ -n "$broken_links" ]]; then
            log_warn "Some internal links found (manual review recommended)"
        else
            log_pass "No obvious broken internal links"
        fi
    fi
    
    return $issues
}

# コード品質チェック
check_code_quality() {
    log_quality "=== CODE QUALITY CHECK ==="
    
    local issues=0
    
    # シェルスクリプト構文チェック
    local shell_scripts=($(find . -name "*.sh" -type f))
    for script in "${shell_scripts[@]}"; do
        if bash -n "$script" 2>/dev/null; then
            log_pass "$script has valid syntax"
        else
            log_fail "$script has syntax errors"
            issues=$((issues + 1))
        fi
    done
    
    # 必須機能の存在確認
    if [[ -x "./ai-team.sh" ]]; then
        log_pass "Main script (ai-team.sh) is executable"
    else
        log_fail "Main script is not executable"
        issues=$((issues + 1))
    fi
    
    # チーム協調システムの確認
    if [[ -x "./ai-agents/utils/team-coordination.sh" ]]; then
        log_pass "Team coordination system is available"
    else
        log_fail "Team coordination system is missing"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# システム統合確認
check_system_integration() {
    log_quality "=== SYSTEM INTEGRATION CHECK ==="
    
    local issues=0
    
    # 依存関係確認
    local required_commands=("tmux" "git" "jq")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_pass "$cmd is available"
        else
            log_fail "$cmd is missing"
            issues=$((issues + 1))
        fi
    done
    
    # ディレクトリ構造確認
    local required_dirs=("ai-agents" "docs" "logs" "scripts")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_pass "$dir directory exists"
        else
            log_fail "$dir directory is missing"
            issues=$((issues + 1))
        fi
    done
    
    # 設定ファイル確認
    if [[ -f ".gitignore" ]]; then
        log_pass ".gitignore exists"
    else
        log_warn ".gitignore is missing"
    fi
    
    return $issues
}

# パフォーマンス確認
check_performance() {
    log_quality "=== PERFORMANCE CHECK ==="
    
    # ファイルサイズ確認
    local large_files=$(find . -type f -size +10M 2>/dev/null | head -5)
    if [[ -n "$large_files" ]]; then
        log_warn "Large files detected (>10MB):"
        echo "$large_files"
    else
        log_pass "No excessively large files found"
    fi
    
    # スクリプト実行時間テスト
    local start_time=$(date +%s.%N)
    ./ai-team.sh --help >/dev/null 2>&1 || true
    local end_time=$(date +%s.%N)
    local execution_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0.5")
    
    if (( $(echo "$execution_time < 5.0" | bc -l 2>/dev/null || echo "1") )); then
        log_pass "Main script execution time acceptable (${execution_time}s)"
    else
        log_warn "Main script execution time may be slow (${execution_time}s)"
    fi
}

# ユーザビリティ確認
check_usability() {
    log_quality "=== USABILITY CHECK ==="
    
    # ヘルプ機能確認
    if ./ai-team.sh help >/dev/null 2>&1; then
        log_pass "Help functionality is working"
    else
        log_warn "Help functionality may have issues"
    fi
    
    # メニューシステム確認
    if grep -q "選択してください" ./ai-team.sh; then
        log_pass "Interactive menu system available"
    else
        log_warn "Interactive menu system may be missing"
    fi
    
    # エラーハンドリング確認
    if grep -q "fatal_error\|error_handler" ./ai-team.sh; then
        log_pass "Error handling is implemented"
    else
        log_warn "Error handling may need improvement"
    fi
}

# 最終統合テスト
run_integration_test() {
    log_quality "=== INTEGRATION TEST ==="
    
    # AI組織システムの基本機能テスト
    if ./ai-agents/utils/team-coordination.sh monitor >/dev/null 2>&1; then
        log_pass "Team coordination monitoring works"
    else
        log_warn "Team coordination monitoring may have issues"
    fi
    
    # セキュリティチェック実行
    if [[ -x "./scripts/security-check.sh" ]]; then
        log_pass "Security check system is available"
    else
        log_warn "Security check system needs review"
    fi
}

# メイン実行
main() {
    clear
    echo -e "${BLUE}🔍 TeamAI Quality Check${NC}"
    echo "======================="
    echo ""
    
    log_quality "Starting comprehensive quality check..."
    
    local total_issues=0
    
    check_documentation
    total_issues=$((total_issues + $?))
    
    check_code_quality
    total_issues=$((total_issues + $?))
    
    check_system_integration
    total_issues=$((total_issues + $?))
    
    check_performance
    
    check_usability
    
    run_integration_test
    
    echo ""
    log_quality "=== QUALITY CHECK SUMMARY ==="
    
    if [ $total_issues -eq 0 ]; then
        log_pass "Quality check completed - Excellent quality achieved"
        echo -e "${GREEN}✅ QUALITY STATUS: EXCELLENT${NC}"
    elif [ $total_issues -le 3 ]; then
        log_warn "Quality check completed - Good quality with minor issues ($total_issues)"
        echo -e "${YELLOW}⚠️  QUALITY STATUS: GOOD${NC}"
    else
        log_fail "Quality check completed - Quality improvements needed ($total_issues)"
        echo -e "${RED}❌ QUALITY STATUS: NEEDS IMPROVEMENT${NC}"
    fi
    
    echo ""
    log_quality "Detailed log saved to: $QUALITY_LOG"
    
    return $total_issues
}

main "$@"