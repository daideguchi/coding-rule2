#!/bin/bash

# 🛡️ ワーカー暴走防止システム v2.0
# WORKER2により設計・実装

set -euo pipefail

# システム設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
CONTROL_LOG="${LOG_DIR}/worker-control.log"
STATUS_FILE="${SCRIPT_DIR}/worker-status.json"
ALERT_LOG="${LOG_DIR}/worker-alerts.log"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${CONTROL_LOG}"
}

alert() {
    echo "[ALERT][$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${ALERT_LOG}"
    log "🚨 ALERT: $1"
}

# ワーカー状態監視
monitor_worker_status() {
    local worker=$1
    local session="multiagent:0.${worker}"
    
    # セッション存在確認
    if ! tmux has-session -t "${session}" 2>/dev/null; then
        alert "ワーカー${worker}のセッションが存在しません"
        return 1
    fi
    
    # 最新の画面出力を取得
    local output=$(tmux capture-pane -t "${session}" -p | tail -10)
    
    # 暴走パターン検出
    if echo "${output}" | grep -q "Error\|Failed\|Exception"; then
        alert "ワーカー${worker}でエラーが検出されました"
        emergency_stop_worker "${worker}"
        return 1
    fi
    
    # 長時間の応答なし検出
    local last_activity=$(tmux display-message -t "${session}" -p '#{pane_activity}')
    local current_time=$(date +%s)
    local activity_diff=$((current_time - last_activity))
    
    if [ "${activity_diff}" -gt 600 ]; then  # 10分以上無応答
        alert "ワーカー${worker}が10分以上無応答です"
        check_worker_health "${worker}"
    fi
    
    log "ワーカー${worker}: 正常稼働中"
    return 0
}

# ワーカー健康状態チェック
check_worker_health() {
    local worker=$1
    local session="multiagent:0.${worker}"
    
    log "ワーカー${worker}の健康状態をチェック中..."
    
    # プロンプトの確認
    tmux send-keys -t "${session}" "" C-m
    sleep 2
    
    local output=$(tmux capture-pane -t "${session}" -p | tail -5)
    
    if echo "${output}" | grep -q ">"; then
        log "ワーカー${worker}: プロンプト正常"
        return 0
    else
        alert "ワーカー${worker}: プロンプト異常 - 復旧を試行"
        recover_worker "${worker}"
        return 1
    fi
}

# 緊急停止機能
emergency_stop_worker() {
    local worker=$1
    local session="multiagent:0.${worker}"
    
    alert "ワーカー${worker}を緊急停止します"
    
    # Ctrl+C送信
    tmux send-keys -t "${session}" C-c C-c C-c
    sleep 2
    
    # 強制終了コマンド
    tmux send-keys -t "${session}" "exit" C-m
    sleep 1
    
    # セッションを再作成
    tmux kill-session -t "${session}" 2>/dev/null || true
    sleep 1
    
    # ワーカー再起動
    restart_worker "${worker}"
    
    log "ワーカー${worker}の緊急停止・再起動が完了しました"
}

# ワーカー復旧
recover_worker() {
    local worker=$1
    local session="multiagent:0.${worker}"
    
    log "ワーカー${worker}の復旧を開始..."
    
    # プロンプト復旧試行
    tmux send-keys -t "${session}" C-c
    sleep 1
    tmux send-keys -t "${session}" "clear" C-m
    sleep 1
    
    # Claudeプロンプト再表示
    tmux send-keys -t "${session}" "" C-m
    sleep 2
    
    if check_worker_health "${worker}"; then
        log "ワーカー${worker}: 復旧成功"
        return 0
    else
        alert "ワーカー${worker}: 復旧失敗 - 再起動を実行"
        restart_worker "${worker}"
        return 1
    fi
}

# ワーカー再起動
restart_worker() {
    local worker=$1
    local session="multiagent:0.${worker}"
    
    log "ワーカー${worker}を再起動中..."
    
    # セッション終了
    tmux kill-session -t "${session}" 2>/dev/null || true
    sleep 2
    
    # 新セッション作成
    tmux new-session -d -s "${session}"
    sleep 1
    
    # Claude起動
    tmux send-keys -t "${session}" "claude" C-m
    sleep 3
    
    # ワーカー指示書読み込み
    tmux send-keys -t "${session}" "WORKER${worker}として ./ai-agents/instructions/worker.md の指示に従い、作業準備を整えてください。" C-m
    sleep 2
    
    log "ワーカー${worker}の再起動が完了しました"
}

# 作業権限チェック
check_work_permission() {
    local worker=$1
    local task=$2
    
    # BOSS1からの指示確認
    if [ ! -f "${SCRIPT_DIR}/boss-instructions.log" ]; then
        alert "ワーカー${worker}: BOSS1からの正式指示なしで作業を試行"
        return 1
    fi
    
    # 最新指示の確認
    local latest_instruction=$(tail -1 "${SCRIPT_DIR}/boss-instructions.log")
    
    if echo "${latest_instruction}" | grep -q "WORKER${worker}"; then
        log "ワーカー${worker}: 作業権限確認済み"
        return 0
    else
        alert "ワーカー${worker}: 権限外の作業を試行 - ${task}"
        return 1
    fi
}

# 作業範囲制限チェック
check_work_scope() {
    local worker=$1
    local file_path=$2
    
    case "${worker}" in
        "1")  # WORKER1 - フロントエンド専門
            if [[ "${file_path}" =~ \.(js|jsx|ts|tsx|css|scss|html|md)$ ]]; then
                return 0
            else
                alert "ワーカー1: 専門外ファイルへの操作を試行 - ${file_path}"
                return 1
            fi
            ;;
        "2")  # WORKER2 - バックエンド専門
            if [[ "${file_path}" =~ \.(sh|py|json|yaml|yml|conf|cfg|md)$ ]]; then
                return 0
            else
                alert "ワーカー2: 専門外ファイルへの操作を試行 - ${file_path}"
                return 1
            fi
            ;;
        "3")  # WORKER3 - UI/UX専門
            if [[ "${file_path}" =~ \.(md|css|scss|html|json|yaml|yml)$ ]]; then
                return 0
            else
                alert "ワーカー3: 専門外ファイルへの操作を試行 - ${file_path}"
                return 1
            fi
            ;;
        *)
            alert "不明なワーカー番号: ${worker}"
            return 1
            ;;
    esac
}

# リアルタイム監視開始
start_monitoring() {
    log "🛡️ ワーカー暴走防止システムを開始"
    
    while true; do
        for worker in 1 2 3; do
            if tmux has-session -t "multiagent:0.${worker}" 2>/dev/null; then
                monitor_worker_status "${worker}"
            fi
        done
        
        sleep 30  # 30秒間隔で監視
    done
}

# システム停止
stop_monitoring() {
    log "🛡️ ワーカー暴走防止システムを停止"
    # 監視プロセスを終了
    pkill -f "worker-control-system.sh" 2>/dev/null || true
}

# 状況レポート生成
generate_status_report() {
    local report_file="${LOG_DIR}/worker-control-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "${report_file}" << EOF
# ワーカー制御システム状況レポート

## 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## ワーカー稼働状況
EOF
    
    for worker in 1 2 3; do
        if tmux has-session -t "multiagent:0.${worker}" 2>/dev/null; then
            echo "- ✅ WORKER${worker}: 稼働中" >> "${report_file}"
        else
            echo "- ❌ WORKER${worker}: 停止中" >> "${report_file}"
        fi
    done
    
    cat >> "${report_file}" << EOF

## 最新アラート (直近10件)
$(tail -10 "${ALERT_LOG}" 2>/dev/null || echo "アラートなし")

## 制御ログ (直近20件)
$(tail -20 "${CONTROL_LOG}" 2>/dev/null || echo "ログなし")

---
*自動生成: ワーカー暴走防止システム*
EOF
    
    log "状況レポートを生成: ${report_file}"
    echo "${report_file}"
}

# メイン処理
main() {
    local command=${1:-"help"}
    
    case "${command}" in
        "start")
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "check")
            for worker in 1 2 3; do
                if tmux has-session -t "multiagent:0.${worker}" 2>/dev/null; then
                    monitor_worker_status "${worker}"
                fi
            done
            ;;
        "report")
            generate_status_report
            ;;
        "restart")
            local worker=${2:-""}
            if [ -n "${worker}" ]; then
                restart_worker "${worker}"
            else
                echo "エラー: ワーカー番号を指定してください"
                exit 1
            fi
            ;;
        "emergency-stop")
            local worker=${2:-""}
            if [ -n "${worker}" ]; then
                emergency_stop_worker "${worker}"
            else
                echo "エラー: ワーカー番号を指定してください"
                exit 1
            fi
            ;;
        "help")
            cat << EOF
🛡️ ワーカー暴走防止システム v2.0

使用方法:
  $0 start                    # 監視開始
  $0 stop                     # 監視停止
  $0 check                    # 現在状況確認
  $0 report                   # 状況レポート生成
  $0 restart <worker>         # ワーカー再起動
  $0 emergency-stop <worker>  # 緊急停止

ワーカー番号: 1, 2, 3

機能:
- リアルタイム暴走監視
- 自動エラー検出・対処
- 作業権限・範囲制限
- 緊急停止・復旧機能
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