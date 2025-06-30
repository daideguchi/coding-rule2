#!/bin/bash
# 🔥 自動ステータス検知・表示システム
# 作成日: 2025-06-29
# 目的: 実態に基づいた正確なステータスバー表示

# 要件定義から取得した役職構造
declare -A ROLES=(
    ["president"]="👑PRESIDENT │ 統括責任者・意思決定・品質管理"
    ["0"]="👔BOSS1 │ チームリーダー・タスク分割・分担管理"
    ["1"]="💻WORKER1 │ フロントエンド開発・UI/UX実装"
    ["2"]="🔧WORKER2 │ バックエンド開発・API設計・DB設計"  
    ["3"]="🎨WORKER3 │ UI/UXデザイナー・デザインシステム"
)

# ステータス検知関数
detect_status() {
    local target="$1"
    local content=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "ERROR")
    
    if [[ "$content" == "ERROR" ]]; then
        echo "🔴未起動"
        return
    fi
    
    # 重要: Bypassing Permissions は AI組織のデフォルト正常状態
    # この状態は待機中ではなく、正常動作を意味する
    
    # 作業中判定（ローディングやCoordinating...状態）
    if echo "$content" | grep -qE "(Coordinating|·.*tokens|Loading|Processing)"; then
        echo "🟢作業中"
        return
    fi
    
    # プロンプト待ち状態をチェック（> ■ の状態）
    if echo "$content" | grep -q "> ■" || echo "$content" | grep -q "> $"; then
        echo "🟡待機中"
        return
    fi
    
    # プロンプト入力待ち状態をチェック  
    if echo "$content" | grep -q "╰────.*╯"; then
        echo "🟡待機中"
        return
    fi
    
    # デフォルトは待機中
    echo "🟡待機中"
}

# ステータスバー更新関数
update_status_bar() {
    local session="$1"
    local pane="$2"
    local role_key="$3"
    
    local status=$(detect_status "$session:$pane")
    local role="${ROLES[$role_key]}"
    
    tmux select-pane -t "$session:$pane" -T "$status $role"
    echo "✅ $session:$pane → $status $role"
}

# 全ステータス更新
update_all_status() {
    echo "🔄 AI組織ステータス自動検知・更新開始"
    
    # PRESIDENT
    local president_status=$(detect_status "president")
    tmux select-pane -t "president" -T "$president_status ${ROLES[president]}"
    echo "✅ PRESIDENT → $president_status ${ROLES[president]}"
    
    # WORKERS
    for i in {0..3}; do
        update_status_bar "multiagent" "0.$i" "$i"
    done
    
    echo "🎯 AI組織ステータス自動更新完了"
}

# 連続監視モード
continuous_monitor() {
    echo "🔄 連続ステータス監視開始（Ctrl+Cで停止）"
    while true; do
        update_all_status
        sleep 10
    done
}

# 実行
case "${1:-update}" in
    "update")
        update_all_status
        ;;
    "monitor")
        continuous_monitor
        ;;
    *)
        echo "使用方法:"
        echo "  $0 update    # 1回更新"
        echo "  $0 monitor   # 連続監視"
        ;;
esac