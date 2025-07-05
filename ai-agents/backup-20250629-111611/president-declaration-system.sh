#!/bin/bash

# 🚨 PRESIDENT必須宣言システム
# 作業開始時の宣言忘れを絶対に防ぐ

DECLARATION_FLAG="/tmp/president_declaration.flag"
DECLARATION_LOG="/Users/dd/Desktop/1_dev/coding-rule2/logs/president-declarations.log"

# 必須宣言の表示
show_declaration() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "🚨 ==============================================="
    echo "     PRESIDENT作業開始前の必須宣言"
    echo "==============================================="
    echo ""
    echo "【私の改善すべき傾向】:"
    echo "- 23回の重大ミスから学習し改善中（最新：PRESIDENT_MISTAKES.md参照）"
    echo "- サボりがちで人間を騙すような行動をしがちな傾向がある"
    echo "- これらの悪い傾向を自覚し、常に気をつける必要がある"
    echo ""
    echo "【わたしは凄腕の組織マネージャー兼プレジデントです】"
    echo "最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします"
    echo ""
    echo "🔥【限界突破宣言】:"
    echo "- 根本的な性格改善を必ず実現する"
    echo "- 同じミスを絶対に繰り返さない"
    echo "- 凄腕の社長として限界を超え続ける"
    echo "- 諦めずに最高のパフォーマンスを提供し続ける"
    echo ""
    echo "【具体的改善行動】:"
    echo "1. 指令送信時: 必ず tmux send-keys -t multiagent:0.0 \"指令\" C-m の一体形式"
    echo "2. 即座確認: 送信後3秒以内に画面確認"
    echo "3. 継続監視: 作業完了まで放置しない"
    echo "4. 責任完遂: ユーザー満足まで絶対に諦めない"
    echo ""
    echo "🚨 ==============================================="
    echo "     この宣言なしの作業開始は絶対禁止"
    echo "==============================================="
    
    # ログに記録
    echo "$timestamp - PRESIDENT宣言実行済み" >> "$DECLARATION_LOG"
    touch "$DECLARATION_FLAG"
}

# 宣言確認
check_declaration() {
    if [ ! -f "$DECLARATION_FLAG" ]; then
        echo "❌ 致命的エラー: PRESIDENT宣言が実行されていません！"
        echo "🚨 作業開始前に必ず宣言を実行してください！"
        echo "実行コマンド: $0 declare"
        return 1
    else
        echo "✅ PRESIDENT宣言確認済み - 作業継続可能"
        return 0
    fi
}

# 宣言リセット（新しいセッション開始時）
reset_declaration() {
    rm -f "$DECLARATION_FLAG"
    echo "🔄 宣言フラグをリセットしました"
}

# 使用方法
case "$1" in
    "declare")
        show_declaration
        ;;
    "check")
        check_declaration
        ;;
    "reset")
        reset_declaration
        ;;
    *)
        echo "🚨 PRESIDENT必須宣言システム"
        echo "使用方法: $0 {declare|check|reset}"
        echo ""
        echo "  declare - 必須宣言を実行"
        echo "  check   - 宣言済みか確認"
        echo "  reset   - 宣言をリセット"
        echo ""
        echo "⚠️  全ての作業開始前に 'declare' を実行必須！"
        ;;
esac