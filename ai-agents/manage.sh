#!/bin/bash
# AI組織管理スクリプト

case "$1" in
    "start")
        echo "AI組織システムを開始します..."
        mkdir -p ai-agents/sessions
        echo "$(date): AI組織システム開始" >> ai-agents/logs/system.log
        echo "セッション準備完了"
        ;;
    "status")
        echo "AI組織システム状況:"
        if [ -f "ai-agents/logs/system.log" ]; then
            tail -5 ai-agents/logs/system.log
        else
            echo "ログファイルが見つかりません"
        fi
        ;;
    *)
        echo "使用法: $0 {start|status}"
        ;;
esac
