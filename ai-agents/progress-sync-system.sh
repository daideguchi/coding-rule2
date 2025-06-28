#!/bin/bash

# 📊 進捗同期システム v2.0
# WORKER2により設計・実装

set -euo pipefail

# システム設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
SYNC_LOG="${LOG_DIR}/progress-sync.log"
PROGRESS_DB="${SCRIPT_DIR}/progress-database.json"
SYNC_CONFIG="${SCRIPT_DIR}/sync-config.json"
STATUS_BOARD="${SCRIPT_DIR}/../tmp/progress-status-board.json"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${SYNC_LOG}"
}

# 同期設定初期化
initialize_sync_config() {
    cat > "${SYNC_CONFIG}" << 'EOF'
{
  "sync_settings": {
    "interval_seconds": 30,
    "timeout_seconds": 10,
    "max_retries": 3,
    "batch_size": 10
  },
  "sync_levels": {
    "basic": {
      "description": "基本情報同期",
      "fields": ["worker_id", "current_task", "status", "progress_percent", "last_update"],
      "frequency": "high"
    },
    "detailed": {
      "description": "詳細状況同期",
      "fields": ["task_details", "files_modified", "errors", "warnings", "performance_metrics"],
      "frequency": "medium"
    },
    "strategic": {
      "description": "戦略レベル同期",
      "fields": ["overall_plan", "priority_changes", "resource_allocation", "timeline_adjustments"],
      "frequency": "low"
    }
  },
  "workers": {
    "PRESIDENT": {
      "session": "multiagent:0.president",
      "sync_level": ["basic", "detailed", "strategic"],
      "priority": 1
    },
    "BOSS1": {
      "session": "multiagent:0.0", 
      "sync_level": ["basic", "detailed"],
      "priority": 2
    },
    "WORKER1": {
      "session": "multiagent:0.1",
      "sync_level": ["basic"],
      "priority": 3
    },
    "WORKER2": {
      "session": "multiagent:0.2",
      "sync_level": ["basic"],
      "priority": 3
    },
    "WORKER3": {
      "session": "multiagent:0.3",
      "sync_level": ["basic"],
      "priority": 3
    }
  }
}
EOF
    log "同期設定を初期化しました"
}

# 進捗データベース初期化
initialize_progress_database() {
    cat > "${PROGRESS_DB}" << 'EOF'
{
  "last_sync": null,
  "sync_cycle": 0,
  "workers": {
    "PRESIDENT": {
      "status": "standby",
      "current_task": null,
      "progress_percent": 0,
      "last_update": null,
      "session_active": false,
      "performance": {
        "tasks_completed": 0,
        "avg_completion_time": 0,
        "error_count": 0
      }
    },
    "BOSS1": {
      "status": "standby", 
      "current_task": null,
      "progress_percent": 0,
      "last_update": null,
      "session_active": false,
      "performance": {
        "tasks_completed": 0,
        "avg_completion_time": 0,
        "error_count": 0
      }
    },
    "WORKER1": {
      "status": "standby",
      "current_task": null,
      "progress_percent": 0,
      "last_update": null,
      "session_active": false,
      "performance": {
        "tasks_completed": 0,
        "avg_completion_time": 0,
        "error_count": 0
      }
    },
    "WORKER2": {
      "status": "standby",
      "current_task": null,
      "progress_percent": 0,
      "last_update": null,
      "session_active": false,
      "performance": {
        "tasks_completed": 0,
        "avg_completion_time": 0,
        "error_count": 0
      }
    },
    "WORKER3": {
      "status": "standby",
      "current_task": null,
      "progress_percent": 0,
      "last_update": null,
      "session_active": false,
      "performance": {
        "tasks_completed": 0,
        "avg_completion_time": 0,
        "error_count": 0
      }
    }
  },
  "overall": {
    "total_tasks": 0,
    "completed_tasks": 0,
    "in_progress_tasks": 0,
    "failed_tasks": 0,
    "overall_progress": 0,
    "estimated_completion": null
  }
}
EOF
    log "進捗データベースを初期化しました"
}

# ワーカー状態収集
collect_worker_status() {
    local worker="$1"
    local session_name=""
    
    # セッション名決定
    case "${worker}" in
        "PRESIDENT") session_name="multiagent:0.president" ;;
        "BOSS1") session_name="multiagent:0.0" ;;
        "WORKER1") session_name="multiagent:0.1" ;;
        "WORKER2") session_name="multiagent:0.2" ;;
        "WORKER3") session_name="multiagent:0.3" ;;
        *) 
            log "ERROR: 不明なワーカー: ${worker}"
            return 1
            ;;
    esac
    
    local status_data="{}"
    
    # セッション存在確認
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        # 画面出力取得
        local output=$(tmux capture-pane -t "${session_name}" -p 2>/dev/null || echo "")
        local recent_output=$(echo "${output}" | tail -10)
        
        # 状態解析
        local status="unknown"
        local current_task="none"
        local progress=0
        
        # 状態パターン検出
        if echo "${recent_output}" | grep -q ">"; then
            status="ready"
        elif echo "${recent_output}" | grep -qi "作業中\|working\|processing"; then
            status="working"
            # タスク名抽出試行
            current_task=$(echo "${recent_output}" | grep -i "作業\|task" | tail -1 | sed 's/.*作業[：:]\s*//; s/.*task[：:]\s*//' | head -c 50)
        elif echo "${recent_output}" | grep -qi "完了\|完成\|finished\|done"; then
            status="completed"
            progress=100
        elif echo "${recent_output}" | grep -qi "エラー\|失敗\|error\|failed"; then
            status="error"
        else
            status="standby"
        fi
        
        # 進捗推定
        if [ "${status}" = "working" ]; then
            # 簡易進捗推定（作業時間ベース）
            local start_pattern=$(echo "${output}" | grep -n "作業開始\|starting" | tail -1 | cut -d: -f1)
            if [ -n "${start_pattern}" ]; then
                local total_lines=$(echo "${output}" | wc -l)
                local progress_lines=$((total_lines - start_pattern))
                progress=$((progress_lines * 10))  # 簡易計算
                [ ${progress} -gt 100 ] && progress=100
            fi
        fi
        
        # JSON構築
        status_data=$(cat << EOF
{
  "status": "${status}",
  "current_task": "${current_task}",
  "progress_percent": ${progress},
  "last_update": "$(date -Iseconds)",
  "session_active": true,
  "raw_output": $(echo "${recent_output}" | jq -R -s .)
}
EOF
)
        
        log "ワーカー状態収集: ${worker} → ${status} (${progress}%)"
    else
        # セッション非存在
        status_data=$(cat << EOF
{
  "status": "offline",
  "current_task": null,
  "progress_percent": 0,
  "last_update": "$(date -Iseconds)",
  "session_active": false,
  "raw_output": ""
}
EOF
)
        log "ワーカーオフライン: ${worker}"
    fi
    
    echo "${status_data}"
}

# 全ワーカー同期
sync_all_workers() {
    log "全ワーカー同期を開始"
    
    local sync_timestamp=$(date -Iseconds)
    local sync_results=()
    
    # 各ワーカーから状態収集
    for worker in PRESIDENT BOSS1 WORKER1 WORKER2 WORKER3; do
        local worker_status=$(collect_worker_status "${worker}")
        
        # データベース更新
        update_worker_progress "${worker}" "${worker_status}"
        
        sync_results+=("${worker}:OK")
    done
    
    # 全体統計更新
    update_overall_statistics
    
    # 同期サイクル更新
    update_sync_metadata "${sync_timestamp}"
    
    log "全ワーカー同期完了: $(IFS=','; echo "${sync_results[*]}")"
}

# ワーカー進捗更新
update_worker_progress() {
    local worker="$1"
    local status_json="$2"
    
    if [ ! -f "${PROGRESS_DB}" ]; then
        initialize_progress_database
    fi
    
    # データベース更新
    local temp_file=$(mktemp)
    cat "${PROGRESS_DB}" | jq ".workers.${worker} = (.workers.${worker} // {}) * (${status_json} // {})" > "${temp_file}"
    mv "${temp_file}" "${PROGRESS_DB}"
    
    log "ワーカー進捗更新: ${worker}"
}

# 全体統計更新
update_overall_statistics() {
    if [ ! -f "${PROGRESS_DB}" ]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    
    # 統計計算
    local total_workers=5
    local active_workers=$(cat "${PROGRESS_DB}" | jq '[.workers[] | select(.session_active == true)] | length')
    local working_workers=$(cat "${PROGRESS_DB}" | jq '[.workers[] | select(.status == "working")] | length')
    local ready_workers=$(cat "${PROGRESS_DB}" | jq '[.workers[] | select(.status == "ready")] | length')
    local error_workers=$(cat "${PROGRESS_DB}" | jq '[.workers[] | select(.status == "error")] | length')
    
    # 平均進捗計算
    local avg_progress=$(cat "${PROGRESS_DB}" | jq '[.workers[].progress_percent] | add / length')
    
    # 統計更新
    cat "${PROGRESS_DB}" | jq "
        .overall.total_workers = ${total_workers} |
        .overall.active_workers = ${active_workers} |
        .overall.working_workers = ${working_workers} |
        .overall.ready_workers = ${ready_workers} |
        .overall.error_workers = ${error_workers} |
        .overall.average_progress = ${avg_progress} |
        .overall.last_calculated = \"$(date -Iseconds)\"
    " > "${temp_file}"
    
    mv "${temp_file}" "${PROGRESS_DB}"
    
    log "全体統計更新: Active=${active_workers}, Working=${working_workers}, Progress=${avg_progress}%"
}

# 同期メタデータ更新
update_sync_metadata() {
    local sync_timestamp="$1"
    
    if [ ! -f "${PROGRESS_DB}" ]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    cat "${PROGRESS_DB}" | jq "
        .last_sync = \"${sync_timestamp}\" |
        .sync_cycle = (.sync_cycle + 1)
    " > "${temp_file}"
    
    mv "${temp_file}" "${PROGRESS_DB}"
}

# ステータスボード生成
generate_status_board() {
    if [ ! -f "${PROGRESS_DB}" ]; then
        log "ERROR: 進捗データベースが存在しません"
        return 1
    fi
    
    mkdir -p "$(dirname "${STATUS_BOARD}")"
    
    # ステータスボード構築
    cat "${PROGRESS_DB}" | jq '{
        "generated_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "sync_info": {
            "last_sync": .last_sync,
            "sync_cycle": .sync_cycle
        },
        "workers": .workers,
        "overall": .overall,
        "alerts": [
            (.workers | to_entries[] | select(.value.status == "error") | "⚠️ " + .key + ": エラー状態"),
            (.workers | to_entries[] | select(.value.session_active == false) | "🔴 " + .key + ": オフライン"),
            (if .overall.working_workers == 0 then "⏳ 全ワーカー待機中" else empty end)
        ]
    }' > "${STATUS_BOARD}"
    
    log "ステータスボード生成: ${STATUS_BOARD}"
}

# リアルタイム同期開始
start_realtime_sync() {
    local interval_seconds
    if [ -f "${SYNC_CONFIG}" ]; then
        interval_seconds=$(cat "${SYNC_CONFIG}" | jq -r '.sync_settings.interval_seconds')
    else
        interval_seconds=30
    fi
    
    log "リアルタイム同期開始（間隔: ${interval_seconds}秒）"
    
    while true; do
        sync_all_workers
        generate_status_board
        
        # アラート検出・通知
        check_and_alert
        
        sleep "${interval_seconds}"
    done
}

# アラート検出・通知
check_and_alert() {
    if [ ! -f "${PROGRESS_DB}" ]; then
        return 1
    fi
    
    # エラー状態のワーカー検出
    local error_workers=$(cat "${PROGRESS_DB}" | jq -r '.workers | to_entries[] | select(.value.status == "error") | .key')
    if [ -n "${error_workers}" ]; then
        log "🚨 ALERT: エラー状態ワーカー検出: ${error_workers}"
    fi
    
    # オフラインワーカー検出
    local offline_workers=$(cat "${PROGRESS_DB}" | jq -r '.workers | to_entries[] | select(.value.session_active == false) | .key')
    if [ -n "${offline_workers}" ]; then
        log "⚠️ WARNING: オフラインワーカー: ${offline_workers}"
    fi
    
    # 長時間無応答検出
    local stale_workers=$(cat "${PROGRESS_DB}" | jq -r "
        .workers | to_entries[] | 
        select(.value.last_update and (now - (.value.last_update | fromdate)) > 300) | 
        .key
    ")
    if [ -n "${stale_workers}" ]; then
        log "⏰ WARNING: 長時間無応答ワーカー: ${stale_workers}"
    fi
}

# 進捗レポート生成
generate_progress_report() {
    local report_file="${LOG_DIR}/progress-sync-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "${report_file}" << EOF
# 進捗同期システム レポート

## 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## 全体状況
EOF
    
    if [ -f "${PROGRESS_DB}" ]; then
        echo "### システム統計" >> "${report_file}"
        cat "${PROGRESS_DB}" | jq -r '
            "- 同期サイクル: " + (.sync_cycle | tostring),
            "- 最終同期: " + (.last_sync // "未実行"),
            "- アクティブワーカー: " + (.overall.active_workers | tostring) + "/" + (.overall.total_workers | tostring),
            "- 作業中ワーカー: " + (.overall.working_workers | tostring),
            "- 平均進捗: " + (.overall.average_progress | tostring) + "%"
        ' >> "${report_file}"
        
        echo "" >> "${report_file}"
        echo "### ワーカー詳細状況" >> "${report_file}"
        cat "${PROGRESS_DB}" | jq -r '
            .workers | to_entries[] |
            "- **" + .key + "**: " + .value.status + " (" + (.value.progress_percent | tostring) + "%) - " + (.value.current_task // "タスクなし")
        ' >> "${report_file}"
    else
        echo "データベースなし" >> "${report_file}"
    fi
    
    cat >> "${report_file}" << EOF

## 最新同期ログ (直近30件)
$(tail -30 "${SYNC_LOG}" 2>/dev/null || echo "ログなし")

---
*自動生成: 進捗同期システム*
EOF
    
    log "進捗レポート生成: ${report_file}"
    echo "${report_file}"
}

# 手動同期実行
manual_sync() {
    local worker="${1:-all}"
    
    if [ "${worker}" = "all" ]; then
        sync_all_workers
        generate_status_board
    else
        # 単一ワーカー同期
        local worker_status=$(collect_worker_status "${worker}")
        update_worker_progress "${worker}" "${worker_status}"
        update_overall_statistics
        log "手動同期完了: ${worker}"
    fi
}

# 進捗データリセット
reset_progress_data() {
    log "進捗データをリセット"
    initialize_progress_database
    rm -f "${STATUS_BOARD}"
}

# メイン処理
main() {
    local command=${1:-"help"}
    
    case "${command}" in
        "init")
            initialize_sync_config
            initialize_progress_database
            ;;
        "start")
            start_realtime_sync
            ;;
        "sync")
            local worker="${2:-all}"
            manual_sync "${worker}"
            ;;
        "status")
            if [ -f "${STATUS_BOARD}" ]; then
                cat "${STATUS_BOARD}" | jq .
            else
                echo "ステータスボードが存在しません。'sync'を実行してください。"
            fi
            ;;
        "board")
            generate_status_board
            echo "ステータスボード生成: ${STATUS_BOARD}"
            ;;
        "report")
            generate_progress_report
            ;;
        "reset")
            reset_progress_data
            ;;
        "check")
            check_and_alert
            ;;
        "help")
            cat << EOF
📊 進捗同期システム v2.0

使用方法:
  $0 init                    # システム初期化
  $0 start                   # リアルタイム同期開始
  $0 sync [worker]           # 手動同期実行
  $0 status                  # 現在状況表示
  $0 board                   # ステータスボード生成
  $0 report                  # 進捗レポート生成
  $0 reset                   # 進捗データリセット
  $0 check                   # アラート確認

ワーカー: PRESIDENT, BOSS1, WORKER1, WORKER2, WORKER3

機能:
- リアルタイム進捗同期
- 全体状況の可視化
- 自動アラート・通知
- パフォーマンス追跡
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