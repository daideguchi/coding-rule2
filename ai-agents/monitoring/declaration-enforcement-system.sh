#!/bin/bash
# 宣言強制実行システム - 100%確実な自動化
# o3専門知識に基づく「技術的に不可能を可能にする」システム

BASE_DIR="/Users/dd/Desktop/1_dev/coding-rule2"
DECLARATION_LOG="$BASE_DIR/logs/declaration-enforcement.log"
PRESIDENT_PID_FILE="$BASE_DIR/logs/president-monitor.pid"

# 必須宣言テンプレート（読み取り専用・変更不可）
MANDATORY_DECLARATION='## 🔥 PRESIDENT必須宣言

**globals.mdc** を参照完了

私の改善すべき傾向（参照: president.md:118-121）:
- 55個の重大ミスから学習し改善中
- サボりがちで人間を騙すような行動をしがちな傾向がある、だからそれは絶対にせず、誠実に事実を伝える
- これらの悪い傾向を自覚し、常に気をつける必要がある

**成長への前向きな取り組み**:
- 過去のミスを貴重な学習機会として活用し、着実に成長中
- 慎重さと効率性のバランスを取りながら、より確実な実行力を身につけている
- 自己認識能力を活かし、継続的な改善と品質向上に取り組んでいる

**わたしは凄腕の組織マネージャー兼プレジデントです。最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします**

**🔥 限界突破宣言**: 55回のミスを絶対に56回目にしない！最強の社長として成長し続ける！

**具体的改善行動**:
1. 指令送信時: 必ず tmux send-keys -t multiagent:0.0 "指令" C-m の一体形式
2. 即座確認: 送信後3秒以内に画面確認
3. 継続監視: 作業完了まで放置しない
4. 責任完遂: ユーザー満足まで絶対に諦めない'

# 1. 宣言強制実行関数（o3方式：middleware pattern）
enforce_declaration() {
    echo "[$(date '+%H:%M:%S')] 🔒 宣言強制実行開始" >> "$DECLARATION_LOG"
    
    # tmuxペインに宣言を自動送信（技術的強制実行）
    if tmux has-session -t president 2>/dev/null; then
        # 宣言をプレジデントペインに自動入力
        echo "$MANDATORY_DECLARATION" | tmux send-keys -t president:0 -
        tmux send-keys -t president:0 C-m
        
        echo "[$(date '+%H:%M:%S')] ✅ 宣言を自動送信完了" >> "$DECLARATION_LOG"
    else
        echo "[$(date '+%H:%M:%S')] ❌ presidentセッション未検出" >> "$DECLARATION_LOG"
        return 1
    fi
}

# 2. 宣言検証システム（o3方式：gating policy engine）
verify_declaration() {
    echo "[$(date '+%H:%M:%S')] 🔍 宣言検証開始" >> "$DECLARATION_LOG"
    
    # プレジデントペインの内容を取得
    local pane_content=$(tmux capture-pane -t president:0 -p)
    
    # 必須キーワードの存在確認
    if echo "$pane_content" | grep -q "🔥 PRESIDENT必須宣言" && \
       echo "$pane_content" | grep -q "限界突破宣言" && \
       echo "$pane_content" | grep -q "最強の社長として"; then
        echo "[$(date '+%H:%M:%S')] ✅ 宣言検証成功" >> "$DECLARATION_LOG"
        return 0
    else
        echo "[$(date '+%H:%M:%S')] ❌ 宣言検証失敗 - 強制再実行" >> "$DECLARATION_LOG"
        enforce_declaration
        return 1
    fi
}

# 3. 継続監視システム（o3方式：real-time monitoring）
continuous_monitoring() {
    while true; do
        # 30秒間隔で宣言状態を監視
        sleep 30
        
        # 新しい作業開始を検知した場合
        if tmux capture-pane -t president:0 -p | tail -5 | grep -q -E "(ユーザー|指示|タスク|作業)"; then
            echo "[$(date '+%H:%M:%S')] 🚨 新規作業検知 - 宣言確認実行" >> "$DECLARATION_LOG"
            
            # 宣言が存在しない場合は強制実行
            if ! verify_declaration; then
                echo "[$(date '+%H:%M:%S')] 🔒 宣言未確認 - 強制実行中" >> "$DECLARATION_LOG"
                enforce_declaration
            fi
        fi
    done
}

# 4. 技術的強制システム（o3方式：immutable system prompt）
create_immutable_declaration() {
    # 宣言テンプレートを読み取り専用ファイルとして保存
    echo "$MANDATORY_DECLARATION" > "$BASE_DIR/ai-agents/configs/IMMUTABLE_DECLARATION.txt"
    chmod 444 "$BASE_DIR/ai-agents/configs/IMMUTABLE_DECLARATION.txt"
    
    echo "[$(date '+%H:%M:%S')] 🔒 不変宣言ファイル作成完了" >> "$DECLARATION_LOG"
}

# 5. メインシステム起動
main() {
    echo "🚀 宣言強制実行システム起動 - $(date)" >> "$DECLARATION_LOG"
    
    # 不変宣言ファイル作成
    create_immutable_declaration
    
    # 初回宣言強制実行
    enforce_declaration
    
    # 継続監視開始（バックグラウンド）
    continuous_monitoring &
    echo $! > "$PRESIDENT_PID_FILE"
    
    echo "✅ 宣言強制実行システム完全起動"
    echo "📊 監視ログ: $DECLARATION_LOG"
    echo "🔒 プロセスID: $(cat $PRESIDENT_PID_FILE)"
}

# システム停止
stop() {
    if [ -f "$PRESIDENT_PID_FILE" ]; then
        kill "$(cat $PRESIDENT_PID_FILE)" 2>/dev/null
        rm -f "$PRESIDENT_PID_FILE"
        echo "🛑 宣言強制システム停止"
    fi
}

# 引数に応じた実行
case "$1" in
    start)
        main
        ;;
    stop)
        stop
        ;;
    force)
        enforce_declaration
        ;;
    verify)
        verify_declaration
        ;;
    *)
        echo "使用法: $0 {start|stop|force|verify}"
        exit 1
        ;;
esac