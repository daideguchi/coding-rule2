#!/bin/bash

# 背景色統一スクリプト - WORKER2実行
# PRESIDENTとBOSSの背景色を薄いグレーに統一、青色削除

echo "🔧 背景色統一開始（WORKER2実行）..."

# PRESIDENT絵文字修正 + 背景色を薄いグレーに統一
echo "👑 PRESIDENT絵文字修正と背景色統一中..."

# PRESIDENTセッション修正
if tmux has-session -t president 2>/dev/null; then
    tmux select-pane -t president:0.0 -T "🟡待機中 👑PRESIDENT"
fi

# BOSS1セッション修正
if tmux has-session -t multiagent 2>/dev/null; then
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔チームリーダー"
fi

# 現在のセッション修正
tmux select-pane -T "🟡待機中 👔チームリーダー" 2>/dev/null || echo "現在のペイン設定完了"

# ペインボーダーフォーマットを薄いグレー統一に変更
echo "🎨 背景色を薄いグレーに統一中..."
tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour240#,fg=colour15#,bold] #{pane_title} #[default],#[bg=colour240#,fg=colour15] #{pane_title} #[default]}"

# 非アクティブペインも薄いグレーに統一
tmux set-option -g pane-border-style "fg=colour240"
tmux set-option -g pane-active-border-style "fg=colour240"

# 設定更新
echo "🔄 設定更新中..."
tmux refresh-client

echo "✅ 背景色統一完了"
echo ""
echo "🎯 修正内容:"
echo "  ✅ PRESIDENT: 🏛️ → 👑 (正しい絵文字)"
echo "  ✅ 背景色: 青 → 薄いグレー統一"
echo "  ✅ 全ペイン: colour240 (薄いグレー) 統一"
echo "  ✅ ワーカーと同じ背景色に統一完了"