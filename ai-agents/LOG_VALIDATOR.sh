#!/bin/bash
# 🔍 ログクリーンアップ事前検証システム
# 実行前の安全性チェックとシミュレーション

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$SCRIPT_DIR/logs"
SESSIONS_DIR="$SCRIPT_DIR/sessions"

# 色付きログ関数
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# 事前検証
validate_environment() {
    log_info "🔍 環境検証開始"
    
    # ディレクトリ存在確認
    if [ ! -d "$LOGS_DIR" ]; then
        log_error "❌ ログディレクトリが見つかりません: $LOGS_DIR"
        return 1
    fi
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        log_warn "⚠️ セッションディレクトリが見つかりません: $SESSIONS_DIR"
    fi
    
    # 権限確認
    if [ ! -w "$SCRIPT_DIR" ]; then
        log_error "❌ 書き込み権限がありません: $SCRIPT_DIR"
        return 1
    fi
    
    # ディスク容量確認
    local available_space=$(df -h "$SCRIPT_DIR" | tail -1 | awk '{print $4}' | sed 's/[A-Za-z]//g')
    local logs_size=$(du -sm "$LOGS_DIR" | cut -f1)
    local required_space=$((logs_size * 3))  # バックアップ用に3倍の容量を確保
    
    log_info "💾 ディスク容量チェック:"
    echo "  - ログサイズ: ${logs_size}MB"
    echo "  - 必要容量: ${required_space}MB"
    echo "  - 利用可能: ${available_space}GB"
    
    if [ "$available_space" -lt $(($required_space / 1024)) ]; then
        log_warn "⚠️ ディスク容量が不足している可能性があります"
    fi
    
    log_success "✅ 環境検証完了"
    return 0
}

# ファイル詳細分析
analyze_files_detailed() {
    log_info "📊 詳細ファイル分析"
    
    echo "## 📈 ファイルサイズ分析"
    echo "ファイル名 | サイズ | 分類予測"
    echo "---------|------|--------"
    
    find "$LOGS_DIR" -type f | while read -r file; do
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local category="unknown"
        
        # 分類予測
        if [[ "$filename" =~ status|Status|STATUS ]]; then
            category="ステータス"
        elif [[ "$filename" =~ error|Error|ERROR|FAIL|CRITICAL ]]; then
            category="エラー"
        elif [[ "$filename" =~ master|compliance|emergency|system ]]; then
            category="システム"
        elif [[ "$filename" =~ session ]]; then
            category="セッション"
        else
            category="その他"
        fi
        
        echo "$filename | $size | $category"
    done
    
    echo ""
    echo "## 🎯 削除対象予測"
    
    # 重複ファイル特定
    local redundant_count=0
    local redundant_size=0
    
    # ステータス関連の重複
    local status_files=$(find "$LOGS_DIR" -name "*status*" -type f | wc -l)
    if [ "$status_files" -gt 3 ]; then
        log_warn "⚠️ ステータス関連ファイル: ${status_files}個 (3個以上は重複の可能性)"
        redundant_count=$((redundant_count + status_files - 3))
    fi
    
    # 大容量ファイル
    find "$LOGS_DIR" -type f -size +1M | while read -r file; do
        local size=$(du -sm "$file" | cut -f1)
        echo "🔴 大容量ファイル: $(basename "$file") (${size}MB)"
        redundant_size=$((redundant_size + size))
    done
    
    # テンプレートファイル
    local template_files=$(find "$LOGS_DIR" -name "*\$(date*" -type f | wc -l)
    if [ "$template_files" -gt 0 ]; then
        log_warn "⚠️ テンプレートファイル: ${template_files}個発見"
        redundant_count=$((redundant_count + template_files))
    fi
    
    echo ""
    echo "予想削除ファイル数: $redundant_count"
    echo "予想容量削減: ${redundant_size}MB"
}

# シミュレーション実行
run_simulation() {
    log_info "🎭 クリーンアップシミュレーション"
    
    echo "実行される操作:"
    echo "1. 📋 ファイル分析と分類"
    echo "2. 💾 完全バックアップ作成"
    echo "3. 🧠 インテリジェント分類"
    echo "4. 🔗 ログ統合"
    echo "5. 🗑️ 削除計画作成"
    echo "6. 🏗️ 新システム構築"
    echo ""
    
    echo "作成されるディレクトリ:"
    echo "- backup-cleanup-YYYYMMDD-HHMMSS/"
    echo "  ├── original/          # 完全バックアップ"
    echo "  ├── classified/        # 分類されたファイル"
    echo "  ├── consolidated/      # 統合ログ"
    echo "  └── reports/           # 分析レポート"
    echo ""
    
    echo "新しいログ構造:"
    echo "$LOGS_DIR/"
    echo "├── system/             # システムログ"
    echo "├── monitoring/         # ステータス・監視"
    echo "├── archive/           # アーカイブ"
    echo "└── logging.conf       # 設定ファイル"
    echo ""
}

# 安全性チェック
safety_check() {
    log_info "🛡️ 安全性チェック"
    
    local safety_score=0
    local max_score=10
    
    # チェック1: バックアップ機能
    if [ -f "$SCRIPT_DIR/LOG_CLEANUP_SYSTEM.sh" ]; then
        echo "✅ クリーンアップスクリプト存在"
        safety_score=$((safety_score + 2))
    else
        echo "❌ クリーンアップスクリプトが見つかりません"
    fi
    
    # チェック2: 権限確認
    if [ -w "$SCRIPT_DIR" ]; then
        echo "✅ 書き込み権限あり"
        safety_score=$((safety_score + 2))
    else
        echo "❌ 書き込み権限なし"
    fi
    
    # チェック3: Git状態確認
    if git -C "$SCRIPT_DIR" status > /dev/null 2>&1; then
        local uncommitted=$(git -C "$SCRIPT_DIR" status --porcelain | wc -l)
        if [ "$uncommitted" -eq 0 ]; then
            echo "✅ Git状態: コミット済み"
            safety_score=$((safety_score + 2))
        else
            echo "⚠️ Git状態: 未コミット変更あり"
            safety_score=$((safety_score + 1))
        fi
    else
        echo "ℹ️ Git管理外"
        safety_score=$((safety_score + 1))
    fi
    
    # チェック4: 重要ファイル保護
    local important_files=("manage.sh" "MASTER_CONTROL.sh" "utils/smart-status.sh")
    local protected_count=0
    for file in "${important_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            protected_count=$((protected_count + 1))
        fi
    done
    
    if [ "$protected_count" -eq 3 ]; then
        echo "✅ 重要ファイル保護: 全て存在"
        safety_score=$((safety_score + 2))
    else
        echo "⚠️ 重要ファイル保護: 一部欠損"
        safety_score=$((safety_score + 1))
    fi
    
    # チェック5: 実行環境
    if command -v tmux > /dev/null && command -v git > /dev/null; then
        echo "✅ 実行環境: 必要ツール完備"
        safety_score=$((safety_score + 2))
    else
        echo "⚠️ 実行環境: 一部ツール不足"
        safety_score=$((safety_score + 1))
    fi
    
    # 安全性スコア表示
    echo ""
    echo "🛡️ 安全性スコア: $safety_score/$max_score"
    
    if [ "$safety_score" -ge 8 ]; then
        log_success "✅ 安全性: 高 - 実行推奨"
        return 0
    elif [ "$safety_score" -ge 6 ]; then
        log_warn "⚠️ 安全性: 中 - 注意して実行"
        return 1
    else
        log_error "❌ 安全性: 低 - 実行非推奨"
        return 2
    fi
}

# 推奨実行手順
show_recommendations() {
    log_info "📋 推奨実行手順"
    
    echo "## 🚀 実行前準備"
    echo "1. Git コミット (推奨):"
    echo "   git add -A && git commit -m '🧹 ログクリーンアップ前のバックアップ'"
    echo ""
    echo "2. tmux セッション停止 (任意):"
    echo "   tmux kill-session -t president"
    echo "   tmux kill-session -t multiagent"
    echo ""
    
    echo "## 🔄 実行コマンド"
    echo "1. 事前検証 (このスクリプト):"
    echo "   ./ai-agents/LOG_VALIDATOR.sh"
    echo ""
    echo "2. 分析のみ実行:"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh analyze"
    echo ""
    echo "3. 段階的実行:"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh backup"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh classify"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh consolidate"
    echo ""
    echo "4. 完全実行:"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh main"
    echo ""
    
    echo "## 🔙 ロールバック方法"
    echo "問題が発生した場合:"
    echo "1. バックアップディレクトリ確認:"
    echo "   ls ai-agents/backup-cleanup-*"
    echo ""
    echo "2. 完全復元:"
    echo "   ./ai-agents/LOG_CLEANUP_SYSTEM.sh restore"
    echo ""
}

# メイン実行
main() {
    echo "🔍 AI-Agents ログクリーンアップ事前検証システム"
    echo "=================================================="
    echo ""
    
    if ! validate_environment; then
        log_error "❌ 環境検証に失敗しました"
        exit 1
    fi
    
    echo ""
    analyze_files_detailed
    
    echo ""
    run_simulation
    
    echo ""
    safety_check
    local safety_result=$?
    
    echo ""
    show_recommendations
    
    echo ""
    echo "📊 検証結果サマリー:"
    echo "- 対象ファイル数: $(find "$LOGS_DIR" -type f | wc -l)"
    echo "- 総ファイルサイズ: $(du -sh "$LOGS_DIR" | cut -f1)"
    echo "- 安全性レベル: $([ $safety_result -eq 0 ] && echo "高" || [ $safety_result -eq 1 ] && echo "中" || echo "低")"
    
    if [ $safety_result -eq 0 ]; then
        echo ""
        log_success "✅ クリーンアップ実行準備完了"
        echo "次のコマンドで実行できます:"
        echo "  ./ai-agents/LOG_CLEANUP_SYSTEM.sh main"
    else
        echo ""
        log_warn "⚠️ 実行前に課題を解決してください"
    fi
    
    return $safety_result
}

# コマンドライン引数処理
case "${1:-main}" in
    "validate")
        validate_environment
        ;;
    "analyze")
        analyze_files_detailed
        ;;
    "simulate")
        run_simulation
        ;;
    "safety")
        safety_check
        ;;
    "recommend")
        show_recommendations
        ;;
    "main")
        main
        ;;
    *)
        echo "使用方法:"
        echo "  $0 main       # 完全検証"
        echo "  $0 validate   # 環境検証のみ"
        echo "  $0 analyze    # ファイル分析のみ"
        echo "  $0 simulate   # シミュレーションのみ"
        echo "  $0 safety     # 安全性チェックのみ"
        echo "  $0 recommend  # 推奨手順のみ"
        ;;
esac