#!/bin/bash

# 🚨 Enter押し忘れ防止システム（23回のミス教訓）
# PRESIDENT専用 - メッセージセット後の自動Enter実行

# 使用方法: ./auto-enter-system.sh [target] "message"
# target: boss, worker1, worker2, worker3, all

TARGET=$1
MESSAGE=$2

if [ -z "$TARGET" ] || [ -z "$MESSAGE" ]; then
    echo "使用方法: $0 [target] \"message\""
    echo "target: boss, worker1, worker2, worker3, all"
    exit 1
fi

# ターゲット番号を決定
case $TARGET in
    "boss")
        PANE_NUM="0.0"
        DISPLAY_NAME="BOSS1"
        ;;
    "worker1")
        PANE_NUM="0.1"
        DISPLAY_NAME="WORKER1"
        ;;
    "worker2")
        PANE_NUM="0.2"
        DISPLAY_NAME="WORKER2"
        ;;
    "worker3")
        PANE_NUM="0.3"
        DISPLAY_NAME="WORKER3"
        ;;
    "all")
        echo "🔥 全ワーカーに同一メッセージ送信"
        for i in {0..3}; do
            echo "送信中: multiagent:0.$i"
            tmux send-keys -t multiagent:0.$i ">$MESSAGE" C-m
            sleep 0.5
            tmux send-keys -t multiagent:0.$i C-m
            sleep 0.5
        done
        echo "✅ 全ワーカーに送信完了（Enter2回自動実行済み）"
        exit 0
        ;;
    *)
        echo "❌ 無効なターゲット: $TARGET"
        exit 1
        ;;
esac

# 🚨 23回のミス教訓：メッセージセットとEnter実行を同時実行
echo "📤 送信中: $DISPLAY_NAME (multiagent:$PANE_NUM)"
echo "💬 メッセージ: $MESSAGE"

# 重要：C-mを2回実行（確実なEnter実行）
tmux send-keys -t multiagent:$PANE_NUM ">$MESSAGE" C-m
sleep 0.5
tmux send-keys -t multiagent:$PANE_NUM C-m

# 送信後即座に確認
sleep 1
echo "✅ 送信完了（Enter2回自動実行済み）"

# 状況確認（オプション）
echo "📊 送信後状況確認:"
tmux capture-pane -t multiagent:$PANE_NUM -p | tail -3

echo "🎯 $DISPLAY_NAME への指示送信が完了しました"