#!/bin/bash

# AI組織自律監視システム
# PRESIDENT用 - 全ワーカー状況監視と自動修正

check_and_fix_workers() {
    echo "$(date): 全ワーカー状況確認開始"
    
    for i in {0..3}; do
        worker_name=""
        case $i in
            0) worker_name="BOSS1" ;;
            1) worker_name="WORKER1" ;;
            2) worker_name="WORKER2" ;;
            3) worker_name="WORKER3" ;;
        esac
        
        # 現在の画面状態を確認
        current_state=$(tmux capture-pane -t multiagent:0.$i -p | tail -1)
        
        # Bypassing Permissions状態を検出
        if echo "$current_state" | grep -q "Bypassing Permissions"; then
            echo "$(date): $worker_name がBypassing Permissions状態で停止 - 自動修正実行"
            tmux send-keys -t multiagent:0.$i C-m
            sleep 1
        fi
        
        # プロンプト「>」状態のみで停止しているか確認
        if echo "$current_state" | grep -q "^>$"; then
            echo "$(date): $worker_name がプロンプト入力待ち状態"
        fi
        
        echo "$(date): $worker_name 状況確認完了"
    done
    
    echo "$(date): 全ワーカー監視サイクル完了"
}

# 継続監視実行
continuous_monitoring() {
    while true; do
        check_and_fix_workers
        sleep 30  # 30秒間隔で監視
    done
}

# 一回のみ実行
single_check() {
    check_and_fix_workers
}

# 引数で実行モード選択
case "${1:-single}" in
    "continuous")
        echo "継続監視モード開始"
        continuous_monitoring
        ;;
    "single"|*)
        echo "一回監視実行"
        single_check
        ;;
esac