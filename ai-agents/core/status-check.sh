#!/bin/bash
# 🔍 AI組織ステータス確認システム（非侵襲的）
# UIを変更せずにステータス情報を提供

echo "🔄 AI組織ステータス確認中..."

# ステータス検知（AUTO_STATUS_DETECTION.shから抜粋）
detect_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "ERROR")
    
    if [[ "$content" == "ERROR" ]]; then
        echo "🔴未起動"
        return
    fi
    
    if echo "$content" | grep -qE "(Coordinating|·.*tokens|Loading|Processing)"; then
        echo "🟢作業中"
        return
    fi
    
    if echo "$content" | grep -q "> ■" || echo "$content" | grep -q "> $"; then
        echo "🟡待機中"
        return
    fi
    
    if echo "$content" | grep -q "╰────.*╯"; then
        echo "🟡待機中"
        return
    fi
    
    echo "🟡待機中"
}

# 役職定義
ROLES=(
    "👔BOSS1│チームリーダー"
    "💻WORKER1│フロントエンド開発"
    "🔧WORKER2│バックエンド開発"
    "🎨WORKER3│UI/UXデザイナー"
)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏢 AI組織 現在ステータス"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 各ワーカーのステータス確認
for i in {0..3}; do
    status=$(detect_status "multiagent:0.$i")
    role="${ROLES[$i]}"
    echo "  $status $role"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""