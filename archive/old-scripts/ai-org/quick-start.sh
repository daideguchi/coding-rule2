#!/bin/bash

# =============================================================================
# AI組織クイックスタート - 超シンプル版
# =============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 AI組織クイックスタート"
echo "========================"
echo -e "${NC}"

# 初回セットアップチェック
if [[ ! -f "./.ai-org-configured" ]]; then
    echo -e "${YELLOW}初回セットアップを実行します...${NC}"
    
    # 基本設定
    if [[ ! -f "./setup.sh" ]]; then
        echo "❌ setup.shが見つかりません"
        exit 1
    fi
    
    echo "📋 認証設定を行います（claude.ai Pro推奨）"
    echo "1) claude.ai でログイン済みの場合: Enter"
    echo "2) API Key使用の場合: ANTHROPIC_API_KEY を設定"
    echo ""
    read -p "Enter を押して継続..."
    
    # 設定完了マーク
    touch ./.ai-org-configured
    echo -e "${GREEN}✅ 初回セットアップ完了${NC}"
    echo ""
fi

# AI組織起動
echo -e "${GREEN}🔥 AI組織を起動中...${NC}"
echo ""

# メインスクリプト実行
if [[ -f "./start-ai-org.sh" ]]; then
    ./start-ai-org.sh
else
    echo "❌ start-ai-org.sh が見つかりません"
    echo "💡 以下のコマンドで復旧してください："
    echo "   curl -O https://raw.githubusercontent.com/your-repo/start-ai-org.sh"
    exit 1
fi