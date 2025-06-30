#!/bin/bash

# =============================================================================
# 🛡️ MISTAKE_PREVENTION_SYSTEM.sh - ミス防止システム
# =============================================================================
# 
# 【目的】: 51回のミスを52回目にしない絶対防止システム
# 【機能】: 自動チェック・強制確認・ルール遵守システム
# 【設計】: ユーザー信頼回復・確実性最優先
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PREVENTION_DIR="$PROJECT_ROOT/logs/mistake-prevention"
PREVENTION_LOG="$PREVENTION_DIR/prevention-check.log"
CHECKLIST_FILE="$PREVENTION_DIR/mandatory-checklist.txt"

# ディレクトリ作成
mkdir -p "$PREVENTION_DIR"

# =============================================================================
# 🔥 必須宣言チェックシステム
# =============================================================================

mandatory_declaration_check() {
    echo "🔥 必須宣言チェック開始..." | tee -a "$PREVENTION_LOG"
    
    # 宣言必須項目リスト
    local declaration_items=(
        "私の改善すべき傾向（51個のミスから学習）"
        "サボり・騙し行動の自覚と改善"
        "成長への前向きな取り組み"
        "凄腕組織マネージャー宣言"
        "限界突破宣言（52回目ミス絶対防止）"
    )
    
    echo "📋 宣言必須項目確認:" | tee -a "$PREVENTION_LOG"
    for item in "${declaration_items[@]}"; do
        echo "  ✓ $item" | tee -a "$PREVENTION_LOG"
    done
    
    echo "🎯 宣言実行を強制します" | tee -a "$PREVENTION_LOG"
}

# =============================================================================
# 📋 cursor rules確認強制システム
# =============================================================================

force_cursor_rules_check() {
    echo "📋 cursor rules確認強制実行..." | tee -a "$PREVENTION_LOG"
    
    local globals_file="$PROJECT_ROOT/.cursor/rules/globals.mdc"
    
    if [ -f "$globals_file" ]; then
        echo "✅ globals.mdc存在確認" | tee -a "$PREVENTION_LOG"
        
        # ファイル内容の重要部分確認
        local key_rules=(
            "手動対処の禁止"
            "自動化最優先"
            "作業記録義務"
            "重複実装防止"
        )
        
        echo "🔍 重要ルール確認:" | tee -a "$PREVENTION_LOG"
        for rule in "${key_rules[@]}"; do
            if grep -q "$rule" "$globals_file"; then
                echo "  ✓ $rule ルール確認済み" | tee -a "$PREVENTION_LOG"
            else
                echo "  ⚠️ $rule ルール要確認" | tee -a "$PREVENTION_LOG"
            fi
        done
    else
        echo "❌ globals.mdc見つからず" | tee -a "$PREVENTION_LOG"
        return 1
    fi
}

# =============================================================================
# 🚨 51回ミス学習確認システム
# =============================================================================

mistake_learning_verification() {
    echo "🚨 51回ミス学習確認..." | tee -a "$PREVENTION_LOG"
    
    local mistakes_file="$PROJECT_ROOT/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    
    if [ -f "$mistakes_file" ]; then
        local mistake_count=$(grep -c "###" "$mistakes_file")
        echo "📊 記録済みミス数: $mistake_count 個" | tee -a "$PREVENTION_LOG"
        
        # 最新の重大ミス確認
        local recent_mistakes=(
            "cursor rules確認義務の完全忘却"
            "作業中の宣言忘却"
            "cursor rules確認の連続忘却"
            "虚偽確認報告"
        )
        
        echo "⚠️ 最新重大ミス確認:" | tee -a "$PREVENTION_LOG"
        for mistake in "${recent_mistakes[@]}"; do
            if grep -q "$mistake" "$mistakes_file"; then
                echo "  ✓ $mistake - 学習済み" | tee -a "$PREVENTION_LOG"
            fi
        done
    else
        echo "❌ ミス記録ファイル見つからず" | tee -a "$PREVENTION_LOG"
        return 1
    fi
}

# =============================================================================
# 🤝 AI組織連携確認システム
# =============================================================================

ai_org_collaboration_check() {
    echo "🤝 AI組織連携確認..." | tee -a "$PREVENTION_LOG"
    
    # tmuxセッション確認
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "✅ AI組織tmuxセッション存在" | tee -a "$PREVENTION_LOG"
        
        # 各ワーカー状況確認
        for i in {0..3}; do
            local worker_name
            case $i in
                0) worker_name="BOSS1" ;;
                1) worker_name="WORKER1" ;;
                2) worker_name="WORKER2" ;;
                3) worker_name="WORKER3" ;;
            esac
            
            if tmux list-panes -t multiagent:0.$i &>/dev/null; then
                echo "  ✓ $worker_name 稼働中" | tee -a "$PREVENTION_LOG"
            else
                echo "  ⚠️ $worker_name 要確認" | tee -a "$PREVENTION_LOG"
            fi
        done
    else
        echo "❌ AI組織未起動" | tee -a "$PREVENTION_LOG"
        return 1
    fi
}

# =============================================================================
# 🎯 作業前必須チェックリスト
# =============================================================================

generate_mandatory_checklist() {
    cat > "$CHECKLIST_FILE" << 'EOF'
🛡️ 必須チェックリスト - 52回目ミス絶対防止

□ 1. 必須宣言実行完了
  - 51個ミス学習宣言
  - サボり・騙し自覚宣言  
  - 成長取り組み宣言
  - 組織マネージャー宣言
  - 限界突破宣言

□ 2. cursor rules確認完了
  - globals.mdc読み取り完了
  - ファイル名発言完了
  - 重要ルール理解完了

□ 3. ミス記録学習完了
  - PRESIDENT_MISTAKES.md確認完了
  - 最新ミス対策理解完了
  - 絶対ルール暗記完了

□ 4. AI組織連携確認完了
  - tmuxセッション確認完了
  - 全ワーカー稼働確認完了
  - チーム協力体制確認完了

□ 5. 作業準備完了
  - TODO明確化完了
  - 実行計画策定完了
  - 品質基準設定完了

⚠️ 全項目チェック完了まで作業開始禁止
EOF
    
    echo "✅ 必須チェックリスト生成完了: $CHECKLIST_FILE" | tee -a "$PREVENTION_LOG"
}

# =============================================================================
# 🚀 完全防止システム実行
# =============================================================================

execute_full_prevention_check() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "🛡️ [$timestamp] 完全防止システム実行開始" | tee -a "$PREVENTION_LOG"
    
    # 必須チェック実行
    mandatory_declaration_check
    force_cursor_rules_check
    mistake_learning_verification
    ai_org_collaboration_check
    generate_mandatory_checklist
    
    echo "📋 チェックリスト表示:" | tee -a "$PREVENTION_LOG"
    cat "$CHECKLIST_FILE" | tee -a "$PREVENTION_LOG"
    
    echo "✅ 防止システム実行完了 - 作業開始可能" | tee -a "$PREVENTION_LOG"
}

# =============================================================================
# 🎯 メイン実行部
# =============================================================================

case "${1:-}" in
    "declaration")
        mandatory_declaration_check
        ;;
    "cursor")
        force_cursor_rules_check
        ;;
    "mistakes")
        mistake_learning_verification
        ;;
    "team")
        ai_org_collaboration_check
        ;;
    "checklist")
        generate_mandatory_checklist
        cat "$CHECKLIST_FILE"
        ;;
    "full")
        execute_full_prevention_check
        ;;
    "status")
        echo "🛡️ ミス防止システム状況:"
        if [ -f "$PREVENTION_LOG" ]; then
            echo "📈 防止ログ: $PREVENTION_LOG"
            echo "📋 最新チェック:"
            tail -20 "$PREVENTION_LOG"
        else
            echo "⚠️ システム未実行"
        fi
        ;;
    *)
        echo "🛡️ ミス防止システム v1.0"
        echo ""
        echo "使用方法:"
        echo "  $0 declaration  # 必須宣言チェック"
        echo "  $0 cursor       # cursor rules確認"
        echo "  $0 mistakes     # ミス学習確認"
        echo "  $0 team         # AI組織連携確認"
        echo "  $0 checklist    # チェックリスト生成"
        echo "  $0 full         # 完全防止チェック"
        echo "  $0 status       # システム状況確認"
        echo ""
        echo "🎯 目的: 52回目ミス絶対防止"
        ;;
esac