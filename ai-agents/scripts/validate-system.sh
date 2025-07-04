#!/bin/bash

# =============================================================================
# AI組織システム検証スクリプト
# エージェント設定の検証と起動状態の確認
# =============================================================================

set -euo pipefail

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 設定ローダーの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh"

# ログ出力
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_info() { echo -e "${BLUE}[i]${NC} $1"; }

# 検証結果の追跡
VALIDATION_PASSED=0
VALIDATION_FAILED=0

# 検証レポート
validation_report() {
    echo ""
    echo -e "${BLUE}=== 検証レポート ===${NC}"
    echo -e "通過: ${GREEN}$VALIDATION_PASSED${NC}"
    echo -e "失敗: ${RED}$VALIDATION_FAILED${NC}"
    echo ""
    
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 全ての検証が完了しました！${NC}"
        return 0
    else
        echo -e "${RED}❌ $VALIDATION_FAILED 件の問題が見つかりました${NC}"
        return 1
    fi
}

# 検証結果の記録
record_result() {
    if [[ "$1" == "pass" ]]; then
        ((VALIDATION_PASSED++))
    else
        ((VALIDATION_FAILED++))
    fi
}

# 1. 設定ファイルの検証
validate_config_files() {
    log_info "設定ファイルの検証..."
    
    # agents.json の検証
    if validate_config > /dev/null 2>&1; then
        log_success "agents.json は有効です"
        record_result "pass"
    else
        log_error "agents.json の検証に失敗しました"
        record_result "fail"
    fi
    
    # 指示書ファイルの存在確認
    local instruction_files=("president.md" "boss.md" "worker.md")
    for file in "${instruction_files[@]}"; do
        local path="$SCRIPT_DIR/../instructions/$file"
        if [[ -f "$path" ]]; then
            log_success "指示書ファイル $file が存在します"
            record_result "pass"
        else
            log_error "指示書ファイル $file が見つかりません: $path"
            record_result "fail"
        fi
    done
}

# 2. tmuxセッションの検証
validate_tmux_sessions() {
    log_info "tmuxセッションの検証..."
    
    # tmux の存在確認
    if ! command -v tmux &> /dev/null; then
        log_error "tmuxコマンドが見つかりません"
        record_result "fail"
        return
    fi
    
    # セッションの存在確認
    local sessions=("president" "multiagent")
    for session in "${sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            log_success "tmuxセッション '$session' が存在します"
            record_result "pass"
            
            # multiagentセッションのペイン確認
            if [[ "$session" == "multiagent" ]]; then
                local pane_count=$(tmux display-message -t "$session" -p "#{window_panes}")
                if [[ "$pane_count" -eq 4 ]]; then
                    log_success "multiagentセッションに4つのペインがあります"
                    record_result "pass"
                else
                    log_warning "multiagentセッションのペイン数が異常です: $pane_count"
                    record_result "fail"
                fi
            fi
        else
            log_warning "tmuxセッション '$session' が見つかりません"
            record_result "fail"
        fi
    done
}

# 3. Claudeプロセスの検証
validate_claude_processes() {
    log_info "Claudeプロセスの検証..."
    
    local claude_count=$(ps aux | grep claude | grep -v grep | wc -l)
    if [[ "$claude_count" -gt 0 ]]; then
        log_success "Claudeプロセスが $claude_count 個実行中です"
        record_result "pass"
        
        # 推奨数の確認（5個: PRESIDENT + 4 WORKERS）
        if [[ "$claude_count" -ge 5 ]]; then
            log_success "推奨数のClaude プロセスが実行中です"
            record_result "pass"
        else
            log_warning "Claudeプロセス数が少ない可能性があります (推奨: 5個以上)"
            record_result "fail"
        fi
    else
        log_error "Claudeプロセスが見つかりません"
        record_result "fail"
    fi
}

# 4. ポートの可用性確認
validate_ports() {
    log_info "ポートの可用性確認..."
    
    local websocket_port=$(load_system_config "websocket_port")
    if [[ -n "$websocket_port" ]]; then
        if lsof -i ":$websocket_port" &>/dev/null; then
            log_success "ポート $websocket_port が使用中です（WebSocketサーバー稼働中）"
            record_result "pass"
        else
            log_warning "ポート $websocket_port が使用されていません"
            record_result "fail"
        fi
    else
        log_error "WebSocketポート設定が見つかりません"
        record_result "fail"
    fi
}

# 5. ログファイルの確認
validate_log_files() {
    log_info "ログファイルの確認..."
    
    local log_dir="$SCRIPT_DIR/../../logs/ai-agents"
    if [[ -d "$log_dir" ]]; then
        log_success "ログディレクトリが存在します: $log_dir"
        record_result "pass"
        
        # 最新のログファイルの確認
        local log_files=($(find "$log_dir" -name "*.log" -type f 2>/dev/null))
        if [[ ${#log_files[@]} -gt 0 ]]; then
            log_success "ログファイルが ${#log_files[@]} 個見つかりました"
            record_result "pass"
        else
            log_warning "ログファイルが見つかりません"
            record_result "fail"
        fi
    else
        log_warning "ログディレクトリが見つかりません: $log_dir"
        record_result "fail"
    fi
}

# 6. エージェント通信の検証
validate_agent_communication() {
    log_info "エージェント通信の検証..."
    
    # tmuxセッションが存在する場合のみ実行
    if tmux has-session -t "president" 2>/dev/null; then
        # PRESIDENTセッションの最新の出力を確認
        local president_output
        president_output=$(tmux capture-pane -t "president" -p 2>/dev/null | tail -5)
        
        if [[ -n "$president_output" ]]; then
            log_success "PRESIDENTセッションからの出力を確認しました"
            record_result "pass"
        else
            log_warning "PRESIDENTセッションからの出力が見つかりません"
            record_result "fail"
        fi
    else
        log_warning "PRESIDENTセッションが存在しないため、通信検証をスキップしました"
        record_result "fail"
    fi
}

# メイン検証プロセス
main() {
    echo -e "${BLUE}🔍 AI組織システム検証を開始します...${NC}"
    echo ""
    
    # 依存関係の確認
    check_jq
    check_config_file
    
    # 各種検証の実行
    validate_config_files
    validate_tmux_sessions
    validate_claude_processes
    validate_ports
    validate_log_files
    validate_agent_communication
    
    # 検証結果の表示
    validation_report
}

# スクリプトが直接実行された場合のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi