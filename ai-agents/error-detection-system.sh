#!/bin/bash

# 🔧 エラー検出・自動修正システム v2.0
# WORKER2により設計・実装

set -euo pipefail

# システム設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
ERROR_LOG="${LOG_DIR}/error-detection.log"
ERROR_DB="${SCRIPT_DIR}/error-database.json"
RECOVERY_SCRIPTS="${SCRIPT_DIR}/recovery-scripts"
LEARNING_DB="${SCRIPT_DIR}/error-learning.json"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${ERROR_LOG}"
}

alert() {
    echo "[ALERT][$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${ERROR_LOG}"
    # アラート通知（実装可能な場合）
}

# エラーパターンデータベース初期化
initialize_error_patterns() {
    cat > "${ERROR_DB}" << 'EOF'
{
  "detection_patterns": {
    "level_1_basic": {
      "syntax_error": {
        "patterns": ["SyntaxError", "ParseError", "IndentationError", "unexpected token"],
        "severity": "high",
        "auto_fix": true,
        "recovery_script": "fix_syntax_error.sh"
      },
      "file_not_found": {
        "patterns": ["No such file", "FileNotFoundError", "cannot access"],
        "severity": "medium",
        "auto_fix": true,
        "recovery_script": "fix_file_not_found.sh"
      },
      "permission_denied": {
        "patterns": ["Permission denied", "PermissionError", "Access forbidden"],
        "severity": "medium",
        "auto_fix": true,
        "recovery_script": "fix_permissions.sh"
      },
      "command_not_found": {
        "patterns": ["command not found", "not recognized", "No such command"],
        "severity": "medium",
        "auto_fix": true,
        "recovery_script": "fix_command_not_found.sh"
      }
    },
    "level_2_advanced": {
      "memory_error": {
        "patterns": ["MemoryError", "out of memory", "cannot allocate"],
        "severity": "high",
        "auto_fix": false,
        "recovery_script": "handle_memory_error.sh"
      },
      "network_error": {
        "patterns": ["Connection refused", "Network unreachable", "Timeout"],
        "severity": "medium",
        "auto_fix": true,
        "recovery_script": "fix_network_error.sh"
      },
      "dependency_error": {
        "patterns": ["ModuleNotFoundError", "ImportError", "No module named"],
        "severity": "high",
        "auto_fix": true,
        "recovery_script": "fix_dependencies.sh"
      }
    },
    "level_3_system": {
      "worker_hung": {
        "patterns": ["no response", "timeout", "unresponsive"],
        "severity": "critical",
        "auto_fix": true,
        "recovery_script": "recover_hung_worker.sh"
      },
      "session_lost": {
        "patterns": ["session not found", "connection lost", "session terminated"],
        "severity": "critical",
        "auto_fix": true,
        "recovery_script": "restore_session.sh"
      },
      "resource_conflict": {
        "patterns": ["resource busy", "lock timeout", "concurrent access"],
        "severity": "medium",
        "auto_fix": true,
        "recovery_script": "resolve_resource_conflict.sh"
      }
    }
  },
  "error_statistics": {
    "total_detected": 0,
    "auto_fixed": 0,
    "manual_intervention": 0,
    "detection_accuracy": 0
  }
}
EOF
    log "エラーパターンデータベースを初期化しました"
}

# 学習データベース初期化
initialize_learning_database() {
    cat > "${LEARNING_DB}" << 'EOF'
{
  "learned_patterns": [],
  "successful_fixes": [],
  "failed_fixes": [],
  "pattern_frequency": {},
  "fix_success_rate": {},
  "last_learning_update": null
}
EOF
    log "学習データベースを初期化しました"
}

# 回復スクリプトディレクトリ作成
create_recovery_scripts() {
    mkdir -p "${RECOVERY_SCRIPTS}"
    
    # 基本的な回復スクリプト作成
    
    # 構文エラー修正
    cat > "${RECOVERY_SCRIPTS}/fix_syntax_error.sh" << 'EOF'
#!/bin/bash
# 構文エラー自動修正スクリプト
echo "構文エラーの自動修正を試行中..."
# 基本的な構文修正ロジック
exit 0
EOF
    
    # ファイル不存在エラー修正
    cat > "${RECOVERY_SCRIPTS}/fix_file_not_found.sh" << 'EOF'
#!/bin/bash
# ファイル不存在エラー修正スクリプト
file_path="$1"
echo "ファイル作成を試行: ${file_path}"
# ディレクトリ作成とファイル作成
mkdir -p "$(dirname "${file_path}")"
touch "${file_path}"
exit 0
EOF
    
    # 権限エラー修正
    cat > "${RECOVERY_SCRIPTS}/fix_permissions.sh" << 'EOF'
#!/bin/bash
# 権限エラー修正スクリプト
target="$1"
echo "権限修正を試行: ${target}"
chmod +x "${target}" 2>/dev/null || true
exit 0
EOF
    
    # ワーカー復旧
    cat > "${RECOVERY_SCRIPTS}/recover_hung_worker.sh" << 'EOF'
#!/bin/bash
# ワーカー復旧スクリプト
worker="$1"
session="multiagent:0.${worker: -1}"
echo "ワーカー復旧を試行: ${worker}"
tmux send-keys -t "${session}" C-c C-c
sleep 2
tmux send-keys -t "${session}" "clear" C-m
exit 0
EOF
    
    # すべてのスクリプトに実行権限付与
    chmod +x "${RECOVERY_SCRIPTS}"/*.sh
    
    log "回復スクリプトを作成しました"
}

# エラー検出エンジン
detect_errors() {
    local source="$1"  # "worker" または "system"
    local target="${2:-all}"  # 検出対象
    local detected_errors=()
    
    log "エラー検出開始: ${source} → ${target}"
    
    case "${source}" in
        "worker")
            detected_errors=($(detect_worker_errors "${target}"))
            ;;
        "system")
            detected_errors=($(detect_system_errors))
            ;;
        "logs")
            detected_errors=($(detect_log_errors "${target}"))
            ;;
        *)
            log "ERROR: 不明な検出ソース: ${source}"
            return 1
            ;;
    esac
    
    # 検出結果処理
    if [ ${#detected_errors[@]} -gt 0 ]; then
        log "エラー検出: ${#detected_errors[@]}件"
        for error in "${detected_errors[@]}"; do
            process_detected_error "${error}"
        done
    else
        log "エラー検出: なし"
    fi
    
    return 0
}

# ワーカーエラー検出
detect_worker_errors() {
    local worker="${1:-all}"
    local errors=()
    
    if [ "${worker}" = "all" ]; then
        for w in 1 2 3; do
            local worker_errors=($(detect_single_worker_errors "WORKER${w}"))
            errors+=("${worker_errors[@]}")
        done
        # BOSS1とPRESIDENTも確認
        local boss_errors=($(detect_single_worker_errors "BOSS1"))
        errors+=("${boss_errors[@]}")
    else
        errors=($(detect_single_worker_errors "${worker}"))
    fi
    
    printf '%s\n' "${errors[@]}"
}

# 単一ワーカーエラー検出
detect_single_worker_errors() {
    local worker="$1"
    local session_name=""
    local errors=()
    
    # セッション名決定
    case "${worker}" in
        "BOSS1") session_name="multiagent:0.0" ;;
        "WORKER1") session_name="multiagent:0.1" ;;
        "WORKER2") session_name="multiagent:0.2" ;;
        "WORKER3") session_name="multiagent:0.3" ;;
        *) return 1 ;;
    esac
    
    # セッション存在確認
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        errors+=("${worker}:session_lost:critical")
        printf '%s\n' "${errors[@]}"
        return 0
    fi
    
    # 画面出力取得
    local output=$(tmux capture-pane -t "${session_name}" -p 2>/dev/null || echo "")
    local recent_output=$(echo "${output}" | tail -20)
    
    # エラーパターンマッチング
    if [ -f "${ERROR_DB}" ]; then
        # Level 1 エラー検出
        while IFS= read -r pattern; do
            if echo "${recent_output}" | grep -qi "${pattern}"; then
                local error_type=$(get_error_type "${pattern}")
                errors+=("${worker}:${error_type}:high")
                log "Level 1 エラー検出: ${worker} → ${error_type}"
            fi
        done < <(cat "${ERROR_DB}" | jq -r '.detection_patterns.level_1_basic[].patterns[]')
        
        # Level 2 エラー検出
        while IFS= read -r pattern; do
            if echo "${recent_output}" | grep -qi "${pattern}"; then
                local error_type=$(get_error_type "${pattern}")
                errors+=("${worker}:${error_type}:medium")
                log "Level 2 エラー検出: ${worker} → ${error_type}"
            fi
        done < <(cat "${ERROR_DB}" | jq -r '.detection_patterns.level_2_advanced[].patterns[]')
    fi
    
    # 無応答検出
    if echo "${recent_output}" | tail -5 | grep -q ">" && \
       [ "$(echo "${recent_output}" | wc -l)" -lt 5 ]; then
        # 最近の活動が少ない = 無応答の可能性
        errors+=("${worker}:no_response:medium")
        log "無応答検出: ${worker}"
    fi
    
    printf '%s\n' "${errors[@]}"
}

# システムエラー検出
detect_system_errors() {
    local errors=()
    
    # ディスク容量チェック
    local disk_usage=$(df . | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "${disk_usage}" -gt 90 ]; then
        errors+=("system:disk_full:critical")
        log "システムエラー検出: ディスク容量不足 (${disk_usage}%)"
    fi
    
    # メモリ使用量チェック
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "${mem_usage}" -gt 90 ]; then
        errors+=("system:memory_high:high")
        log "システムエラー検出: メモリ使用量高 (${mem_usage}%)"
    fi
    
    # プロセス確認
    if ! pgrep -f "tmux" > /dev/null; then
        errors+=("system:tmux_not_running:critical")
        log "システムエラー検出: tmux未実行"
    fi
    
    printf '%s\n' "${errors[@]}"
}

# ログエラー検出
detect_log_errors() {
    local log_file="${1:-${ERROR_LOG}}"
    local errors=()
    
    if [ -f "${log_file}" ]; then
        # 最近のエラーログ確認
        local recent_errors=$(tail -100 "${log_file}" | grep -i "error\|failed\|exception" | wc -l)
        if [ "${recent_errors}" -gt 5 ]; then
            errors+=("logs:error_spike:medium")
            log "ログエラー検出: エラー急増 (${recent_errors}件)"
        fi
    fi
    
    printf '%s\n' "${errors[@]}"
}

# エラータイプ特定
get_error_type() {
    local pattern="$1"
    local error_type="unknown"
    
    if [ -f "${ERROR_DB}" ]; then
        error_type=$(cat "${ERROR_DB}" | jq -r "
            .detection_patterns[][] | 
            select(.patterns[] | test(\"${pattern}\"; \"i\")) | 
            keys[0]
        " 2>/dev/null | head -1)
    fi
    
    echo "${error_type:-unknown}"
}

# 検出エラー処理
process_detected_error() {
    local error_info="$1"
    IFS=':' read -r component error_type severity <<< "${error_info}"
    
    log "エラー処理開始: ${component} → ${error_type} (${severity})"
    
    # エラー統計更新
    update_error_statistics "${error_type}" "detected"
    
    # 自動修正判定
    local auto_fix=$(should_auto_fix "${error_type}")
    
    if [ "${auto_fix}" = "true" ]; then
        attempt_auto_fix "${component}" "${error_type}" "${severity}"
    else
        log "手動介入が必要: ${component} → ${error_type}"
        alert "手動介入要求: ${component} でエラー ${error_type} が検出されました"
        update_error_statistics "${error_type}" "manual_intervention"
    fi
}

# 自動修正判定
should_auto_fix() {
    local error_type="$1"
    local auto_fix="false"
    
    if [ -f "${ERROR_DB}" ]; then
        auto_fix=$(cat "${ERROR_DB}" | jq -r "
            .detection_patterns[][] | 
            select(keys[0] == \"${error_type}\") | 
            .auto_fix
        " 2>/dev/null | head -1)
    fi
    
    # 学習データベースから成功率確認
    if [ -f "${LEARNING_DB}" ]; then
        local success_rate=$(cat "${LEARNING_DB}" | jq -r ".fix_success_rate.${error_type} // 0")
        if (( $(echo "${success_rate} < 0.3" | bc -l) )); then
            auto_fix="false"  # 成功率が低い場合は自動修正しない
        fi
    fi
    
    echo "${auto_fix:-false}"
}

# 自動修正試行
attempt_auto_fix() {
    local component="$1"
    local error_type="$2"
    local severity="$3"
    
    log "自動修正試行: ${component} → ${error_type}"
    
    # 回復スクリプト特定
    local recovery_script
    if [ -f "${ERROR_DB}" ]; then
        recovery_script=$(cat "${ERROR_DB}" | jq -r "
            .detection_patterns[][] | 
            select(keys[0] == \"${error_type}\") | 
            .recovery_script
        " 2>/dev/null | head -1)
    fi
    
    if [ -n "${recovery_script}" ] && [ -f "${RECOVERY_SCRIPTS}/${recovery_script}" ]; then
        log "回復スクリプト実行: ${recovery_script}"
        
        # 修正前状態記録
        local pre_fix_state=$(capture_component_state "${component}")
        
        # 修正実行
        local fix_start_time=$(date +%s)
        if "${RECOVERY_SCRIPTS}/${recovery_script}" "${component}"; then
            local fix_end_time=$(date +%s)
            local fix_duration=$((fix_end_time - fix_start_time))
            
            # 修正後検証
            sleep 5  # 修正効果確認のための待機
            local post_fix_state=$(capture_component_state "${component}")
            
            if verify_fix_success "${component}" "${error_type}" "${pre_fix_state}" "${post_fix_state}"; then
                log "自動修正成功: ${component} → ${error_type} (${fix_duration}秒)"
                update_error_statistics "${error_type}" "auto_fixed"
                record_successful_fix "${component}" "${error_type}" "${recovery_script}" "${fix_duration}"
            else
                log "自動修正失敗: 効果確認不可 ${component} → ${error_type}"
                update_error_statistics "${error_type}" "fix_failed"
                record_failed_fix "${component}" "${error_type}" "${recovery_script}"
            fi
        else
            log "自動修正失敗: スクリプト実行エラー ${component} → ${error_type}"
            update_error_statistics "${error_type}" "fix_failed"
            record_failed_fix "${component}" "${error_type}" "${recovery_script}"
        fi
    else
        log "回復スクリプト不存在: ${recovery_script}"
        alert "回復スクリプトが見つかりません: ${error_type}"
    fi
}

# コンポーネント状態キャプチャ
capture_component_state() {
    local component="$1"
    local state="{}"
    
    case "${component}" in
        WORKER*|BOSS1)
            local session_name=""
            case "${component}" in
                "BOSS1") session_name="multiagent:0.0" ;;
                "WORKER1") session_name="multiagent:0.1" ;;
                "WORKER2") session_name="multiagent:0.2" ;;
                "WORKER3") session_name="multiagent:0.3" ;;
            esac
            
            if tmux has-session -t "${session_name}" 2>/dev/null; then
                local output=$(tmux capture-pane -t "${session_name}" -p 2>/dev/null || echo "")
                state=$(cat << EOF
{
  "session_active": true,
  "last_output": $(echo "${output}" | tail -5 | jq -R -s .),
  "timestamp": "$(date -Iseconds)"
}
EOF
)
            else
                state='{"session_active": false, "timestamp": "'$(date -Iseconds)'"}'
            fi
            ;;
        system)
            state=$(cat << EOF
{
  "disk_usage": $(df . | awk 'NR==2 {print $5}' | sed 's/%//'),
  "memory_usage": $(free | awk 'NR==2{printf "%.0f", $3*100/$2}'),
  "tmux_running": $(pgrep -f "tmux" > /dev/null && echo true || echo false),
  "timestamp": "$(date -Iseconds)"
}
EOF
)
            ;;
    esac
    
    echo "${state}"
}

# 修正成功検証
verify_fix_success() {
    local component="$1"
    local error_type="$2"
    local pre_state="$3"
    local post_state="$4"
    
    # 基本的な検証ロジック
    case "${error_type}" in
        "session_lost")
            local post_active=$(echo "${post_state}" | jq -r '.session_active')
            [ "${post_active}" = "true" ]
            ;;
        "no_response")
            local post_output=$(echo "${post_state}" | jq -r '.last_output')
            echo "${post_output}" | grep -q ">"
            ;;
        *)
            # デフォルト: エラー再検出がないことを確認
            local redetected_errors=($(detect_single_worker_errors "${component}"))
            [ ${#redetected_errors[@]} -eq 0 ]
            ;;
    esac
}

# エラー統計更新
update_error_statistics() {
    local error_type="$1"
    local action="$2"  # detected, auto_fixed, manual_intervention, fix_failed
    
    if [ ! -f "${ERROR_DB}" ]; then
        initialize_error_patterns
    fi
    
    local temp_file=$(mktemp)
    cat "${ERROR_DB}" | jq "
        .error_statistics.total_detected += (if \"${action}\" == \"detected\" then 1 else 0 end) |
        .error_statistics.auto_fixed += (if \"${action}\" == \"auto_fixed\" then 1 else 0 end) |
        .error_statistics.manual_intervention += (if \"${action}\" == \"manual_intervention\" then 1 else 0 end)
    " > "${temp_file}"
    
    mv "${temp_file}" "${ERROR_DB}"
}

# 成功修正記録
record_successful_fix() {
    local component="$1"
    local error_type="$2"
    local recovery_script="$3"
    local duration="$4"
    
    if [ ! -f "${LEARNING_DB}" ]; then
        initialize_learning_database
    fi
    
    local fix_record=$(cat << EOF
{
  "component": "${component}",
  "error_type": "${error_type}",
  "recovery_script": "${recovery_script}",
  "duration": ${duration},
  "timestamp": "$(date -Iseconds)"
}
EOF
)
    
    local temp_file=$(mktemp)
    cat "${LEARNING_DB}" | jq ".successful_fixes += [${fix_record}]" > "${temp_file}"
    mv "${temp_file}" "${LEARNING_DB}"
    
    update_fix_success_rate "${error_type}" true
}

# 失敗修正記録
record_failed_fix() {
    local component="$1"
    local error_type="$2"
    local recovery_script="$3"
    
    if [ ! -f "${LEARNING_DB}" ]; then
        initialize_learning_database
    fi
    
    local fail_record=$(cat << EOF
{
  "component": "${component}",
  "error_type": "${error_type}",
  "recovery_script": "${recovery_script}",
  "timestamp": "$(date -Iseconds)"
}
EOF
)
    
    local temp_file=$(mktemp)
    cat "${LEARNING_DB}" | jq ".failed_fixes += [${fail_record}]" > "${temp_file}"
    mv "${temp_file}" "${LEARNING_DB}"
    
    update_fix_success_rate "${error_type}" false
}

# 修正成功率更新
update_fix_success_rate() {
    local error_type="$1"
    local success="$2"  # true/false
    
    if [ ! -f "${LEARNING_DB}" ]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    cat "${LEARNING_DB}" | jq "
        .fix_success_rate.${error_type} = (
            (.successful_fixes | map(select(.error_type == \"${error_type}\")) | length) /
            ((.successful_fixes | map(select(.error_type == \"${error_type}\")) | length) +
             (.failed_fixes | map(select(.error_type == \"${error_type}\")) | length))
        )
    " > "${temp_file}"
    
    mv "${temp_file}" "${LEARNING_DB}"
}

# 継続監視開始
start_continuous_monitoring() {
    local interval_seconds="${1:-60}"
    
    log "継続監視開始（間隔: ${interval_seconds}秒）"
    
    while true; do
        # 全エラー検出実行
        detect_errors "worker" "all"
        detect_errors "system"
        
        # 学習データ更新
        update_learning_patterns
        
        sleep "${interval_seconds}"
    done
}

# 学習パターン更新
update_learning_patterns() {
    if [ ! -f "${LEARNING_DB}" ]; then
        return 1
    fi
    
    # 新しいエラーパターンの学習ロジック
    # (実装簡略化のため基本構造のみ)
    
    local temp_file=$(mktemp)
    cat "${LEARNING_DB}" | jq ".last_learning_update = \"$(date -Iseconds)\"" > "${temp_file}"
    mv "${temp_file}" "${LEARNING_DB}"
}

# エラーレポート生成
generate_error_report() {
    local report_file="${LOG_DIR}/error-detection-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "${report_file}" << EOF
# エラー検出・自動修正システム レポート

## 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## エラー統計
EOF
    
    if [ -f "${ERROR_DB}" ]; then
        echo "### 検出・修正統計" >> "${report_file}"
        cat "${ERROR_DB}" | jq -r '
            .error_statistics |
            "- 総検出数: " + (.total_detected | tostring),
            "- 自動修正成功: " + (.auto_fixed | tostring),
            "- 手動介入要求: " + (.manual_intervention | tostring)
        ' >> "${report_file}"
    fi
    
    if [ -f "${LEARNING_DB}" ]; then
        echo "" >> "${report_file}"
        echo "### 学習データ" >> "${report_file}"
        cat "${LEARNING_DB}" | jq -r '
            "- 成功修正数: " + (.successful_fixes | length | tostring),
            "- 失敗修正数: " + (.failed_fixes | length | tostring),
            "- 最終学習更新: " + (.last_learning_update // "未実行")
        ' >> "${report_file}"
    fi
    
    cat >> "${report_file}" << EOF

## 最新検出ログ (直近30件)
$(tail -30 "${ERROR_LOG}" 2>/dev/null || echo "ログなし")

---
*自動生成: エラー検出・自動修正システム*
EOF
    
    log "エラーレポート生成: ${report_file}"
    echo "${report_file}"
}

# メイン処理
main() {
    local command=${1:-"help"}
    
    case "${command}" in
        "init")
            initialize_error_patterns
            initialize_learning_database
            create_recovery_scripts
            ;;
        "detect")
            local source="${2:-worker}"
            local target="${3:-all}"
            detect_errors "${source}" "${target}"
            ;;
        "monitor")
            local interval="${2:-60}"
            start_continuous_monitoring "${interval}"
            ;;
        "fix")
            local component="${2:-""}"
            local error_type="${3:-""}"
            if [ -n "${component}" ] && [ -n "${error_type}" ]; then
                attempt_auto_fix "${component}" "${error_type}" "manual"
            else
                echo "エラー: コンポーネントとエラータイプを指定してください"
                exit 1
            fi
            ;;
        "status")
            if [ -f "${ERROR_DB}" ]; then
                echo "📊 エラー検出システム状況"
                echo "========================="
                cat "${ERROR_DB}" | jq '.error_statistics'
            else
                echo "データベース未初期化"
            fi
            ;;
        "report")
            generate_error_report
            ;;
        "help")
            cat << EOF
🔧 エラー検出・自動修正システム v2.0

使用方法:
  $0 init                           # システム初期化
  $0 detect <source> [target]       # エラー検出実行
  $0 monitor [interval]             # 継続監視開始
  $0 fix <component> <error_type>   # 手動修正実行
  $0 status                         # システム状況表示
  $0 report                         # エラーレポート生成

検出ソース: worker, system, logs
対象: all, WORKER1, WORKER2, WORKER3, BOSS1

機能:
- 多段階エラー検出
- 自動修正・復旧
- 学習機能による改善
- 継続監視・アラート
EOF
            ;;
        *)
            echo "エラー: 不明なコマンド '${command}'"
            echo "使用方法: $0 help"
            exit 1
            ;;
    esac
}

# ログディレクトリ作成
mkdir -p "${LOG_DIR}"

# メイン実行
main "$@"