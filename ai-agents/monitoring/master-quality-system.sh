#!/bin/bash
# 統合品質管理マスターシステム
# 51回ミス教訓完全対応型

MASTER_LOG="$BASE_DIR/logs/master-quality-system.log"

# 全防止システムの起動
start_all_prevention_systems() {
    echo "[$(date '+%H:%M:%S')] 全防止システム起動開始" >> "$MASTER_LOG"
    
    # Enter押し忘れ防止
    if [[ -f "$BASE_DIR/ai-agents/monitoring/enter-guard.sh" ]]; then
        bash "$BASE_DIR/ai-agents/monitoring/enter-guard.sh" &
        echo "✅ Enter防止システム起動" >> "$MASTER_LOG"
    fi
    
    # cursor rules確認強制
    if [[ -f "$BASE_DIR/ai-agents/monitoring/cursor-rules-guard.sh" ]]; then
        bash "$BASE_DIR/ai-agents/monitoring/cursor-rules-guard.sh" &
        echo "✅ cursor rules強制システム起動" >> "$MASTER_LOG"
    fi
    
    # 宣言忘れ防止
    if [[ -f "$BASE_DIR/ai-agents/monitoring/declaration-guard.sh" ]]; then
        bash "$BASE_DIR/ai-agents/monitoring/declaration-guard.sh" &
        echo "✅ 宣言防止システム起動" >> "$MASTER_LOG"
    fi
    
    echo "🎯 統合品質管理体制完全起動完了" >> "$MASTER_LOG"
}

# 品質スコア算出
calculate_quality_score() {
    local mistakes_file="$BASE_DIR/logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    
    if [[ -f "$mistakes_file" ]]; then
        local total_mistakes=$(grep -c "###" "$mistakes_file" 2>/dev/null || echo "0")
        local quality_score=$((100 - total_mistakes))
        
        if [[ $quality_score -lt 0 ]]; then quality_score=0; fi
        
        echo "📊 現在の品質スコア: $quality_score/100" >> "$MASTER_LOG"
        echo "📋 総ミス数: $total_mistakes" >> "$MASTER_LOG"
        
        # tmuxペインタイトルに品質スコア表示
        if tmux has-session -t multiagent 2>/dev/null; then
            tmux select-pane -t multiagent:0.3 -T "WORKER3:品質管理(Score:$quality_score)" 2>/dev/null
        fi
    fi
}

# メイン実行
start_all_prevention_systems
calculate_quality_score
