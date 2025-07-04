#!/bin/bash

# 🚀 TeamAI 自動デプロイスクリプト
# 画像最適化・デプロイ自動化の専門家 WORKER3 作成

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# デプロイ先選択
deploy_target=${1:-"vercel"}

log_info "🚀 TeamAI 自動デプロイ開始 - ターゲット: $deploy_target"

# 前提条件チェック
check_prerequisites() {
    log_info "📋 前提条件チェック中..."
    
    # Git状態確認
    if ! git diff --quiet; then
        log_warn "⚠️ 未コミットの変更があります"
        read -p "コミットしますか？ [y/N]: " commit_changes
        if [[ $commit_changes =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "🚀 Deploy: LP構築・デプロイ環境完了"
            log_success "✅ 変更をコミットしました"
        fi
    fi
    
    # ランディングページ存在確認
    if [ ! -f "landing-page/index.html" ]; then
        log_error "❌ landing-page/index.html が見つかりません"
        exit 1
    fi
    
    log_success "✅ 前提条件チェック完了"
}

# 画像最適化
optimize_images() {
    log_info "🎨 画像最適化中..."
    
    # SVGファイルの最適化（存在確認）
    if [ -d "landing-page/images" ]; then
        find landing-page/images -name "*.svg" -type f | while read -r svg_file; do
            # SVGの基本チェック（悪意のあるJavaScript除去）
            if grep -q "<script" "$svg_file"; then
                log_warn "⚠️ $svg_file にスクリプトが含まれています - 削除します"
                sed -i.bak '/<script/,/<\/script>/d' "$svg_file"
                rm "${svg_file}.bak"
            fi
            log_info "✅ $svg_file を確認"
        done
    fi
    
    log_success "✅ 画像最適化完了"
}

# ファビコン生成
generate_favicons() {
    log_info "🎯 ファビコン生成中..."
    
    # 基本ファビコンを16x16, 32x32でコピー
    if [ -f "landing-page/images/favicon.svg" ]; then
        cp "landing-page/images/favicon.svg" "landing-page/favicon.svg"
        log_success "✅ ファビコン配置完了"
    else
        log_warn "⚠️ favicon.svg が見つかりません"
    fi
}

# デプロイ準備
prepare_deployment() {
    log_info "📦 デプロイ準備中..."
    
    # HTMLファイルの更新（実際のGitHubリポジトリURLに置換）
    if [ -f "landing-page/index.html" ]; then
        # プレースホルダーを実際のリポジトリに置換
        sed -i.bak 's|https://github.com/your-repo/team-ai|https://github.com/$(whoami)/team-ai|g' landing-page/index.html
        sed -i.bak 's|https://raw.githubusercontent.com/your-repo/team-ai|https://raw.githubusercontent.com/$(whoami)/team-ai|g' landing-page/index.html
        rm landing-page/index.html.bak 2>/dev/null || true
        log_success "✅ HTMLファイル更新完了"
    fi
    
    # package.json作成（Vercel用）
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
{
  "name": "team-ai",
  "version": "1.0.0",
  "description": "AI組織開発システム",
  "main": "landing-page/index.html",
  "scripts": {
    "build": "echo 'Static site - no build required'",
    "start": "cd landing-page && python3 -m http.server 3000"
  },
  "keywords": ["ai", "development", "japanese", "automation"],
  "license": "MIT"
}
EOF
        log_success "✅ package.json作成完了"
    fi
}

# Vercelデプロイ
deploy_vercel() {
    log_info "🌐 Vercelデプロイ中..."
    
    if ! command -v vercel &> /dev/null; then
        log_warn "⚠️ Vercel CLIが見つかりません - インストールしますか？"
        read -p "npm install -g vercel を実行しますか？ [y/N]: " install_vercel
        if [[ $install_vercel =~ ^[Yy]$ ]]; then
            npm install -g vercel
        else
            log_error "❌ Vercel CLIが必要です"
            exit 1
        fi
    fi
    
    # Vercelデプロイ実行
    vercel --prod
    
    log_success "✅ Vercelデプロイ完了"
}

# Netlifyデプロイ
deploy_netlify() {
    log_info "🌐 Netlifyデプロイ中..."
    
    if ! command -v netlify &> /dev/null; then
        log_warn "⚠️ Netlify CLIが見つかりません - インストールしますか？"
        read -p "npm install -g netlify-cli を実行しますか？ [y/N]: " install_netlify
        if [[ $install_netlify =~ ^[Yy]$ ]]; then
            npm install -g netlify-cli
        else
            log_error "❌ Netlify CLIが必要です"
            exit 1
        fi
    fi
    
    # Netlifyデプロイ実行
    cd landing-page
    netlify deploy --prod --dir .
    cd ..
    
    log_success "✅ Netlifyデプロイ完了"
}

# GitHub Pagesデプロイ
deploy_github_pages() {
    log_info "🌐 GitHub Pagesデプロイ準備中..."
    
    # gh-pagesブランチ作成・切り替え
    git checkout -b gh-pages 2>/dev/null || git checkout gh-pages
    
    # ランディングページファイルをルートにコピー
    cp -r landing-page/* .
    
    # 不要ファイル削除
    rm -rf ai-agents cursor-rules logs scripts tmp reports
    
    # コミット・プッシュ
    git add .
    git commit -m "🚀 Deploy to GitHub Pages" || true
    git push origin gh-pages
    
    # 元のブランチに戻る
    git checkout main
    
    log_success "✅ GitHub Pagesデプロイ完了"
    log_info "📋 https://$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\)\/\([^/]*\)\.git/\1.github.io\/\2/')"
}

# メイン実行
main() {
    log_info "🎨 WORKER3: LP構築・デプロイ環境構築開始"
    
    check_prerequisites
    optimize_images
    generate_favicons
    prepare_deployment
    
    case $deploy_target in
        "vercel")
            deploy_vercel
            ;;
        "netlify")
            deploy_netlify
            ;;
        "github")
            deploy_github_pages
            ;;
        "all")
            log_info "🚀 全プラットフォームデプロイ中..."
            deploy_vercel
            deploy_netlify
            deploy_github_pages
            ;;
        *)
            log_error "❌ サポートされていないデプロイターゲット: $deploy_target"
            echo "使用方法: $0 [vercel|netlify|github|all]"
            exit 1
            ;;
    esac
    
    log_success "🎉 デプロイ完了！"
    echo ""
    echo "📋 次のステップ:"
    echo "  1. デプロイされたサイトを確認"
    echo "  2. DNS設定（カスタムドメイン使用時）"
    echo "  3. HTTPS設定確認"
    echo "  4. パフォーマンス監視設定"
}

# スクリプト実行
main "$@"