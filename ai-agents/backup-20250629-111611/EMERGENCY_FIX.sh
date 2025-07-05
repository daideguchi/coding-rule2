#!/bin/bash
# ⚡ 緊急修正実行スクリプト

# 1. 強制的な個別タイトル設定
echo "🔧 強制個別タイトル設定"
tmux select-pane -t multiagent:0.0 -T "🟢作業中 👔BOSS1・チームリーダー │ チーム指示実行中"
tmux select-pane -t multiagent:0.1 -T "🟢作業中 💻WORKER1・フロントエンド │ ログイン画面開発中"  
tmux select-pane -t multiagent:0.2 -T "🟢作業中 🔧WORKER2・バックエンド │ API設計中"
tmux select-pane -t multiagent:0.3 -T "🟢作業中 🎨WORKER3・デザイナー │ UI改善中"

# 2. 30分後の自動報告設定
(sleep 1800 && echo "30分経過 - 進捗報告時間" && tmux send-keys -t multiagent:0.0 "30分経過しました。各WORKERの進捗報告をお願いします。" C-m) &

echo "✅ 緊急修正完了"