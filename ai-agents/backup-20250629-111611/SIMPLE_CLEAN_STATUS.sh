#!/bin/bash
# 🎯 シンプル・クリーンなステータス管理
# 作成日: 2025-06-29
# 目的: 複雑な表示をやめて、実態に合った正確なステータス

# 実態に基づく正確なステータス設定
set_accurate_clean_status() {
    echo "🔧 実態に基づくクリーンステータス設定"
    
    for i in {0..3}; do
        # 実際の画面内容確認
        local content=$(tmux capture-pane -t "multiagent:0.$i" -p)
        local last_line=$(echo "$content" | tail -1)
        
        # 役職設定
        local role=""
        case $i in
            0) role="👔BOSS1" ;;
            1) role="💻WORKER1" ;;
            2) role="🔧WORKER2" ;;
            3) role="🎨WORKER3" ;;
        esac
        
        # 実態判定（空白または>があれば待機中）
        if [[ -z "$last_line" ]] || echo "$last_line" | grep -q "> *$"; then
            echo "WORKER$i: 🟡待機中 $role"
        else
            echo "WORKER$i: 🟢作業中 $role"
        fi
    done
}

# 全ての複雑な監視システムを停止
stop_all_complex_systems() {
    echo "🛑 複雑な監視システム全停止"
    
    # 全ての監視プロセス停止
    pkill -f "ULTIMATE_ORGANIZATION_SYSTEM" 2>/dev/null
    pkill -f "auto_status_updater" 2>/dev/null
    pkill -f "TIMER_SYSTEM" 2>/dev/null
    pkill -f "organization" 2>/dev/null
    pkill -f "monitor" 2>/dev/null
    
    # PIDファイル削除
    rm -f /tmp/auto_status_updater.pid
    rm -f /tmp/timer_30min.pid
    
    echo "✅ 複雑システム停止完了"
}

# tmux設定をシンプルに
simplify_tmux_config() {
    echo "🎯 tmux設定シンプル化"
    
    # ペインボーダー表示オフ
    tmux set-option -g pane-border-status off
    
    # 自動リネーム有効化（自然な表示）
    tmux set-option -g automatic-rename on
    tmux set-option -g allow-rename on
    
    # ウィンドウ名だけシンプルに
    tmux rename-window -t multiagent:0 "AI-TEAM"
    tmux rename-window -t president:0 "PRESIDENT"
    
    echo "✅ tmux設定シンプル化完了"
}

# メイン実行
case "${1:-clean}" in
    "clean")
        stop_all_complex_systems
        simplify_tmux_config
        set_accurate_clean_status
        ;;
    "status")
        set_accurate_clean_status
        ;;
    *)
        echo "使用方法:"
        echo "  $0 clean   # 全システムクリーン化（デフォルト）"
        echo "  $0 status  # ステータス確認のみ"
        ;;
esac