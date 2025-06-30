#!/bin/bash
# 🚀 統合自動エンターシステム v2.0
# 全機能統合・エラーハンドリング強化・プロンプト検知システム
# 作成日: 2025-06-30

set -e
set -o pipefail

# =====================================
# 基本設定とログシステム
# =====================================

# ログディレクトリとファイル設定
LOG_DIR="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs"
MAIN_LOG="$LOG_DIR/unified-auto-enter.log"
ERROR_LOG="$LOG_DIR/auto-enter-error.log"
STATUS_LOG="$LOG_DIR/auto-enter-status.log"

# PIDファイル
PID_FILE="/tmp/unified_auto_enter.pid"
MONITOR_PID_FILE="/tmp/auto_enter_monitor.pid"

# 作業ディレクトリ
TEMP_DIR="/tmp/auto_enter_system"

# 初期化
init_system() {
    mkdir -p "$LOG_DIR" "$TEMP_DIR"
    
    # ログファイル初期化
    if [ ! -f "$MAIN_LOG" ]; then
        touch "$MAIN_LOG"
    fi
    
    log_info "🔄 統合自動エンターシステム v2.0 初期化完了"
}

# ログ関数群（カラー対応）
log_info() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\033[1;32m[INFO]\033[0m [$timestamp] $message" | tee -a "$MAIN_LOG"
}

log_success() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\033[1;34m[SUCCESS]\033[0m [$timestamp] $message" | tee -a "$MAIN_LOG"
}

log_warn() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\033[1;33m[WARN]\033[0m [$timestamp] $message" | tee -a "$MAIN_LOG"
}

log_error() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\033[1;31m[ERROR]\033[0m [$timestamp] $message" | tee -a "$MAIN_LOG" | tee -a "$ERROR_LOG"
}

# =====================================
# 統一的なプロンプト検知システム
# =====================================

# プロンプト停止の詳細検知（全パターン対応）
detect_prompt_state() {
    local target="$1"
    local worker_name="$2"
    
    # tmuxペインが存在するかチェック
    if ! tmux capture-pane -t "$target" -p >/dev/null 2>&1; then
        echo "pane_not_found"
        return 1
    fi
    
    local content=$(tmux capture-pane -t "$target" -p)
    
    # 1. 入力フィールドチェック（改行とスペースの詳細確認）
    local input_field=$(echo "$content" | grep -A 3 "╭─\|>" | grep "│" | grep -v "╰" | tail -1)
    
    # 2. Bypassing Permissions状態検知
    local bypassing_count=$(echo "$content" | grep -c "Bypassing Permissions" || echo "0")
    bypassing_count=${bypassing_count//[^0-9]/}  # 数字以外を除去
    
    # 3. Welcome to Claude Code検知
    local welcome_present=$(echo "$content" | grep -c "Welcome to Claude Code" || echo "0")
    welcome_present=${welcome_present//[^0-9]/}  # 数字以外を除去
    
    # 4. プロンプト（>）検知
    local prompt_present=0
    if echo "$content" | grep -E "^\s*>\s*[^[:space:]]" >/dev/null; then
        prompt_present=1
    fi
    
    # 5. エラー状態検知
    local error_present=0
    if echo "$content" | grep -E "(Error|Failed|Exception)" >/dev/null; then
        error_present=1
    fi
    
    # ログに状態記録
    echo "[$worker_name] bypassing:$bypassing_count welcome:$welcome_present prompt:$prompt_present error:$error_present" >> "$STATUS_LOG"
    
    # 状態判定ロジック
    if [[ "$bypassing_count" -gt 0 ]] && [[ -n "$input_field" ]] && echo "$input_field" | grep -q "│ > [^[:space:]]"; then
        echo "stuck_with_input"
        return 0
    elif [[ "$bypassing_count" -gt 0 ]] && [[ "$prompt_present" -eq 1 ]]; then
        echo "stuck_with_prompt"
        return 0
    elif [[ "$error_present" -eq 1 ]]; then
        echo "error_state"
        return 0
    elif [[ "$welcome_present" -gt 0 ]]; then
        echo "ready"
        return 0
    else
        echo "unknown"
        return 0
    fi
}

# 継続的状態チェック（前回との比較）
check_state_change() {
    local target="$1"
    local worker_name="$2"
    
    # 現在の画面内容のハッシュを取得
    local current_hash=""
    if tmux capture-pane -t "$target" -p >/dev/null 2>&1; then
        current_hash=$(tmux capture-pane -t "$target" -p | tail -5 | md5sum | cut -d' ' -f1)
    else
        echo "state_change_unknown"
        return 1
    fi
    
    local state_file="$TEMP_DIR/${worker_name}_state.txt"
    local previous_hash=""
    
    if [[ -f "$state_file" ]]; then
        previous_hash=$(cat "$state_file")
    fi
    
    # 現在のハッシュを保存
    echo "$current_hash" > "$state_file"
    
    # 変化判定
    if [[ "$current_hash" == "$previous_hash" ]]; then
        echo "no_change"
    else
        echo "changed"
    fi
}

# =====================================
# 確実なエンター送信機能
# =====================================

# 基本エンター送信（エラーハンドリング付き）
send_enter() {
    local target="$1"
    local count="${2:-1}"
    local worker_name="$3"
    
    log_info "⚡ $worker_name エンター送信開始 (${count}回)"
    
    # ペインアクティブ化
    if ! tmux select-pane -t "$target" 2>/dev/null; then
        log_error "❌ ペイン選択失敗: $target"
        return 1
    fi
    
    # エンター送信
    for ((i=1; i<=count; i++)); do
        if tmux send-keys -t "$target" "" C-m; then
            log_info "✅ $worker_name エンター送信 $i/$count 成功"
            sleep 0.5
        else
            log_error "❌ $worker_name エンター送信 $i/$count 失敗"
            return 1
        fi
    done
    
    return 0
}

# 強化版ダブルエンター（確認付き）
enhanced_double_enter() {
    local target="$1"
    local message="$2"
    local worker_name="$3"
    
    log_info "📤 $worker_name 強化版ダブルエンター開始"
    
    # ペインアクティブ化
    if ! tmux select-pane -t "$target"; then
        log_error "❌ ペインアクティブ化失敗: $target"
        return 1
    fi
    
    # メッセージ送信（オプション）
    if [[ -n "$message" ]]; then
        log_info "💬 メッセージ送信: $message"
        tmux send-keys -t "$target" "$message" C-m
        sleep 1
    fi
    
    # 第1回エンター
    send_enter "$target" 1 "$worker_name"
    sleep 1
    
    # 第2回エンター
    send_enter "$target" 1 "$worker_name"
    sleep 2
    
    # 送信効果確認
    local after_state=$(detect_prompt_state "$target" "$worker_name")
    log_info "🔍 送信後状態: $after_state"
    
    case "$after_state" in
        "ready")
            log_success "✅ $worker_name ダブルエンター成功"
            return 0
            ;;
        "stuck_with_input"|"stuck_with_prompt")
            log_warn "⚠️ $worker_name 追加エンター必要"
            send_enter "$target" 1 "$worker_name"
            return 2
            ;;
        *)
            log_warn "⚠️ $worker_name 状態不明: $after_state"
            return 1
            ;;
    esac
}

# =====================================
# 自動復旧システム
# =====================================

# 自動復旧実行（段階的アプローチ）
auto_recovery() {
    local target="$1"
    local worker_name="$2"
    local max_attempts="${3:-3}"
    
    log_info "🔧 $worker_name 自動復旧開始 (最大${max_attempts}回試行)"
    
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        log_info "🔄 $worker_name 復旧試行 $attempt/$max_attempts"
        
        # 現在の状態確認
        local current_state=$(detect_prompt_state "$target" "$worker_name")
        log_info "📊 現在状態: $current_state"
        
        case "$current_state" in
            "stuck_with_input"|"stuck_with_prompt")
                # ダブルエンターによる復旧
                if enhanced_double_enter "$target" "" "$worker_name"; then
                    log_success "✅ $worker_name 復旧成功 (試行 $attempt)"
                    return 0
                fi
                ;;
            "error_state")
                # エラー状態からの強制復旧
                log_warn "⚠️ エラー状態検知 - 強制復旧実行"
                tmux send-keys -t "$target" C-c
                sleep 1
                tmux send-keys -t "$target" "状況を教えてください" C-m
                sleep 2
                ;;
            "ready")
                log_success "✅ $worker_name 既に復旧済み"
                return 0
                ;;
            "pane_not_found")
                log_error "❌ $worker_name ペインが見つかりません"
                return 1
                ;;
        esac
        
        # 試行間隔
        if [[ $attempt -lt $max_attempts ]]; then
            sleep 2
        fi
    done
    
    log_error "❌ $worker_name 自動復旧失敗 (${max_attempts}回試行後)"
    return 1
}

# =====================================
# 継続的監視システム
# =====================================

# 継続的監視メイン処理
continuous_monitoring() {
    local interval="${1:-10}"
    
    log_info "🔄 継続的監視開始 (${interval}秒間隔)"
    
    # 監視対象定義
    local -a targets=(
        "president:PRESIDENT"
        "multiagent:0.0:BOSS1"
        "multiagent:0.1:WORKER1"
        "multiagent:0.2:WORKER2"
        "multiagent:0.3:WORKER3"
    )
    
    while true; do
        for target_info in "${targets[@]}"; do
            IFS=':' read -r session pane worker_name <<< "$target_info"
            
            local target_id=""
            if [[ "$session" == "president" ]]; then
                target_id="president"
            else
                target_id="${session}:${pane}"
            fi
            
            # 状態チェック
            local state=$(detect_prompt_state "$target_id" "$worker_name")
            local change=$(check_state_change "$target_id" "$worker_name")
            
            # ログ記録
            echo "$(date '+%H:%M:%S') [$worker_name] state:$state change:$change" >> "$STATUS_LOG"
            
            # 問題状態の場合は自動復旧
            case "$state" in
                "stuck_with_input"|"stuck_with_prompt"|"error_state")
                    log_warn "🚨 $worker_name 問題状態検知: $state"
                    auto_recovery "$target_id" "$worker_name" 2
                    ;;
            esac
        done
        
        sleep "$interval"
    done
}

# =====================================
# メッセージ送信システム（manage.sh連携）
# =====================================

# 自動エンター付きメッセージ送信
send_message_with_auto_enter() {
    local target="$1"
    local message="$2"
    local worker_name="$3"
    local enter_count="${4:-2}"
    
    log_info "📤 $worker_name メッセージ送信+自動エンター"
    log_info "💬 メッセージ: $message"
    
    # メッセージ送信
    if ! tmux send-keys -t "$target" "$message" C-m; then
        log_error "❌ メッセージ送信失敗"
        return 1
    fi
    
    sleep 1
    
    # 自動エンター送信
    if send_enter "$target" "$enter_count" "$worker_name"; then
        log_success "✅ $worker_name メッセージ送信+自動エンター完了"
        return 0
    else
        log_error "❌ 自動エンター送信失敗"
        return 1
    fi
}

# 初期メッセージ配布システム
distribute_initial_messages() {
    log_info "🚀 初期メッセージ配布開始"
    
    # PRESIDENT初期化
    local president_msg="あなたはプレジデントです。./ai-agents/instructions/president.mdの指示書を参照して実行してください。ワーカーたちを立ち上げてボスに指令を伝達して下さい。"
    send_message_with_auto_enter "president" "$president_msg" "PRESIDENT" 2
    
    sleep 2
    
    # WORKER起動コマンド
    local worker_startup_cmd="for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude --dangerously-skip-permissions ' C-m; done"
    send_message_with_auto_enter "president" "$worker_startup_cmd" "PRESIDENT" 1
    
    # 各ワーカーの初期化
    local -a worker_messages=(
        "あなたはBOSS・チームリーダーです。プロジェクト全体の調査結果をまとめて、具体的な改善指示をワーカーたちに出してください。./ai-agents/instructions/boss.md を参照して日本語で応答してください。"
        "あなたはフロントエンドエンジニアです。React・Vue・HTML/CSS等の技術でUI改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。"
        "あなたはバックエンドエンジニアです。Node.js・Python・データベース等の技術でシステム改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。"
        "あなたはUI/UXデザイナーです。デザインシステム・ユーザビリティ改善を実行してください。./ai-agents/instructions/worker.md を参照して日本語で応答してください。"
    )
    
    for i in {0..3}; do
        local target="multiagent:0.$i"
        local worker_name="WORKER$((i+1))"
        local message="${worker_messages[$i]}"
        
        # ワーカーの起動状況をチェックしてからメッセージ送信
        local state=$(detect_prompt_state "$target" "$worker_name")
        if [[ "$state" == "ready" ]]; then
            send_message_with_auto_enter "$target" "$message" "$worker_name" 2
            sleep 1
        else
            log_warn "⚠️ $worker_name 未準備状態 - メッセージ送信スキップ"
        fi
    done
    
    log_success "✅ 初期メッセージ配布完了"
}

# =====================================
# 緊急システム
# =====================================

# 緊急プロンプト解消
emergency_prompt_clear() {
    log_warn "🚨 緊急プロンプト解消実行"
    
    # 全ターゲットに緊急エンター送信
    local -a emergency_targets=(
        "president:PRESIDENT"
        "multiagent:0.0:BOSS1"
        "multiagent:0.1:WORKER1" 
        "multiagent:0.2:WORKER2"
        "multiagent:0.3:WORKER3"
    )
    
    for target_info in "${emergency_targets[@]}"; do
        IFS=':' read -r session pane worker_name <<< "$target_info"
        
        local target_id=""
        if [[ "$session" == "president" ]]; then
            target_id="president"
        else
            target_id="${session}:${pane}"
        fi
        
        # 強制ダブルエンター
        if tmux send-keys -t "$target_id" "" C-m; then
            tmux send-keys -t "$target_id" "" C-m
            log_warn "⚡ $worker_name 緊急エンター送信"
        else
            log_error "❌ $worker_name 緊急エンター送信失敗"
        fi
    done
    
    log_warn "🚨 緊急プロンプト解消完了"
}

# システム停止
stop_system() {
    log_info "🛑 統合自動エンターシステム停止中..."
    
    # 監視プロセス停止
    if [[ -f "$MONITOR_PID_FILE" ]]; then
        local monitor_pid=$(cat "$MONITOR_PID_FILE")
        if kill "$monitor_pid" 2>/dev/null; then
            log_info "🛑 監視プロセス停止 (PID: $monitor_pid)"
        fi
        rm -f "$MONITOR_PID_FILE"
    fi
    
    # メインプロセス停止
    if [[ -f "$PID_FILE" ]]; then
        local main_pid=$(cat "$PID_FILE")
        if kill "$main_pid" 2>/dev/null; then
            log_info "🛑 メインプロセス停止 (PID: $main_pid)"
        fi
        rm -f "$PID_FILE"
    fi
    
    log_success "✅ システム停止完了"
}

# =====================================
# システム状況確認
# =====================================

show_status() {
    echo "🤖 統合自動エンターシステム v2.0 状況"
    echo "========================================"
    echo ""
    
    # システム稼働状況
    echo "💻 システム稼働状況:"
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "  ✅ メインシステム: 稼働中 (PID: $(cat "$PID_FILE"))"
    else
        echo "  ❌ メインシステム: 停止中"
    fi
    
    if [[ -f "$MONITOR_PID_FILE" ]] && kill -0 "$(cat "$MONITOR_PID_FILE")" 2>/dev/null; then
        echo "  ✅ 監視システム: 稼働中 (PID: $(cat "$MONITOR_PID_FILE"))"
    else
        echo "  ❌ 監視システム: 停止中"
    fi
    echo ""
    
    # ログファイル状況
    echo "📊 ログファイル状況:"
    for log_file in "$MAIN_LOG" "$ERROR_LOG" "$STATUS_LOG"; do
        if [[ -f "$log_file" ]]; then
            local size=$(wc -l < "$log_file")
            echo "  ✅ $(basename "$log_file"): ${size}行"
        else
            echo "  ❌ $(basename "$log_file"): 未作成"
        fi
    done
    echo ""
    
    # ワーカー状況確認
    echo "👥 ワーカー状況:"
    local -a check_targets=(
        "president:PRESIDENT"
        "multiagent:0.0:BOSS1"
        "multiagent:0.1:WORKER1"
        "multiagent:0.2:WORKER2"
        "multiagent:0.3:WORKER3"
    )
    
    for target_info in "${check_targets[@]}"; do
        IFS=':' read -r session pane worker_name <<< "$target_info"
        
        local target_id=""
        if [[ "$session" == "president" ]]; then
            target_id="president"
        else
            target_id="${session}:${pane}"
        fi
        
        local state=$(detect_prompt_state "$target_id" "$worker_name")
        
        case "$state" in
            "ready")
                echo "  ✅ $worker_name: 準備完了"
                ;;
            "stuck_with_input"|"stuck_with_prompt")
                echo "  ⚠️ $worker_name: プロンプト停止"
                ;;
            "error_state")
                echo "  ❌ $worker_name: エラー状態"
                ;;
            "pane_not_found")
                echo "  🔍 $worker_name: ペイン未発見"
                ;;
            *)
                echo "  ❓ $worker_name: 状態不明 ($state)"
                ;;
        esac
    done
}

# =====================================
# ヘルプ表示
# =====================================

show_help() {
    echo "🚀 統合自動エンターシステム v2.0"
    echo "=================================="
    echo ""
    echo "🎯 基本コマンド:"
    echo "  $0 start                     # システム開始"
    echo "  $0 monitor                   # 継続的監視開始"
    echo "  $0 stop                      # システム停止"
    echo "  $0 status                    # システム状況確認"
    echo ""
    echo "📤 メッセージ送信:"
    echo "  $0 send [target] [message]   # 自動エンター付きメッセージ送信"
    echo "  $0 init-messages             # 初期メッセージ配布"
    echo ""
    echo "🔧 復旧・メンテナンス:"
    echo "  $0 recover [target]          # 指定ターゲットの自動復旧"
    echo "  $0 emergency                 # 緊急プロンプト解消"
    echo "  $0 clear-logs               # ログファイル削除"
    echo ""
    echo "🔍 診断:"
    echo "  $0 check [target]            # 指定ターゲットの状態確認"
    echo "  $0 test                      # システムテスト実行"
    echo ""
    echo "💡 使用例:"
    echo "  $0 start                     # システム開始"
    echo "  $0 monitor &                 # バックグラウンド監視"
    echo "  $0 send president 'こんにちは' # PRESIDENTにメッセージ送信"
    echo ""
}

# =====================================
# メイン処理
# =====================================

main() {
    init_system
    
    case "${1:-help}" in
        "start")
            echo $$ > "$PID_FILE"
            log_info "🚀 統合自動エンターシステム開始 (PID: $$)"
            distribute_initial_messages
            ;;
        "monitor")
            continuous_monitoring "${2:-10}" &
            echo $! > "$MONITOR_PID_FILE"
            log_info "🔄 継続的監視開始 (PID: $!)"
            wait
            ;;
        "stop")
            stop_system
            ;;
        "status")
            show_status
            ;;
        "send")
            if [[ $# -lt 3 ]]; then
                log_error "❌ 使用方法: $0 send [target] [message] [worker_name]"
                exit 1
            fi
            send_message_with_auto_enter "$2" "$3" "${4:-UNKNOWN}"
            ;;
        "init-messages")
            distribute_initial_messages
            ;;
        "recover")
            if [[ $# -lt 2 ]]; then
                log_error "❌ 使用方法: $0 recover [target] [worker_name]"
                exit 1
            fi
            auto_recovery "$2" "${3:-UNKNOWN}"
            ;;
        "emergency")
            emergency_prompt_clear
            ;;
        "check")
            if [[ $# -lt 2 ]]; then
                log_error "❌ 使用方法: $0 check [target] [worker_name]"
                exit 1
            fi
            local state=$(detect_prompt_state "$2" "${3:-UNKNOWN}")
            echo "状態: $state"
            ;;
        "clear-logs")
            rm -f "$MAIN_LOG" "$ERROR_LOG" "$STATUS_LOG"
            log_info "🧹 ログファイル削除完了"
            ;;
        "test")
            log_info "🧪 システムテスト実行中..."
            show_status
            ;;
        "help"|"--help"|"-h"|*)
            show_help
            ;;
    esac
}

# スクリプト実行
main "$@"