#!/bin/bash

# デバッグ用監視システム
# 実際のペイン内容を表示してプロンプト検知ロジックを確認

echo "🔍 デバッグ監視開始..."
echo "📊 各ワーカーの実際の内容を表示します"
echo ""

MULTIAGENT_SESSION="multiagent"

while true; do
    echo "==================== $(date +%H:%M:%S) ===================="
    
    for i in {0..3}; do
        case $i in
            0) worker_name="👔 BOSS" ;;
            1) worker_name="💻 フロントエンド" ;;
            2) worker_name="🔧 バックエンド" ;;
            3) worker_name="🎨 UI/UX" ;;
        esac
        
        echo ""
        echo "[$worker_name] ペイン内容:"
        echo "----------------------------------------"
        
        # ペイン全体の内容を取得
        full_content=$(tmux capture-pane -t $MULTIAGENT_SESSION:0.$i -p 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "$full_content" | tail -10
            echo ""
            
            # プロンプト行の検索
            prompt_line=$(echo "$full_content" | grep "│ >" | tail -1)
            if [ -n "$prompt_line" ]; then
                echo "🔍 プロンプト行検知: $prompt_line"
                
                # プロンプト内容の詳細チェック
                if echo "$prompt_line" | grep -q "│ >.*[あ-ん]"; then
                    echo "✅ 日本語プロンプト検知"
                elif echo "$prompt_line" | grep -q "│ >.*[a-zA-Z]"; then
                    echo "✅ 英語プロンプト検知"
                else
                    echo "❌ プロンプト内容なし"
                fi
            else
                echo "❌ プロンプト行なし"
            fi
            
            # Bypassing Permissions チェック
            if echo "$full_content" | grep -q "Bypassing Permissions"; then
                echo "⚠️ Bypassing Permissions 検知"
            fi
            
        else
            echo "❌ ペイン取得失敗"
        fi
        
        echo "----------------------------------------"
    done
    
    echo ""
    echo "⏳ 10秒後に再チェック... (Ctrl+C で終了)"
    sleep 10
done 