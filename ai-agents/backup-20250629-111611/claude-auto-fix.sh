#!/bin/bash

# Claude Code設定ファイル自動修復システム
# Configuration Error や Raw mode エラーを自動で解決

echo "🔧 Claude Code自動修復システム起動..."

# 設定ファイル修復関数
fix_claude_config() {
    echo "⚠️ Claude Code設定ファイル破損を検知"
    
    # 破損した設定ファイルを削除
    if [ -f ~/.claude.json ]; then
        echo "🗑️ 破損した設定ファイルを削除: ~/.claude.json"
        rm -f ~/.claude.json
    fi
    
    # 認証設定のクリア（API Key競合回避）
    echo "🔄 認証設定をクリア"
    unset ANTHROPIC_API_KEY
    
    # claude logoutで認証リセット
    echo "🚪 Claude認証をリセット"
    claude logout 2>/dev/null || true
    
    echo "✅ 設定ファイル修復完了"
}

# Claude Code起動試行（エラー自動検知・修復）
start_claude_with_autofix() {
    local session_name="$1"
    local pane_id="$2"
    local worker_name="$3"
    
    echo "🚀 Claude Code起動試行: $worker_name"
    
    # 最大3回まで修復試行
    for attempt in {1..3}; do
        echo "📝 起動試行 $attempt/3: $worker_name"
        
        # Claude Code起動
        tmux send-keys -t "$session_name:$pane_id" "claude --dangerously-skip-permissions" C-m
        
        # 3秒待機してエラーチェック（高速化）
        sleep 3
        
        # ペイン内容を取得
        content=$(tmux capture-pane -t "$session_name:$pane_id" -p 2>/dev/null)
        
        # エラーパターンをチェック
        if echo "$content" | grep -q "Configuration Error\|invalid JSON\|Raw mode is not supported"; then
            echo "❌ エラー検知: $worker_name (試行 $attempt)"
            
            # 自動修復実行
            fix_claude_config
            
            # 現在のプロセスを終了
            tmux send-keys -t "$session_name:$pane_id" C-c
            sleep 1
            
            # 再起動準備
            tmux send-keys -t "$session_name:$pane_id" "clear" C-m
            tmux send-keys -t "$session_name:$pane_id" "echo '🔄 $worker_name 再起動中... (試行 $((attempt+1)))'" C-m
            sleep 2
            
                 elif echo "$content" | grep -q "Welcome to Claude Code\|Choose an option\|Choose the text style\|Dark mode"; then
             echo "✅ 起動成功: $worker_name"
             
             # 設定選択画面の場合は自動選択
                           if echo "$content" | grep -q "Choose an option\|Choose the text style\|Dark mode"; then
                 echo "🎯 設定選択を自動実行: $worker_name"
                 tmux send-keys -t "$session_name:$pane_id" "1" C-m
                 sleep 2
                 
                 # 追加の設定画面があるかチェック
                 sleep 3
                 additional_content=$(tmux capture-pane -t "$session_name:$pane_id" -p 2>/dev/null)
                 if echo "$additional_content" | grep -q "Choose an option"; then
                     echo "🎯 追加設定選択を自動実行: $worker_name"
                     tmux send-keys -t "$session_name:$pane_id" "2" C-m
                     sleep 2
                 fi
             fi
             
             # プレジデントの場合は初期メッセージを自動送信
             if [ "$worker_name" = "PRESIDENT" ]; then
                 echo "📝 プレジデント初期メッセージ自動送信中..."
                 sleep 2
                 tmux send-keys -t "$session_name:$pane_id" "あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。さらにワーカーたちを立ち上げてボスに指令を伝達して下さい。" C-m
                 sleep 1
                 tmux send-keys -t "$session_name:$pane_id" "for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude --dangerously-skip-permissions ' C-m; done" C-m
                 echo "✅ プレジデント初期メッセージ送信完了"
             fi
             
             return 0
        else
            echo "⏳ 起動待機中: $worker_name"
            sleep 3
        fi
    done
    
    echo "❌ 起動失敗: $worker_name (3回試行後)"
    return 1
}

# 使用方法の表示
show_usage() {
    echo "使用方法:"
    echo "  $0 <session_name> <pane_id> <worker_name>"
    echo ""
    echo "例:"
    echo "  $0 president 0 PRESIDENT"
    echo "  $0 multiagent 0.0 BOSS"
    echo "  $0 multiagent 0.1 WORKER1"
}

# メイン処理
if [ $# -eq 3 ]; then
    start_claude_with_autofix "$1" "$2" "$3"
else
    show_usage
fi 