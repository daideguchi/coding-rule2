#!/bin/bash

# 🎯 スマート起動システム - Claude認証問題完全解決
# 一回のコマンドで全自動起動を実現

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/ai-smart-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 🔍 認証状態チェック
check_auth_status() {
    log "🔍 Claude認証状態確認中..."
    
    # 一時的なセッションで認証確認
    timeout 10s claude --version 2>/dev/null || return 1
    return 0
}

# 🚀 インテリジェント起動フロー
smart_startup() {
    log "🚀 スマート起動システム v2.0 開始"
    
    if check_auth_status; then
        log "✅ 認証済み - 自動モードで起動"
        start_automatic_mode
    else
        log "🔑 認証が必要 - ガイド付き起動"
        start_guided_mode
    fi
}

# 🤖 自動モード（認証済み）
start_automatic_mode() {
    log "🤖 自動モード実行中..."
    
    # 1. tmuxセッション起動
    cd "$SCRIPT_DIR/.."
    ./ai-agents/manage.sh claude-auth
    
    # 2. 自動復旧システム実行
    sleep 3
    ./ai-agents/auto-recovery-system.sh monitor
    
    # 3. PRESIDENT自動状況把握
    sleep 2
    tmux send-keys -t multiagent:0.0 "プレジデントとして起動しました。過去のミス記録を確認し、チーム状況を把握します。これまでの進捗と課題について現状を報告してください。" C-m
    
    log "🎉 自動モード完了 - 即座に使用可能"
}

# 👨‍💻 ガイド付きモード（認証必要）
start_guided_mode() {
    log "👨‍💻 ガイド付きモード実行中..."
    
    echo "
🔑 Claude認証が必要です

📋 **簡単3ステップ起動**:

1️⃣ **初回認証**: 以下を実行
   \`\`\`bash
   ./ai-agents/manage.sh claude-auth
   \`\`\`
   
2️⃣ **ターミナル再起動**: 一度ターミナルを閉じて新しく開く

3️⃣ **自動起動**: 以下を実行  
   \`\`\`bash
   ./ai-agents/smart-startup.sh
   \`\`\`

⚡ **もっと簡単にしたい場合**:
   \`\`\`bash
   # ワンライナー起動
   ./ai-agents/quick-start.sh
   \`\`\`
"
    
    # インタラクティブ起動支援
    read -p "🤔 今すぐ初回認証を実行しますか？ (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        log "🔑 初回認証実行中..."
        cd "$SCRIPT_DIR/.."
        ./ai-agents/manage.sh claude-auth
        
        echo "
✅ **認証完了！**

🔄 **次のステップ**:
1. このターミナルを閉じる
2. 新しいターミナルを開く  
3. 以下を実行: \`./ai-agents/smart-startup.sh\`

または以下のコマンドをコピペ:
\`\`\`bash
# 新しいターミナルで実行
cd $(pwd) && ./ai-agents/smart-startup.sh
\`\`\`
"
    fi
}

# 📱 ワンライナー起動システム
create_quick_start() {
    cat > "$SCRIPT_DIR/quick-start.sh" << 'EOF'
#!/bin/bash

# 🚀 ワンライナー起動システム
# 史上最も簡単なAI組織起動

echo "🚀 AI組織システム - 超簡単起動"

# 認証状態自動判定
if timeout 5s claude --version >/dev/null 2>&1; then
    echo "✅ 認証済み - 自動起動中..."
    ./ai-agents/manage.sh claude-auth
    sleep 3
    ./ai-agents/auto-recovery-system.sh monitor
else
    echo "🔑 認証実行中..."
    ./ai-agents/manage.sh claude-auth
    echo "
🎉 起動完了！認証が必要でした。

🔄 再起動手順:
1. Ctrl+C でターミナル終了
2. 新しいターミナルで: ./ai-agents/quick-start.sh
"
fi
EOF
    chmod +x "$SCRIPT_DIR/quick-start.sh"
    log "📱 ワンライナー起動システム作成完了"
}

# 🎯 メイン実行
main() {
    case "$1" in
        "create-quick")
            create_quick_start
            ;;
        "guided")
            start_guided_mode
            ;;
        *)
            smart_startup
            ;;
    esac
}

main "$@"