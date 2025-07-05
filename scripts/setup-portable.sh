#!/bin/bash

# =============================================================================
# ポータブルセットアップスクリプト
# 任意の環境でAI組織システムを自動セットアップ
# =============================================================================

set -euo pipefail

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${CYAN}==== $1 ====${NC}"; }

# 動的パス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
export PROJECT_ROOT

# プラットフォーム検出スクリプトの読み込み
source "$PROJECT_ROOT/scripts/detect-platform.sh"

# 必須コマンドリスト
REQUIRED_COMMANDS=("tmux" "jq" "git" "curl")
RECOMMENDED_COMMANDS=("gh" "claude")

# 環境検出
detect_environment() {
    log_step "環境検出"
    
    export OS_TYPE=$(detect_os)
    export ARCH_TYPE=$(detect_arch)
    export PKG_MANAGER=$(detect_package_manager)
    
    log_info "OS: $OS_TYPE"
    log_info "アーキテクチャ: $ARCH_TYPE"
    log_info "パッケージマネージャー: $PKG_MANAGER"
    
    # システム情報保存
    get_system_info > "$PROJECT_ROOT/system-info.json"
    log_success "システム情報を保存しました: system-info.json"
}

# 依存関係チェック
check_dependencies() {
    log_step "依存関係チェック"
    
    local missing_required=()
    local missing_recommended=()
    
    # 必須コマンドチェック
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_required+=("$cmd")
            log_warning "必須コマンドが見つかりません: $cmd"
        else
            log_success "$cmd は利用可能です"
        fi
    done
    
    # 推奨コマンドチェック
    for cmd in "${RECOMMENDED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_recommended+=("$cmd")
            log_warning "推奨コマンドが見つかりません: $cmd"
        else
            log_success "$cmd は利用可能です"
        fi
    done
    
    # 不足コマンドの自動インストール提案
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_warning "必須コマンドが不足しています: ${missing_required[*]}"
        read -p "自動インストールを実行しますか？ [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            install_missing_dependencies "${missing_required[@]}"
        else
            log_error "必須コマンドをインストールしてから再実行してください"
            exit 1
        fi
    fi
    
    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
        log_info "推奨コマンドのインストールも可能です: ${missing_recommended[*]}"
        read -p "推奨コマンドもインストールしますか？ [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_missing_dependencies "${missing_recommended[@]}"
        fi
    fi
}

# 不足依存関係のインストール
install_missing_dependencies() {
    local packages=("$@")
    log_step "依存関係インストール"
    
    for package in "${packages[@]}"; do
        # パッケージ名のマッピング
        local pkg_name="$package"
        case "$package" in
            "claude")
                case "$PKG_MANAGER" in
                    "brew") pkg_name="anthropics/claude/claude" ;;
                    *) 
                        log_warning "Claude Code CLIは手動インストールが必要です"
                        log_info "https://claude.ai/code からダウンロードしてください"
                        continue
                        ;;
                esac
                ;;
            "gh")
                case "$PKG_MANAGER" in
                    "apt") pkg_name="gh" ;;
                    "dnf"|"yum") pkg_name="gh" ;;
                    *) pkg_name="gh" ;;
                esac
                ;;
        esac
        
        local install_cmd=$(get_install_command "$PKG_MANAGER" "$pkg_name")
        log_info "実行: $install_cmd"
        
        if eval "$install_cmd"; then
            log_success "$package のインストール完了"
        else
            log_error "$package のインストールに失敗しました"
        fi
    done
}

# 設定ファイル生成
generate_config_files() {
    log_step "設定ファイル生成"
    
    # .mcp.json生成
    if [[ -f "$PROJECT_ROOT/.mcp.json.template" ]]; then
        log_info ".mcp.json を生成中..."
        sed "s|\${PROJECT_ROOT}|$PROJECT_ROOT|g" "$PROJECT_ROOT/.mcp.json.template" > "$PROJECT_ROOT/.mcp.json"
        log_success ".mcp.json を生成しました"
    fi
    
    # 環境設定ファイル生成
    cat > "$PROJECT_ROOT/.env.local" <<EOF
# AI組織システム環境設定
PROJECT_ROOT=$PROJECT_ROOT
OS_TYPE=$OS_TYPE
ARCH_TYPE=$ARCH_TYPE
PKG_MANAGER=$PKG_MANAGER

# MCPサーバー設定
MCP_PORT=\${MCP_PORT:-8765}
WEBSOCKET_PORT=\${WEBSOCKET_PORT:-8080}

# API設定（必要に応じて設定）
# ANTHROPIC_API_KEY=your_api_key_here
# GITHUB_TOKEN=your_github_token_here
# OPENAI_API_KEY=your_openai_api_key_here

# tmux設定
TMUX_SESSION_PREFIX=ai-org
EOF
    
    log_success "環境設定ファイルを生成しました: .env.local"
}

# ディレクトリ構造の確認・修正
verify_directory_structure() {
    log_step "ディレクトリ構造確認"
    
    local required_dirs=(
        "ai-agents/logs"
        "ai-agents/sessions"
        "ai-agents/instructions"
        "ai-agents/configs"
        "logs/ai-agents/president"
        "tmp"
        "docs"
        "reports"
    )
    
    for dir in "${required_dirs[@]}"; do
        local full_path="$PROJECT_ROOT/$dir"
        if [[ ! -d "$full_path" ]]; then
            mkdir -p "$full_path"
            log_info "作成: $dir"
        else
            log_success "確認: $dir"
        fi
    done
}

# 権限設定
set_permissions() {
    log_step "実行権限設定"
    
    local script_files=(
        "ai-team.sh"
        "setup-portable.sh"
        "scripts/detect-platform.sh"
        "ai-agents/manage.sh"
        "ai-agents/scripts/start-president.sh"
        "ai-agents/scripts/load-config.sh"
        "ai-agents/scripts/validate-system.sh"
    )
    
    for script in "${script_files[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        if [[ -f "$script_path" ]]; then
            chmod +x "$script_path"
            log_success "実行権限設定: $script"
        else
            log_warning "ファイルが見つかりません: $script"
        fi
    done
}

# API設定の確認
check_api_configuration() {
    log_step "API設定確認"
    
    local api_configured=false
    
    # Claude API確認
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        log_success "ANTHROPIC_API_KEY が設定されています"
        api_configured=true
    else
        log_warning "ANTHROPIC_API_KEY が未設定です"
    fi
    
    # GitHub Token確認
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_success "GITHUB_TOKEN が設定されています"
        api_configured=true
    else
        log_warning "GITHUB_TOKEN が未設定です"
    fi
    
    if [[ "$api_configured" == false ]]; then
        log_info "API設定については .env.local ファイルを編集してください"
    fi
}

# 初期化完了マーク
mark_initialization_complete() {
    touch "$PROJECT_ROOT/.ai-org-configured"
    cat > "$PROJECT_ROOT/.ai-org-setup-info" <<EOF
{
  "setup_date": "$(date -Iseconds)",
  "os_type": "$OS_TYPE",
  "arch_type": "$ARCH_TYPE",
  "package_manager": "$PKG_MANAGER",
  "project_root": "$PROJECT_ROOT",
  "version": "portable-v1.0"
}
EOF
    log_success "初期化完了マークを作成しました"
}

# 使用方法案内
show_usage_guide() {
    log_step "使用方法案内"
    
    echo -e "${CYAN}🎉 AI組織システムのポータブルセットアップが完了しました！${NC}"
    echo ""
    echo -e "${GREEN}📋 次のステップ:${NC}"
    echo ""
    echo "1. API設定（必要に応じて）:"
    echo "   vim .env.local"
    echo ""
    echo "2. AI組織システム起動:"
    echo "   ./ai-team.sh"
    echo ""
    echo "3. PRESIDENT単体起動:"
    echo "   ./ai-team.sh president"
    echo ""
    echo -e "${BLUE}💡 ヒント:${NC}"
    echo "• 設定確認: ./ai-agents/scripts/validate-system.sh"
    echo "• システム情報: cat system-info.json"
    echo "• 環境設定: cat .env.local"
    echo ""
}

# メイン処理
main() {
    clear
    echo -e "${CYAN}🚀 AI組織システム ポータブルセットアップ${NC}"
    echo "============================================="
    echo ""
    echo "このスクリプトは任意の環境でAI組織システムを自動セットアップします"
    echo ""
    
    detect_environment
    check_dependencies
    generate_config_files
    verify_directory_structure
    set_permissions
    check_api_configuration
    mark_initialization_complete
    show_usage_guide
    
    echo -e "${GREEN}✅ セットアップ完了！${NC}"
}

# エラーハンドリング
trap 'log_error "セットアップ中にエラーが発生しました"; exit 1' ERR

# スクリプト直接実行時のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi