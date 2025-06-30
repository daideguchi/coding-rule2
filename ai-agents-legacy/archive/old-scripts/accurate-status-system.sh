#!/bin/bash

# 📊 正確なステータス管理システム
# 実際の作業状況に基づいた正確なステータス表示

# 実際の作業状況を検知（改良版）
detect_actual_status() {
    local pane=$1
    local content=$(tmux capture-pane -t "$pane" -p)
    local recent_content=$(tmux capture-pane -t "$pane" -p | tail -10)
    
    # より正確な作業状況判定
    # 1. 明確に作業中のパターン
    if echo "$recent_content" | grep -q "Wrangling\|Organizing\|Planning\|Polishing\|Searching\|Thinking\|Writing\|Creating\|Analyzing\|Processing"; then
        echo "🔵作業中"
    # 2. メッセージ入力中やコマンド実行中
    elif echo "$content" | grep -q "tokens.*esc to interrupt\|Context left until auto-compact"; then
        echo "🔵作業中"
    # 3. アクティブなセッション（プロンプトが表示されているが何かしている）
    elif echo "$content" | grep -q "> " && echo "$content" | grep -v "PRESIDENTからの指示をお待ちしております"; then
        echo "🔵作業中"
    # 4. タスク完了後も待機中扱い
    elif echo "$content" | grep -q "completed\|完了\|finished\|✅"; then
        echo "🟡待機中"
    # 5. Bypassing Permissions状態
    elif echo "$content" | grep -q "Bypassing Permissions"; then
        echo "🟡待機中"
    # 6. 完全に空白（未起動）
    elif [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
        echo "⚫未起動"
    # 7. Claude Code起動済みだが明確に待機中
    elif echo "$content" | grep -q "PRESIDENTからの指示をお待ちしております\|BOSSからの指示をお待ちしております"; then
        echo "🟡待機中"
    # 8. デフォルト：アクティブなセッションは作業中とみなす
    else
        echo "🔵作業中"
    fi
}

# 全ワーカーの正確なステータス更新
update_accurate_status() {
    echo "📊 実際の作業状況に基づくステータス更新中..."
    
    # プレジデント確認
    local president_status=$(detect_actual_status "president:0")
    tmux select-pane -t president:0 -T "#[bg=colour238,fg=colour15] $president_status 👑PRESIDENT │ システム統括管理 #[default]"
    echo "PRESIDENT: $president_status"
    
    # ワーカー確認
    local worker_roles=("👔チームリーダー │ 作業指示・進捗管理" "💻フロントエンド │ UI実装・React開発" "🔧バックエンド │ API開発・DB設計" "🎨UI/UXデザイン │ デザイン改善・UX最適化")
    
    for i in {0..3}; do
        local worker_status=$(detect_actual_status "multiagent:0.$i")
        tmux select-pane -t multiagent:0.$i -T "#[bg=colour238,fg=colour15] $worker_status ${worker_roles[$i]} #[default]"
        echo "WORKER$i: $worker_status"
    done
    
    echo "✅ 正確なステータス更新完了"
}

# 手動ステータス変更
manual_status_change() {
    local worker=$1
    local status=$2
    
    case $status in
        "working"|"work") status="🔵作業中" ;;
        "waiting"|"wait") status="🟡待機中" ;;
        "offline"|"off") status="⚫未起動" ;;
        *) echo "❌ 無効なステータス: $status"; return 1 ;;
    esac
    
    case $worker in
        "president"|"p")
            tmux select-pane -t president:0 -T "#[bg=colour238,fg=colour15] $status 👑PRESIDENT │ システム統括管理 #[default]"
            echo "✅ PRESIDENT: $status"
            ;;
        "boss"|"0")
            tmux select-pane -t multiagent:0.0 -T "#[bg=colour238,fg=colour15] $status 👔チームリーダー │ 作業指示・進捗管理 #[default]"
            echo "✅ BOSS1: $status"
            ;;
        "1")
            tmux select-pane -t multiagent:0.1 -T "#[bg=colour238,fg=colour15] $status 💻フロントエンド │ UI実装・React開発 #[default]"
            echo "✅ WORKER1: $status"
            ;;
        "2")
            tmux select-pane -t multiagent:0.2 -T "#[bg=colour238,fg=colour15] $status 🔧バックエンド │ API開発・DB設計 #[default]"
            echo "✅ WORKER2: $status"
            ;;
        "3")
            tmux select-pane -t multiagent:0.3 -T "#[bg=colour238,fg=colour15] $status 🎨UI/UXデザイン │ デザイン改善・UX最適化 #[default]"
            echo "✅ WORKER3: $status"
            ;;
        *) echo "❌ 無効なワーカー: $worker"; return 1 ;;
    esac
}

# 現在のステータス表示
show_current_status() {
    echo "📊 現在のステータス:"
    echo "  PRESIDENT: $(tmux display-message -t president:0 -p "#{pane_title}")"
    for i in {0..3}; do
        echo "  WORKER$i: $(tmux display-message -t multiagent:0.$i -p "#{pane_title}")"
    done
}

# 使用方法
case "$1" in
    "update")
        update_accurate_status
        ;;
    "set")
        manual_status_change "$2" "$3"
        ;;
    "show")
        show_current_status
        ;;
    *)
        echo "📊 正確なステータス管理システム"
        echo ""
        echo "使用方法:"
        echo "  $0 update                    # 実際の状況に基づく自動更新"
        echo "  $0 set [worker] [status]     # 手動ステータス変更"
        echo "  $0 show                      # 現在のステータス表示"
        echo ""
        echo "ワーカー: president, boss, 0, 1, 2, 3"
        echo "ステータス: working, waiting, offline"
        echo ""
        echo "例: $0 set 1 working          # WORKER1を作業中に"
        echo "例: $0 set boss waiting       # BOSS1を待機中に"
        ;;
esac