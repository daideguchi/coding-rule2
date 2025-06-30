#!/bin/bash
# PRESIDENT起動時必須チェックリスト自動実行システム

BASE_DIR="/Users/dd/Desktop/1_dev/coding-rule2"
CHECKLIST_LOG="$BASE_DIR/logs/president-checklist.log"

echo "🔥 PRESIDENT必須チェックリスト開始 - $(date)" >> "$CHECKLIST_LOG"

# Step 1: 必須宣言確認
check_declaration() {
    echo "Step 1: 必須宣言確認" >> "$CHECKLIST_LOG"
    echo "❌ 宣言省略の重大ミスが発生しました" >> "$CHECKLIST_LOG"
    echo "⚠️  この機能では宣言を強制することはできません" >> "$CHECKLIST_LOG"
    echo "✅ 手動で必須宣言を実行してください:" >> "$CHECKLIST_LOG"
    echo "   - 54個の重大ミスから学習し改善中" >> "$CHECKLIST_LOG"
    echo "   - サボりがちな傾向を自覚し誠実に対応" >> "$CHECKLIST_LOG"
    echo "   - 最強社長として限界突破継続" >> "$CHECKLIST_LOG"
    
    # 重要：宣言は自動化できない - 毎回手動で必須実行
    echo "🚨 重要：宣言は自動化不可能 - 毎回手動実行必須" >> "$CHECKLIST_LOG"
}

# Step 2: 必須ファイル確認
check_required_files() {
    echo "Step 2: 必須ファイル確認" >> "$CHECKLIST_LOG"
    
    # PRESIDENT_MISTAKES.md確認
    if [ -f "$BASE_DIR/logs/ai-agents/president/PRESIDENT_MISTAKES.md" ]; then
        echo "✅ PRESIDENT_MISTAKES.md確認済み" >> "$CHECKLIST_LOG"
    else
        echo "❌ PRESIDENT_MISTAKES.md未確認" >> "$CHECKLIST_LOG"
        return 1
    fi
    
    # work-log.mdc確認
    if [ -f "$BASE_DIR/.cursor/rules/work-log.mdc" ]; then
        echo "✅ work-log.mdc確認済み" >> "$CHECKLIST_LOG"
    else
        echo "❌ work-log.mdc未確認" >> "$CHECKLIST_LOG"
        return 1
    fi
    
    # globals.mdc確認
    if [ -f "$BASE_DIR/.cursor/rules/globals.mdc" ]; then
        echo "✅ globals.mdc確認済み" >> "$CHECKLIST_LOG"
    else
        echo "❌ globals.mdc未確認" >> "$CHECKLIST_LOG"
        return 1
    fi
}

# Step 3: ワーカー状況確認
check_workers() {
    echo "Step 3: ワーカー状況確認" >> "$CHECKLIST_LOG"
    
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "✅ multiagentセッション稼働中" >> "$CHECKLIST_LOG"
        
        # 各ワーカーの状況確認
        for i in {0..3}; do
            if tmux list-panes -t "multiagent:0" | grep -q "^$i:"; then
                echo "✅ WORKER$i稼働中" >> "$CHECKLIST_LOG"
            else
                echo "❌ WORKER$i未稼働" >> "$CHECKLIST_LOG"
                return 1
            fi
        done
    else
        echo "❌ multiagentセッション未起動" >> "$CHECKLIST_LOG"
        return 1
    fi
}

# Step 4: ステータスバー確認
check_status_bar() {
    echo "Step 4: ステータスバー確認" >> "$CHECKLIST_LOG"
    
    if [ -f "$BASE_DIR/ai-agents/scripts/automation/core/auto-status-detection.sh" ]; then
        echo "✅ ステータスバー更新スクリプト存在" >> "$CHECKLIST_LOG"
    else
        echo "❌ ステータスバー更新スクリプト未存在" >> "$CHECKLIST_LOG"
        return 1
    fi
}

# 全チェック実行
main() {
    echo "🚀 PRESIDENT必須チェックリスト実行開始"
    
    check_declaration
    if ! check_required_files; then
        echo "❌ 必須ファイル確認でエラーが発生しました"
        exit 1
    fi
    
    if ! check_workers; then
        echo "❌ ワーカー状況確認でエラーが発生しました"
        exit 1
    fi
    
    check_status_bar
    
    echo "✅ PRESIDENT必須チェックリスト完了 - $(date)" >> "$CHECKLIST_LOG"
    echo "🎯 全ての必須チェックが完了しました！"
}

# メイン実行
main "$@"