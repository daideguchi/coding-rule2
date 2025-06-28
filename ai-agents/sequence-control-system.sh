#!/bin/bash

# ⚡ 作業順序制御システム v2.0
# WORKER2により設計・実装

set -euo pipefail

# システム設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
SEQUENCE_LOG="${LOG_DIR}/sequence-control.log"
DEPENDENCY_DB="${SCRIPT_DIR}/task-dependencies.json"
EXECUTION_QUEUE="${SCRIPT_DIR}/execution-queue.json"
LOCK_DIR="${SCRIPT_DIR}/locks"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${SEQUENCE_LOG}"
}

# 依存関係データベース初期化
initialize_dependencies() {
    cat > "${DEPENDENCY_DB}" << 'EOF'
{
  "task_types": {
    "analysis": {
      "dependencies": [],
      "can_parallel": true,
      "priority": 1,
      "estimated_time": 300
    },
    "design": {
      "dependencies": ["analysis"],
      "can_parallel": true,
      "priority": 2,
      "estimated_time": 600
    },
    "implementation": {
      "dependencies": ["design"],
      "can_parallel": true,
      "priority": 3,
      "estimated_time": 1200
    },
    "integration": {
      "dependencies": ["implementation"],
      "can_parallel": false,
      "priority": 4,
      "estimated_time": 900
    },
    "testing": {
      "dependencies": ["integration"],
      "can_parallel": true,
      "priority": 5,
      "estimated_time": 600
    },
    "documentation": {
      "dependencies": ["testing"],
      "can_parallel": true,
      "priority": 6,
      "estimated_time": 300
    }
  },
  "worker_dependencies": {
    "WORKER1": {
      "conflicts": ["WORKER2_backend", "WORKER3_system"],
      "collaborates": ["WORKER3_ui", "WORKER2_api"]
    },
    "WORKER2": {
      "conflicts": ["WORKER1_frontend", "WORKER3_ui"], 
      "collaborates": ["WORKER1_api", "WORKER3_data"]
    },
    "WORKER3": {
      "conflicts": ["WORKER1_implementation", "WORKER2_backend"],
      "collaborates": ["WORKER1_design", "WORKER2_docs"]
    }
  },
  "resource_dependencies": {
    "file_system": ["WORKER1", "WORKER2", "WORKER3"],
    "git_repository": ["WORKER1", "WORKER2", "WORKER3"],
    "documentation": ["WORKER1", "WORKER3"],
    "configuration": ["WORKER2"]
  }
}
EOF
    log "依存関係データベースを初期化しました"
}

# 実行キュー初期化
initialize_execution_queue() {
    cat > "${EXECUTION_QUEUE}" << 'EOF'
{
  "phases": {
    "phase_1": {
      "name": "独立作業フェーズ",
      "parallel": true,
      "tasks": []
    },
    "phase_2": {
      "name": "統合作業フェーズ", 
      "parallel": false,
      "tasks": []
    },
    "phase_3": {
      "name": "検証・完成フェーズ",
      "parallel": true,
      "tasks": []
    }
  },
  "current_phase": "phase_1",
  "execution_status": "ready"
}
EOF
    log "実行キューを初期化しました"
}

# タスク依存関係解析
analyze_dependencies() {
    local task_id="$1"
    local task_type="$2"
    local worker="$3"
    
    log "依存関係解析開始: ${task_id} (${task_type}) → ${worker}"
    
    # 依存タスク確認
    local dependencies=()
    if [ -f "${DEPENDENCY_DB}" ]; then
        local deps=$(cat "${DEPENDENCY_DB}" | jq -r ".task_types.${task_type}.dependencies[]?" 2>/dev/null || echo "")
        if [ -n "${deps}" ]; then
            mapfile -t dependencies <<< "${deps}"
        fi
    fi
    
    # ワーカー競合確認
    local worker_conflicts=()
    if [ -f "${DEPENDENCY_DB}" ]; then
        local conflicts=$(cat "${DEPENDENCY_DB}" | jq -r ".worker_dependencies.${worker}.conflicts[]?" 2>/dev/null || echo "")
        if [ -n "${conflicts}" ]; then
            mapfile -t worker_conflicts <<< "${conflicts}"
        fi
    fi
    
    # 結果出力
    local result=$(cat << EOF
{
  "task_id": "${task_id}",
  "task_type": "${task_type}",
  "worker": "${worker}",
  "dependencies": [$(printf '"%s",' "${dependencies[@]}" | sed 's/,$//')]
  "conflicts": [$(printf '"%s",' "${worker_conflicts[@]}" | sed 's/,$//')]
  "can_parallel": $(cat "${DEPENDENCY_DB}" | jq ".task_types.${task_type}.can_parallel" 2>/dev/null || echo "true"),
  "priority": $(cat "${DEPENDENCY_DB}" | jq ".task_types.${task_type}.priority" 2>/dev/null || echo "3"),
  "estimated_time": $(cat "${DEPENDENCY_DB}" | jq ".task_types.${task_type}.estimated_time" 2>/dev/null || echo "600")
}
EOF
)
    
    log "依存関係解析完了: ${task_id}"
    echo "${result}"
}

# 最適実行順序決定
determine_execution_order() {
    local task_list=("$@")
    local ordered_tasks=()
    local phase_assignments=()
    
    log "最適実行順序の決定を開始（タスク数: ${#task_list[@]}）"
    
    # 各タスクの依存関係解析
    local task_data=()
    for task in "${task_list[@]}"; do
        # タスク情報パース（例: "task1:analysis:WORKER1"）
        IFS=':' read -r task_id task_type worker <<< "${task}"
        
        local analysis=$(analyze_dependencies "${task_id}" "${task_type}" "${worker}")
        task_data+=("${analysis}")
    done
    
    # 優先度ベースソート
    local sorted_tasks=$(printf '%s\n' "${task_data[@]}" | jq -s 'sort_by(.priority)')
    
    # フェーズ分割
    local phase1=()  # 独立並列実行可能
    local phase2=()  # 順序実行必須
    local phase3=()  # 最終検証・統合
    
    echo "${sorted_tasks}" | jq -c '.[]' | while IFS= read -r task; do
        local can_parallel=$(echo "${task}" | jq -r '.can_parallel')
        local priority=$(echo "${task}" | jq -r '.priority')
        local task_id=$(echo "${task}" | jq -r '.task_id')
        
        if [ "${priority}" -le 2 ] && [ "${can_parallel}" = "true" ]; then
            phase1+=("${task_id}")
        elif [ "${priority}" -le 4 ]; then
            phase2+=("${task_id}")
        else
            phase3+=("${task_id}")
        fi
    done
    
    log "実行順序決定完了 - Phase1: ${#phase1[@]} Phase2: ${#phase2[@]} Phase3: ${#phase3[@]}"
}

# 並列処理最適化
optimize_parallel_execution() {
    local phase="$1"
    local task_list=("${@:2}")
    
    log "並列処理最適化開始: ${phase}"
    
    local parallel_groups=()
    local current_group=()
    local used_workers=()
    
    for task in "${task_list[@]}"; do
        IFS=':' read -r task_id task_type worker <<< "${task}"
        
        # ワーカー競合チェック
        local can_add=true
        for used_worker in "${used_workers[@]}"; do
            if check_worker_conflict "${worker}" "${used_worker}"; then
                can_add=false
                break
            fi
        done
        
        if [ "${can_add}" = true ]; then
            current_group+=("${task}")
            used_workers+=("${worker}")
        else
            # 新しいグループ開始
            if [ ${#current_group[@]} -gt 0 ]; then
                parallel_groups+=("$(IFS=','; echo "${current_group[*]}")")
            fi
            current_group=("${task}")
            used_workers=("${worker}")
        fi
    done
    
    # 最後のグループ追加
    if [ ${#current_group[@]} -gt 0 ]; then
        parallel_groups+=("$(IFS=','; echo "${current_group[*]}")")
    fi
    
    log "並列グループ数: ${#parallel_groups[@]}"
    printf '%s\n' "${parallel_groups[@]}"
}

# ワーカー競合チェック
check_worker_conflict() {
    local worker1="$1"
    local worker2="$2"
    
    if [ "${worker1}" = "${worker2}" ]; then
        return 0  # 同一ワーカーは競合
    fi
    
    # 依存関係データベースから競合情報取得
    if [ -f "${DEPENDENCY_DB}" ]; then
        local conflicts=$(cat "${DEPENDENCY_DB}" | jq -r ".worker_dependencies.${worker1}.conflicts[]?" 2>/dev/null || echo "")
        if echo "${conflicts}" | grep -q "${worker2}"; then
            return 0  # 競合あり
        fi
    fi
    
    return 1  # 競合なし
}

# リソースロック管理
acquire_resource_lock() {
    local resource="$1"
    local worker="$2"
    local lock_file="${LOCK_DIR}/${resource}.lock"
    
    mkdir -p "${LOCK_DIR}"
    
    # ロック取得試行
    local max_attempts=30
    local attempt=0
    
    while [ ${attempt} -lt ${max_attempts} ]; do
        if mkdir "${lock_file}" 2>/dev/null; then
            echo "${worker}" > "${lock_file}/owner"
            echo "$(date +%s)" > "${lock_file}/timestamp"
            log "リソースロック取得: ${resource} → ${worker}"
            return 0
        fi
        
        # 既存ロック確認
        if [ -f "${lock_file}/timestamp" ]; then
            local lock_time=$(cat "${lock_file}/timestamp")
            local current_time=$(date +%s)
            local lock_age=$((current_time - lock_time))
            
            # 古いロック（10分以上）は強制解除
            if [ ${lock_age} -gt 600 ]; then
                log "古いロックを強制解除: ${resource}"
                release_resource_lock "${resource}"
                continue
            fi
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log "ERROR: リソースロック取得失敗: ${resource}"
    return 1
}

# リソースロック解除
release_resource_lock() {
    local resource="$1"
    local lock_file="${LOCK_DIR}/${resource}.lock"
    
    if [ -d "${lock_file}" ]; then
        rm -rf "${lock_file}"
        log "リソースロック解除: ${resource}"
    fi
}

# タスク実行制御
execute_task_sequence() {
    local phase="$1"
    local parallel_group="$2"
    
    log "タスク実行開始: ${phase} - ${parallel_group}"
    
    IFS=',' read -ra tasks <<< "${parallel_group}"
    local pids=()
    
    # 並列実行開始
    for task in "${tasks[@]}"; do
        IFS=':' read -r task_id task_type worker <<< "${task}"
        
        # リソースロック取得
        if ! acquire_resource_lock "worker_${worker}" "${worker}"; then
            log "ERROR: ワーカーロック取得失敗: ${worker}"
            continue
        fi
        
        # タスク実行（バックグラウンド）
        execute_single_task "${task_id}" "${task_type}" "${worker}" &
        local pid=$!
        pids+=("${pid}")
        
        log "タスク実行開始: ${task_id} (PID: ${pid})"
    done
    
    # 完了待ち
    local all_success=true
    for pid in "${pids[@]}"; do
        if ! wait "${pid}"; then
            log "ERROR: タスク実行失敗 (PID: ${pid})"
            all_success=false
        fi
    done
    
    # リソースロック解除
    for task in "${tasks[@]}"; do
        IFS=':' read -r task_id task_type worker <<< "${task}"
        release_resource_lock "worker_${worker}"
    done
    
    if [ "${all_success}" = true ]; then
        log "並列グループ実行完了: ${parallel_group}"
        return 0
    else
        log "ERROR: 並列グループ実行失敗: ${parallel_group}"
        return 1
    fi
}

# 単一タスク実行
execute_single_task() {
    local task_id="$1"
    local task_type="$2"
    local worker="$3"
    
    log "単一タスク実行: ${task_id} → ${worker}"
    
    # ワーカーセッション確認
    local session="multiagent:0.${worker: -1}"
    if ! tmux has-session -t "${session}" 2>/dev/null; then
        log "ERROR: ワーカーセッション不存在: ${session}"
        return 1
    fi
    
    # タスク指示送信
    local instruction="タスク実行: ${task_id} (${task_type})"
    tmux send-keys -t "${session}" "${instruction}" C-m
    
    # 実行時間推定
    local estimated_time
    if [ -f "${DEPENDENCY_DB}" ]; then
        estimated_time=$(cat "${DEPENDENCY_DB}" | jq ".task_types.${task_type}.estimated_time" 2>/dev/null || echo "600")
    else
        estimated_time=600
    fi
    
    # 実行監視
    local start_time=$(date +%s)
    local timeout_time=$((start_time + estimated_time + 300))  # +5分のバッファ
    
    while [ $(date +%s) -lt ${timeout_time} ]; do
        local output=$(tmux capture-pane -t "${session}" -p | tail -5)
        
        # 完了パターン検出
        if echo "${output}" | grep -q "完了\|完成\|finished\|done"; then
            log "タスク完了検出: ${task_id}"
            return 0
        fi
        
        # エラーパターン検出
        if echo "${output}" | grep -q "エラー\|失敗\|error\|failed"; then
            log "ERROR: タスク実行エラー: ${task_id}"
            return 1
        fi
        
        sleep 10
    done
    
    log "WARNING: タスクタイムアウト: ${task_id}"
    return 1
}

# ボトルネック解消
resolve_bottlenecks() {
    log "ボトルネック解析・解消を開始"
    
    # 実行中タスクの確認
    local running_tasks=()
    local waiting_tasks=()
    
    # ワーカー使用状況確認
    for worker in 1 2 3; do
        if [ -f "${LOCK_DIR}/worker_WORKER${worker}.lock" ]; then
            log "ワーカー${worker}: 使用中"
        else
            log "ワーカー${worker}: 待機中"
            # 待機中ワーカーにタスク割当可能
        fi
    done
    
    # リソース競合解消
    for lock_file in "${LOCK_DIR}"/*.lock; do
        if [ -f "${lock_file}/timestamp" ]; then
            local lock_time=$(cat "${lock_file}/timestamp")
            local current_time=$(date +%s)
            local lock_age=$((current_time - lock_time))
            
            if [ ${lock_age} -gt 600 ]; then
                local resource=$(basename "${lock_file}" .lock)
                log "古いロック解除: ${resource}"
                release_resource_lock "${resource}"
            fi
        fi
    done
}

# 進捗監視
monitor_progress() {
    local monitoring_interval=30
    
    log "進捗監視を開始（間隔: ${monitoring_interval}秒）"
    
    while true; do
        # 実行状況確認
        local active_workers=0
        for worker in 1 2 3; do
            if [ -f "${LOCK_DIR}/worker_WORKER${worker}.lock" ]; then
                active_workers=$((active_workers + 1))
            fi
        done
        
        log "進捗状況 - アクティブワーカー: ${active_workers}/3"
        
        # ボトルネック解消
        resolve_bottlenecks
        
        # 監視終了条件
        if [ ${active_workers} -eq 0 ]; then
            log "全タスク完了 - 監視終了"
            break
        fi
        
        sleep ${monitoring_interval}
    done
}

# 実行レポート生成
generate_execution_report() {
    local report_file="${LOG_DIR}/sequence-execution-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "${report_file}" << EOF
# 作業順序制御システム 実行レポート

## 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## 実行統計
EOF
    
    # ロック状況
    echo "### リソースロック状況" >> "${report_file}"
    if [ -d "${LOCK_DIR}" ] && [ -n "$(ls -A "${LOCK_DIR}" 2>/dev/null)" ]; then
        for lock_file in "${LOCK_DIR}"/*.lock; do
            if [ -d "${lock_file}" ]; then
                local resource=$(basename "${lock_file}" .lock)
                local owner=$(cat "${lock_file}/owner" 2>/dev/null || echo "unknown")
                echo "- ${resource}: ${owner}" >> "${report_file}"
            fi
        done
    else
        echo "- ロックなし" >> "${report_file}"
    fi
    
    cat >> "${report_file}" << EOF

## 最新実行ログ (直近30件)
$(tail -30 "${SEQUENCE_LOG}" 2>/dev/null || echo "ログなし")

---
*自動生成: 作業順序制御システム*
EOF
    
    log "実行レポート生成: ${report_file}"
    echo "${report_file}"
}

# メイン処理
main() {
    local command=${1:-"help"}
    
    case "${command}" in
        "init")
            initialize_dependencies
            initialize_execution_queue
            mkdir -p "${LOCK_DIR}"
            ;;
        "analyze")
            local task_id="${2:-task1}"
            local task_type="${3:-analysis}"
            local worker="${4:-WORKER1}"
            analyze_dependencies "${task_id}" "${task_type}" "${worker}"
            ;;
        "execute")
            shift
            local task_list=("$@")
            if [ ${#task_list[@]} -gt 0 ]; then
                determine_execution_order "${task_list[@]}"
            else
                echo "エラー: タスクリストを指定してください"
                exit 1
            fi
            ;;
        "monitor")
            monitor_progress
            ;;
        "resolve")
            resolve_bottlenecks
            ;;
        "lock")
            local resource="${2:-""}"
            local worker="${3:-""}"
            if [ -n "${resource}" ] && [ -n "${worker}" ]; then
                acquire_resource_lock "${resource}" "${worker}"
            else
                echo "エラー: リソース名とワーカー名を指定してください"
                exit 1
            fi
            ;;
        "unlock")
            local resource="${2:-""}"
            if [ -n "${resource}" ]; then
                release_resource_lock "${resource}"
            else
                echo "エラー: リソース名を指定してください"
                exit 1
            fi
            ;;
        "status")
            echo "📊 作業順序制御システム状況"
            echo "================================="
            echo "ロック状況:"
            if [ -d "${LOCK_DIR}" ] && [ -n "$(ls -A "${LOCK_DIR}" 2>/dev/null)" ]; then
                for lock_file in "${LOCK_DIR}"/*.lock; do
                    if [ -d "${lock_file}" ]; then
                        local resource=$(basename "${lock_file}" .lock)
                        local owner=$(cat "${lock_file}/owner" 2>/dev/null || echo "unknown")
                        echo "  - ${resource}: ${owner}"
                    fi
                done
            else
                echo "  - ロックなし"
            fi
            ;;
        "report")
            generate_execution_report
            ;;
        "help")
            cat << EOF
⚡ 作業順序制御システム v2.0

使用方法:
  $0 init                               # システム初期化
  $0 analyze <task_id> <type> <worker>  # 依存関係解析
  $0 execute <task1:type:worker> ...    # タスク実行
  $0 monitor                            # 進捗監視
  $0 resolve                            # ボトルネック解消
  $0 lock <resource> <worker>           # リソースロック
  $0 unlock <resource>                  # ロック解除
  $0 status                             # 現在状況表示
  $0 report                             # 実行レポート生成

タスク形式: task_id:task_type:worker
例: task1:analysis:WORKER1

機能:
- 依存関係自動解析
- 最適実行順序決定
- 並列処理最大化
- リソース競合回避
- ボトルネック解消
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