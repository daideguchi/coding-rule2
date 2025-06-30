#!/bin/bash
# cursor rules確認強制システム

CURSOR_RULES_FILE="globals.mdc"
CONFIRMATION_LOG="$BASE_DIR/logs/cursor-rules-confirmations.log"

enforce_cursor_rules_check() {
    echo "[$(date '+%H:%M:%S')] cursor rules確認強制チェック開始" >> "$CONFIRMATION_LOG"
    
    # globals.mdcファイル存在確認
    if [[ ! -f "$CURSOR_RULES_FILE" ]]; then
        echo "❌ globals.mdcファイルが見つかりません" >> "$CONFIRMATION_LOG"
        return 1
    fi
    
    # ファイル内容確認（実際に読み取り）
    local rules_content=$(head -10 "$CURSOR_RULES_FILE" 2>/dev/null)
    if [[ -n "$rules_content" ]]; then
        echo "✅ cursor rules確認完了" >> "$CONFIRMATION_LOG"
        echo "確認内容:" >> "$CONFIRMATION_LOG"
        echo "$rules_content" >> "$CONFIRMATION_LOG"
        echo "---" >> "$CONFIRMATION_LOG"
        return 0
    else
        echo "❌ cursor rules読み取り失敗" >> "$CONFIRMATION_LOG"
        return 1
    fi
}

# 定期的な確認強制実行
while true; do
    enforce_cursor_rules_check
    sleep 300  # 5分間隔
done
