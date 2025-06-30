#!/bin/bash

# AI組織ガバナンス：管理支援システム
# 組織運営を効率化し、品質を向上させる

# 設定
SESSION_MULTIAGENT="multiagent"
GOVERNANCE_LOG="/tmp/ai-governance.log"

# 関数：全ワーカー状態チェック
check_all_workers() {
    echo "🔍 全ワーカー状態チェック ($(date '+%H:%M:%S'))"
    echo "================================================"
    
    for i in {0..3}; do
        case $i in
            0) worker_name="👔 BOSS" ;;
            1) worker_name="💻 WORKER1" ;;
            2) worker_name="🔧 WORKER2" ;;
            3) worker_name="🎨 WORKER3" ;;
        esac
        
        # 画面内容を取得（全体を確認）
        content=$(tmux capture-pane -t $SESSION_MULTIAGENT:0.$i -p 2>/dev/null)
        
        if echo "$content" | grep -q "Divining\|Exploring\|Polishing\|Envisioning\|Searching\|Documenting\|Architecting\|Guiding\|Organizing\|Planning"; then
            echo "$worker_name: 🟢 実行中"
            status="WORKING"
        elif echo "$content" | grep -q "Bypassing Permissions"; then
            echo "$worker_name: 🟡 待機中"
            status="STANDBY"
        elif echo "$content" | grep -q "completed\|完了\|finished"; then
            echo "$worker_name: ✅ 完了"
            status="COMPLETED"
        elif echo "$content" | grep -q "> "; then
            echo "$worker_name: 🟡 待機中"
            status="STANDBY"
        else
            echo "$worker_name: 🔵 処理中"
            status="PROCESSING"
        fi
        
        # ログに記録
        echo "$(date '+%H:%M:%S') WORKER$i $status" >> "$GOVERNANCE_LOG"
    done
    echo "================================================"
}

# 関数：一括Enter送信
send_enter_all() {
    echo "⚡ 全ワーカーEnter送信実行..."
    for i in {0..3}; do
        tmux send-keys -t $SESSION_MULTIAGENT:0.$i C-m
        echo "  → WORKER$i: Enter送信完了"
    done
    echo "✅ 一括Enter送信完了"
}

# 関数：ワーカー向けメッセージ送信
send_message() {
    local worker_id=$1
    local message="$2"
    
    if [ -z "$worker_id" ] || [ -z "$message" ]; then
        echo "❌ 使用方法: send_message [worker_id] [message]"
        return 1
    fi
    
    echo "📤 WORKER$worker_id にメッセージ送信: $message"
    tmux send-keys -t $SESSION_MULTIAGENT:0.$worker_id "$message" C-m
    
    # ログに記録
    echo "$(date '+%H:%M:%S') SENT_TO_WORKER$worker_id: $message" >> "$GOVERNANCE_LOG"
    echo "✅ メッセージ送信完了"
}

# 関数：緊急停止
emergency_stop() {
    echo "🚨 緊急停止実行..."
    for i in {0..3}; do
        tmux send-keys -t $SESSION_MULTIAGENT:0.$i C-c
        echo "  → WORKER$i: 停止信号送信"
    done
    echo "⏹️ 緊急停止完了"
}

# 関数：コンテキストクリア
clear_context() {
    local worker_id=$1
    
    if [ -z "$worker_id" ]; then
        echo "❌ 使用方法: clear_context [worker_id]"
        return 1
    fi
    
    echo "🧹 WORKER$worker_id コンテキストクリア実行..."
    tmux send-keys -t $SESSION_MULTIAGENT:0.$worker_id "/clear" C-m
    sleep 1
    echo "✅ WORKER$worker_id コンテキストクリア完了"
}

# 関数：ガバナンスレポート
governance_report() {
    echo "📊 AI組織ガバナンスレポート"
    echo "============================================"
    echo "📅 生成時刻: $(date)"
    echo ""
    
    # 現在の状態
    check_all_workers
    echo ""
    
    # 進捗状況
    if [ -x "./ai-agents/utils/report-system.sh" ]; then
        ./ai-agents/utils/report-system.sh progress
        echo ""
        ./ai-agents/utils/report-system.sh recent
    fi
    
    # 最近のガバナンスログ
    echo "🏛️ 最近のガバナンス活動"
    echo "============================================"
    if [ -f "$GOVERNANCE_LOG" ]; then
        tail -20 "$GOVERNANCE_LOG"
    else
        echo "ガバナンス活動なし"
    fi
    echo "============================================"
}

# メイン処理
case "$1" in
    "check")
        check_all_workers
        ;;
    "enter")
        send_enter_all
        ;;
    "send")
        send_message "$2" "$3"
        ;;
    "stop")
        emergency_stop
        ;;
    "clear")
        clear_context "$2"
        ;;
    "report")
        governance_report
        ;;
    "init")
        echo "🏛️ ガバナンスシステム初期化"
        > "$GOVERNANCE_LOG"
        echo "✅ 初期化完了"
        ;;
    *)
        echo "🏛️ AI組織ガバナンス管理システム"
        echo "============================================"
        echo "使用方法:"
        echo "  $0 check                     # 全ワーカー状態チェック"
        echo "  $0 enter                     # 全ワーカー一括Enter送信"
        echo "  $0 send [worker_id] [msg]    # 指定ワーカーにメッセージ送信"
        echo "  $0 stop                      # 緊急停止"
        echo "  $0 clear [worker_id]         # コンテキストクリア"
        echo "  $0 report                    # ガバナンスレポート表示"
        echo "  $0 init                      # システム初期化"
        echo "============================================"
        ;;
esac