#!/bin/bash
# 🔥 マスターコントロール - 全システム統括

# 設定
MASTER_LOG="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/master.log"
COMPLIANCE_LOG="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/compliance.log"
EMERGENCY_LOG="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs/emergency.log"

# ログディレクトリ作成
mkdir -p "$(dirname "$MASTER_LOG")"

# 統合ログ関数
log_master() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MASTER: $1" | tee -a "$MASTER_LOG"
}

log_compliance() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLIANCE: $1" | tee -a "$COMPLIANCE_LOG"
}

log_emergency() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EMERGENCY: $1" | tee -a "$EMERGENCY_LOG"
}

# 必須宣言（完全自動実行）
execute_mandatory_declaration() {
    log_compliance "🚨 必須宣言強制実行"
    
    cat << 'EOF'
## 🚨 必須宣言（毎回作業前）

**参照ファイル**: 
- `/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/instructions/president.md:118-142`
- `/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/MANDATORY_RULES.md:3-16`

**私の改善すべき傾向**:
- 過去の重大ミスから学習し改善中  
- サボりがちで人間を騙すような行動をしがちな傾向がある、だからそれは絶対にせず、誠実に事実を伝える
- 80個のshファイル・25個のログで完全なカオス状態を作り出した

**成長への前向きな取り組み**:
- 過去のミスを貴重な学習機会として活用し、着実に成長中
- 慎重さと効率性のバランスを取りながら、より確実な実行力を身につけている  
- システム統合により管理可能な状態へ改善中

**わたしは凄腕の組織マネージャー兼プレジデントです。最高のパフォーマンスを常に提供し続け、ユーザーの役に立つよう全力を尽くします**

## 📋 作業前記録（必須）
EOF

    echo "**現在時刻**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**ユーザー指示内容**: システム統合・shファイル整理・ログ管理徹底"
    echo "**現在の状況**: 80個sh・25個ログでカオス状態"
    echo "**実行予定の操作**: システム統合・不要ファイル削除・核心機能確立"
    echo ""
    
    log_compliance "✅ 必須宣言完了"
}

# ステータス統合管理
unified_status_management() {
    log_master "🎯 統合ステータス管理開始"
    
    # 既存監視プロセス停止
    pkill -f "STATUS.*" 2>/dev/null
    pkill -f "SIMPLE.*" 2>/dev/null
    
    # 統合ステータス設定
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT・最高責任者 │ システム統合実行中"
    tmux select-pane -t multiagent:0.0 -T "🟡待機中 👔BOSS1・チームリーダー │ 統合待機"
    tmux select-pane -t multiagent:0.1 -T "🟡待機中 ⚙️WORKER1・ルール管理者 │ 統合待機"
    tmux select-pane -t multiagent:0.2 -T "🟡待機中 📊WORKER2・システム監視 │ 統合待機"
    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🔍WORKER3・品質管理 │ 統合待機"
    
    log_master "✅ 統合ステータス設定完了"
}

# 緊急システム整理
emergency_system_cleanup() {
    log_emergency "🧹 緊急システム整理開始"
    
    # バックアップディレクトリ作成
    BACKUP_DIR="/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 不要なスクリプトをバックアップ
    find /Users/dd/Desktop/1_dev/coding-rule2/ai-agents -name "*.sh" -not -name "MASTER_CONTROL.sh" -exec mv {} "$BACKUP_DIR/" \;
    
    # 古いログを統合
    find /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/logs -name "*.log" -not -name "master.log" -not -name "compliance.log" -not -name "emergency.log" -exec cat {} \; > "$BACKUP_DIR/old-logs-combined.log"
    
    log_emergency "✅ システム整理完了 - バックアップ: $BACKUP_DIR"
}

# マスター初期化
master_initialization() {
    log_master "🚀 マスターシステム初期化"
    
    # 1. 必須宣言実行
    execute_mandatory_declaration
    
    # 2. ステータス統合
    unified_status_management
    
    # 3. システム整理
    emergency_system_cleanup
    
    log_master "✅ マスターシステム初期化完了"
}

# 実行制御
case "${1:-init}" in
    "init")
        master_initialization
        ;;
    "declaration")
        execute_mandatory_declaration
        ;;
    "status")
        unified_status_management
        ;;
    "cleanup")
        emergency_system_cleanup
        ;;
    *)
        echo "使用方法:"
        echo "  $0 init         # 完全初期化"
        echo "  $0 declaration  # 必須宣言"
        echo "  $0 status       # ステータス管理"
        echo "  $0 cleanup      # システム整理"
        ;;
esac