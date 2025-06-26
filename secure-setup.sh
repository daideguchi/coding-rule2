#!/bin/bash

# セキュア設定スクリプト
# セキュリティリスクを最小化した設定

set -euo pipefail

# ログ関数
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_warn() { echo "⚠️ $1"; }
log_error() { echo "❌ $1"; exit 1; }

# セキュリティチェック関数
security_check() {
    log_info "🔒 セキュリティチェックを実行中..."
    
    # 1. API Key環境変数の確認
    if [ ! -z "${ANTHROPIC_API_KEY:-}" ]; then
        log_warn "ANTHROPIC_API_KEY環境変数が設定されています"
        read -p "セキュリティのため無効化しますか？ [y/N]: " unset_key
        if [[ $unset_key =~ ^[Yy]$ ]]; then
            unset ANTHROPIC_API_KEY
            log_success "API Key環境変数を無効化しました"
        fi
    fi
    
    # 2. 危険なファイルの存在確認
    dangerous_files=(".claude-auth-method" ".env" "*.key" "*.pem")
    for pattern in "${dangerous_files[@]}"; do
        if ls $pattern 2>/dev/null | grep -q .; then
            log_warn "潜在的に危険なファイルが発見されました: $pattern"
        fi
    done
    
    # 3. ログファイルの機密情報チェック
    if [ -d "logs/" ]; then
        if grep -r -i "api_key\|password\|token\|secret" logs/ 2>/dev/null; then
            log_error "ログファイルに機密情報が含まれている可能性があります"
        fi
    fi
    
    log_success "セキュリティチェック完了"
}

# セキュアな.claude設定生成
setup_secure_claude_config() {
    log_info "🔧 セキュアな.claude設定を生成中..."
    
    mkdir -p .claude
    
    # セキュリティを重視した設定
    cat > .claude/claude_desktop_config.json << 'EOF'
{
  "name": "AI開発支援プロジェクト（セキュア版）",
  "description": "セキュリティを重視したClaude Code連携環境",
  "rules": [
    "日本語でコミュニケーション",
    "ユーザーの要求を最優先",
    "セキュリティを最重要視",
    "機密情報の適切な管理"
  ],
  "security": {
    "require_explicit_permission": true,
    "log_sensitive_data": false,
    "auto_bypass_disabled": true
  },
  "tools": {
    "enabled": true,
    "auto_bypass_permissions": false,
    "dangerous_commands": false,
    "require_user_confirmation": true
  }
}
EOF
    
    log_success "セキュアな.claude設定を生成しました"
}

# .gitignoreの強化
enhance_gitignore() {
    log_info "🔒 .gitignoreを強化中..."
    
    # セキュリティ関連ファイルを追加
    cat >> .gitignore << 'EOF'

# === セキュリティ強化設定 ===
# 認証情報
.claude-auth-method
.anthropic-key
.api-keys
.env*
*.key
*.pem
*.crt
*.p12
*.pfx

# ログファイル（機密情報含有可能性）
nohup.out
*.log
/tmp/ai-agents-*.log
/tmp/claude-*.log

# バックアップファイル
*.bak
*.backup
*~

# システム固有ファイル
.DS_Store
Thumbs.db
EOF
    
    log_success ".gitignoreを強化しました"
}

# セキュアなmanage.sh設定
secure_manage_script() {
    log_info "🔧 manage.shのセキュリティ設定を確認中..."
    
    if grep -q "dangerously-skip-permissions" ai-agents/manage.sh; then
        log_warn "manage.shで危険なフラグが使用されています"
        echo "   手動でセキュリティ確認を有効化することを推奨します"
    fi
    
    if grep -q "auto_bypass_permissions.*true" setup.sh; then
        log_warn "自動バイパス設定が有効になっています"
        echo "   セキュリティのため無効化を推奨します"
    fi
}

# メイン実行関数
main() {
    echo "🔒 セキュア設定スクリプト v1.0"
    echo "====================================="
    echo ""
    
    security_check
    echo ""
    
    setup_secure_claude_config
    echo ""
    
    enhance_gitignore
    echo ""
    
    secure_manage_script
    echo ""
    
    log_success "🎉 セキュア設定が完了しました！"
    echo ""
    echo "📋 次のステップ:"
    echo "  1. 設定を確認: cat .claude/claude_desktop_config.json"
    echo "  2. gitignore確認: cat .gitignore"
    echo "  3. セキュリティガイド: cat SECURITY.md"
    echo ""
    echo "⚠️ 重要: APIキーは環境変数または専用の設定ファイルで管理してください"
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi