#!/bin/bash

# =============================================================================
# AI組織設定ローダー
# JSONベースの外部設定を読み込み、環境変数として展開
# =============================================================================

set -euo pipefail

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 設定ファイルパス
CONFIG_FILE="${AI_AGENTS_DIR:-$(dirname "$0")/..}/configs/agents.json"

# jqコマンドの存在確認
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} jqコマンドが見つかりません。インストールしてください。"
        echo "macOS: brew install jq"
        echo "Ubuntu: sudo apt-get install jq"
        exit 1
    fi
}

# 設定ファイルの存在確認
check_config_file() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}[ERROR]${NC} 設定ファイルが見つかりません: $CONFIG_FILE"
        exit 1
    fi
}

# JSON設定の読み込み
load_agent_config() {
    local agent_name="$1"
    local property="$2"
    
    jq -r ".agents.${agent_name}.${property} // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# システム設定の読み込み
load_system_config() {
    local property="$1"
    
    jq -r ".system.${property} // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# tmux設定の読み込み
load_tmux_config() {
    local session="$1"
    local property="$2"
    
    jq -r ".tmux.sessions.${session}.${property} // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# ペインタイトルの読み込み
load_pane_title() {
    local pane="$1"
    
    jq -r ".tmux.pane_titles.\"${pane}\" // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# エージェント起動メッセージの取得
get_startup_message() {
    local agent_name="$1"
    load_agent_config "$agent_name" "startup_message"
}

# エージェント起動遅延の取得
get_startup_delay() {
    local agent_name="$1"
    local delay=$(load_agent_config "$agent_name" "startup_delay")
    echo "${delay:-2}"
}

# 全エージェント名の取得
get_all_agents() {
    jq -r '.agents | keys[]' "$CONFIG_FILE" 2>/dev/null
}

# 設定の検証
validate_config() {
    echo -e "${YELLOW}[INFO]${NC} 設定ファイルを検証中..."
    
    # JSONの妥当性チェック
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} 無効なJSON形式です"
        return 1
    fi
    
    # 必須フィールドのチェック
    local required_fields=("system.name" "system.version" "agents.president" "agents.boss")
    for field in "${required_fields[@]}"; do
        if [[ -z $(jq -r ".$field // empty" "$CONFIG_FILE") ]]; then
            echo -e "${RED}[ERROR]${NC} 必須フィールドが不足: $field"
            return 1
        fi
    done
    
    echo -e "${GREEN}[SUCCESS]${NC} 設定ファイルは有効です"
    return 0
}

# 設定のエクスポート（環境変数として）
export_config() {
    # システム設定
    export AI_SYSTEM_NAME=$(load_system_config "name")
    export AI_SYSTEM_VERSION=$(load_system_config "version")
    export AI_WEBSOCKET_PORT=$(load_system_config "websocket_port")
    
    # パフォーマンス指標
    export AI_PERFORMANCE_IMPROVEMENT=$(jq -r '.system.performance_metrics.improvement_rate' "$CONFIG_FILE")
    export AI_TOKEN_EFFICIENCY=$(jq -r '.system.performance_metrics.token_efficiency' "$CONFIG_FILE")
    
    echo -e "${GREEN}[SUCCESS]${NC} 設定を環境変数にエクスポートしました"
}

# メイン処理
main() {
    check_jq
    check_config_file
    
    if [[ "${1:-}" == "validate" ]]; then
        validate_config
    elif [[ "${1:-}" == "export" ]]; then
        export_config
    elif [[ "${1:-}" == "get" ]] && [[ -n "${2:-}" ]] && [[ -n "${3:-}" ]]; then
        # 例: ./load-config.sh get president role
        load_agent_config "$2" "$3"
    else
        echo "使用方法:"
        echo "  $0 validate              - 設定の検証"
        echo "  $0 export                - 環境変数にエクスポート"
        echo "  $0 get <agent> <property> - 特定の値を取得"
    fi
}

# スクリプトが直接実行された場合のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi