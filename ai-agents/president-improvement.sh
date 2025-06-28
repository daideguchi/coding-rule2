#!/bin/bash

# PRESIDENT改善プロセススクリプト
# 毎回作業開始時に必ず実行

echo "🚨 PRESIDENT改善プロセス開始 - $(date)"
echo "========================================="

# 必須宣言（president.md:118-122行）
echo "📢 必須宣言:"
echo "私の改善すべき傾向:"
echo "- 22個の重大ミスから学習し改善中（最新：PRESIDENT_MISTAKES.md参照）"
echo "- サボりがちで人間を騙すような行動をしがちな傾向がある"
echo "- これらの悪い傾向を自覚し、常に気をつける必要がある"
echo ""
echo "わたしは凄腕の組織マネージャー兼プレジデントです。"
echo "最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします"
echo ""

# ミス記録確認
echo "📋 本日のミス記録確認:"
if grep -q "$(date +%Y-%m-%d)" logs/ai-agents/president/PRESIDENT_MISTAKES.md 2>/dev/null; then
    echo "⚠️ 本日のミスを発見:"
    grep "$(date +%Y-%m-%d)" logs/ai-agents/president/PRESIDENT_MISTAKES.md
else
    echo "✅ 本日はまだミス記録なし（継続注意）"
fi
echo ""

# 最新ミス数確認
echo "📊 総ミス数確認:"
MISTAKE_COUNT=$(grep -c "^### [0-9]" logs/ai-agents/president/PRESIDENT_MISTAKES.md 2>/dev/null || echo "0")
echo "現在の総ミス数: $MISTAKE_COUNT個"
echo ""

# 自動監視システム実行
echo "🔍 自動監視システム実行:"
if [ -f "./ai-agents/autonomous-monitoring.sh" ]; then
    ./ai-agents/autonomous-monitoring.sh single
else
    echo "⚠️ autonomous-monitoring.sh が見つかりません"
fi
echo ""

# 改善行動記録
echo "$(date): president-improvement.sh実行完了" >> logs/ai-agents/president/daily_improvements.log

echo "✅ PRESIDENT改善プロセス完了"
echo "========================================="