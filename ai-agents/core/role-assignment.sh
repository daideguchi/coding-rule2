#!/bin/bash
# 確実な役職設定システム

set -euo pipefail

echo "🎯 AI組織役職設定開始"

# BOSS1への役職設定
tmux send-keys -t multiagent:0.0 "あなたはBOSS1です。PRESIDENTからの指示を受けてWORKERに作業分担する責任者です。ai-agents/instructions/boss.mdを確認してください。" C-m

# 汎用WORKERとして設定（具体的専門分野は指定しない）
tmux send-keys -t multiagent:0.1 "あなたはWORKER1です。BOSSからの作業指示を受けて実行する担当者です。ai-agents/instructions/worker.mdを確認してください。" C-m

tmux send-keys -t multiagent:0.2 "あなたはWORKER2です。BOSSからの作業指示を受けて実行する担当者です。ai-agents/instructions/worker.mdを確認してください。" C-m

tmux send-keys -t multiagent:0.3 "あなたはWORKER3です。BOSSからの作業指示を受けて実行する担当者です。ai-agents/instructions/worker.mdを確認してください。" C-m

echo "✅ 役職設定指示送信完了"

# Permissions突破
sleep 3
for i in {0..3}; do
    tmux send-keys -t multiagent:0.$i C-m
done

echo "✅ Permissions突破完了"
echo "🎯 役職設定システム実行完了"