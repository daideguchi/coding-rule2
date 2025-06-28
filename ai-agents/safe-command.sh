#!/bin/bash

# 🚨 21回ミス撲滅システム - Enter確実実行
# BOSS1作成: PRESIDENTのEnter忘れ問題完全解決

set -e

# 確実コマンド送信（分離不可能な原子実行）
send_command_safely() {
    local target_pane="$1"
    local message="$2"
    
    echo "🚨 21回ミス防止チェック実行中..."
    echo "対象: $target_pane"
    echo "内容: $message"
    
    # 原子的実行（分離不可能）
    tmux send-keys -t "$target_pane" "$message" C-m
    
    echo "✅ 確実送信完了 (C-m自動実行済み)"
    
    # 即座確認
    sleep 1
    echo "📋 送信後画面確認:"
    tmux capture-pane -t "$target_pane" -p | tail -3
    
    return 0
}

# BOSS専用確実指示送信
boss_instruction() {
    local instruction="$1"
    echo "👔 BOSS1への確実指示送信"
    send_command_safely "multiagent:0.0" "$instruction"
}

# WORKER指示（全ワーカー一括）
workers_instruction() {
    local instruction="$1"
    echo "👥 全ワーカーへの確実指示送信"
    
    for i in {1..3}; do
        echo "📨 WORKER$i に送信中..."
        send_command_safely "multiagent:0.$i" "$instruction"
        sleep 0.5
    done
}

# 使用方法表示
show_usage() {
    echo "🚨 21回ミス撲滅システム"
    echo "========================"
    echo "使用方法:"
    echo "  $0 boss \"指示内容\"     # BOSS1への確実送信"
    echo "  $0 workers \"指示内容\"  # 全ワーカーへの確実送信"
    echo "  $0 single pane \"内容\"  # 指定ペインへの確実送信"
    echo ""
    echo "特徴: C-mを絶対に忘れない原子的実行"
}

# メイン実行
main() {
    case "${1:-}" in
        "boss")
            boss_instruction "$2"
            ;;
        "workers")
            workers_instruction "$2"
            ;;
        "single")
            send_command_safely "$2" "$3"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"