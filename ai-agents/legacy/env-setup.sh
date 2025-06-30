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
