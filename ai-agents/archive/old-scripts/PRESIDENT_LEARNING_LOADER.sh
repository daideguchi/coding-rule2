#!/bin/bash

# PRESIDENT 学習データ読み込みシステム
# 起動時に過去の学習データを自動読み込み

set -euo pipefail

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 設定
PROJECT_ROOT="/Users/dd/Desktop/1_dev/coding-rule2"
LEARNING_DATA_DIR="$PROJECT_ROOT/ai-agents/learning-data"
LOG_FILE="$PROJECT_ROOT/logs/president-learning.log"

# ディレクトリ作成
mkdir -p "$(dirname "$LOG_FILE")"

# メイン関数
main() {
    log_info "🧠 PRESIDENT学習データ読み込み開始"
    
    # 1. 重大ミス記録の確認
    check_critical_mistakes
    
    # 2. 過去の作業記録確認
    check_work_logs
    
    # 3. ユーザープロファイル読み込み
    load_user_profiles
    
    # 4. 学習モデル状態確認
    check_learning_models
    
    # 5. 今日の学習目標設定
    set_daily_learning_goals
    
    log_success "✅ PRESIDENT学習データ読み込み完了"
}

# 重大ミス記録確認
check_critical_mistakes() {
    log_info "📋 重大ミス記録を確認中..."
    
    local mistakes_file="$PROJECT_ROOT/ai-agents/PRESIDENT_MISTAKES_RECORD.md"
    if [[ -f "$mistakes_file" ]]; then
        local mistake_count=$(grep -c "^##" "$mistakes_file" 2>/dev/null || echo "0")
        log_warning "⚠️  過去の重大ミス: ${mistake_count}件 - 必ず確認すること"
        
        # 最新5件のミスを表示
        if [[ $mistake_count -gt 0 ]]; then
            log_info "最新の重大ミス（上位5件）:"
            grep "^##" "$mistakes_file" | head -5 | while read -r line; do
                echo "  - $line"
            done
        fi
    else
        log_error "❌ 重大ミス記録ファイルが見つかりません: $mistakes_file"
    fi
}

# 過去の作業記録確認
check_work_logs() {
    log_info "📊 過去の作業記録を確認中..."
    
    local work_log="$PROJECT_ROOT/cursor work-log.mdc"
    if [[ -f "$work_log" ]]; then
        local log_size=$(wc -l < "$work_log" 2>/dev/null || echo "0")
        log_info "📝 作業ログ: ${log_size}行の記録があります"
        
        # 今日の作業記録確認
        local today=$(date +%Y-%m-%d)
        if grep -q "$today" "$work_log" 2>/dev/null; then
            log_info "📅 今日の作業記録が存在します"
        else
            log_warning "⚠️  今日の作業記録はまだありません"
        fi
    else
        log_warning "⚠️  作業ログファイルが見つかりません"
    fi
}

# ユーザープロファイル読み込み
load_user_profiles() {
    log_info "👤 ユーザープロファイルを読み込み中..."
    
    local profiles_dir="$LEARNING_DATA_DIR/user-profiles"
    if [[ -d "$profiles_dir" ]]; then
        local profile_count=$(find "$profiles_dir" -name "user_*.json" 2>/dev/null | wc -l)
        log_info "📊 ユーザープロファイル: ${profile_count}件"
        
        # 最新のプロファイルを確認
        local latest_profile=$(find "$profiles_dir" -name "user_*.json" -type f -exec ls -t {} + | head -1 2>/dev/null || echo "")
        if [[ -n "$latest_profile" ]]; then
            log_info "📋 最新プロファイル: $(basename "$latest_profile")"
            
            # プロファイルの基本情報を表示
            if command -v jq >/dev/null 2>&1; then
                local language=$(jq -r '.preferences.language // "ja"' "$latest_profile" 2>/dev/null || echo "ja")
                local interactions=$(jq -r '.learning_metadata.total_interactions // 0' "$latest_profile" 2>/dev/null || echo "0")
                log_info "  - 言語設定: $language"
                log_info "  - 総インタラクション数: $interactions"
            fi
        fi
    else
        log_warning "⚠️  ユーザープロファイルディレクトリが見つかりません"
    fi
}

# 学習モデル状態確認
check_learning_models() {
    log_info "🤖 学習モデル状態を確認中..."
    
    local models_dir="$LEARNING_DATA_DIR/learning-models"
    local registry_file="$models_dir/model_registry.json"
    
    if [[ -f "$registry_file" ]]; then
        log_info "📋 モデルレジストリが存在します"
        
        if command -v jq >/dev/null 2>&1; then
            local model_count=$(jq '.models | length' "$registry_file" 2>/dev/null || echo "0")
            log_info "🎯 登録モデル数: $model_count"
            
            # 各モデルの状態確認
            jq -r '.models | keys[]' "$registry_file" 2>/dev/null | while read -r model_name; do
                local updated_at=$(jq -r ".models.\"$model_name\".updated_at // \"未訓練\"" "$registry_file" 2>/dev/null)
                log_info "  - $model_name: $updated_at"
            done
        fi
    else
        log_warning "⚠️  モデルレジストリが見つかりません"
    fi
}

# 今日の学習目標設定
set_daily_learning_goals() {
    log_info "🎯 今日の学習目標を設定中..."
    
    local today=$(date +%Y-%m-%d)
    local goals_file="$LEARNING_DATA_DIR/daily_goals_$today.json"
    
    if [[ ! -f "$goals_file" ]]; then
        cat > "$goals_file" << EOF
{
  "date": "$today",
  "goals": [
    "重大ミスの再発防止を最優先する",
    "ユーザーの指示を正確に理解し実行する", 
    "作業プロセスを丁寧に記録する",
    "チーム連携を円滑に行う",
    "技術的理解を深める"
  ],
  "metrics": {
    "mistakes_avoided": 0,
    "successful_completions": 0,
    "user_satisfaction": 0
  },
  "status": "active"
}
EOF
        log_success "✅ 今日の学習目標を設定しました"
    else
        log_info "📅 今日の学習目標は既に設定済みです"
    fi
    
    # 目標を表示
    if command -v jq >/dev/null 2>&1; then
        log_info "📋 今日の学習目標:"
        jq -r '.goals[]' "$goals_file" 2>/dev/null | while read -r goal; do
            echo "  - $goal"
        done
    fi
}

# 学習データの自動収集開始
start_learning_collection() {
    log_info "📊 学習データ収集を開始します"
    
    # バックグラウンドで学習データ収集
    (
        while true; do
            sleep 300  # 5分間隔
            collect_interaction_data
        done
    ) &
    
    local pid=$!
    echo $pid > "/tmp/president-learning-collector.pid"
    log_success "🔄 学習データ収集プロセス開始 (PID: $pid)"
}

# インタラクションデータ収集
collect_interaction_data() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_file="$LEARNING_DATA_DIR/interaction-logs/commands_$(date +%Y%m%d).log"
    
    # tmuxセッションからの情報収集
    if command -v tmux >/dev/null 2>&1; then
        local active_sessions=$(tmux list-sessions 2>/dev/null | wc -l || echo "0")
        echo "[$timestamp] Active sessions: $active_sessions" >> "$log_file"
    fi
}

# メイン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" 2>&1 | tee -a "$LOG_FILE"
fi