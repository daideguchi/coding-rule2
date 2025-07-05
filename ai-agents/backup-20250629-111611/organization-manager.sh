#!/bin/bash

# AI組織統合管理システム
# 組織の健全性を維持し、継続的改善を実現

VERSION="2.0.0"
CONFIG_DIR="./ai-agents"
LOG_DIR="$CONFIG_DIR/logs"
TOOLS_DIR="$CONFIG_DIR"

# 初期化
init_organization_tools() {
    echo "=== AI組織統合管理システム v$VERSION 初期化 ==="
    
    # 必要なディレクトリ作成
    mkdir -p "$LOG_DIR/audit"
    mkdir -p "./tmp/health-checks"
    
    # 権限管理初期化
    if [[ -x "$TOOLS_DIR/permission-manager.sh" ]]; then
        "$TOOLS_DIR/permission-manager.sh" init
        echo "✅ 権限管理システム初期化完了"
    else
        echo "❌ 権限管理システムが見つかりません"
        return 1
    fi
    
    # ヘルスチェック実行
    perform_health_check
    
    echo "🎯 組織管理システム初期化完了"
}

# 組織ヘルスチェック
perform_health_check() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local health_report="./tmp/health-checks/health-$(date +%Y%m%d-%H%M%S).txt"
    
    echo "=== 組織ヘルスチェック [$timestamp] ===" > "$health_report"
    echo "" >> "$health_report"
    
    local overall_health="HEALTHY"
    
    # 1. エージェント状態チェック
    echo "📊 エージェント状態チェック:" >> "$health_report"
    if ! "$TOOLS_DIR/monitoring-dashboard.sh" status >> "$health_report" 2>&1; then
        echo "⚠️ エージェント監視に問題があります" >> "$health_report"
        overall_health="WARNING"
    fi
    echo "" >> "$health_report"
    
    # 2. 権限システムチェック
    echo "🔐 権限システムチェック:" >> "$health_report"
    if ! "$TOOLS_DIR/permission-manager.sh" check-workers >> "$health_report" 2>&1; then
        echo "⚠️ 権限システムに問題があります" >> "$health_report"
        overall_health="WARNING"
    fi
    echo "" >> "$health_report"
    
    # 3. ログ整合性チェック
    echo "📋 ログ整合性チェック:" >> "$health_report"
    check_log_integrity >> "$health_report"
    echo "" >> "$health_report"
    
    # 4. 組織ルール遵守チェック
    echo "📏 組織ルール遵守チェック:" >> "$health_report"
    check_rule_compliance >> "$health_report"
    echo "" >> "$health_report"
    
    # 総合評価
    echo "🎯 総合健全性: $overall_health" >> "$health_report"
    echo "📅 チェック実行日時: $timestamp" >> "$health_report"
    
    echo "ヘルスチェック完了: $health_report"
    
    # 問題がある場合はアラート
    if [[ "$overall_health" != "HEALTHY" ]]; then
        echo "⚠️ 組織に問題が検出されました。詳細: $health_report"
        generate_improvement_plan "$health_report"
    fi
}

# ログ整合性チェック
check_log_integrity() {
    local log_issues=0
    
    # 必要なログファイルの存在確認
    local required_logs=("permissions.log" "decision-workflow.log" "dashboard.log")
    
    for log_file in "${required_logs[@]}"; do
        if [[ ! -f "$LOG_DIR/$log_file" ]]; then
            echo "❌ 必要なログファイルが存在しません: $log_file"
            ((log_issues++))
        else
            echo "✅ ログファイル確認: $log_file"
        fi
    done
    
    # ログサイズチェック（1MB以上で警告）
    if [[ -d "$LOG_DIR" ]]; then
        local log_size=$(du -sm "$LOG_DIR" 2>/dev/null | awk '{print $1}')
        if [[ ${log_size:-0} -gt 1 ]]; then
            echo "⚠️ ログサイズが大きくなっています: ${log_size}MB"
            echo "💡 ログローテーションを検討してください"
        fi
    fi
    
    return $log_issues
}

# 組織ルール遵守チェック
check_rule_compliance() {
    local compliance_issues=0
    
    # 最近の権限拒否をチェック
    if [[ -f "$LOG_DIR/permissions.log" ]]; then
        local recent_denials=$(grep -c "PERMISSION_DENIED" "$LOG_DIR/permissions.log" 2>/dev/null || echo "0")
        if [[ $recent_denials -gt 0 ]]; then
            echo "⚠️ 権限拒否が $recent_denials 件発生しています"
            echo "💡 エージェントへの権限教育が必要かもしれません"
            ((compliance_issues++))
        else
            echo "✅ 権限違反なし"
        fi
    fi
    
    # 緊急停止の履歴をチェック
    if [[ -f "$LOG_DIR/permissions.log" ]]; then
        local emergency_stops=$(grep -c "EMERGENCY_STOP" "$LOG_DIR/permissions.log" 2>/dev/null || echo "0")
        if [[ $emergency_stops -gt 0 ]]; then
            echo "🚨 緊急停止が $emergency_stops 件発生しています"
            echo "💡 根本原因の分析が必要です"
            ((compliance_issues++))
        else
            echo "✅ 緊急停止なし"
        fi
    fi
    
    return $compliance_issues
}

# 改善計画生成
generate_improvement_plan() {
    local health_report="$1"
    local plan_file="./reports/improvement-plan-$(date +%Y%m%d-%H%M%S).md"
    
    mkdir -p "./reports"
    
    cat > "$plan_file" << EOF
# 組織改善計画

生成日時: $(date '+%Y-%m-%d %H:%M:%S')
ベースレポート: $health_report

## 検出された問題

$(grep "❌\|⚠️" "$health_report" | sed 's/^/- /')

## 推奨改善アクション

### 緊急対応
- [ ] 問題のあるエージェントの再起動
- [ ] 権限設定の確認と修正
- [ ] ログの詳細分析

### 短期改善（1週間以内）
- [ ] エージェント教育の実施
- [ ] 組織ルールの再確認
- [ ] 監視システムの調整

### 中期改善（1ヶ月以内）
- [ ] プロセス改善の実装
- [ ] 新しい安全策の導入
- [ ] 定期チェックの自動化

### 長期改善（3ヶ月以内）
- [ ] 組織構造の最適化
- [ ] 新技術の導入検討
- [ ] 包括的な組織改革

## 定期チェック項目
- [ ] 週次ヘルスチェック実行
- [ ] 月次改善レビュー
- [ ] 四半期組織見直し

## 実装優先度
1. 🔴 高優先度: セキュリティと権限管理
2. 🟡 中優先度: プロセス改善
3. 🟢 低優先度: 利便性向上

EOF

    echo "改善計画を生成しました: $plan_file"
}

# 組織運営サポート
organization_support() {
    echo "=== 組織運営サポート ==="
    
    # 利用可能なツール一覧
    echo "利用可能なツール:"
    echo "  📊 監視ダッシュボード: $TOOLS_DIR/monitoring-dashboard.sh"
    echo "  🔐 権限管理: $TOOLS_DIR/permission-manager.sh"
    echo "  🔄 意思決定ワークフロー: $TOOLS_DIR/decision-workflow.sh"
    echo ""
    
    # クイックアクション
    echo "クイックアクション:"
    echo "  1. 組織状況確認"
    echo "  2. ヘルスチェック実行"
    echo "  3. 権限状況確認"
    echo "  4. 改善計画生成"
    echo "  5. 緊急停止"
    echo ""
    
    read -p "アクションを選択してください (1-5): " action
    
    case "$action" in
        1)
            "$TOOLS_DIR/monitoring-dashboard.sh" full
            ;;
        2)
            perform_health_check
            ;;
        3)
            "$TOOLS_DIR/permission-manager.sh" status
            ;;
        4)
            generate_improvement_plan "./tmp/health-checks/latest.txt"
            ;;
        5)
            read -p "緊急停止の理由を入力してください: " reason
            "$TOOLS_DIR/permission-manager.sh" emergency-stop "$reason"
            ;;
        *)
            echo "無効な選択です"
            ;;
    esac
}

# 自動修復
auto_repair() {
    echo "=== 自動修復実行 ==="
    
    local repair_count=0
    
    # 1. tmuxセッションの修復
    if ! tmux has-session -t multiagent 2>/dev/null; then
        echo "🔧 tmuxセッションを修復しています..."
        tmux new-session -d -s multiagent
        for i in {1..3}; do
            tmux split-window -t multiagent:0 -h
        done
        echo "✅ tmuxセッション修復完了"
        ((repair_count++))
    fi
    
    # 2. ログディレクトリの修復
    if [[ ! -d "$LOG_DIR" ]]; then
        echo "🔧 ログディレクトリを修復しています..."
        mkdir -p "$LOG_DIR"
        echo "✅ ログディレクトリ修復完了"
        ((repair_count++))
    fi
    
    # 3. 権限ファイルの修復
    local permission_files=("permissions.log" "decision-workflow.log" "dashboard.log")
    for perm_file in "${permission_files[@]}"; do
        if [[ ! -f "$LOG_DIR/$perm_file" ]]; then
            echo "🔧 ログファイルを作成しています: $perm_file"
            touch "$LOG_DIR/$perm_file"
            ((repair_count++))
        fi
    done
    
    echo "🎯 自動修復完了: $repair_count 項目を修復しました"
}

# 組織統計レポート
generate_statistics() {
    local stats_file="./reports/organization-stats-$(date +%Y%m%d).md"
    mkdir -p "./reports"
    
    cat > "$stats_file" << EOF
# AI組織統計レポート

生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## 組織活動統計

### 権限管理統計
$(if [[ -f "$LOG_DIR/permissions.log" ]]; then
    echo "- 総権限チェック数: $(wc -l < "$LOG_DIR/permissions.log")"
    echo "- 権限承認数: $(grep -c "PERMISSION_GRANTED" "$LOG_DIR/permissions.log" 2>/dev/null || echo "0")"
    echo "- 権限拒否数: $(grep -c "PERMISSION_DENIED" "$LOG_DIR/permissions.log" 2>/dev/null || echo "0")"
else
    echo "- データなし"
fi)

### ワークフロー統計
$(if [[ -f "$LOG_DIR/decision-workflow.log" ]]; then
    echo "- 総ワークフロー数: $(wc -l < "$LOG_DIR/decision-workflow.log")"
    echo "- 承認済み操作: $(grep -c "FINAL_APPROVAL.*APPROVED" "$LOG_DIR/decision-workflow.log" 2>/dev/null || echo "0")"
    echo "- 拒否された操作: $(grep -c "FINAL_APPROVAL.*REJECTED" "$LOG_DIR/decision-workflow.log" 2>/dev/null || echo "0")"
else
    echo "- データなし"
fi)

### システム健全性
- 最終ヘルスチェック: $(ls -t ./tmp/health-checks/*.txt 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "未実行")
- アクティブエージェント数: $(tmux list-panes -t multiagent:0 2>/dev/null | wc -l || echo "0")

## 推奨アクション
- 定期的なヘルスチェックの実行
- 権限管理ログの定期確認
- 組織ルールの継続的改善

EOF

    echo "統計レポートを生成しました: $stats_file"
}

# メイン処理
case "$1" in
    "init")
        init_organization_tools
        ;;
    "health")
        perform_health_check
        ;;
    "support")
        organization_support
        ;;
    "repair")
        auto_repair
        ;;
    "stats")
        generate_statistics
        ;;
    "full-check")
        echo "=== 完全組織チェック実行 ==="
        perform_health_check
        auto_repair
        generate_statistics
        echo "🎯 完全チェック完了"
        ;;
    *)
        echo "AI組織統合管理システム v$VERSION"
        echo ""
        echo "Usage: $0 {init|health|support|repair|stats|full-check}"
        echo ""
        echo "Commands:"
        echo "  init       - システム初期化"
        echo "  health     - 組織ヘルスチェック"
        echo "  support    - 組織運営サポート"
        echo "  repair     - 自動修復実行"
        echo "  stats      - 統計レポート生成"
        echo "  full-check - 完全チェック実行"
        echo ""
        echo "Available tools:"
        echo "  - 権限管理: $TOOLS_DIR/permission-manager.sh"
        echo "  - 意思決定: $TOOLS_DIR/decision-workflow.sh"
        echo "  - 監視: $TOOLS_DIR/monitoring-dashboard.sh"
        exit 1
        ;;
esac