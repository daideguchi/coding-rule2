#!/bin/bash

# =============================================================================
# セキュリティチェックスクリプト
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SECURITY_LOG="logs/security-check-$(date +%Y%m%d-%H%M%S).log"

log_security() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SECURITY_LOG"
    echo -e "${BLUE}[SECURITY]${NC} $1"
}

log_success() { echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$SECURITY_LOG"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$SECURITY_LOG"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1" | tee -a "$SECURITY_LOG"; }

# 機密情報チェック
check_sensitive_data() {
    log_security "=== SENSITIVE DATA CHECK ==="
    
    local issues=0
    
    # API Key漏洩チェック
    if grep -r "sk-" . --exclude-dir=.git --exclude="*.log" 2>/dev/null | grep -v "sk-\*\*\*" | grep -v "sk-..." > /dev/null; then
        log_error "Potential API keys found in files"
        issues=$((issues + 1))
    else
        log_success "No exposed API keys found"
    fi
    
    # パスワード・トークンチェック
    if grep -ri "password\|token\|secret" . --exclude-dir=.git --exclude="*.log" --include="*.sh" --include="*.md" | grep -v "password:" | grep -v "token:" | head -5; then
        log_warning "Potential sensitive terms found (manual review required)"
    else
        log_success "No obvious sensitive data patterns found"
    fi
    
    # 個人情報チェック
    if grep -r "/Users/[^/]*/Desktop" . --exclude-dir=.git --exclude="*.log" 2>/dev/null | head -5; then
        log_warning "Personal directory paths found (manual review required)"
    else
        log_success "No personal directory paths exposed"
    fi
    
    return $issues
}

# ファイル権限チェック
check_file_permissions() {
    log_security "=== FILE PERMISSIONS CHECK ==="
    
    local issues=0
    
    # 実行可能ファイルの権限確認
    local executables=($(find . -name "*.sh" -type f))
    for file in "${executables[@]}"; do
        if [[ ! -x "$file" ]]; then
            log_warning "$file is not executable"
        else
            log_success "$file has correct permissions"
        fi
    done
    
    # 過度に開放的な権限チェック
    if find . -type f -perm 777 2>/dev/null | head -1; then
        log_error "Files with 777 permissions found"
        issues=$((issues + 1))
    else
        log_success "No overly permissive files found"
    fi
    
    return $issues
}

# スクリプト脆弱性チェック
check_script_vulnerabilities() {
    log_security "=== SCRIPT VULNERABILITY CHECK ==="
    
    local issues=0
    
    # 危険なコマンド使用チェック
    if grep -r "rm -rf \*\|rm -rf /\|eval.*\$\|bash.*\$" . --include="*.sh" 2>/dev/null; then
        log_error "Potentially dangerous commands found"
        issues=$((issues + 1))
    else
        log_success "No dangerous command patterns found"
    fi
    
    # 未検証入力使用チェック  
    if grep -r "bash.*\$1\|sh.*\$\{" . --include="*.sh" 2>/dev/null; then
        log_warning "Unvalidated input usage found (manual review required)"
    else
        log_success "No obvious unvalidated input usage"
    fi
    
    # set -e使用確認
    local shell_scripts=($(find . -name "*.sh" -type f))
    for script in "${shell_scripts[@]}"; do
        if ! grep -q "set -e" "$script" 2>/dev/null; then
            log_warning "$script does not use 'set -e'"
        fi
    done
    
    return $issues
}

# 依存関係セキュリティチェック
check_dependencies() {
    log_security "=== DEPENDENCY SECURITY CHECK ==="
    
    # 必要なコマンドの存在確認
    local required_commands=("tmux" "jq" "git")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "$cmd is available"
        else
            log_error "$cmd is missing"
        fi
    done
    
    # tmuxセキュリティ設定確認
    if tmux show-options -g | grep -q "escape-time"; then
        log_success "tmux security options configured"
    else
        log_warning "tmux security options may need review"
    fi
}

# ログセキュリティチェック
check_log_security() {
    log_security "=== LOG SECURITY CHECK ==="
    
    # ログファイル内の機密情報チェック
    if find logs/ -name "*.log" -exec grep -l "password\|token\|sk-" {} \; 2>/dev/null; then
        log_warning "Potential sensitive data in log files"
    else
        log_success "No sensitive data found in logs"
    fi
    
    # ログファイル権限確認
    if find logs/ -type f -perm +044 2>/dev/null | head -1; then
        log_warning "Log files may be too accessible"
    else
        log_success "Log file permissions are appropriate"
    fi
}

# Git履歴セキュリティチェック
check_git_security() {
    log_security "=== GIT SECURITY CHECK ==="
    
    # Git履歴内の機密情報チェック
    if git log --all --full-history --grep="password\|token\|secret" --oneline 2>/dev/null | head -5; then
        log_warning "Potential sensitive data in Git history"
    else
        log_success "No obvious sensitive data in Git history"
    fi
    
    # .gitignore確認
    if [[ -f ".gitignore" ]]; then
        if grep -q "\.env\|\.key\|credentials" .gitignore; then
            log_success ".gitignore properly configured for sensitive files"
        else
            log_warning ".gitignore may need sensitive file patterns"
        fi
    else
        log_warning ".gitignore file not found"
    fi
}

# メイン実行
main() {
    clear
    echo -e "${BLUE}🔒 TeamAI Security Check${NC}"
    echo "=========================="
    echo ""
    
    log_security "Starting comprehensive security check..."
    
    local total_issues=0
    
    check_sensitive_data
    total_issues=$((total_issues + $?))
    
    check_file_permissions  
    total_issues=$((total_issues + $?))
    
    check_script_vulnerabilities
    total_issues=$((total_issues + $?))
    
    check_dependencies
    
    check_log_security
    
    check_git_security
    
    echo ""
    log_security "=== SECURITY CHECK SUMMARY ==="
    
    if [ $total_issues -eq 0 ]; then
        log_success "Security check completed - No critical issues found"
        echo -e "${GREEN}✅ SECURITY STATUS: PASS${NC}"
    elif [ $total_issues -le 2 ]; then
        log_warning "Security check completed - Minor issues found ($total_issues)"
        echo -e "${YELLOW}⚠️  SECURITY STATUS: REVIEW REQUIRED${NC}"
    else
        log_error "Security check completed - Critical issues found ($total_issues)"
        echo -e "${RED}❌ SECURITY STATUS: ACTION REQUIRED${NC}"
    fi
    
    echo ""
    log_security "Detailed log saved to: $SECURITY_LOG"
}

main "$@"