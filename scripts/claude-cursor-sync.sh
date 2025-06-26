#!/bin/bash
# Cursor ↔ Claude Code 同期スクリプト

SYNC_FILE=".cursor-claude-sync.json"

case "$1" in
    "record")
        cat > "$SYNC_FILE" << JSON
{
  "timestamp": "$(date -Iseconds)",
  "current_files": $(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.md" | head -20 | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'No git')"
}
JSON
        echo "Cursor作業状況を記録しました"
        ;;
    "share")
        if [ -f "$SYNC_FILE" ]; then
            echo "最新のCursor作業状況:"
            cat "$SYNC_FILE"
        else
            echo "同期ファイルが見つかりません。まず 'record' を実行してください"
        fi
        ;;
    *)
        echo "使用法: $0 {record|share}"
        echo "  record: Cursorの現在状況を記録"
        echo "  share:  記録した状況をClaude Codeで確認"
        ;;
esac
