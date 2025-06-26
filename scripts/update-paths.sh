#!/bin/bash

# パス参照一括更新スクリプト

echo "🔧 パス参照を更新中..."

# setup.shの更新
sed -i '' 's|status-checker\.sh|scripts/status-checker.sh|g' setup.sh
sed -i '' 's|claude-cursor-sync\.sh|scripts/claude-cursor-sync.sh|g' setup.sh

# README.mdの更新
sed -i '' 's|status-checker\.sh|scripts/status-checker.sh|g' README.md
sed -i '' 's|claude-cursor-sync\.sh|scripts/claude-cursor-sync.sh|g' README.md

# STATUS.mdの更新
sed -i '' 's|status-checker\.sh|scripts/status-checker.sh|g' STATUS.md
sed -i '' 's|claude-cursor-sync\.sh|scripts/claude-cursor-sync.sh|g' STATUS.md

# ai-agents内のログパスを統合ログに更新
sed -i '' 's|ai-agents/logs|logs/ai-agents|g' ai-agents/manage.sh
sed -i '' 's|ai-agents/logs|logs/ai-agents|g' ai-agents/agent-send.sh

echo "✅ パス参照更新完了" 