#!/bin/bash
# パフォーマンス監視強化システム

set -euo pipefail

# プロジェクトルート自動検出
detect_project_root() {
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/.git" ] && [ -d "$search_dir/ai-agents" ]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    echo "ERROR: プロジェクトルートが見つかりません" >&2
    return 1
}

if ! PROJECT_ROOT=$(detect_project_root); then
    exit 1
fi

BASE_DIR="$PROJECT_ROOT"
PERFORMANCE_LOG="$BASE_DIR/logs/performance-monitoring.log"

# ログディレクトリ作成
mkdir -p "$(dirname "$PERFORMANCE_LOG")"

monitor_system_performance() {
    echo "[$(date '+%H:%M:%S')] パフォーマンス監視開始" >> "$PERFORMANCE_LOG"
    
    # CPU・メモリ使用率
    local cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || echo "0")
    local memory_usage=$(top -l 1 -n 0 | grep "PhysMem" | awk '{print $2}' 2>/dev/null || echo "不明")
    
    echo "💻 システムリソース:" >> "$PERFORMANCE_LOG"
    echo "  CPU使用率: $cpu_usage%" >> "$PERFORMANCE_LOG"
    echo "  メモリ使用: $memory_usage" >> "$PERFORMANCE_LOG"
    
    # tmuxセッション効率
    local active_sessions=$(tmux list-sessions 2>/dev/null | wc -l)
    local active_panes=$(tmux list-panes -a 2>/dev/null | wc -l)
    local efficiency_score=$((active_panes * 25))
    
    if [[ $efficiency_score -gt 100 ]]; then efficiency_score=100; fi
    
    echo "🔧 組織効率:" >> "$PERFORMANCE_LOG"
    echo "  アクティブセッション: $active_sessions" >> "$PERFORMANCE_LOG"
    echo "  アクティブペイン: $active_panes" >> "$PERFORMANCE_LOG"
    echo "  効率スコア: $efficiency_score%" >> "$PERFORMANCE_LOG"
    
    # 品質維持効果測定
    local prevention_logs=$(find "$BASE_DIR/logs" -name "*prevention*" -o -name "*guard*" 2>/dev/null | wc -l)
    echo "🛡️  防止システム稼働: ${prevention_logs}個" >> "$PERFORMANCE_LOG"
}

# 継続監視ループ
while true; do
    monitor_system_performance
    sleep 60  # 1分間隔
done
