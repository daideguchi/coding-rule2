#!/bin/bash
# 🔍 要件定義・仕様書確認システム
# 作業前の必須チェックを自動化

LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/requirements-check.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_req() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# プロジェクト要件定義ファイル検出
detect_project_requirements() {
    local project_root="$1"
    local requirements_files=()
    
    # プロジェクト固有の要件定義ファイル
    local specific_files=(
        "ai-agents/instructions/president.md"
        ".cursor/rules.md"
        "README.md"
    )
    
    log_req "🔍 要件定義ファイル検索開始: $project_root"
    
    for file in "${specific_files[@]}"; do
        local full_path="$project_root/$file"
        if [[ -f "$full_path" ]]; then
            requirements_files+=("$full_path")
            log_req "📋 発見: $full_path"
        fi
    done
    
    # 結果出力
    if [[ ${#requirements_files[@]} -eq 0 ]]; then
        log_req "⚠️ 要件定義ファイルが見つかりません"
        return 1
    else
        log_req "✅ ${#requirements_files[@]}個の要件定義ファイル発見"
        printf '%s\n' "${requirements_files[@]}"
        return 0
    fi
}

# 要件定義必須確認プロセス
mandatory_requirements_check() {
    local project_root="${1:-$(pwd)}"
    
    log_req "🚨 要件定義必須確認開始"
    log_req "📂 対象プロジェクト: $project_root"
    
    # 1. 要件定義ファイル検出
    local req_files
    if ! req_files=$(detect_project_requirements "$project_root"); then
        log_req "❌ 要件定義ファイル未発見 - 手動確認必要"
        echo "REQUIREMENTS_MISSING"
        return 1
    fi
    
    # 2. 主要ファイル特定
    local primary_req=""
    local president_instruction=""
    
    while IFS= read -r file; do
        case "$file" in
            *instructions/president.md)
                president_instruction="$file"
                log_req "👑 PRESIDENT指示書発見: $file"
                ;;
            *requirements*.md|*specification*.md)
                [[ -z "$primary_req" ]] && primary_req="$file"
                log_req "📋 主要要件定義: $file"
                ;;
        esac
    done <<< "$req_files"
    
    # 3. 確認必須ファイルの表示
    log_req "📖 作業前確認必須ファイル一覧:"
    
    if [[ -n "$president_instruction" ]]; then
        log_req "🔥 最優先: $president_instruction"
        echo "PRESIDENT_INSTRUCTION=$president_instruction"
    fi
    
    if [[ -n "$primary_req" ]]; then
        log_req "📋 要件定義: $primary_req"
        echo "PRIMARY_REQUIREMENTS=$primary_req"
    fi
    
    # 4. 追加確認推奨ファイル
    while IFS= read -r file; do
        if [[ "$file" != "$president_instruction" && "$file" != "$primary_req" ]]; then
            log_req "📄 追加確認推奨: $file"
            echo "ADDITIONAL_REQ=$file"
        fi
    done <<< "$req_files"
    
    log_req "✅ 要件定義確認リスト生成完了"
    return 0
}

# Claude用確認プロンプト生成
generate_claude_check_prompt() {
    local project_root="${1:-$(pwd)}"
    local check_result
    
    log_req "🤖 Claude用確認プロンプト生成"
    
    if ! check_result=$(mandatory_requirements_check "$project_root"); then
        echo "エラー: 要件定義ファイルが見つかりません"
        return 1
    fi
    
    # 確認必須ファイル抽出
    local president_file=""
    local primary_req=""
    local additional_files=()
    
    while IFS= read -r line; do
        case "$line" in
            PRESIDENT_INSTRUCTION=*)
                president_file="${line#PRESIDENT_INSTRUCTION=}"
                ;;
            PRIMARY_REQUIREMENTS=*)
                primary_req="${line#PRIMARY_REQUIREMENTS=}"
                ;;
            ADDITIONAL_REQ=*)
                additional_files+=("${line#ADDITIONAL_REQ=}")
                ;;
        esac
    done <<< "$check_result"
    
    # プロンプト生成
    echo "🔍 作業開始前の必須確認事項:"
    echo ""
    
    if [[ -n "$president_file" ]]; then
        echo "📋 1. PRESIDENT指示書確認 (最優先)"
        echo "   ファイル: $president_file"
        echo "   目的: 作業フロー・注意事項・過去ミス確認"
        echo ""
    fi
    
    if [[ -n "$primary_req" ]]; then
        echo "📋 2. 要件定義・仕様書確認"
        echo "   ファイル: $primary_req"
        echo "   目的: プロジェクト要件・仕様・制約条件確認"
        echo ""
    fi
    
    if [[ ${#additional_files[@]} -gt 0 ]]; then
        echo "📋 3. 追加確認推奨ファイル"
        for file in "${additional_files[@]}"; do
            echo "   - $file"
        done
        echo ""
    fi
    
    echo "⚠️ これらの確認を怠ると憶測による作業・要件違反が発生します"
    echo "✅ 確認完了後に作業を開始してください"
    
    log_req "✅ Claude用プロンプト生成完了"
}

# 自動確認実行（Claude統合用）
auto_check_for_claude() {
    local project_root="${1:-$(pwd)}"
    
    log_req "🤖 Claude自動確認実行"
    
    # プロンプト生成・表示
    generate_claude_check_prompt "$project_root"
    
    echo ""
    echo "🚀 次のステップ: 上記ファイルをRead toolで確認してください"
    
    log_req "✅ Claude自動確認完了"
}

# 実行制御
case "${1:-auto}" in
    "detect")
        detect_project_requirements "${2:-$(pwd)}"
        ;;
    "check")
        mandatory_requirements_check "${2:-$(pwd)}"
        ;;
    "prompt")
        generate_claude_check_prompt "${2:-$(pwd)}"
        ;;
    "auto")
        auto_check_for_claude "${2:-$(pwd)}"
        ;;
    *)
        echo "使用方法:"
        echo "  $0 detect [project_root]  # 要件定義ファイル検出"
        echo "  $0 check [project_root]   # 必須確認ファイル特定"
        echo "  $0 prompt [project_root]  # Claude用プロンプト生成"
        echo "  $0 auto [project_root]    # 自動確認実行"
        ;;
esac