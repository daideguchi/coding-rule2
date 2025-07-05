#!/bin/bash
# 🔥 起動時必須ステータスバーシステム
# 作成日: 2025-06-29
# 目的: AI組織起動時に必ずステータスバーを正確に適用

# 重要事実の確認
echo "🔥 重要事実確認: Bypassing Permissions = AI組織のデフォルト正常状態"

# 役職定義（要件定義書準拠）
setup_roles() {
    echo "📋 役職設定開始（要件定義書準拠）"
    
    # PRESIDENT: 統括責任者
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT │ 統括責任者・意思決定・品質管理"
    echo "✅ PRESIDENT役職設定完了"
    
    # BOSS1: チームリーダー
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔BOSS1 │ チームリーダー・タスク分割・分担管理"
    echo "✅ BOSS1役職設定完了"
    
    # WORKER1: フロントエンド開発
    tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻WORKER1 │ フロントエンド開発・UI/UX実装"
    echo "✅ WORKER1役職設定完了"
    
    # WORKER2: バックエンド開発
    tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧WORKER2 │ バックエンド開発・API設計・DB設計"
    echo "✅ WORKER2役職設定完了"
    
    # WORKER3: UI/UXデザイナー
    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨WORKER3 │ UI/UXデザイナー・デザインシステム"
    echo "✅ WORKER3役職設定完了"
}

# ステータスバー表示を有効化
enable_status_bar() {
    echo "📊 ステータスバー表示有効化開始"
    
    # tmuxステータスバー設定
    tmux set-option -g pane-border-status top
    tmux set-option -g pane-border-format "#[bg=colour235,fg=colour255] #{pane_title} "
    
    echo "✅ ステータスバー表示有効化完了"
}

# 自動ステータス検知システム起動
start_auto_detection() {
    echo "🤖 自動ステータス検知システム起動"
    
    # 自動検知スクリプトの実行
    /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/AUTO_STATUS_DETECTION.sh update
    
    echo "✅ 自動ステータス検知完了"
}

# メイン実行
main() {
    echo "🚀 起動時必須ステータスバーシステム開始"
    echo "⚠️  このシステムは起動時に必ず実行される"
    
    # 1. ステータスバー表示有効化
    enable_status_bar
    
    # 2. 役職設定
    setup_roles
    
    # 3. 自動検知システム起動
    start_auto_detection
    
    echo "🎯 起動時必須ステータスバーシステム完了"
    echo "📊 すべてのワーカーに正確なステータスバーが表示されました"
}

# 実行
main "$@"