#!/bin/bash

# =============================================================================
# 必須確認事項ベリフィケーションシステム
# PRESIDENT作業開始前の強制確認システム
# =============================================================================

set -euo pipefail

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${PURPLE}==== $1 ====${NC}"; }

# 動的パス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 必須確認ファイルリスト（外部設定から読み込み）
REQUIRED_FILES_CONFIG="$PROJECT_ROOT/config/system/required_files.txt"

# 必須ファイルリストを動的読み込み
load_required_files() {
    if [[ ! -f "$REQUIRED_FILES_CONFIG" ]]; then
        log_error "必須ファイル設定が見つかりません: $REQUIRED_FILES_CONFIG"
        return 1
    fi
    
    # コメント行と空行を除外してファイルリストを作成
    MANDATORY_FILES=()
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
            MANDATORY_FILES+=("$line")
        fi
    done < "$REQUIRED_FILES_CONFIG"
    
    log_info "設定ファイルから${#MANDATORY_FILES[@]}個の必須ファイルを読み込みました"
}

# 必須確認フロー
mandatory_verification() {
    log_step "🚨 PRESIDENT必須確認事項ベリフィケーション"
    
    local all_verified=true
    
    # 0. 必須ファイルリスト読み込み
    log_info "Step 0: 必須ファイルリスト読み込み"
    if ! load_required_files; then
        return 1
    fi
    
    # 1. 必須ファイル存在確認
    log_info "Step 1: 必須ファイル存在確認"
    for file in "${MANDATORY_FILES[@]}"; do
        local file_path="$PROJECT_ROOT/$file"
        if [[ -f "$file_path" ]]; then
            log_success "✅ $file"
        else
            log_error "❌ $file - File does not exist"
            all_verified=false
        fi
    done
    
    if [[ "$all_verified" == false ]]; then
        log_error "必須ファイルが不足しています。作業を中断します。"
        return 1
    fi
    
    # 2. cursor rules確認強制
    log_info "Step 2: globals.mdc確認義務"
    echo -e "${YELLOW}globals.mdc を確認してください:${NC}"
    echo "場所: $PROJECT_ROOT/.cursor/rules/globals.mdc"
    read -p "確認しましたか？ [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        log_error "globals.mdc確認は必須です。作業を中断します。"
        return 1
    fi
    log_success "✅ globals.mdc確認完了"
    
    # 3. PRESIDENT_MISTAKES.md学習強制
    log_info "Step 3: PRESIDENT_MISTAKES.md学習義務"
    local mistakes_file="$PROJECT_ROOT/logs/agents/ai-agents/president/PRESIDENT_MISTAKES.md"
    local mistake_count=$(grep -c "### [0-9]" "$mistakes_file" 2>/dev/null || echo "0")
    echo -e "${YELLOW}PRESIDENT_MISTAKES.md (${mistake_count}回分の失敗記録) を確認してください:${NC}"
    echo "場所: $mistakes_file"
    read -p "失敗記録を確認しましたか？ [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        log_error "失敗記録確認は必須です。作業を中断します。"
        return 1
    fi
    log_success "✅ ${mistake_count}回分の失敗記録確認完了"
    
    # 4. work-records.md記録準備
    log_info "Step 4: work-records.md記録システム確認"
    local work_records="$PROJECT_ROOT/logs/work-records.md"
    if [[ -f "$work_records" ]]; then
        local last_record=$(grep -o "#[0-9]\{3\}" "$work_records" | tail -1 | sed 's/#//' | sed 's/^0*//')
        local next_record=$((${last_record:-0} + 1))
        log_success "✅ 次の作業記録番号: #$(printf "%03d" $next_record)"
        export NEXT_WORK_RECORD_NUMBER="$next_record"
    else
        log_error "work-records.md が見つかりません"
        return 1
    fi
    
    # 5. 処理フロー確認
    log_info "Step 5: 5段階処理フロー確認"
    echo -e "${YELLOW}必須の5段階処理フロー:${NC}"
    echo "Phase 1: 作業受領・計画"
    echo "Phase 2: 作業実行・記録"  
    echo "Phase 3: 完了・報告"
    echo "※各フェーズで記録更新必須"
    read -p "処理フローを理解しましたか？ [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        log_error "処理フロー理解は必須です。作業を中断します。"
        return 1
    fi
    log_success "✅ 5段階処理フロー確認完了"
    
    # 6. 最終確認
    log_step "🎯 必須確認事項完了"
    echo -e "${GREEN}すべての必須確認事項が完了しました。${NC}"
    echo -e "${BLUE}作業開始の準備が整いました。${NC}"
    
    # 確認完了のマーク
    echo "$(date -Iseconds)" > "/tmp/president_verification_completed"
    
    return 0
}

# 確認済みかチェック
check_verification_status() {
    if [[ -f "/tmp/president_verification_completed" ]]; then
        local verification_time=$(cat "/tmp/president_verification_completed")
        local current_time=$(date -Iseconds)
        local time_diff=$(($(date -d "$current_time" +%s) - $(date -d "$verification_time" +%s)))
        
        # 1時間以内なら有効
        if [[ $time_diff -lt 3600 ]]; then
            log_success "✅ 必須確認事項は完了済みです (${verification_time})"
            return 0
        else
            log_warning "⚠️ 確認から1時間経過しています。再確認が必要です。"
            rm -f "/tmp/president_verification_completed"
            return 1
        fi
    else
        log_error "❌ 必須確認事項が未完了です。"
        return 1
    fi
}

# メイン処理
main() {
    clear
    echo -e "${PURPLE}🎯 PRESIDENT必須確認システム${NC}"
    echo "======================================"
    echo ""
    
    if [[ "${1:-}" == "check" ]]; then
        check_verification_status
    else
        mandatory_verification
    fi
}

# エラーハンドリング
trap 'log_error "確認プロセス中にエラーが発生しました"; exit 1' ERR

# スクリプト直接実行時のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi