#!/bin/bash

# o3検索システム - AI組織用高度検索機能
# 作成日: 2025-06-30
# 作成者: PRESIDENT
# 参照元: https://zenn.dev/yoshiko/articles/claude-code-with-o3

set -e

# 設定
MCP_CONFIG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/.mcp.json"
SEARCH_LOG_FILE="/Users/dd/Desktop/1_dev/coding-rule2/logs/o3-search.log"
SEARCH_RESULTS_DIR="/Users/dd/Desktop/1_dev/coding-rule2/logs/search-results"

# ディレクトリ作成
mkdir -p "$(dirname "$SEARCH_LOG_FILE")"
mkdir -p "$SEARCH_RESULTS_DIR"

# ログ関数
log_search() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SEARCH_LOG_FILE"
}

# o3検索機能
search_with_o3() {
    local query="$1"
    local context="$2"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local result_file="$SEARCH_RESULTS_DIR/search_${timestamp}.json"
    
    log_search "🔍 検索開始: $query"
    
    # MCP設定確認
    if [ ! -f "$MCP_CONFIG_FILE" ]; then
        echo "❌ MCP設定ファイルが見つかりません: $MCP_CONFIG_FILE"
        log_search "❌ MCP設定ファイルエラー"
        return 1
    fi
    
    # API Key確認
    if [ -z "${OPENAI_API_KEY:-}" ]; then
        echo "❌ OPENAI_API_KEY環境変数が設定されていません"
        echo "   .env ファイルまたは export OPENAI_API_KEY=your-key で設定してください"
        log_search "❌ API Key未設定エラー"
        return 1
    fi
    
    # o3-search-mcpパッケージ実行
    echo "🤖 o3に検索クエリを送信中..."
    
    # 検索実行 (npx経由)
    OPENAI_API_KEY="${OPENAI_API_KEY}" \
    SEARCH_CONTEXT_SIZE="medium" \
    REASONING_EFFORT="medium" \
    npx o3-search-mcp <<EOF > "$result_file" 2>&1
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "search",
    "arguments": {
      "query": "$query",
      "context": "$context"
    }
  }
}
EOF
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ 検索完了: $result_file"
        log_search "✅ 検索成功: $query -> $result_file"
        
        # 結果表示
        echo "📋 検索結果:"
        cat "$result_file" | head -20
        
        return 0
    else
        echo "❌ 検索失敗 (終了コード: $exit_code)"
        log_search "❌ 検索失敗: $query (終了コード: $exit_code)"
        return 1
    fi
}

# AI組織向け検索機能
ai_org_search() {
    local search_type="$1"
    local query="$2"
    
    case "$search_type" in
        "tech")
            search_with_o3 "$query" "技術的な問題解決のための情報を検索してください。具体的な実装方法やベストプラクティスを重視します。"
            ;;
        "debug")
            search_with_o3 "$query" "デバッグやエラー解決のための情報を検索してください。問題の原因分析と解決策を重視します。"
            ;;
        "system")
            search_with_o3 "$query" "システム設計や組織管理に関する情報を検索してください。効率性と安定性を重視します。"
            ;;
        "general")
            search_with_o3 "$query" "一般的な情報検索です。幅広い観点から有用な情報を提供してください。"
            ;;
        *)
            echo "❌ 無効な検索タイプ: $search_type"
            echo "利用可能なタイプ: tech, debug, system, general"
            return 1
            ;;
    esac
}

# ヘルプ表示
show_help() {
    cat << EOF
🔍 o3検索システム - AI組織用高度検索機能

使用方法:
  $0 <検索タイプ> "<検索クエリ>"

検索タイプ:
  tech     - 技術的問題解決
  debug    - デバッグ・エラー解決
  system   - システム設計・組織管理
  general  - 一般的な情報検索

例:
  $0 tech "React hooks useEffect 最適化"
  $0 debug "tmux send-keys C-m not working"
  $0 system "AI組織管理のベストプラクティス"
  $0 general "プログラミング学習法"

設定ファイル: $MCP_CONFIG_FILE
ログファイル: $SEARCH_LOG_FILE
結果保存先: $SEARCH_RESULTS_DIR

環境変数設定:
  export OPENAI_API_KEY=your-api-key
EOF
}

# システム状態確認
check_system() {
    echo "🔍 o3検索システム状態確認"
    echo "=============================="
    
    echo "📄 MCP設定ファイル: $MCP_CONFIG_FILE"
    if [ -f "$MCP_CONFIG_FILE" ]; then
        echo "  ✅ 存在確認済み"
        echo "  📋 設定内容:"
        cat "$MCP_CONFIG_FILE" | jq . 2>/dev/null || cat "$MCP_CONFIG_FILE"
    else
        echo "  ❌ ファイルが見つかりません"
    fi
    
    echo ""
    echo "🔑 環境変数確認:"
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        echo "  ✅ OPENAI_API_KEY設定済み"
    else
        echo "  ❌ OPENAI_API_KEY未設定"
        echo "    export OPENAI_API_KEY=your-key または .env ファイルで設定してください"
    fi
    
    echo ""
    echo "📁 ログディレクトリ: $(dirname "$SEARCH_LOG_FILE")"
    ls -la "$(dirname "$SEARCH_LOG_FILE")" 2>/dev/null || echo "  ❌ ディレクトリが見つかりません"
    
    echo ""
    echo "📁 結果保存ディレクトリ: $SEARCH_RESULTS_DIR"
    ls -la "$SEARCH_RESULTS_DIR" 2>/dev/null || echo "  ❌ ディレクトリが見つかりません"
    
    echo ""
    echo "🧪 o3-search-mcpパッケージ確認:"
    npx o3-search-mcp --version 2>&1 | head -3 || echo "  ❌ パッケージエラー"
}

# メイン処理
main() {
    case "${1:-}" in
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        "check"|"status")
            check_system
            ;;
        "tech"|"debug"|"system"|"general")
            if [ -z "${2:-}" ]; then
                echo "❌ 検索クエリが指定されていません"
                show_help
                return 1
            fi
            ai_org_search "$1" "$2"
            ;;
        *)
            echo "❌ 無効なコマンド: $1"
            show_help
            return 1
            ;;
    esac
}

# 実行
main "$@"