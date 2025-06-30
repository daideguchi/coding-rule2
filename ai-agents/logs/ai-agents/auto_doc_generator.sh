#!/bin/bash
# 自動ドキュメント生成

generate_daily_report() {
    local report_file="ai-agents/docs/daily_report_$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOD
# AI組織日次レポート - $(date +%Y-%m-%d)

## 📊 本日の成果
$(grep "完了" ai-agents/logs/*.log | wc -l) タスク完了

## 🔍 検出された問題
$(grep "ERROR" ai-agents/logs/*.log | wc -l) エラー

## 📈 改善提案
$(cat ai-agents/logs/growth/improvements_*.md 2>/dev/null | tail -10)

## 🎯 明日の優先事項
- [ ] 未完了Issueの処理
- [ ] ルール改善の実装
- [ ] パフォーマンス最適化
EOD
}

# 毎日自動実行
while true; do
    generate_daily_report
    sleep 86400  # 24時間
done &
