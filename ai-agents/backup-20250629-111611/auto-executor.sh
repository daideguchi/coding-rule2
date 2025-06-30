#!/bin/bash

# AI組織システム自動実行監視スクリプト
# コマンドがセットされたら即座にBypass Permissionsを突破して実行

echo "🤖 AI組織システム自動実行監視開始..."

# 設定
PRESIDENT_SESSION="president"
MULTIAGENT_SESSION="multiagent"
CHECK_INTERVAL=2  # 2秒間隔でチェック
MAX_RETRIES=3     # 最大リトライ回数

# 関数: Bypass Permissions自動突破
auto_bypass_permissions() {
    local session=$1
    local pane=$2
    local worker_name=$3
    
    echo "🔓 $worker_name: Bypass Permissions自動突破中..."
    
    # 複数の突破方法を試行
    for attempt in {1..3}; do
        # 現在の状態を確認
        current_state=$(tmux capture-pane -t $session:0.$pane -p | tail -3)
        
        if echo "$current_state" | grep -q "Bypassing Permissions"; then
            echo "  試行 $attempt: Down + Enter送信"
            tmux send-keys -t $session:0.$pane Down C-m
            sleep 1
            
            # Enter連打で強制突破
            tmux send-keys -t $session:0.$pane C-m
            sleep 0.5
        else
            echo "  ✅ $worker_name: Bypass Permissions突破完了"
            return 0
        fi
    done
    
    echo "  ⚠️ $worker_name: Bypass Permissions突破に時間がかかっています"
    return 1
}

# 関数: コマンド実行状態チェック
check_command_execution() {
    local session=$1
    local pane=$2
    local worker_name=$3
    
    # 現在の画面内容を取得
    current_content=$(tmux capture-pane -t $session:0.$pane -p)
    
    # コマンドがセットされているかチェック（入力欄に文字がある）
    if echo "$current_content" | grep -q "│ > .*[あ-ん]\|│ >.*README\|│ >.*manage\|│ >.*tmux\|│ >.*プロジェクト"; then
        echo "📝 $worker_name: コマンド検出 - 即座実行開始"
        
        # Bypass Permissions状態なら突破
        if echo "$current_content" | grep -q "Bypassing Permissions"; then
            auto_bypass_permissions $session $pane $worker_name
            sleep 1
        fi
        
        # コマンド実行（Enter送信）
        echo "⚡ $worker_name: コマンド実行中..."
        tmux send-keys -t $session:0.$pane C-m
        
        return 0
    fi
    
    return 1
}

# 関数: 全ワーカー監視
monitor_all_workers() {
    echo "👀 全ワーカー監視開始..."
    
    # プレジデント監視
    if check_command_execution $PRESIDENT_SESSION "" "PRESIDENT"; then
        echo "🎯 PRESIDENT: 自動実行完了"
    fi
    
    # 4ワーカー監視
    for i in {0..3}; do
        case $i in
            0) worker_name="👔 BOSS" ;;
            1) worker_name="💻 フロントエンド" ;;
            2) worker_name="🔧 バックエンド" ;;
            3) worker_name="🎨 UI/UX" ;;
        esac
        
        if check_command_execution $MULTIAGENT_SESSION $i "$worker_name"; then
            echo "🎯 $worker_name: 自動実行完了"
        fi
    done
}

# 関数: 定期的なBypass Permissions突破チェック
periodic_bypass_check() {
    echo "🔄 定期Bypass Permissions突破チェック..."
    
    # プレジデント
    current_state=$(tmux capture-pane -t $PRESIDENT_SESSION -p | tail -3)
    if echo "$current_state" | grep -q "Bypassing Permissions"; then
        auto_bypass_permissions $PRESIDENT_SESSION "" "PRESIDENT"
    fi
    
    # 4ワーカー
    for i in {0..3}; do
        case $i in
            0) worker_name="👔 BOSS" ;;
            1) worker_name="💻 フロントエンド" ;;
            2) worker_name="🔧 バックエンド" ;;
            3) worker_name="🎨 UI/UX" ;;
        esac
        
        current_state=$(tmux capture-pane -t $MULTIAGENT_SESSION:0.$i -p | tail -3)
        if echo "$current_state" | grep -q "Bypassing Permissions"; then
            auto_bypass_permissions $MULTIAGENT_SESSION $i "$worker_name"
        fi
    done
}

# メイン監視ループ
echo "🚀 自動実行システム開始 (間隔: ${CHECK_INTERVAL}秒)"
echo "📊 監視対象: PRESIDENT + 4ワーカー"
echo "⏹️  停止: Ctrl+C"
echo ""

counter=0
while true; do
    counter=$((counter + 1))
    
    # 監視サイクル表示
    if [ $((counter % 10)) -eq 0 ]; then
        echo "🔄 監視サイクル $counter ($(date '+%H:%M:%S'))"
    fi
    
    # 全ワーカー監視
    monitor_all_workers
    
    # 10秒ごとに定期的なBypass Permissions突破チェック
    if [ $((counter % 5)) -eq 0 ]; then
        periodic_bypass_check
    fi
    
    sleep $CHECK_INTERVAL
done 