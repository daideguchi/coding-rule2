#!/bin/bash
# Cursor → Claude Code 同期スクリプト

SYNC_FILE=".cursor-claude-sync.json"
PROJECT_STATUS="CLAUDE.md"

# プロジェクト状況ファイルの最終更新時刻を更新
update_project_status() {
    if [ -f "$PROJECT_STATUS" ]; then
        # 最終更新時刻を更新
        sed -i '' "s/\*\*最終更新\*\*:.*/\*\*最終更新\*\*: $(date '+%Y年%m月%d日 %H:%M:%S')/" "$PROJECT_STATUS"
        echo "📋 CLAUDE.md を更新しました"
    fi
}

# Cursor作業状況を記録
record_cursor_state() {
    # JSON同期データ作成
    cat > "$SYNC_FILE" << JSON
{
  "timestamp": "$(date -Iseconds)",
  "current_files": $(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.md" | head -20 | jq -R . | jq -s .),
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'No git')",
  "last_modified": "$(find . -type f -name "*.ts" -o -name "*.tsx" -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -5)"
}
JSON
    
    # プロジェクト状況ファイルの更新
    update_project_status
    
    echo "✅ Cursor作業状況を記録しました: $(date)"
}

# Claude Codeに状況共有
share_with_claude() {
    echo "🔄 Cursor ⇄ Claude Code 連携情報"
    echo "=================================="
    
    # プロジェクト状況ファイル表示
    if [ -f "$PROJECT_STATUS" ]; then
        echo ""
        echo "📋 プロジェクト状況概要:"
        echo "------------------------"
        # 概要部分のみ抜粋表示
        sed -n '/## 🎯 プロジェクト概要/,/## 📊 現在の進捗状況/p' "$PROJECT_STATUS" | sed '$d' | sed '$d'
        echo ""
        echo "📊 最新進捗状況:"
        echo "----------------"
        sed -n '/### ✅ 完了済み/,/### 🔄 進行中/p' "$PROJECT_STATUS" | sed '$d' | sed '$d'
        echo ""
        echo "💡 重要な決定事項:"
        echo "------------------"
        sed -n '/### 設計方針/,/### 技術的決定/p' "$PROJECT_STATUS" | sed '$d' | sed '$d'
        echo ""
        echo "📝 詳細は CLAUDE.md を参照してください"
    else
        echo "⚠️  CLAUDE.md が見つかりません"
    fi
    
    # 技術的同期データ表示
    if [ -f "$SYNC_FILE" ]; then
        echo ""
        echo "🔧 技術的同期データ:"
        echo "--------------------"
        cat "$SYNC_FILE"
    else
        echo ""
        echo "⚠️  同期データが見つかりません。./claude-cursor-sync.sh record を実行してください"
    fi
}

case "$1" in
    "record") record_cursor_state ;;
    "share") share_with_claude ;;
    *) echo "使用法: $0 {record|share}" ;;
esac
