#!/bin/bash
# 🔥 究極のステータス修正システム - 限界突破版
# 作成日: 2025-06-29
# 目的: ステータス表示問題を完全根絶

echo "🔥 限界突破！究極のステータス修正システム開始"

# 重要事実の再確認
echo "📋 重要事実: Bypassing Permissions = AI組織のデフォルト正常状態"

# 完全新ロジック: より確実な検知
detect_real_status() {
    local target="$1"
    
    # セッション存在確認
    if ! tmux has-session -t "${target%:*}" 2>/dev/null; then
        echo "🔴未起動"
        return
    fi
    
    # ペイン存在確認
    if ! tmux list-panes -t "$target" >/dev/null 2>&1; then
        echo "🔴未起動"
        return
    fi
    
    # 画面内容取得（複数回試行）
    local content=""
    for attempt in {1..3}; do
        content=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
        if [[ -n "$content" ]]; then
            break
        fi
        sleep 0.5
    done
    
    if [[ -z "$content" ]]; then
        echo "🔴未起動"
        return
    fi
    
    # デバッグ用: 最後の数行を確認
    local last_lines=$(echo "$content" | tail -3)
    
    # 🔥 新しい正確な判定ロジック（ユーザー指摘反映）
    
    # 作業中パターン（明確な作業表示のみ）
    if echo "$content" | grep -qE "(Coordinating.*tokens|Loading|Processing|Computing|· .*tokens|Thinking)"; then
        echo "🟢作業中"
        return
    fi
    
    # 「>」はデフォルト表示 = 待機中（ユーザー指摘）
    if echo "$content" | grep -q ">"; then
        echo "🟡待機中"
        return
    fi
    
    # 空白状態も待機中（ユーザー指摘）
    if echo "$content" | grep -q "? for shortcuts"; then
        echo "🟡待機中"
        return
    fi
    
    # 入力ボックス状態も待機中
    if echo "$content" | grep -q "╰─.*─╯"; then
        echo "🟡待機中"
        return
    fi
    
    # デフォルト: 待機中（安全側）
    echo "🟡待機中"
}

# 強制的にすべてを正しく設定
force_correct_status() {
    echo "🚨 強制的正しいステータス設定開始"
    
    # PRESIDENT（実際に作業中）
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ 統括責任者・意思決定・品質管理"
    echo "✅ PRESIDENT設定完了"
    
    # 各ワーカーの実態確認と設定
    declare -a roles=(
        "👔BOSS1 │ チームリーダー・タスク分割・分担管理"
        "💻WORKER1 │ フロントエンド開発・UI/UX実装"
        "🔧WORKER2 │ バックエンド開発・API設計・DB設計"
        "🎨WORKER3 │ UI/UXデザイナー・デザインシステム"
    )
    
    for i in {0..3}; do
        local status=$(detect_real_status "multiagent:0.$i")
        local role="${roles[$i]}"
        
        tmux select-pane -t "multiagent:0.$i" -T "$status $role"
        echo "✅ WORKER$i → $status $role"
    done
}

# tmux ステータスバー設定の強制適用
force_tmux_settings() {
    echo "📊 tmuxステータスバー設定強制適用"
    
    # 基本設定
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-format "#[bg=colour235,fg=colour255] #{pane_title} "
    tmux set-option -g status-position bottom
    
    # 更新間隔を短縮
    tmux set-option -g status-interval 1
    
    echo "✅ tmux設定適用完了"
}

# 継続監視システム（オプション）
continuous_fix() {
    echo "🔄 継続監視モード開始（Ctrl+Cで停止）"
    while true; do
        force_correct_status
        echo "⏰ $(date '+%H:%M:%S') - ステータス更新完了"
        sleep 5
    done
}

# メイン実行
main() {
    case "${1:-fix}" in
        "fix")
            force_tmux_settings
            force_correct_status
            echo "🎯 究極のステータス修正完了"
            ;;
        "monitor")
            force_tmux_settings
            continuous_fix
            ;;
        *)
            echo "使用方法:"
            echo "  $0 fix      # 1回修正（デフォルト）"
            echo "  $0 monitor  # 継続監視"
            ;;
    esac
}

# 実行
main "$@"