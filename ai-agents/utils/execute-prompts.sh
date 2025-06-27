#!/bin/bash

# シンプルプロンプト実行スクリプト
# 必要な時だけ実行、リソース消費なし

echo "⚡ プロンプト一括実行開始..."

# 設定
PRESIDENT_SESSION="president"
MULTIAGENT_SESSION="multiagent"

# 関数: プロンプト実行
execute_prompt() {
    local session=$1
    local pane=$2
    local worker_name=$3
    
    echo "🚀 $worker_name: プロンプト実行中..."
    
    # Bypass Permissions突破 + プロンプト実行
    tmux send-keys -t $session:0.$pane Down C-m
    sleep 0.5
    tmux send-keys -t $session:0.$pane C-m
    
    echo "✅ $worker_name: 実行完了"
}

# プレジデント実行（必要な場合）
if [ "$1" = "president" ] || [ "$1" = "all" ]; then
    execute_prompt $PRESIDENT_SESSION "" "PRESIDENT"
fi

# 4ワーカー実行
if [ "$1" = "workers" ] || [ "$1" = "all" ] || [ -z "$1" ]; then
    for i in {0..3}; do
        case $i in
            0) worker_name="👔 BOSS" ;;
            1) worker_name="💻 フロントエンド" ;;
            2) worker_name="🔧 バックエンド" ;;
            3) worker_name="🎨 UI/UX" ;;
        esac
        
        execute_prompt $MULTIAGENT_SESSION $i "$worker_name"
        sleep 0.3
    done
fi

echo ""
echo "🎯 プロンプト実行完了！"
echo "📋 使用方法:"
echo "  ./ai-agents/execute-prompts.sh          # 全ワーカー実行"
echo "  ./ai-agents/execute-prompts.sh workers  # ワーカーのみ"
echo "  ./ai-agents/execute-prompts.sh president # プレジデントのみ"
echo "  ./ai-agents/execute-prompts.sh all      # 全員実行" 