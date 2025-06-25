#!/bin/bash

# 🤖 AI開発支援ツール セットアップスクリプト
# A: Cursor Rules設定
# B: Claude Code初期設定
# C: Claude Code Company（AI組織）

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

# ヘルプ表示
show_help() {
    echo "🤖 AI開発支援ツール セットアップ"
    echo "=================================="
    echo ""
    echo "使用法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  A        Cursor Rules設定のみ"
    echo "  AB       Cursor Rules + Claude Code初期設定"
    echo "  ABC      全て（Cursor Rules + Claude Code + AI組織）"
    echo "  init     Claude Code初期設定プロンプト（記事準拠）"
    echo "  --help   このヘルプを表示"
    echo ""
    echo "例："
    echo "  $0 A      # Cursor Rulesのみ"
    echo "  $0 AB     # Cursor Rules + Claude Code"
    echo "  $0 ABC    # 完全セットアップ"
    echo "  $0 init   # 記事準拠の初期設定プロンプト"
    echo ""
}

# Cursor Rules設定（A）
setup_cursor_rules() {
    log_info "📝 Cursor Rules設定開始..."
    
    # .cursorディレクトリ作成
    mkdir -p .cursor
    
    # .cursor/rules ファイル作成
    cat > .cursor/rules << 'EOF'
# AI開発支援ルール

## 基本方針
- 日本語でコミュニケーション
- ユーザーの要求を最優先
- 機能を勝手に変更しない
- 並列処理でツールを効率的に実行

## コード品質
- TypeScript/JavaScript: 型安全性を重視
- React: フック規則を遵守
- エラーハンドリングを適切に実装
- パフォーマンスを考慮した実装

## 開発フロー
- 既存ファイルの編集を優先
- 不要なファイル作成を避ける
- ドキュメントは明示的に要求された場合のみ作成
- Git操作は慎重に実行

## Claude Code連携
- Cursor作業内容をClaude Codeと共有
- セッション状態を同期
- プロジェクト進捗を記録

## メモリ管理
- 重要な設定や決定事項を記憶
- 矛盾した情報は即座に更新
- ユーザーの修正を優先
EOF

    log_success "✅ Cursor Rules設定完了"
}

# Claude Code初期設定（B）
setup_claude_code() {
    log_info "🔧 Claude Code初期設定開始..."
    
    # Claude Code設定確認
    if ! command -v claude &> /dev/null; then
        log_warn "Claude Codeがインストールされていません。インストールしてから再実行してください。"
        echo "インストール方法: npm install -g @anthropic-ai/claude-code"
        return 1
    fi
    
    # プロジェクト設定ファイル作成
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
    
    # Cursor連携設定
    cat > claude-cursor-sync.sh << 'EOF'
#!/bin/bash
# Cursor → Claude Code 同期スクリプト

SYNC_FILE=".cursor-claude-sync.json"

# Cursor作業状況を記録
record_cursor_state() {
    cat > "$SYNC_FILE" << JSON
{
  "timestamp": "$(date -Iseconds)",
  "current_files": $(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.md" | head -20 | jq -R . | jq -s .),
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'No git')",
  "last_modified": "$(find . -type f -name "*.ts" -o -name "*.tsx" -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -5)"
}
JSON
}

# Claude Codeに状況共有
share_with_claude() {
    if [ -f "$SYNC_FILE" ]; then
        echo "最新のCursor作業状況:"
        cat "$SYNC_FILE"
    fi
}

case "$1" in
    "record") record_cursor_state ;;
    "share") share_with_claude ;;
    *) echo "使用法: $0 {record|share}" ;;
esac
EOF
    
    chmod +x claude-cursor-sync.sh
    
    log_success "✅ Claude Code初期設定完了"
}

# Claude Code Company設定（C）
setup_claude_company() {
    log_info "🏢 Claude Code Company（AI組織）設定開始..."
    
    # Claude-Code-Communicationが存在するか確認
    if [ -d "Claude-Code-Communication" ]; then
        log_info "既存のClaude Code Communicationを使用"
        cd Claude-Code-Communication
        
        # セットアップ実行
        if [ -f "setup.sh" ]; then
            log_info "AI組織環境を構築中..."
            ./setup.sh
        else
            log_error "setup.shが見つかりません"
            return 1
        fi
        
        cd ..
    else
        log_warn "Claude-Code-Communicationディレクトリが見つかりません"
        log_info "基本的なAI組織構造を作成します..."
        
        mkdir -p Claude-Code-Communication/{instructions,logs,tmp}
        
        # 基本的な指示書作成
        cat > Claude-Code-Communication/instructions/president.md << 'EOF'
# PRESIDENT 指示書

あなたはPRESIDENTです。プロジェクト全体を統括する責任者として、以下の役割を担います：

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

指示送信: `./agent-send.sh boss1 "指示内容"`
EOF

        cat > Claude-Code-Communication/instructions/boss.md << 'EOF'
# BOSS 指示書

あなたはBOSSです。PRESIDENTからの指示を受けて、WORKERチームを管理します：

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

指示送信: `./agent-send.sh worker[1-3] "作業内容"`
報告送信: `./agent-send.sh president "報告内容"`
EOF

        cat > Claude-Code-Communication/instructions/worker.md << 'EOF'
# WORKER 指示書

あなたはWORKERです。BOSSからの指示を受けて実際の作業を実行します：

## 主な役割
1. BOSSからの指示受信
2. 指定された作業の実行
3. 作業完了報告

## 動作フロー
1. BOSSからの作業指示を受信
2. 指示された作業を実行
3. 完了ファイル作成
4. BOSSに完了報告

完了報告: `./agent-send.sh boss1 "作業完了報告"`
EOF
    fi
    
    log_success "✅ Claude Code Company設定完了"
}

# メイン処理
main() {
    echo "🤖 AI開発支援ツール セットアップ"
    echo "=================================="
    echo ""
    
    case "$1" in
        "A")
            log_info "オプションA: Cursor Rules設定のみ"
            setup_cursor_rules
            ;;
        "AB")
            log_info "オプションAB: Cursor Rules + Claude Code初期設定"
            setup_cursor_rules
            setup_claude_code
            ;;
        "ABC")
            log_info "オプションABC: 完全セットアップ"
            setup_cursor_rules
            setup_claude_code
            setup_claude_company
            ;;
        "init")
            log_info "Claude Code初期設定を実行"
            setup_cursor_rules
            setup_claude_code
            log_success "✅ Claude Code初期設定が完了しました"
            echo ""
            echo "📋 次のステップ:"
            echo "  1. Claude Code で作業開始: claude"
            echo "  2. 最新状況確認: ./claude-cursor-sync.sh share"
            echo "  3. 設定確認: cat CLAUDE.md"
            ;;
        "--help"|"-h"|"")
            show_help
            exit 0
            ;;
        *)
            log_error "無効なオプション: $1"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    log_success "🎉 セットアップ完了！"
    echo ""
    echo "📋 次のステップ:"
    
    case "$1" in
        "A")
            echo "  - Cursorを再起動してRulesを反映"
            ;;
        "AB")
            echo "  - Cursorを再起動してRulesを反映"
            echo "  - Claude Codeで作業開始: claude"
            echo "  - Cursor連携: ./claude-cursor-sync.sh record"
            ;;
        "ABC")
            echo "  - Cursorを再起動してRulesを反映"
            echo "  - Claude Codeで作業開始: claude"
            echo "  - AI組織セッション確認:"
            echo "    tmux attach-session -t multiagent"
            echo "    tmux attach-session -t president"
            echo "  - Cursor連携: ./claude-cursor-sync.sh record"
            ;;
    esac
}

# スクリプト実行
main "$@" 