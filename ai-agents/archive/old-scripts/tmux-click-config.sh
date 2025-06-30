#!/bin/bash

# tmux クリック設定スクリプト
# 分割されたターミナル（ペイン）をクリックでアクティブにする設定

echo "🖱️ tmux クリック設定を適用中..."

# tmux設定ファイルのパス
TMUX_CONFIG="$HOME/.tmux.conf"
BACKUP_CONFIG="$HOME/.tmux.conf.backup"

# 既存の設定をバックアップ
if [ -f "$TMUX_CONFIG" ]; then
    cp "$TMUX_CONFIG" "$BACKUP_CONFIG"
    echo "📁 既存設定をバックアップしました: $BACKUP_CONFIG"
fi

# クリック設定を追加
cat >> "$TMUX_CONFIG" << 'EOF'

# ==============================================
# AI組織システム - tmux クリック設定
# ==============================================

# マウス操作を有効化
set -g mouse on

# クリックでペイン選択
bind-key -T copy-mode-vi MouseDown1Pane select-pane
bind-key -T copy-mode MouseDown1Pane select-pane

# ペイン境界線をクリックでリサイズ
bind-key -T root MouseDrag1Border resize-pane -M

# ペイン内をクリックでアクティブ化
bind-key -T root MouseDown1Pane select-pane -t = \; send-keys -M

# ホイールスクロール設定
bind-key -T copy-mode-vi WheelUpPane send-keys -X scroll-up
bind-key -T copy-mode-vi WheelDownPane send-keys -X scroll-down
bind-key -T copy-mode WheelUpPane send-keys -X scroll-up
bind-key -T copy-mode WheelDownPane send-keys -X scroll-down

# ペイン選択時の視覚的フィードバック
set -g pane-active-border-style fg=yellow,bold
set -g pane-border-style fg=white

# ペイン番号表示時間延長（クリック時に分かりやすく）
set -g display-panes-time 2000

# ステータスバーでアクティブペイン情報表示
set -g status-right '#[fg=yellow]Active: #{pane_current_command} #[fg=white]%H:%M'

EOF

echo "✅ tmux クリック設定を追加しました"

# 現在のtmuxセッションに設定を適用
if tmux list-sessions &>/dev/null; then
    echo "🔄 現在のtmuxセッションに設定を適用中..."
    tmux source-file "$TMUX_CONFIG"
    echo "✅ 設定適用完了"
else
    echo "ℹ️ tmuxセッションが見つかりません。次回起動時に設定が適用されます"
fi

echo ""
echo "🖱️ クリック操作が有効になりました:"
echo "  • ペインをクリック → そのペインがアクティブに"
echo "  • ペイン境界をドラッグ → ペインサイズ変更"
echo "  • マウスホイール → スクロール"
echo "  • アクティブペインは黄色の境界線で表示"
echo ""
echo "🔧 設定ファイル: $TMUX_CONFIG"
echo "📁 バックアップ: $BACKUP_CONFIG" 