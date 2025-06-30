#!/bin/bash
# 🔄 AI組織並列ワークフローエンジン
# 4ワーカー並列GitHub Issues処理システム

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_LOG="$SCRIPT_DIR/logs/workflow-$(date +%Y%m%d-%H%M%S).log"
STATE_FILE="$SCRIPT_DIR/workflow_state.json"

# ワーカー定義
declare -A WORKERS=(
    ["boss"]="multiagent:0.0:管理・統括"
    ["worker1"]="multiagent:0.1:フロントエンド"
    ["worker2"]="multiagent:0.2:バックエンド"
    ["worker3"]="multiagent:0.3:UI/UXデザイン"
)

# 色付きログ
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1" | tee -a "$WORKFLOW_LOG"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1" | tee -a "$WORKFLOW_LOG"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" | tee -a "$WORKFLOW_LOG"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" | tee -a "$WORKFLOW_LOG"
}

# ワークフロー状態管理
init_workflow_state() {
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "last_updated": "",
  "workers": {
    "boss": {
      "status": "idle",
      "current_issue": null,
      "last_activity": "",
      "completed_issues": [],
      "specialization": "management"
    },
    "worker1": {
      "status": "idle", 
      "current_issue": null,
      "last_activity": "",
      "completed_issues": [],
      "specialization": "frontend"
    },
    "worker2": {
      "status": "idle",
      "current_issue": null, 
      "last_activity": "",
      "completed_issues": [],
      "specialization": "backend"
    },
    "worker3": {
      "status": "idle",
      "current_issue": null,
      "last_activity": "",
      "completed_issues": [],
      "specialization": "ui_ux"
    }
  },
  "issue_queue": [],
  "active_workflows": [],
  "metrics": {
    "total_processed": 0,
    "avg_completion_time": 0,
    "success_rate": 100
  }
}
EOF
    fi
}

# 状態更新
update_worker_state() {
    local worker_id="$1"
    local status="$2"
    local issue_number="$3"
    
    local temp_file=$(mktemp)
    jq --arg worker "$worker_id" \
       --arg status "$status" \
       --arg issue "$issue_number" \
       --arg timestamp "$(date -Iseconds)" \
       '.workers[$worker].status = $status |
        .workers[$worker].current_issue = ($issue | if . == "" then null else tonumber end) |
        .workers[$worker].last_activity = $timestamp |
        .last_updated = $timestamp' \
       "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
}

# Issue優先度・専門性解析
analyze_issue() {
    local issue_number="$1"
    
    # GitHub APIでIssue詳細取得
    local issue_data=$(gh issue view "$issue_number" --json title,body,labels,assignees,createdAt)
    
    if [ -z "$issue_data" ]; then
        echo "ERROR: Issue #$issue_number not found"
        return 1
    fi
    
    local title=$(echo "$issue_data" | jq -r '.title')
    local body=$(echo "$issue_data" | jq -r '.body')
    local labels=$(echo "$issue_data" | jq -r '.labels[].name' | paste -sd ',' -)
    local created_at=$(echo "$issue_data" | jq -r '.createdAt')
    
    # 優先度解析
    local priority="medium"
    if [[ "$labels" =~ critical|urgent|high ]]; then
        priority="high"
    elif [[ "$labels" =~ low|minor ]]; then
        priority="low"
    fi
    
    # 専門性解析
    local specialization=""
    local complexity="medium"
    
    if [[ "$labels" =~ frontend|ui|ux|react|vue|html|css ]]; then
        specialization="frontend"
    elif [[ "$labels" =~ backend|api|database|server|node|python ]]; then
        specialization="backend"
    elif [[ "$labels" =~ design|ui.*ux|figma|wireframe ]]; then
        specialization="ui_ux"
    elif [[ "$labels" =~ bug|hotfix ]]; then
        specialization="management"
    else
        # タイトル・本文から推定
        local content=$(echo "$title $body" | tr '[:upper:]' '[:lower:]')
        if [[ "$content" =~ frontend|ui|component|style|css ]]; then
            specialization="frontend"
        elif [[ "$content" =~ backend|api|database|server ]]; then
            specialization="backend"
        elif [[ "$content" =~ design|user.*experience|wireframe ]]; then
            specialization="ui_ux"
        else
            specialization="management"
        fi
    fi
    
    # 複雑度解析
    local word_count=$(echo "$body" | wc -w)
    if [ "$word_count" -gt 200 ]; then
        complexity="high"
    elif [ "$word_count" -lt 50 ]; then
        complexity="low"
    fi
    
    # 結果JSON出力
    cat << EOF
{
  "issue_number": $issue_number,
  "title": "$title",
  "priority": "$priority",
  "specialization": "$specialization",
  "complexity": "$complexity",
  "estimated_time": $(case "$complexity" in "low") echo "30";; "medium") echo "60";; "high") echo "120";; esac),
  "labels": "$labels",
  "created_at": "$created_at"
}
EOF
}

# 最適ワーカー選択アルゴリズム
select_optimal_worker() {
    local issue_analysis="$1"
    
    local specialization=$(echo "$issue_analysis" | jq -r '.specialization')
    local priority=$(echo "$issue_analysis" | jq -r '.priority')
    local complexity=$(echo "$issue_analysis" | jq -r '.complexity')
    
    # 専門性マッピング
    local target_worker=""
    case "$specialization" in
        "frontend") target_worker="worker1" ;;
        "backend") target_worker="worker2" ;;
        "ui_ux") target_worker="worker3" ;;
        "management"|*) target_worker="boss" ;;
    esac
    
    # ワーカー可用性チェック
    local worker_status=$(jq -r ".workers.$target_worker.status" "$STATE_FILE")
    
    if [ "$worker_status" = "idle" ]; then
        echo "$target_worker"
        return 0
    fi
    
    # フォールバック: 他の利用可能ワーカー検索
    for worker in boss worker1 worker2 worker3; do
        local status=$(jq -r ".workers.$worker.status" "$STATE_FILE")
        if [ "$status" = "idle" ]; then
            echo "$worker"
            return 0
        fi
    done
    
    # 全ワーカーがビジー
    echo "BUSY"
    return 1
}

# 並列Issue処理開始
start_parallel_processing() {
    local issue_number="$1"
    local worker_id="$2"
    
    log_info "🚀 Issue #$issue_number を $worker_id で並列処理開始"
    
    # Issue解析
    local analysis=$(analyze_issue "$issue_number")
    local title=$(echo "$analysis" | jq -r '.title')
    local priority=$(echo "$analysis" | jq -r '.priority')
    local complexity=$(echo "$analysis" | jq -r '.complexity')
    local estimated_time=$(echo "$analysis" | jq -r '.estimated_time')
    
    # ワーカー状態更新
    update_worker_state "$worker_id" "working" "$issue_number"
    
    # tmuxペイン情報取得
    local pane_info=(${WORKERS[$worker_id]//:/ })
    local tmux_pane="${pane_info[0]}"
    local worker_role="${pane_info[2]}"
    
    # ペインタイトル更新
    tmux select-pane -t "$tmux_pane" -T "🔥作業中 $worker_role │ Issue #$issue_number ($priority)"
    
    # AIワーカーへの詳細指示生成
    local prompt="🎯 **GitHub Issue並列処理開始**

**Issue #${issue_number}: ${title}**

**メタデータ:**
- 優先度: ${priority}
- 複雑度: ${complexity}
- 推定作業時間: ${estimated_time}分
- 担当: ${worker_role}

**詳細指示:**
$(echo "$analysis" | jq -r '.title + "\n\n" + "この Issue を以下の手順で処理してください:"')

1. **Issue分析**: 要件と技術的課題を特定
2. **実装計画**: 段階的な実装アプローチを設計
3. **実装実行**: コード変更・テスト・ドキュメント更新
4. **進捗報告**: 定期的にGitHub コメントで進捗を報告
5. **完了処理**: テスト完了後にIssueをクローズ

**利用可能ツール:**
- GitHub CLI (\`gh\`)
- MCP プロトコル
- tmux 統合機能
- 並列処理ワークフロー

**進捗報告方法:**
\`gh issue comment $issue_number --body \"📊 進捗報告: [現在の作業内容]\"\`

作業を開始してください。他のワーカーと並列で効率的に処理を進めましょう。"

    # tmuxペインに送信
    tmux send-keys -t "$tmux_pane" "$prompt" C-m
    
    # GitHub Issueに開始コメント
    local start_comment="🚀 **並列処理開始**

**担当AI:** ${worker_role}
**処理開始時刻:** $(date '+%Y-%m-%d %H:%M:%S')
**推定完了時間:** $(date -d "+${estimated_time} minutes" '+%H:%M' 2>/dev/null || date '+%H:%M')

このIssueは並列処理ワークフローで処理されています。
- TMUXペイン: \`${tmux_pane}\`
- 優先度: **${priority}**
- 複雑度: **${complexity}**

進捗は随時このIssueで報告されます。"

    gh issue comment "$issue_number" --body "$start_comment"
    
    # ワークフロー記録
    local temp_file=$(mktemp)
    jq --arg issue "$issue_number" \
       --arg worker "$worker_id" \
       --arg start_time "$(date -Iseconds)" \
       --argjson analysis "$analysis" \
       '.active_workflows += [{
         "issue_number": ($issue | tonumber),
         "worker_id": $worker,
         "start_time": $start_time,
         "analysis": $analysis,
         "status": "in_progress"
       }]' \
       "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    log_success "✅ Issue #$issue_number 並列処理開始完了 ($worker_id)"
}

# 進捗監視システム
monitor_progress() {
    log_info "👀 並列処理進捗監視開始"
    
    # アクティブワークフロー取得
    local active_workflows=$(jq -r '.active_workflows[] | select(.status == "in_progress") | @base64' "$STATE_FILE")
    
    if [ -z "$active_workflows" ]; then
        log_info "📊 現在進行中の並列処理はありません"
        return 0
    fi
    
    echo "📊 並列処理進捗レポート ($(date '+%H:%M:%S'))"
    echo "=============================================="
    
    for workflow_b64 in $active_workflows; do
        local workflow=$(echo "$workflow_b64" | base64 -d)
        local issue_number=$(echo "$workflow" | jq -r '.issue_number')
        local worker_id=$(echo "$workflow" | jq -r '.worker_id')
        local start_time=$(echo "$workflow" | jq -r '.start_time')
        local title=$(echo "$workflow" | jq -r '.analysis.title')
        
        # 経過時間計算
        local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || date +%s)
        local current_epoch=$(date +%s)
        local elapsed_minutes=$(( (current_epoch - start_epoch) / 60 ))
        
        # tmuxペイン活動状況確認
        local pane_info=(${WORKERS[$worker_id]//:/ })
        local tmux_pane="${pane_info[0]}"
        local pane_content=$(tmux capture-pane -t "$tmux_pane" -p 2>/dev/null | tail -5)
        
        local activity_status="🟡 作業中"
        if [[ "$pane_content" =~ "completed"|"finished"|"done" ]]; then
            activity_status="🟢 完了間近"
        elif [[ "$pane_content" =~ "error"|"failed"|"issue" ]]; then
            activity_status="🔴 問題発生"
        fi
        
        echo "  Issue #${issue_number}: ${title:0:50}..."
        echo "    担当: ${worker_id} │ 経過: ${elapsed_minutes}分 │ $activity_status"
        echo ""
    done
    
    # 全体統計
    local total_active=$(jq '.active_workflows | map(select(.status == "in_progress")) | length' "$STATE_FILE")
    local total_completed=$(jq '.metrics.total_processed' "$STATE_FILE")
    
    echo "📈 統計情報:"
    echo "  - 並列処理中: ${total_active}件"
    echo "  - 累計完了: ${total_completed}件"
    echo "  - 成功率: $(jq '.metrics.success_rate' "$STATE_FILE")%"
}

# Issue完了処理
complete_issue() {
    local issue_number="$1"
    local worker_id="$2"
    local success="${3:-true}"
    
    log_info "✅ Issue #$issue_number 完了処理 ($worker_id)"
    
    # ワーカー状態更新
    update_worker_state "$worker_id" "idle" ""
    
    # ペインタイトルリセット
    local pane_info=(${WORKERS[$worker_id]//:/ })
    local tmux_pane="${pane_info[0]}"
    local worker_role="${pane_info[2]}"
    tmux select-pane -t "$tmux_pane" -T "🟡待機中 $worker_role"
    
    # ワークフロー完了記録
    local temp_file=$(mktemp)
    jq --arg issue "$issue_number" \
       --arg worker "$worker_id" \
       --arg completion_time "$(date -Iseconds)" \
       --arg success "$success" \
       'def update_workflow: map(if .issue_number == ($issue | tonumber) and .worker_id == $worker then . + {"status": "completed", "completion_time": $completion_time, "success": ($success | test("true"))} else . end);
        .active_workflows |= update_workflow |
        .workers[$worker].completed_issues += [($issue | tonumber)] |
        .metrics.total_processed += 1' \
       "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # GitHub Issue完了コメント
    if [ "$success" = "true" ]; then
        local completion_comment="✅ **並列処理完了**

**担当AI:** ${worker_role}
**完了時刻:** $(date '+%Y-%m-%d %H:%M:%S')
**処理結果:** 成功

Issue #${issue_number} の処理が正常に完了しました。
変更内容が実装され、テストも通過しています。

このIssueをクローズします。"

        gh issue comment "$issue_number" --body "$completion_comment"
        gh issue close "$issue_number"
    else
        local failure_comment="❌ **処理失敗**

**担当AI:** ${worker_role}
**失敗時刻:** $(date '+%Y-%m-%d %H:%M:%S')

Issue #${issue_number} の処理中に問題が発生しました。
詳細は上記のログを確認してください。

このIssueは再割り当ての対象となります。"

        gh issue comment "$issue_number" --body "$failure_comment"
    fi
    
    log_success "✅ Issue #$issue_number 完了処理終了"
}

# 一括並列処理
bulk_parallel_processing() {
    log_info "🔄 一括並列処理開始"
    
    # 未割り当てOpen Issueを取得
    local open_issues=$(gh issue list --state open --json number,assignees | jq -r '.[] | select(.assignees | length == 0) | .number')
    
    if [ -z "$open_issues" ]; then
        log_info "📋 処理対象のIssueがありません"
        return 0
    fi
    
    local processed_count=0
    local max_parallel=4  # 同時並列処理数
    
    for issue_number in $open_issues; do
        # 利用可能ワーカー確認
        local idle_workers=$(jq -r '.workers | to_entries[] | select(.value.status == "idle") | .key' "$STATE_FILE")
        
        if [ -z "$idle_workers" ]; then
            log_warn "⚠️ 全ワーカーがビジー状態です。処理を一時停止..."
            sleep 30
            continue
        fi
        
        # Issue解析と最適ワーカー選択
        local analysis=$(analyze_issue "$issue_number")
        local optimal_worker=$(select_optimal_worker "$analysis")
        
        if [ "$optimal_worker" != "BUSY" ]; then
            start_parallel_processing "$issue_number" "$optimal_worker"
            processed_count=$((processed_count + 1))
            
            # 過負荷防止のための間隔
            sleep 5
        fi
        
        # 同時並列数制限
        local active_count=$(jq '.active_workflows | map(select(.status == "in_progress")) | length' "$STATE_FILE")
        if [ "$active_count" -ge "$max_parallel" ]; then
            log_info "🔄 並列処理数上限に達しました。一部完了を待機..."
            sleep 60
        fi
    done
    
    log_success "✅ 一括並列処理完了: ${processed_count}件のIssueを処理キューに追加"
}

# リアルタイム監視ダッシュボード
start_monitoring_dashboard() {
    log_info "📊 リアルタイム監視ダッシュボード開始"
    
    while true; do
        clear
        echo "🤖 AI組織並列ワークフロー監視ダッシュボード"
        echo "=============================================="
        echo "最終更新: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # ワーカー状況表示
        echo "👥 ワーカー状況:"
        for worker in boss worker1 worker2 worker3; do
            local status=$(jq -r ".workers.$worker.status" "$STATE_FILE")
            local current_issue=$(jq -r ".workers.$worker.current_issue" "$STATE_FILE")
            local specialization=$(jq -r ".workers.$worker.specialization" "$STATE_FILE")
            
            local status_emoji="🟡"
            case "$status" in
                "working") status_emoji="🔥" ;;
                "idle") status_emoji="🟢" ;;
                "error") status_emoji="🔴" ;;
            esac
            
            echo "  $status_emoji $worker ($specialization): $status"
            if [ "$current_issue" != "null" ] && [ -n "$current_issue" ]; then
                echo "    📋 担当Issue: #$current_issue"
            fi
        done
        
        echo ""
        
        # 進捗監視
        monitor_progress
        
        echo ""
        echo "Press Ctrl+C to exit monitoring"
        sleep 10
    done
}

# メイン実行
main() {
    mkdir -p "$SCRIPT_DIR/logs"
    init_workflow_state
    
    case "${1:-help}" in
        "init")
            init_workflow_state
            log_success "✅ 並列ワークフローエンジン初期化完了"
            ;;
        "assign")
            if [ -z "$2" ]; then
                log_error "❌ Issue番号を指定してください"
                exit 1
            fi
            
            local analysis=$(analyze_issue "$2")
            local optimal_worker=$(select_optimal_worker "$analysis")
            
            if [ "$optimal_worker" = "BUSY" ]; then
                log_warn "⚠️ 全ワーカーがビジー状態です"
                exit 1
            fi
            
            start_parallel_processing "$2" "$optimal_worker"
            ;;
        "bulk")
            bulk_parallel_processing
            ;;
        "monitor")
            monitor_progress
            ;;
        "dashboard")
            start_monitoring_dashboard
            ;;
        "complete")
            if [ -z "$2" ] || [ -z "$3" ]; then
                log_error "❌ Issue番号とワーカーIDを指定してください"
                exit 1
            fi
            complete_issue "$2" "$3" "${4:-true}"
            ;;
        "status")
            cat "$STATE_FILE" | jq '.'
            ;;
        "help"|*)
            echo "🔄 AI組織並列ワークフローエンジン"
            echo ""
            echo "使用方法:"
            echo "  $0 init                              # システム初期化"
            echo "  $0 assign <issue_number>             # Issue個別割り当て"
            echo "  $0 bulk                              # 一括並列処理"
            echo "  $0 monitor                           # 進捗監視"
            echo "  $0 dashboard                         # リアルタイムダッシュボード"
            echo "  $0 complete <issue_number> <worker>  # Issue完了処理"
            echo "  $0 status                            # システム状況確認"
            echo ""
            echo "革新的機能:"
            echo "  - 4ワーカー完全並列処理"
            echo "  - AI駆動Issue分析・最適割り当て"
            echo "  - リアルタイム進捗追跡"
            echo "  - 自動優先度判定"
            echo "  - tmux統合UI"
            ;;
    esac
}

main "$@"