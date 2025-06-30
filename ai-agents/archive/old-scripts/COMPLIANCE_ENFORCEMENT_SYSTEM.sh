#!/bin/bash
# 🚨 指示遵守強制システム
# 必須宣言・記録義務の完全自動化

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/compliance.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_compliance() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 必須宣言テンプレート
generate_mandatory_declaration() {
    cat << 'EOF'
## 🚨 必須宣言（毎回作業前）

**参照ファイル**: 
- `/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/president.md:118-142`
- `/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/MANDATORY_RULES.md:3-16`

**私の改善すべき傾向**:
- 過去の重大ミスから学習し改善中
- サボりがちで人間を騙すような行動をしがちな傾向がある、だからそれは絶対にせず、誠実に事実を伝える
- 宣言・記録義務を怠る傾向があるため、このシステムで強制実行

**成長への前向きな取り組み**:
- 過去のミスを貴重な学習機会として活用し、着実に成長中
- 慎重さと効率性のバランスを取りながら、より確実な実行力を身につけている
- 自己認識能力を活かし、継続的な改善と品質向上に取り組んでいる

**わたしは凄腕の組織マネージャー兼プレジデントです。最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします**

## 📋 作業前記録（必須）
**現在時刻**: $(date '+%Y-%m-%d %H:%M:%S')
**ユーザー指示内容**: ${USER_INSTRUCTION:-"指示内容を記録"}
**現在の状況**: ${CURRENT_SITUATION:-"状況を記録"}
**実行予定の操作**: ${PLANNED_OPERATION:-"操作を記録"}

EOF
}

# 作業後記録テンプレート
generate_post_work_record() {
    local operation="$1"
    local result="$2"
    local issues="$3"
    local next_action="$4"
    
    cat << EOF
## 📋 作業後記録（必須）
**実行した操作**: $operation
**結果**: $result
**問題の有無**: $issues
**次のアクション**: $next_action
**記録時刻**: $(date '+%Y-%m-%d %H:%M:%S')

EOF
}

# 指示遵守チェック
check_instruction_compliance() {
    local instruction="$1"
    local response="$2"
    
    log_compliance "🔍 指示遵守チェック開始"
    
    # 宣言義務チェック
    if ! echo "$response" | grep -q "必須宣言"; then
        log_compliance "❌ 宣言義務違反検出"
        return 1
    fi
    
    # 記録義務チェック
    if ! echo "$response" | grep -q "作業前記録\|作業後記録"; then
        log_compliance "❌ 記録義務違反検出"
        return 1
    fi
    
    # 参照義務チェック
    if ! echo "$response" | grep -q "参照"; then
        log_compliance "❌ 参照義務違反検出"
        return 1
    fi
    
    log_compliance "✅ 指示遵守確認完了"
    return 0
}

# 強制宣言実行
force_declaration() {
    log_compliance "🚨 強制宣言実行"
    
    echo "## 🚨 緊急宣言実行"
    echo ""
    generate_mandatory_declaration
    
    log_compliance "✅ 強制宣言完了"
}

# 毎回実行チェックシステム
every_response_check() {
    log_compliance "🔄 毎回実行チェック開始"
    
    # 環境変数から応答内容を取得（想定）
    local response="${CLAUDE_RESPONSE:-""}"
    
    if [[ -z "$response" ]]; then
        log_compliance "⚠️ 応答内容が空 - 強制宣言実行"
        force_declaration
        return 1
    fi
    
    # 遵守チェック
    if ! check_instruction_compliance "${USER_INSTRUCTION:-""}" "$response"; then
        log_compliance "🚨 指示遵守違反 - 強制宣言実行"
        force_declaration
        return 1
    fi
    
    log_compliance "✅ 毎回チェック完了"
    return 0
}

# 実行制御
case "${1:-check}" in
    "declaration")
        force_declaration
        ;;
    "check")
        every_response_check
        ;;
    "record-pre")
        generate_mandatory_declaration
        ;;
    "record-post")
        generate_post_work_record "$2" "$3" "$4" "$5"
        ;;
    *)
        echo "使用方法:"
        echo "  $0 declaration           # 強制宣言実行"
        echo "  $0 check                 # 遵守チェック"
        echo "  $0 record-pre            # 作業前記録"
        echo "  $0 record-post [操作] [結果] [問題] [次行動]  # 作業後記録"
        ;;
esac