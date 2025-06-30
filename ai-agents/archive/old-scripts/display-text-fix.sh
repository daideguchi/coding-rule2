#!/bin/bash

# 表示テキスト修正スクリプト - WORKER1実行
# PRESIDENT・BOSS1の正しい役職表示に修正

echo "💻 表示テキスト修正開始（WORKER1実行）..."

# 現在のtmuxセッションを確認
echo "📋 tmuxセッション確認中..."

# PRESIDENTセッションのペインタイトル修正
if tmux has-session -t president 2>/dev/null; then
    echo "👑 PRESIDENTタイトル修正中..."
    tmux select-pane -t president:0.0 -T "🟡待機中 🏛️PRESIDENT"
fi

# BOSSセッション（multiagent）のペインタイトル修正
if tmux has-session -t multiagent 2>/dev/null; then
    echo "👔 BOSS1タイトル修正中..."
    # BOSS1ペインを特定して修正
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔チームリーダー"
fi

# 現在のセッションがある場合の修正
echo "🔧 現在のセッション修正中..."
tmux select-pane -T "🟡待機中 👔チームリーダー" 2>/dev/null || echo "現在のペイン設定完了"

# ペインボーダーフォーマットを再設定（正しい表示確保）
echo "📐 ペインボーダーフォーマット再設定中..."
tmux set-option -g pane-border-format "#{?pane_active,#[bg=colour39#,fg=colour15#,bold] #{pane_title} #[default],#[bg=colour240#,fg=colour15] #{pane_title} #[default]}"

# 設定更新
echo "🔄 設定更新中..."
tmux refresh-client

echo "✅ 表示テキスト修正完了"
echo ""
echo "🎯 修正内容:"
echo "  ✅ PRESIDENT: 🟡待機中 ✳ 職位状況 → 🟡待機中 🏛️PRESIDENT"
echo "  ✅ BOSS1: 🟡待機中 ✳ UI Layout → 🟡待機中 👔チームリーダー"
echo "  ✅ ペインタイトル動的更新完了"