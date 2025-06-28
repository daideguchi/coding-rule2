#!/bin/bash

# =============================================================================
# プロジェクトフォルダ名変更スクリプト
# coding-rule2 → team-ai
# =============================================================================

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔄 プロジェクトフォルダ名変更スクリプト${NC}"
echo "=================================="
echo "変更: coding-rule2 → team-ai"
echo ""

# 現在の場所確認
echo -e "${YELLOW}📍 現在の場所:${NC}"
pwd
echo ""

# 変更実行
echo -e "${YELLOW}🚀 フォルダ名変更を実行します...${NC}"
echo ""

# 親ディレクトリに移動して変更
cd /Users/dd/Desktop/1_dev
if [ -d "coding-rule2" ]; then
    echo -e "${GREEN}✅ coding-rule2 フォルダを発見${NC}"
    
    # バックアップ確認
    echo -e "${YELLOW}⚠️  変更前の最終確認:${NC}"
    echo "- 現在のフォルダ: coding-rule2"
    echo "- 変更後のフォルダ: team-ai"
    echo ""
    
    read -p "続行しますか？ [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        # フォルダ名変更実行
        mv coding-rule2 team-ai
        
        if [ -d "team-ai" ]; then
            echo -e "${GREEN}🎉 フォルダ名変更完了！${NC}"
            echo ""
            echo -e "${GREEN}✅ 新しいパス: /Users/dd/Desktop/1_dev/team-ai${NC}"
            echo ""
            
            # 移動してconfirm
            cd team-ai
            echo -e "${YELLOW}📊 変更後の確認:${NC}"
            echo "現在の作業ディレクトリ: $(pwd)"
            echo ""
            
            # メインファイルの存在確認
            echo -e "${YELLOW}🔍 主要ファイル確認:${NC}"
            if [ -f "README.md" ]; then
                echo "✅ README.md 存在"
            fi
            if [ -f "PROJECT-STATUS.md" ]; then
                echo "✅ PROJECT-STATUS.md 存在"
            fi
            if [ -f "start-ai-org.sh" ]; then
                echo "✅ start-ai-org.sh 存在"
            fi
            if [ -d "ai-agents" ]; then
                echo "✅ ai-agents/ ディレクトリ存在"
            fi
            
            echo ""
            echo -e "${GREEN}🏆 プロジェクト名変更が完全に完了しました！${NC}"
            echo -e "${GREEN}新しいプロジェクト名: TeamAI${NC}"
            echo -e "${GREEN}新しいフォルダ名: team-ai${NC}"
            
        else
            echo -e "${RED}❌ フォルダ名変更に失敗しました${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}🚫 フォルダ名変更をキャンセルしました${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ coding-rule2 フォルダが見つかりません${NC}"
    echo "現在の場所: $(pwd)"
    ls -la
    exit 1
fi