#!/bin/bash
# 🔧 パス管理システム v1.0 - 環境移植性向上

set -euo pipefail

# ================================================================================
# 🎯 環境移植性向上 - 動的パス管理システム
# ================================================================================

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# 🔍 プロジェクトルート自動検出
detect_project_root() {
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    
    # .git, .cursor, ai-agentsディレクトリの存在でプロジェクトルート判定
    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/.git" ] && [ -d "$search_dir/.cursor" ] && [ -d "$search_dir/ai-agents" ]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    log_error "プロジェクトルートが見つかりません"
    return 1
}

# 📁 重要パス動的生成
generate_dynamic_paths() {
    local project_root="$1"
    
    cat << EOF
# 🔧 動的パス設定（環境移植性対応）
# プロジェクトルート: $project_root

export PROJECT_ROOT="$project_root"
export PRESIDENT_MISTAKES="\$PROJECT_ROOT/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
export CURSOR_WORK_LOG="\$PROJECT_ROOT/.cursor/rules/work-log.mdc"
export CURSOR_GLOBALS="\$PROJECT_ROOT/.cursor/rules/globals.mdc"
export CONTINUOUS_IMPROVEMENT="\$PROJECT_ROOT/ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md"
export WORK_RECORDS="\$PROJECT_ROOT/logs/work-records.md"
export AI_AGENTS_DIR="\$PROJECT_ROOT/ai-agents"
export LOGS_DIR="\$PROJECT_ROOT/logs"

# 相対パス（推奨）
export REL_PRESIDENT_MISTAKES="./logs/ai-agents/president/PRESIDENT_MISTAKES.md"
export REL_CURSOR_WORK_LOG="./.cursor/rules/work-log.mdc"
export REL_CURSOR_GLOBALS="./.cursor/rules/globals.mdc"
export REL_CONTINUOUS_IMPROVEMENT="./ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md"
export REL_WORK_RECORDS="./logs/work-records.md"
EOF
}

# 🔍 パス存在確認
verify_paths() {
    local project_root="$1"
    
    log_info "📁 重要ファイル存在確認"
    
    local paths=(
        "$project_root/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
        "$project_root/.cursor/rules/work-log.mdc"
        "$project_root/.cursor/rules/globals.mdc"
        "$project_root/ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md"
        "$project_root/logs/work-records.md"
    )
    
    local missing_files=()
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ]; then
            log_success "✅ $(basename "$path")"
        else
            log_error "❌ $(basename "$path") - $path"
            missing_files+=("$path")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "$(printf '%s\n' "${missing_files[@]}")"
        return 1
    fi
    
    log_success "✅ 全重要ファイル確認完了"
}

# 🚀 環境設定スクリプト生成
create_env_setup() {
    local project_root="$1"
    local env_file="$project_root/ai-agents/env-setup.sh"
    
    cat > "$env_file" << 'EOF'
#!/bin/bash
# 🔧 環境設定スクリプト（自動生成）

# プロジェクトルート自動検出
detect_project_root() {
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    
    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/.git" ] && [ -d "$search_dir/.cursor" ] && [ -d "$search_dir/ai-agents" ]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    echo "ERROR: プロジェクトルートが見つかりません" >&2
    return 1
}

# 環境変数設定
if PROJECT_ROOT=$(detect_project_root); then
    export PROJECT_ROOT
    export PRESIDENT_MISTAKES="$PROJECT_ROOT/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    export CURSOR_WORK_LOG="$PROJECT_ROOT/.cursor/rules/work-log.mdc"
    export CURSOR_GLOBALS="$PROJECT_ROOT/.cursor/rules/globals.mdc"
    export CONTINUOUS_IMPROVEMENT="$PROJECT_ROOT/ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md"
    export WORK_RECORDS="$PROJECT_ROOT/logs/work-records.md"
    
    echo "✅ 環境設定完了: $PROJECT_ROOT"
else
    echo "❌ 環境設定失敗"
    exit 1
fi
EOF

    chmod +x "$env_file"
    log_success "✅ 環境設定スクリプト作成: $env_file"
}

# 📋 使用例生成
create_usage_examples() {
    local project_root="$1"
    local examples_file="$project_root/ai-agents/path-usage-examples.md"
    
    cat > "$examples_file" << 'EOF'
# 🔧 パス管理システム使用例

## 📁 推奨パターン（相対パス）

```bash
# ✅ 推奨：相対パス使用
cat ./logs/ai-agents/president/PRESIDENT_MISTAKES.md
cat ./.cursor/rules/work-log.mdc
cat ./ai-agents/CONTINUOUS_IMPROVEMENT_SYSTEM.md

# ✅ 推奨：環境変数使用
source ./ai-agents/env-setup.sh
cat "$PRESIDENT_MISTAKES"
cat "$CURSOR_WORK_LOG"
```

## ❌ 非推奨パターン（固定パス）

```bash
# ❌ 環境依存：絶対パス
cat /Users/dd/Desktop/1_dev/coding-rule2/logs/ai-agents/president/PRESIDENT_MISTAKES.md

# ❌ 硬直：ユーザー名固定
cat /Users/specific-user/project/file.md
```

## 🔧 環境検出パターン

```bash
# プロジェクトルート検出
if [ -f "./.cursor/rules/globals.mdc" ]; then
    echo "✅ プロジェクトルートで実行中"
    PROJECT_ROOT="$(pwd)"
else
    echo "❌ プロジェクトルートに移動してください"
    exit 1
fi
```

## 🚀 動的パス構築

```python
import os
import pathlib

# Python例
project_root = pathlib.Path(__file__).parent.parent
mistakes_file = project_root / "logs" / "ai-agents" / "president" / "PRESIDENT_MISTAKES.md"

if mistakes_file.exists():
    print(f"✅ {mistakes_file}")
else:
    print(f"❌ File not found: {mistakes_file}")
```

## 📊 移植性チェックリスト

- [ ] 絶対パス使用禁止
- [ ] 相対パス優先使用
- [ ] 環境変数活用
- [ ] プロジェクトルート自動検出
- [ ] 異なる環境での動作確認
EOF

    log_success "✅ 使用例ドキュメント作成: $examples_file"
}

# ================================================================================
# 🎯 メイン実行部分
# ================================================================================

main() {
    log_info "🔧 パス管理システム v1.0 開始"
    
    # プロジェクトルート検出
    if ! PROJECT_ROOT=$(detect_project_root); then
        log_error "❌ プロジェクトルート検出失敗"
        exit 1
    fi
    
    log_success "✅ プロジェクトルート検出: $PROJECT_ROOT"
    
    # パス存在確認
    if verify_paths "$PROJECT_ROOT"; then
        log_success "✅ パス検証完了"
    else
        log_error "❌ パス検証失敗"
        exit 1
    fi
    
    # 動的パス設定表示
    echo ""
    log_info "📋 動的パス設定:"
    generate_dynamic_paths "$PROJECT_ROOT"
    
    # 環境設定スクリプト生成
    create_env_setup "$PROJECT_ROOT"
    
    # 使用例生成
    create_usage_examples "$PROJECT_ROOT"
    
    echo ""
    log_success "🎊 パス管理システム構築完了"
    echo ""
    echo "📋 次のステップ:"
    echo "1. source ./ai-agents/env-setup.sh"
    echo "2. echo \$PROJECT_ROOT で確認"
    echo "3. 相対パス ./file.md を優先使用"
    echo ""
}

# 引数がある場合の処理分岐
case "${1:-main}" in
    "detect")
        detect_project_root
        ;;
    "verify")
        if PROJECT_ROOT=$(detect_project_root); then
            verify_paths "$PROJECT_ROOT"
        fi
        ;;
    "main"|*)
        main
        ;;
esac