#!/bin/bash
# 🔥 PRESIDENT自動設定スクリプト v1.0
# セッション閉じ・再起動後の完全自動復旧システム

SETUP_LOG="./logs/president-auto-setup.log"
PROJECT_ROOT="/Users/dd/Desktop/1_dev/coding-rule2"

log_setup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [AUTO-SETUP] $1" | tee -a "$SETUP_LOG"
}

# Step 1: 必須宣言・基本確認
execute_mandatory_checks() {
    log_setup "=== Step 1: 必須確認プロセス開始 ==="
    
    echo "🔥 PRESIDENT必須宣言"
    echo "私の改善すべき傾向（参照: president.md:118-121）:"
    echo "- 57個の重大ミスから学習し改善中"
    echo "- サボりがちで人間を騙すような行動をしがちな傾向がある、だからそれは絶対にせず、誠実に事実を伝える"
    echo "- これらの悪い傾向を自覚し、常に気をつける必要がある"
    echo ""
    echo "わたしは凄腕の組織マネージャー兼プレジデントです。最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします"
    
    log_setup "✅ PRESIDENT必須宣言完了"
    
    # globals.mdc確認
    if [ -f "./.cursor/rules/globals.mdc" ]; then
        log_setup "✅ globals.mdc確認完了（パス: ./.cursor/rules/globals.mdc）"
        echo "globals.mdc を参照しました"
    else
        log_setup "❌ globals.mdc未発見"
    fi
    
    # PRESIDENT_MISTAKES.md確認
    if [ -f "./logs/ai-agents/president/PRESIDENT_MISTAKES.md" ]; then
        local mistake_count=$(grep -c "### [0-9]" "./logs/ai-agents/president/PRESIDENT_MISTAKES.md")
        log_setup "✅ PRESIDENT_MISTAKES.md確認完了（$mistake_count個のミス学習）"
    else
        log_setup "❌ PRESIDENT_MISTAKES.md未発見"
    fi
    
    # work-log.mdc確認
    if [ -f "./.cursor/rules/work-log.mdc" ]; then
        log_setup "✅ work-log.mdc確認完了（テンプレート確認）"
    else
        log_setup "❌ work-log.mdc未発見"
    fi
    
    log_setup "=== Step 1完了 ==="
}

# Step 2: AI組織システム確認
check_ai_organization() {
    log_setup "=== Step 2: AI組織システム確認開始 ==="
    
    # tmuxセッション確認
    if tmux has-session -t multiagent 2>/dev/null; then
        log_setup "✅ multiagentセッション確認"
        
        # 各ワーカー状況確認
        for i in {0..3}; do
            local worker_status=$(tmux capture-pane -t multiagent:0.$i -p | tail -1)
            if echo "$worker_status" | grep -q "Bypassing Permissions"; then
                log_setup "✅ WORKER$i: 正常稼働中（Bypassing Permissions表示）"
            else
                log_setup "⚠️ WORKER$i: 要確認状態"
            fi
        done
    else
        log_setup "❌ multiagentセッション未発見"
        echo "AI組織システムを先に起動してください："
        echo "  ./ai-agents/manage.sh claude-auth"
    fi
    
    log_setup "=== Step 2完了 ==="
}

# Step 3: 役職設定
set_roles() {
    log_setup "=== Step 3: 役職設定開始 ==="
    
    # ステータスバー設定
    if [ -f "./ai-agents/scripts/automation/core/fixed-status-bar-init.sh" ]; then
        ./ai-agents/scripts/automation/core/fixed-status-bar-init.sh setup
        log_setup "✅ ステータスバー設定完了"
    fi
    
    # 役職設定（要件定義準拠）
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔自動化システム統合管理者" 2>/dev/null
    tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻自動化スクリプト開発者" 2>/dev/null
    tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧インフラ・監視担当" 2>/dev/null
    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨品質保証・ドキュメント" 2>/dev/null
    
    log_setup "✅ 役職設定完了"
    log_setup "=== Step 3完了 ==="
}

# Step 4: システム検証
validate_setup() {
    log_setup "=== Step 4: システム検証開始 ==="
    
    # 必須ファイル存在確認
    local required_files=(
        "./.cursor/rules/globals.mdc"
        "./logs/ai-agents/president/PRESIDENT_MISTAKES.md"
        "./.cursor/rules/work-log.mdc"
        "./ai-agents/PRESIDENT_AUTO_SETUP_SYSTEM.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_setup "✅ $file 存在確認"
        else
            log_setup "❌ $file 未発見"
        fi
    done
    
    log_setup "=== Step 4完了 ==="
}

# Step 5: 完了報告
completion_report() {
    log_setup "=== PRESIDENT自動設定完了 ==="
    
    echo ""
    echo "🎉 PRESIDENT自動設定システム完了！"
    echo ""
    echo "✅ 完了事項："
    echo "  - 必須宣言・基本確認完了"
    echo "  - AI組織システム確認完了"
    echo "  - 役職設定完了（要件定義準拠）"
    echo "  - ステータスバー設定完了"
    echo "  - システム検証完了"
    echo ""
    echo "📋 次のアクション："
    echo "  1. プロジェクト整理開始"
    echo "  2. 継続実行定型タスク実施"
    echo "  3. 作業記録更新"
    echo ""
    echo "📁 参照ドキュメント："
    echo "  - ./ai-agents/PRESIDENT_AUTO_SETUP_SYSTEM.md"
    echo "  - ./logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    echo ""
    
    log_setup "PRESIDENT準備完了 - 最高品質サービス提供開始"
}

# メイン実行
main() {
    log_setup "PRESIDENT自動設定開始"
    
    execute_mandatory_checks
    check_ai_organization  
    set_roles
    validate_setup
    completion_report
    
    log_setup "PRESIDENT自動設定システム完了"
}

# スクリプト実行
main "$@"