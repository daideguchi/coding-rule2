#!/bin/bash

# プロンプト送信→即座Enter実行スクリプト
# シンプルで効率的

if [ $# -lt 2 ]; then
    echo "使用方法: $0 <ワーカー番号> <プロンプト>"
    echo "例: $0 1 'README.mdを改善してください'"
    echo "ワーカー番号: 0=BOSS, 1=フロントエンド, 2=バックエンド, 3=UI/UX"
    exit 1
fi

WORKER_ID=$1
PROMPT=$2

case $WORKER_ID in
    0) WORKER_NAME="👔 BOSS" ;;
    1) WORKER_NAME="💻 フロントエンド" ;;
    2) WORKER_NAME="🔧 バックエンド" ;;
    3) WORKER_NAME="🎨 UI/UX" ;;
    *) echo "❌ 無効なワーカー番号: $WORKER_ID"; exit 1 ;;
esac

echo "📤 $WORKER_NAME にプロンプト送信中..."
echo "💬 プロンプト: $PROMPT"

# プロンプト送信
tmux send-keys -t multiagent:0.$WORKER_ID "$PROMPT"

# 0.5秒待機してからEnter
sleep 0.5
tmux send-keys -t multiagent:0.$WORKER_ID C-m

echo "✅ $WORKER_NAME: プロンプト送信→実行完了" 