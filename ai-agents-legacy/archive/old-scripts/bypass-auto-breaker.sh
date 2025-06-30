#!/bin/bash

# Bypassing Permissions自動突破スクリプト
# 1秒間隔で全ワーカーを監視し、Bypassing Permissions画面を検出したら即座に突破

echo "🔓 Bypassing Permissions自動突破システム起動..."

while true; do
    # 全ワーカー（0-3）をチェック
    for i in {0..3}; do
        # 現在の画面内容を取得（最後の5行）
        content=$(tmux capture-pane -t multiagent:0.$i -p 2>/dev/null | tail -5)
        
        # Bypassing Permissions画面を検出
        if echo "$content" | grep -q "Bypassing Permissions"; then
            echo "🚨 WORKER$i: Bypassing Permissions検出 - 自動突破開始"
            
            # 複数の方法で確実に突破
            # 方法1: 下矢印 + Enter
            tmux send-keys -t multiagent:0.$i Down
            sleep 0.1
            tmux send-keys -t multiagent:0.$i Enter
            
            # 方法2: 追加のEnter（確実性向上）
            sleep 0.2
            tmux send-keys -t multiagent:0.$i Enter
            
            # 方法3: 空文字 + Enter
            sleep 0.2
            tmux send-keys -t multiagent:0.$i ""
            tmux send-keys -t multiagent:0.$i C-m
            
            echo "✅ WORKER$i: Bypassing Permissions突破完了"
        fi
    done
    
    # プレジデントセッションもチェック
    president_content=$(tmux capture-pane -t president -p 2>/dev/null | tail -5)
    if echo "$president_content" | grep -q "Bypassing Permissions"; then
        echo "🚨 PRESIDENT: Bypassing Permissions検出 - 自動突破開始"
        tmux send-keys -t president Down
        sleep 0.1
        tmux send-keys -t president Enter
        sleep 0.2
        tmux send-keys -t president Enter
        echo "✅ PRESIDENT: Bypassing Permissions突破完了"
    fi
    
    # 1秒待機（高頻度チェック）
    sleep 1
done