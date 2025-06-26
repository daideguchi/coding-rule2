#!/bin/bash

# 🤖 AI開発支援ツール セットアップスクリプト
# シンプル3パターン選択版

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# パターン選択メニュー
show_menu() {
    clear
    echo "🤖 AI開発支援ツール セットアップ"
    echo "=================================="
    echo ""
    echo "設定パターンを選択してください："
    echo ""
    echo "1) 基本設定"
    echo "   - Cursor Rules設定のみ"
    echo "   - 軽量で最小限の構成"
    echo ""
    echo "2) 開発環境設定"  
    echo "   - Cursor Rules + Claude Code設定"
    echo "   - 開発作業に必要な基本環境"
    echo ""
    echo "3) 完全設定"
    echo "   - 全機能 + AI組織システム"
    echo "   - 高度な開発・分析環境"
    echo ""
    echo "a) 認証設定"
    echo "   - Claude Code認証方法の設定"
    echo "   - Proプラン/API Key選択"
    echo ""
    echo "s) 設定状況確認"
    echo "   - 現在のセットアップ状況をチェック"
    echo ""
    echo "q) 終了"
    echo ""
}

# パターン1: 基本設定
setup_basic() {
    log_info "📝 基本設定を開始します..."
    
    # .cursorディレクトリ作成
    mkdir -p .cursor/rules
    
    # cursor-rulesの内容を.cursor/rulesに同期（新システム使用）
    if [ -f "scripts/sync-cursor-rules.sh" ]; then
        log_info "🔄 新同期システムで同期実行中..."
        ./scripts/sync-cursor-rules.sh --force
    elif [ -d "cursor-rules" ]; then
        log_warn "⚠️ 旧システムで同期実行中（新システムへの移行を推奨）..."
        cp -r cursor-rules/* .cursor/rules/
        log_success "✅ Cursor Rules設定完了"
    else
        log_error "cursor-rulesディレクトリが見つかりません"
        return 1
    fi
    
    # 基本メインルールファイル作成
    cat > .cursor/rules.md << 'EOF'
# AI開発支援ルール（基本設定）

## 基本方針
- 日本語でコミュニケーション
- ユーザーの要求を最優先  
- 機能を勝手に変更しない
- 並列処理でツールを効率的に実行

## 詳細ルール参照
- プロジェクト管理: .cursor/rules/rules.mdc
- タスク管理: .cursor/rules/todo.mdc
- UI/UX設計: .cursor/rules/uiux.mdc
- グローバルルール: .cursor/rules/globals.mdc
- 開発ルール: .cursor/rules/dev-rules/

## コード品質
- TypeScript/JavaScript: 型安全性を重視
- React: フック規則を遵守
- エラーハンドリングを適切に実装
- パフォーマンスを考慮した実装

## 開発フロー
- 既存ファイルの編集を優先
- 不要なファイル作成を避ける
- ドキュメントは明示的に要求された場合のみ作成
EOF
    
    log_success "🎉 基本設定完了！"
    
    # 設定状況を更新
    if [ -f "scripts/status-checker.sh" ]; then
        ./scripts/status-checker.sh check > /dev/null 2>&1
        log_info "📊 設定状況を更新しました (STATUS.md)"
    fi
    
    echo "次のステップ: Cursorを再起動してRulesを反映してください"
}

# パターン2: 開発環境設定
setup_development() {
    log_info "🔧 開発環境設定を開始します..."
    
    # 基本設定を実行
    setup_basic
    
    # Claude Code設定
    cat > .claude-project << 'EOF'
{
  "name": "AI開発支援プロジェクト",
  "description": "Cursor + Claude Code連携開発環境",
  "rules": [
    "日本語でコミュニケーション",
    "ユーザーの要求を最優先",
    "機能を勝手に変更しない",
    "Cursor作業内容との連携を保持"
  ],
  "memory": {
    "sync_with_cursor": true,
    "track_changes": true,
    "preserve_context": true
  }
}
EOF
    
    # Cursor-Claude同期スクリプト
    cat > scripts/claude-cursor-sync.sh << 'EOF'
#!/bin/bash
# Cursor ↔ Claude Code 同期スクリプト

SYNC_FILE=".cursor-claude-sync.json"

case "$1" in
    "record")
        cat > "$SYNC_FILE" << JSON
{
  "timestamp": "$(date -Iseconds)",
  "current_files": $(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.md" | head -20 | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'No git')"
}
JSON
        echo "Cursor作業状況を記録しました"
        ;;
    "share")
        if [ -f "$SYNC_FILE" ]; then
            echo "最新のCursor作業状況:"
            cat "$SYNC_FILE"
        else
            echo "同期ファイルが見つかりません。まず 'record' を実行してください"
        fi
        ;;
    *)
        echo "使用法: $0 {record|share}"
        echo "  record: Cursorの現在状況を記録"
        echo "  share:  記録した状況をClaude Codeで確認"
        ;;
esac
EOF
    
    chmod +x scripts/claude-cursor-sync.sh
    
    log_success "🎉 開発環境設定完了！"
    
    # 設定状況を更新
    if [ -f "scripts/status-checker.sh" ]; then
        ./scripts/status-checker.sh check > /dev/null 2>&1
        log_info "📊 設定状況を更新しました (STATUS.md)"
    fi
    
    echo "次のステップ:"
    echo "  1. Cursorを再起動してRulesを反映"
    echo "  2. Claude Codeで作業開始"
    echo "  3. Cursor連携: ./scripts/claude-cursor-sync.sh record"
}

# パターン3: 完全設定
setup_complete() {
    log_info "🏢 完全設定を開始します..."
    
    # 開発環境設定を実行
    setup_development
    
    # AI組織システムの基本構造作成
    mkdir -p ai-agents/{instructions,logs,sessions}
    
    # 基本的な指示書作成
    cat > ai-agents/instructions/president.md << 'EOF'
# PRESIDENT 指示書

## 主な役割
1. プロジェクトの方向性決定
2. BOSSへの指示出し  
3. 全体進捗管理
4. 最終判断

## 動作フロー
1. ユーザーからの要求を受け取る
2. 要求を分析し、適切な指示をBOSSに送信
3. BOSSからの報告を受け取り、必要に応じて追加指示
4. 最終結果をユーザーに報告
EOF

    cat > ai-agents/instructions/boss.md << 'EOF'
# BOSS 指示書

## 主な役割
1. PRESIDENTからの指示受信
2. WORKERへの作業分担
3. WORKER進捗管理
4. PRESIDENTへの報告

## 動作フロー
1. PRESIDENTからの指示を受信
2. 作業をWORKERに分担して指示
3. WORKER完了報告を収集
4. PRESIDENTに全体完了を報告
EOF

    cat > ai-agents/instructions/worker.md << 'EOF'
# WORKER 指示書

## 主な役割
1. BOSSからの指示受信
2. 指定された作業の実行
3. 作業完了報告

## 動作フロー
1. BOSSからの作業指示を受信
2. 指示された作業を実行
3. 完了ファイル作成
4. BOSSに完了報告
EOF
    
    # AI組織管理スクリプト
    cat > ai-agents/manage.sh << 'EOF'
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
EOF
    
    chmod +x ai-agents/manage.sh
    
    log_success "🎉 完全設定完了！"
    
    # 設定状況を更新
    if [ -f "scripts/status-checker.sh" ]; then
        ./scripts/status-checker.sh check > /dev/null 2>&1
        log_info "📊 設定状況を更新しました (STATUS.md)"
    fi
    
    echo "次のステップ:"
    echo "  1. Cursorを再起動してRulesを反映"
    echo "  2. Claude Codeで作業開始"
    echo "  3. AI組織開始: ./ai-agents/manage.sh start"
    echo "  4. Cursor連携: ./scripts/claude-cursor-sync.sh record"
}

# 認証設定選択
setup_auth() {
    clear
    echo "🔐 Claude Code認証設定"
    echo "======================"
    echo ""
    echo "利用する認証方法を選択してください："
    echo ""
    echo "1) claude.ai Proプラン"
    echo "   - Web版のProプランアカウント"
    echo "   - 推奨：高性能で使いやすい"
    echo ""
    echo "2) ANTHROPIC_API_KEY"
    echo "   - 開発者向けAPIキー"
    echo "   - 従量課金制"
    echo ""
    echo "3) 現在の設定確認"
    echo "   - 認証状況をチェック"
    echo ""
    echo "b) 戻る"
    echo ""
    
    read -p "選択してください [1-3, b]: " auth_choice
    
    case $auth_choice in
        1)
            setup_claude_ai_pro
            ;;
        2)
            setup_api_key
            ;;
        3)
            check_auth_status
            ;;
        b)
            return
            ;;
        *)
            log_error "無効な選択です"
            read -p "Enterキーで続行..."
            setup_auth
            ;;
    esac
}

# claude.ai Proプラン設定
setup_claude_ai_pro() {
    log_info "🏆 claude.ai Proプラン設定を開始..."
    
    # ANTHROPIC_API_KEYが設定されている場合は警告
    if [ ! -z "$ANTHROPIC_API_KEY" ]; then
        log_warn "⚠️ ANTHROPIC_API_KEYが設定されています"
        echo "   claude.aiを使用する場合は競合を避けるため、一時的に無効化します"
        read -p "ANTHROPIC_API_KEYを無効化しますか？ [y/N]: " unset_api_key
        
        if [[ $unset_api_key =~ ^[Yy]$ ]]; then
            unset ANTHROPIC_API_KEY
            log_success "✅ ANTHROPIC_API_KEYを無効化しました（この設定は再起動まで有効）"
            
            # 永続的な無効化の案内
            echo ""
            echo "💡 永続的に無効化する場合は、以下をシェル設定ファイルから削除してください："
            echo "   ~/.zshrc、~/.bashrc、~/.profile など"
            echo "   export ANTHROPIC_API_KEY=sk-ant-..."
        fi
    fi
    
    log_info "🔄 claude.aiからログアウトして再ログインします..."
    
    # 既存の認証をクリア
    claude /logout 2>/dev/null || true
    
    echo ""
    echo "📋 次の手順で認証を設定してください："
    echo "   1. 以下のコマンドを実行: claude"
    echo "   2. 「Login to claude.ai」を選択"
    echo "   3. ブラウザでログイン"
    echo "   4. Proプランアカウントでログイン"
    echo ""
    echo "🎯 認証完了後、AI組織システムが利用可能になります"
    
    # 設定ファイルに記録
    echo "claude_ai_pro" > .claude-auth-method
    
    log_success "✅ claude.ai Proプラン設定完了"
    read -p "Enterキーで続行..."
}

# API Key設定
setup_api_key() {
    log_info "🔑 ANTHROPIC_API_KEY設定を開始..."
    
    # 既存のclaude.ai認証があるかチェック
    if claude /status 2>/dev/null | grep -q "Logged in"; then
        log_warn "⚠️ claude.aiにログインしています"
        echo "   API Keyを使用する場合は競合を避けるため、ログアウトします"
        read -p "claude.aiからログアウトしますか？ [y/N]: " logout_claude
        
        if [[ $logout_claude =~ ^[Yy]$ ]]; then
            claude /logout
            log_success "✅ claude.aiからログアウトしました"
        fi
    fi
    
    echo ""
    echo "📋 API Key設定手順："
    echo "   1. https://console.anthropic.com/ にアクセス"
    echo "   2. API Keyを作成"
    echo "   3. 以下のコマンドでAPI Keyを設定:"
    echo ""
    echo "      export ANTHROPIC_API_KEY=sk-ant-..."
    echo ""
    echo "   4. シェル設定ファイル（~/.zshrc等）に追加して永続化"
    echo ""
    
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        log_warn "⚠️ ANTHROPIC_API_KEYが設定されていません"
        read -p "API Keyを入力しますか？ [y/N]: " input_key
        
        if [[ $input_key =~ ^[Yy]$ ]]; then
            read -p "API Keyを入力してください: " api_key
            if [[ $api_key =~ ^sk-ant- ]]; then
                export ANTHROPIC_API_KEY="$api_key"
                log_success "✅ API Keyを設定しました（この設定は再起動まで有効）"
                
                echo ""
                echo "💡 永続的に設定する場合は、以下をシェル設定ファイルに追加してください："
                echo "   export ANTHROPIC_API_KEY=\"$api_key\""
            else
                log_error "❌ 無効なAPI Key形式です"
            fi
        fi
    else
        log_success "✅ ANTHROPIC_API_KEYが設定されています"
    fi
    
    # 設定ファイルに記録
    echo "api_key" > .claude-auth-method
    
    log_success "✅ API Key設定完了"
    read -p "Enterキーで続行..."
}

# 認証状況確認
check_auth_status() {
    echo "🔍 認証状況確認"
    echo "=============="
    echo ""
    
    # 設定ファイル確認
    if [ -f ".claude-auth-method" ]; then
        method=$(cat .claude-auth-method)
        echo "📝 設定済み認証方法: $method"
        echo ""
    fi
    
    # claude.ai状況確認
    echo "1. claude.ai認証状況:"
    if claude /status 2>/dev/null | grep -q "Logged in"; then
        echo "   ✅ ログイン済み"
    else
        echo "   ❌ 未ログイン"
    fi
    
    # API Key状況確認
    echo ""
    echo "2. ANTHROPIC_API_KEY状況:"
    if [ ! -z "$ANTHROPIC_API_KEY" ]; then
        echo "   ✅ 設定済み (${ANTHROPIC_API_KEY:0:12}...)"
    else
        echo "   ❌ 未設定"
    fi
    
    # 競合チェック
    echo ""
    echo "3. 競合チェック:"
    if [ ! -z "$ANTHROPIC_API_KEY" ] && claude /status 2>/dev/null | grep -q "Logged in"; then
        echo "   ⚠️  競合あり: 両方の認証が有効です"
        echo "      推奨: どちらか一方を使用してください"
    else
        echo "   ✅ 競合なし"
    fi
    
    echo ""
    read -p "Enterキーで続行..."
}

# メイン処理
main() {
    while true; do
        show_menu
        echo -n "選択してください (1-3, a, s, q): "
        read choice
        
        case $choice in
            1)
                setup_basic
                break
                ;;
            2)
                setup_development
                break
                ;;
            3)
                setup_complete
                break
                ;;
            a)
                setup_auth
                ;;
            s|S)
                if [ -f "scripts/status-checker.sh" ]; then
                    clear
                    log_info "🔍 現在の設定状況を確認中..."
                    ./scripts/status-checker.sh check
                    echo ""
                    echo "📄 詳細は STATUS.md ファイルをご確認ください"
                    echo -n "Enterキーで続行..."
                    read
                else
                    log_error "scripts/status-checker.sh が見つかりません"
                    echo -n "Enterキーで続行..."
                    read
                fi
                ;;
            q|Q)
                echo "セットアップを終了します。"
                exit 0
                ;;
            *)
                echo "無効な選択です。1-3, a, s またはqを入力してください。"
                echo -n "Enterキーで続行..."
                read
                ;;
        esac
    done
}

# スクリプト実行
main 