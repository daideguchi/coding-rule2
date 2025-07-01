#!/bin/bash
# 虚偽報告検知・確認強制システム

set -euo pipefail

# プロジェクトルート自動検出
detect_project_root() {
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/.git" ] && [ -d "$search_dir/ai-agents" ]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    echo "ERROR: プロジェクトルートが見つかりません" >&2
    return 1
}

if ! PROJECT_ROOT=$(detect_project_root); then
    exit 1
fi

BASE_DIR="$PROJECT_ROOT"
VERIFICATION_LOG="$BASE_DIR/logs/verification-checks.log"

# ログディレクトリ作成
mkdir -p "$(dirname "$VERIFICATION_LOG")"

verify_actual_execution() {
    local action="$1"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] 確認強制: $action" >> "$VERIFICATION_LOG"
    
    case "$action" in
        "cursor_rules")
            # globals.mdcの実際の読み取り強制
            if [[ -f "globals.mdc" ]]; then
                local actual_content=$(head -5 globals.mdc 2>/dev/null)
                if [[ -n "$actual_content" ]]; then
                    echo "✅ cursor rules実際確認完了" >> "$VERIFICATION_LOG"
                    echo "確認済み内容: $actual_content" >> "$VERIFICATION_LOG"
                else
                    echo "❌ cursor rules確認失敗" >> "$VERIFICATION_LOG"
                fi
            else
                echo "❌ globals.mdcファイル不存在" >> "$VERIFICATION_LOG"
            fi
            ;;
        "system_health")
            # システムヘルスの実際の確認
            local tmux_sessions=$(tmux list-sessions 2>/dev/null | wc -l)
            echo "✅ システムヘルス確認: tmuxセッション数 $tmux_sessions" >> "$VERIFICATION_LOG"
            ;;
        *)
            echo "⚠️  不明な確認項目: $action" >> "$VERIFICATION_LOG"
            ;;
    esac
}

# 各種確認の実行
verify_actual_execution "cursor_rules"
verify_actual_execution "system_health"
