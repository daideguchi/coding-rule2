#!/bin/bash

# 👥 役割分担明確化システム v2.0
# WORKER2により設計・実装

set -euo pipefail

# システム設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
ROLE_LOG="${LOG_DIR}/role-assignment.log"
TASK_DB="${SCRIPT_DIR}/task-assignments.json"
ROLE_CONFIG="${SCRIPT_DIR}/role-definitions.json"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${ROLE_LOG}"
}

# 役割定義初期化
initialize_roles() {
    cat > "${ROLE_CONFIG}" << 'EOF'
{
  "roles": {
    "PRESIDENT": {
      "id": "president",
      "name": "PRESIDENT",
      "specialties": ["organization_management", "quality_assurance", "user_communication", "strategic_planning"],
      "responsibilities": ["全体責任", "最終判断", "品質保証", "ユーザー対応"],
      "restrictions": ["直接作業禁止", "単独判断時は承認必須"],
      "priority": 1
    },
    "BOSS1": {
      "id": "boss1", 
      "name": "BOSS1",
      "specialties": ["team_management", "task_distribution", "progress_monitoring", "quality_control"],
      "responsibilities": ["作業分配", "進捗管理", "チーム統制", "品質統制"],
      "restrictions": ["PRESIDENT承認なしの重要判断禁止"],
      "priority": 2
    },
    "WORKER1": {
      "id": "worker1",
      "name": "WORKER1", 
      "specialties": ["frontend", "ui_implementation", "documentation", "user_experience"],
      "responsibilities": ["UI/UX実装", "フロントエンド開発", "ドキュメント作成", "ユーザー体験"],
      "restrictions": ["バックエンド作業禁止", "システム設計変更禁止"],
      "file_types": [".js", ".jsx", ".ts", ".tsx", ".css", ".scss", ".html", ".md"],
      "priority": 3
    },
    "WORKER2": {
      "id": "worker2",
      "name": "WORKER2",
      "specialties": ["backend", "system_architecture", "api_development", "infrastructure"],
      "responsibilities": ["システム構築", "API開発", "インフラ管理", "制御システム"],
      "restrictions": ["フロントエンド実装禁止", "UI設計禁止"],
      "file_types": [".sh", ".py", ".json", ".yaml", ".yml", ".conf", ".cfg", ".md"],
      "priority": 3
    },
    "WORKER3": {
      "id": "worker3",
      "name": "WORKER3",
      "specialties": ["ui_design", "ux_design", "document_organization", "usability"],
      "responsibilities": ["UI/UXデザイン", "文書整理", "ユーザビリティ", "デザインシステム"],
      "restrictions": ["技術実装禁止", "システム設計禁止"],
      "file_types": [".md", ".css", ".scss", ".html", ".json", ".yaml", ".yml"],
      "priority": 3
    }
  }
}
EOF
    log "役割定義を初期化しました"
}

# タスク分類
classify_task() {
    local task_description="$1"
    local task_type=""
    
    # キーワードベース分類
    if echo "${task_description}" | grep -qi "frontend\|ui\|ux\|css\|html\|javascript\|react\|vue"; then
        task_type="frontend"
    elif echo "${task_description}" | grep -qi "backend\|server\|api\|database\|system\|infrastructure\|bash\|python"; then
        task_type="backend"
    elif echo "${task_description}" | grep -qi "design\|document\|organize\|usability\|style\|layout"; then
        task_type="design"
    elif echo "${task_description}" | grep -qi "manage\|coordinate\|supervise\|control\|monitor"; then
        task_type="management"
    elif echo "${task_description}" | grep -qi "strategy\|decision\|approve\|overall\|quality"; then
        task_type="executive"
    else
        task_type="general"
    fi
    
    echo "${task_type}"
}

# 最適ワーカー選定
select_optimal_worker() {
    local task_type="$1"
    local task_complexity="$2"
    local selected_worker=""
    
    case "${task_type}" in
        "executive")
            selected_worker="PRESIDENT"
            ;;
        "management")
            selected_worker="BOSS1"
            ;;
        "frontend")
            selected_worker="WORKER1"
            ;;
        "backend")
            selected_worker="WORKER2"
            ;;
        "design")
            selected_worker="WORKER3"
            ;;
        "general")
            # 複雑度に基づいて選定
            case "${task_complexity}" in
                "high")
                    selected_worker="BOSS1"
                    ;;
                "medium")
                    selected_worker="WORKER2"
                    ;;
                "low")
                    selected_worker="WORKER3"
                    ;;
                *)
                    selected_worker="WORKER1"
                    ;;
            esac
            ;;
        *)
            selected_worker="BOSS1"
            ;;
    esac
    
    echo "${selected_worker}"
}

# タスク複雑度評価
evaluate_task_complexity() {
    local task_description="$1"
    local complexity="medium"
    
    # 高複雑度キーワード
    if echo "${task_description}" | grep -qi "system\|architecture\|integration\|complex\|multiple\|comprehensive"; then
        complexity="high"
    # 低複雑度キーワード
    elif echo "${task_description}" | grep -qi "simple\|basic\|single\|quick\|small\|minor"; then
        complexity="low"
    fi
    
    echo "${complexity}"
}

# 作業権限確認
check_work_authorization() {
    local worker="$1"
    local file_path="$2"
    local authorized=false
    
    if [ ! -f "${ROLE_CONFIG}" ]; then
        log "ERROR: 役割設定ファイルが見つかりません"
        return 1
    fi
    
    # ファイル拡張子取得
    local file_extension="${file_path##*.}"
    file_extension=".${file_extension}"
    
    # 役割設定から許可ファイル型を取得
    local allowed_types
    case "${worker}" in
        "WORKER1")
            allowed_types='[".js", ".jsx", ".ts", ".tsx", ".css", ".scss", ".html", ".md"]'
            ;;
        "WORKER2")
            allowed_types='[".sh", ".py", ".json", ".yaml", ".yml", ".conf", ".cfg", ".md"]'
            ;;
        "WORKER3")
            allowed_types='[".md", ".css", ".scss", ".html", ".json", ".yaml", ".yml"]'
            ;;
        "BOSS1"|"PRESIDENT")
            # 管理者は全ファイル許可
            authorized=true
            ;;
        *)
            log "ERROR: 不明なワーカー: ${worker}"
            return 1
            ;;
    esac
    
    # ファイル型チェック（ワーカーのみ）
    if [ "${authorized}" = false ]; then
        if echo "${allowed_types}" | grep -q "\"${file_extension}\""; then
            authorized=true
        fi
    fi
    
    if [ "${authorized}" = true ]; then
        log "${worker}は${file_path}の操作が許可されています"
        return 0
    else
        log "WARNING: ${worker}は${file_path}の操作が許可されていません"
        return 1
    fi
}

# 役割競合チェック
check_role_conflicts() {
    local task_id="$1"
    local assigned_worker="$2"
    local task_area="$3"
    
    # 現在のタスク割当を確認
    if [ -f "${TASK_DB}" ]; then
        local active_tasks=$(cat "${TASK_DB}" | jq -r '.active_tasks[] | select(.area == "'"${task_area}"'" and .status == "in_progress") | .worker')
        
        if [ -n "${active_tasks}" ] && [ "${active_tasks}" != "${assigned_worker}" ]; then
            log "WARNING: 役割競合検出 - エリア:${task_area}, 既存:${active_tasks}, 新規:${assigned_worker}"
            return 1
        fi
    fi
    
    return 0
}

# タスク割当実行
assign_task() {
    local task_description="$1"
    local task_id="${2:-$(date +%s)}"
    local force_worker="${3:-""}"
    
    log "タスク割当を開始: ${task_description}"
    
    # タスク分析
    local task_type=$(classify_task "${task_description}")
    local task_complexity=$(evaluate_task_complexity "${task_description}")
    
    # ワーカー選定
    local selected_worker
    if [ -n "${force_worker}" ]; then
        selected_worker="${force_worker}"
        log "強制指定ワーカー: ${selected_worker}"
    else
        selected_worker=$(select_optimal_worker "${task_type}" "${task_complexity}")
    fi
    
    # 競合チェック
    if ! check_role_conflicts "${task_id}" "${selected_worker}" "${task_type}"; then
        log "ERROR: 役割競合のため割当を中止"
        return 1
    fi
    
    # タスクDB更新
    update_task_database "${task_id}" "${task_description}" "${selected_worker}" "${task_type}" "${task_complexity}"
    
    log "タスク割当完了: ${task_description} → ${selected_worker}"
    echo "${selected_worker}"
}

# タスクデータベース更新
update_task_database() {
    local task_id="$1"
    local description="$2"
    local worker="$3"
    local type="$4"
    local complexity="$5"
    
    # DB初期化（存在しない場合）
    if [ ! -f "${TASK_DB}" ]; then
        echo '{"active_tasks": [], "completed_tasks": []}' > "${TASK_DB}"
    fi
    
    # タスク情報作成
    local task_info=$(cat << EOF
{
  "id": "${task_id}",
  "description": "${description}",
  "worker": "${worker}",
  "type": "${type}",
  "complexity": "${complexity}",
  "status": "assigned",
  "assigned_at": "$(date -Iseconds)",
  "started_at": null,
  "completed_at": null
}
EOF
)
    
    # DB更新
    local temp_file=$(mktemp)
    cat "${TASK_DB}" | jq ".active_tasks += [${task_info}]" > "${temp_file}"
    mv "${temp_file}" "${TASK_DB}"
    
    log "タスクDB更新: ${task_id}"
}

# タスク状態更新
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local timestamp_field=""
    
    case "${new_status}" in
        "in_progress")
            timestamp_field="started_at"
            ;;
        "completed")
            timestamp_field="completed_at"
            ;;
        "failed")
            timestamp_field="failed_at"
            ;;
    esac
    
    if [ -f "${TASK_DB}" ] && [ -n "${timestamp_field}" ]; then
        local temp_file=$(mktemp)
        cat "${TASK_DB}" | jq ".active_tasks |= map(if .id == \"${task_id}\" then .status = \"${new_status}\" | .${timestamp_field} = \"$(date -Iseconds)\" else . end)" > "${temp_file}"
        mv "${temp_file}" "${TASK_DB}"
        
        log "タスク状態更新: ${task_id} → ${new_status}"
    fi
}

# 完了タスク移動
complete_task() {
    local task_id="$1"
    
    if [ -f "${TASK_DB}" ]; then
        local temp_file=$(mktemp)
        
        # 完了タスクを completed_tasks に移動
        cat "${TASK_DB}" | jq "
            .completed_tasks += [.active_tasks[] | select(.id == \"${task_id}\")] |
            .active_tasks = [.active_tasks[] | select(.id != \"${task_id}\")]
        " > "${temp_file}"
        
        mv "${temp_file}" "${TASK_DB}"
        log "タスク完了処理: ${task_id}"
    fi
}

# 現在の割当状況表示
show_current_assignments() {
    if [ ! -f "${TASK_DB}" ]; then
        echo "タスク割当なし"
        return
    fi
    
    echo "📋 現在のタスク割当状況"
    echo "========================"
    
    cat "${TASK_DB}" | jq -r '.active_tasks[] | "- \(.worker): \(.description) (\(.status))"'
    
    echo ""
    echo "📊 ワーカー別集計"
    echo "=================="
    
    for worker in PRESIDENT BOSS1 WORKER1 WORKER2 WORKER3; do
        local count=$(cat "${TASK_DB}" | jq -r ".active_tasks[] | select(.worker == \"${worker}\") | .id" | wc -l)
        echo "- ${worker}: ${count}件"
    done
}

# レポート生成
generate_assignment_report() {
    local report_file="${LOG_DIR}/role-assignment-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "${report_file}" << EOF
# 役割分担システム レポート

## 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

## 現在のタスク割当
EOF
    
    if [ -f "${TASK_DB}" ]; then
        echo "### アクティブタスク" >> "${report_file}"
        cat "${TASK_DB}" | jq -r '.active_tasks[] | "- **\(.worker)**: \(.description) (\(.status))"' >> "${report_file}"
        
        echo "" >> "${report_file}"
        echo "### 完了タスク（直近10件）" >> "${report_file}"
        cat "${TASK_DB}" | jq -r '.completed_tasks[-10:] | .[] | "- **\(.worker)**: \(.description) (完了: \(.completed_at))"' >> "${report_file}"
    else
        echo "タスクデータなし" >> "${report_file}"
    fi
    
    cat >> "${report_file}" << EOF

## システム統計
- 総タスク数: $(cat "${TASK_DB}" 2>/dev/null | jq '.active_tasks | length' || echo 0)
- 完了タスク数: $(cat "${TASK_DB}" 2>/dev/null | jq '.completed_tasks | length' || echo 0)

## 最新ログ (直近20件)
$(tail -20 "${ROLE_LOG}" 2>/dev/null || echo "ログなし")

---
*自動生成: 役割分担明確化システム*
EOF
    
    log "レポート生成: ${report_file}"
    echo "${report_file}"
}

# メイン処理
main() {
    local command=${1:-"help"}
    
    case "${command}" in
        "init")
            initialize_roles
            ;;
        "assign")
            local task="${2:-""}"
            local worker="${3:-""}"
            if [ -n "${task}" ]; then
                assign_task "${task}" "" "${worker}"
            else
                echo "エラー: タスク説明を指定してください"
                exit 1
            fi
            ;;
        "status")
            local task_id="${2:-""}"
            local new_status="${3:-""}"
            if [ -n "${task_id}" ] && [ -n "${new_status}" ]; then
                update_task_status "${task_id}" "${new_status}"
            else
                echo "エラー: タスクIDと新しい状態を指定してください"
                exit 1
            fi
            ;;
        "complete")
            local task_id="${2:-""}"
            if [ -n "${task_id}" ]; then
                update_task_status "${task_id}" "completed"
                complete_task "${task_id}"
            else
                echo "エラー: タスクIDを指定してください"
                exit 1
            fi
            ;;
        "show")
            show_current_assignments
            ;;
        "check")
            local worker="${2:-""}"
            local file_path="${3:-""}"
            if [ -n "${worker}" ] && [ -n "${file_path}" ]; then
                check_work_authorization "${worker}" "${file_path}"
            else
                echo "エラー: ワーカー名とファイルパスを指定してください"
                exit 1
            fi
            ;;
        "report")
            generate_assignment_report
            ;;
        "help")
            cat << EOF
👥 役割分担明確化システム v2.0

使用方法:
  $0 init                           # システム初期化
  $0 assign "<task>" [worker]       # タスク割当
  $0 status <task_id> <status>      # タスク状態更新
  $0 complete <task_id>             # タスク完了
  $0 show                           # 現在の割当表示
  $0 check <worker> <file_path>     # 作業権限確認
  $0 report                         # レポート生成

タスク状態: assigned, in_progress, completed, failed
ワーカー: PRESIDENT, BOSS1, WORKER1, WORKER2, WORKER3

機能:
- 自動タスク分類・割当
- 役割競合チェック
- 作業権限管理
- 進捗追跡・レポート
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