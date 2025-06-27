#!/bin/bash

# 🚀 CodingRule2 クイックインストール
# curlワンコマンドでの完全セットアップ

set -e

REPO_URL="https://github.com/your-repo/coding-rule2"
INSTALL_DIR="coding-rule2"
VERSION="2.0.0"

# 色付きログ
log_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

log_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

# ヘッダー表示
show_header() {
    echo ""
    echo "🚀 ============================================="
    echo "   CodingRule2 クイックインストール v$VERSION"
    echo "   🤖 AI組織開発システム - 日本語完全対応"
    echo "============================================= 🚀"
    echo ""
}

# 環境チェック
check_environment() {
    log_info "環境チェック中..."
    
    # Git確認
    if ! command -v git &> /dev/null; then
        log_error "Gitがインストールされていません"
        exit 1
    fi
    
    # curl確認
    if ! command -v curl &> /dev/null; then
        log_error "curlがインストールされていません"
        exit 1
    fi
    
    # tmux確認
    if ! command -v tmux &> /dev/null; then
        log_warning "tmuxがインストールされていません（AI組織システムに必要）"
        echo "インストール方法:"
        echo "  macOS: brew install tmux"
        echo "  Ubuntu: sudo apt install tmux"
        echo "  CentOS: sudo yum install tmux"
        echo ""
        read -p "続行しますか？ (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "環境チェック完了"
}

# リポジトリクローン
clone_repository() {
    log_info "リポジトリをクローン中..."
    
    # 既存ディレクトリの確認
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warning "ディレクトリ '$INSTALL_DIR' が既に存在します"
        read -p "削除して続行しますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            log_info "既存ディレクトリを削除しました"
        else
            log_error "インストールを中止しました"
            exit 1
        fi
    fi
    
    # クローン実行
    git clone "$REPO_URL.git" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log_success "リポジトリクローン完了"
}

# 権限設定
setup_permissions() {
    log_info "実行権限を設定中..."
    
    # 主要スクリプトに実行権限付与
    local scripts=(
        "setup.sh"
        "ai-agents/manage.sh"
        "ai-agents/permission-manager.sh"
        "ai-agents/decision-workflow.sh"
        "ai-agents/monitoring-dashboard.sh"
        "ai-agents/organization-manager.sh"
        "scripts/sync-cursor-rules.sh"
        "scripts/status-checker.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            log_info "✅ $script"
        else
            log_warning "⚠️ $script が見つかりません"
        fi
    done
    
    log_success "権限設定完了"
}

# 初期セットアップ実行
run_initial_setup() {
    log_info "初期セットアップを実行中..."
    
    if [[ -f "setup.sh" ]]; then
        # 自動セットアップ（完全版を選択）
        echo "3" | ./setup.sh
        log_success "初期セットアップ完了"
    else
        log_error "setup.shが見つかりません"
        exit 1
    fi
}

# 認証設定ガイド
show_auth_guide() {
    echo ""
    echo "🔐 ==============================================="
    echo "            認証設定が必要です"
    echo "=============================================== 🔐"
    echo ""
    echo "次のいずれかの方法で認証を設定してください："
    echo ""
    echo "📋 方法1: Pro プラン（推奨）"
    echo "   claude.ai Pro プランで高性能・安定・月額固定"
    echo ""
    echo "📋 方法2: API Key"
    echo "   ANTHROPIC_API_KEY で従量課金・開発者向け"
    echo ""
    echo "実行コマンド:"
    echo "   ./setup.sh → a) 認証設定 → 使いたい方法を選択"
    echo ""
}

# 使用方法ガイド
show_usage_guide() {
    echo ""
    echo "🎯 ==============================================="
    echo "              使用方法"
    echo "=============================================== 🎯"
    echo ""
    echo "1️⃣ 認証設定（まず最初に実行）:"
    echo "   ./setup.sh → a) 認証設定"
    echo ""
    echo "2️⃣ AI組織システム起動:"
    echo "   ./ai-agents/manage.sh claude-auth"
    echo ""
    echo "3️⃣ PRESIDENT画面でプロジェクト指示:"
    echo "   「Hello Worldプロジェクトを作成してください」"
    echo ""
    echo "4️⃣ AI活動監視:"
    echo "   tmux attach-session -t multiagent"
    echo ""
    echo "💡 詳細はREADME.mdを参照してください"
    echo ""
}

# 完了メッセージ
show_completion() {
    echo ""
    echo "🎉 ==============================================="
    echo "        インストール完了！"
    echo "=============================================== 🎉"
    echo ""
    echo "📁 インストール場所: $(pwd)"
    echo "📄 詳細ドキュメント: README.md"
    echo "🔧 設定スクリプト: setup.sh"
    echo ""
    echo "次のステップ:"
    echo "1. 認証設定: ./setup.sh → a) 認証設定"
    echo "2. AI組織起動: ./ai-agents/manage.sh claude-auth"
    echo ""
    echo "🚀 準備完了！AI組織開発システムをお楽しみください！"
    echo ""
}

# エラーハンドリング
handle_error() {
    log_error "インストール中にエラーが発生しました"
    echo ""
    echo "🔧 トラブルシューティング:"
    echo "1. 権限を確認してください"
    echo "2. インターネット接続を確認してください"  
    echo "3. 既存のディレクトリがないか確認してください"
    echo ""
    echo "手動インストール手順:"
    echo "git clone $REPO_URL.git"
    echo "cd coding-rule2"
    echo "./setup.sh"
    echo ""
    exit 1
}

# メイン処理
main() {
    # エラートラップ設定
    trap handle_error ERR
    
    show_header
    check_environment
    clone_repository
    setup_permissions
    run_initial_setup
    show_auth_guide
    show_usage_guide
    show_completion
}

# 引数チェック
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "🚀 CodingRule2 クイックインストール"
    echo ""
    echo "使用方法:"
    echo "  curl -fsSL https://raw.githubusercontent.com/your-repo/coding-rule2/main/quick-install.sh | bash"
    echo ""
    echo "オプション:"
    echo "  --help, -h    このヘルプを表示"
    echo ""
    echo "機能:"
    echo "  ✅ 自動クローン"
    echo "  ✅ 権限設定"
    echo "  ✅ 初期セットアップ"
    echo "  ✅ 使用方法ガイド"
    echo ""
    exit 0
fi

# メイン処理実行
main