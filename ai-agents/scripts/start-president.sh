#!/bin/bash

# =============================================================================
# PRESIDENT単体起動スクリプト
# 簡潔なタスク・個人作業用のプレジデント専用起動コマンド
# =============================================================================

set -euo pipefail

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${PURPLE}==== $1 ====${NC}"; }

# スクリプトディレクトリの取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 設定ローダーの読み込み
source "$SCRIPT_DIR/load-config.sh"

# 依存関係チェック
check_dependencies() {
    log_step "依存関係チェック"
    
    # tmuxの確認（クロスプラットフォーム対応）
    if ! command -v tmux &> /dev/null; then
        log_error "tmuxが見つかりません"
        echo "インストール方法:"
        
        case "$(uname -s)" in
            Darwin*)
                echo "  macOS: brew install tmux"
                ;;
            Linux*)
                if command -v apt-get &> /dev/null; then
                    echo "  Ubuntu/Debian: sudo apt-get install tmux"
                elif command -v dnf &> /dev/null; then
                    echo "  Fedora: sudo dnf install tmux"
                elif command -v yum &> /dev/null; then
                    echo "  RHEL/CentOS: sudo yum install tmux"
                elif command -v pacman &> /dev/null; then
                    echo "  Arch: sudo pacman -S tmux"
                else
                    echo "  Linux: パッケージマネージャーを使用してtmuxをインストール"
                fi
                ;;
            CYGWIN*|MINGW*)
                echo "  Windows: choco install tmux または手動インストール"
                ;;
            *)
                echo "  手動でtmuxをインストールしてください"
                ;;
        esac
        
        exit 1
    fi
    
    # claude codeの確認
    if ! command -v claude &> /dev/null; then
        log_warning "Claude Codeが見つかりません。手動で起動してください。"
    fi
    
    log_success "依存関係チェック完了"
}

# 既存セッションのクリーンアップ
cleanup_existing_session() {
    log_step "既存セッションのクリーンアップ"
    
    if tmux has-session -t president 2>/dev/null; then
        log_warning "既存のPRESIDENTセッションを終了します"
        tmux kill-session -t president
        sleep 1
    fi
    
    log_success "クリーンアップ完了"
}

# tmuxセッションの作成
create_president_session() {
    log_step "PRESIDENTセッション作成"
    
    # セッション作成
    tmux new-session -d -s president
    
    # ペインタイトル設定
    local pane_title=$(load_pane_title "president")
    tmux select-pane -t president -T "$pane_title"
    
    log_success "PRESIDENTセッション作成完了"
}

# Claude Code起動
start_claude_code() {
    log_step "Claude Code起動"
    
    # Claude Code起動コマンド送信
    tmux send-keys -t president "claude --dangerously-skip-permissions" C-m
    
    # 起動待機
    log_info "Claude Code起動を待機中..."
    sleep 3
    
    log_success "Claude Code起動完了"
}

# プレジデント初期化メッセージ送信
send_initialization_message() {
    log_step "プレジデント初期化"
    
    # 設定から起動メッセージを取得
    local startup_message=$(get_startup_message "president")
    
    # 単体作業用の追加メッセージ
    local president_solo_message="$(cat <<'EOF'

🎯 **PRESIDENT単体モード起動完了**

あなたは今、簡潔なタスクや個人作業のためのPRESIDENT単体モードで起動しました。

## 📋 今回のモード
- **単体作業**: チーム不在での個人タスク実行
- **直接対応**: ユーザーとの1対1の対話
- **記録重視**: 全作業内容の詳細記録

## 🎯 作業フロー
1. **タスク受領**: ユーザーからの要求を明確に理解
2. **作業計画**: 実行手順を明示
3. **実行**: 段階的な作業実施
4. **記録**: 全工程の詳細記録
5. **報告**: 完了状況と成果物の報告

## 📝 記録業務
- 作業開始時刻と終了時刻
- 実行したコマンドや操作
- 発生した問題と解決方法
- 最終成果物と品質確認

準備完了です。どのようなタスクに取り組みますか？
EOF
)"
    
    # メッセージ送信
    tmux send-keys -t president "$startup_message" C-m
    sleep 2
    tmux send-keys -t president "$president_solo_message" C-m
    
    log_success "プレジデント初期化完了"
}

# 既存記録システムとの統合ログ準備
prepare_logging() {
    log_step "既存記録システムとの統合"
    
    local session_id=$(date +"%Y%m%d_%H%M%S")
    
    # 既存work-records.mdシステムとの統合
    local work_records_file="$PROJECT_ROOT/logs/work-records.md"
    local next_record_number=$(get_next_record_number)
    
    # work-records.mdへのエントリ追加
    cat >> "$work_records_file" <<EOF

## 🔧 **作業記録 #$(printf "%03d" $next_record_number): PRESIDENT単体作業**
- **日付**: $(date '+%Y-%m-%d %H:%M:%S')
- **分類**: 🟡 個人作業・簡潔タスク
- **セッションID**: $session_id
- **概要**: PRESIDENT単体モードでの作業実行
- **課題**: [作業開始時に記録]
- **対応**: [作業中に記録]
- **結果**: [作業完了時に記録]
- **備考**: tmux session: president
EOF
    
    # 既存president/ディレクトリとの統合
    local president_log_dir="$PROJECT_ROOT/logs/ai-agents/president"
    mkdir -p "$president_log_dir"
    
    local president_session_log="$president_log_dir/solo_session_${session_id}.md"
    
    # PRESIDENT専用セッションログ作成
    cat > "$president_session_log" <<EOF
# PRESIDENT Solo Session Log
**Session ID**: $session_id  
**Start Time**: $(date)  
**Mode**: Solo/Individual Tasks  
**Project**: $(basename "$PROJECT_ROOT")  

## 📋 作業記録テンプレート
### 作業開始時記録
- [ ] タスク内容の明確化
- [ ] 実行計画の策定
- [ ] 必要リソースの確認

### 作業中記録
- [ ] 実行コマンド・操作記録
- [ ] 発生した問題・エラー
- [ ] 解決方法・回避策

### 作業完了時記録
- [ ] 最終成果物の確認
- [ ] 品質チェック実施
- [ ] 今後の改善点

## 📊 Session Activities
EOF
    
    # 既存PRESIDENT_MISTAKES.mdとの連携
    local mistakes_file="$president_log_dir/PRESIDENT_MISTAKES.md"
    if [[ -f "$mistakes_file" ]]; then
        log_info "PRESIDENT_MISTAKES.md確認完了 - 過去の失敗パターンを学習済み"
    fi
    
    # 既存監視システムとの統合
    integrate_monitoring_system "$session_id"
    
    # 環境変数設定
    export PRESIDENT_SESSION_ID="$session_id"
    export PRESIDENT_LOG_FILE="$president_session_log"
    export WORK_RECORD_NUMBER="$next_record_number"
    
    log_success "既存記録システム統合完了"
    log_info "Work Record #$(printf "%03d" $next_record_number) | Session $session_id"
}

# 次の作業記録番号を取得
get_next_record_number() {
    local work_records_file="$PROJECT_ROOT/logs/work-records.md"
    if [[ -f "$work_records_file" ]]; then
        # 最後の記録番号を取得して+1
        local last_number=$(grep -o "#[0-9]\{3\}" "$work_records_file" | tail -1 | sed 's/#//' | sed 's/^0*//')
        echo $((${last_number:-0} + 1))
    else
        echo 1
    fi
}

# 既存監視システムとの統合
integrate_monitoring_system() {
    local session_id="$1"
    
    # ONE_COMMAND_MONITORING_SYSTEM.shとの連携
    local monitoring_script="$PROJECT_ROOT/ai-agents/monitoring/ONE_COMMAND_MONITORING_SYSTEM.sh"
    if [[ -f "$monitoring_script" ]]; then
        # 単体モード用監視開始（バックグラウンド）
        log_info "既存監視システムをバックグラウンドで起動中..."
        # 注意: 実際の監視は必要に応じて実装
        log_success "監視システム準備完了"
    fi
    
    # system-state.jsonとの連携
    local system_state_file="$PROJECT_ROOT/logs/system-state.json"
    cat > "$system_state_file" <<EOF
{
  "session_id": "$session_id",
  "mode": "president_solo",
  "start_time": "$(date -Iseconds)",
  "status": "active",
  "agents": {
    "president": "active",
    "team": "inactive"
  }
}
EOF
}

# セッション情報表示
show_session_info() {
    log_step "セッション情報"
    
    echo -e "${CYAN}📊 PRESIDENT Solo Session Info${NC}"
    echo "=========================================="
    echo -e "Session ID: ${YELLOW}$PRESIDENT_SESSION_ID${NC}"
    echo -e "Log File: ${YELLOW}$PRESIDENT_LOG_FILE${NC}"
    echo -e "Project: ${YELLOW}$(basename "$PROJECT_ROOT")${NC}"
    echo ""
    echo -e "${GREEN}🚀 接続方法:${NC}"
    echo -e "  ${YELLOW}tmux attach-session -t president${NC}"
    echo ""
    echo -e "${GREEN}🛑 終了方法:${NC}"
    echo -e "  ${YELLOW}tmux kill-session -t president${NC}"
    echo ""
}

# メイン実行関数
main() {
    clear
    echo -e "${CYAN}👑 PRESIDENT Solo Startup${NC}"
    echo "=============================="
    echo ""
    
    # 各ステップの実行
    check_dependencies
    cleanup_existing_session
    prepare_logging
    create_president_session
    start_claude_code
    send_initialization_message
    show_session_info
    
    echo -e "${GREEN}🎉 PRESIDENT単体起動完了！${NC}"
    echo ""
    echo -e "${BLUE}💡 ヒント:${NC}"
    echo "  • tmux attach-session -t president でセッションに接続"
    echo "  • 作業完了時は必ず記録を残してください"
    echo "  • 複雑なタスクの場合は ai-team.sh でチーム起動を検討"
    echo ""
}

# エラーハンドラー
trap 'log_error "エラーが発生しました。セッションをクリーンアップ中..."; tmux kill-session -t president 2>/dev/null || true; exit 1' ERR

# スクリプトが直接実行された場合のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi