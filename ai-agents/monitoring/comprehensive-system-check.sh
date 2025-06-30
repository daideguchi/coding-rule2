#!/bin/bash
# AI最強組織包括的システムチェック
# 大きな欠陥・脆弱性の徹底検証

BASE_DIR="/Users/dd/Desktop/1_dev/coding-rule2"
CHECK_LOG="$BASE_DIR/logs/system-check-$(date +%Y%m%d-%H%M%S).log"
ISSUES_FOUND=0

echo "🔍 AI最強組織包括的システムチェック開始 - $(date)" | tee "$CHECK_LOG"

# 1. 重要ファイル・ディレクトリの整合性チェック
check_file_integrity() {
    echo "📁 ファイル整合性チェック開始" | tee -a "$CHECK_LOG"
    
    local critical_files=(
        "ai-agents/manage.sh"
        "ai-agents/scripts/automation/core/auto-status-detection.sh"
        "ai-agents/monitoring/balanced-auto-system.sh"
        "ai-agents/monitoring/system-recovery-engine.sh"
        ".cursor/rules/globals.mdc"
        "logs/ai-agents/president/PRESIDENT_MISTAKES.md"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$BASE_DIR/$file" ]; then
            echo "✅ $file 存在確認" | tee -a "$CHECK_LOG"
        else
            echo "❌ $file 不存在" | tee -a "$CHECK_LOG"
            ((ISSUES_FOUND++))
        fi
    done
}

# 2. スクリプト構文チェック
check_script_syntax() {
    echo "🔧 スクリプト構文チェック開始" | tee -a "$CHECK_LOG"
    
    find "$BASE_DIR/ai-agents" -name "*.sh" -type f | while read script; do
        if bash -n "$script" 2>/dev/null; then
            echo "✅ $(basename $script) 構文正常" | tee -a "$CHECK_LOG"
        else
            echo "❌ $(basename $script) 構文エラー" | tee -a "$CHECK_LOG"
            bash -n "$script" 2>&1 | tee -a "$CHECK_LOG"
            ((ISSUES_FOUND++))
        fi
    done
}

# 3. プロセス・リソース状況チェック
check_system_resources() {
    echo "💻 システムリソースチェック開始" | tee -a "$CHECK_LOG"
    
    # メモリ使用量
    local memory_usage=$(ps aux | awk '{sum+=$6} END {print sum/1024}')
    echo "📊 メモリ使用量: ${memory_usage}MB" | tee -a "$CHECK_LOG"
    
    # プロセス数
    local process_count=$(ps aux | grep -E "(claude|tmux|ai-agents)" | wc -l)
    echo "⚙️ AI関連プロセス数: $process_count" | tee -a "$CHECK_LOG"
    
    # ディスク使用量
    local disk_usage=$(du -sh "$BASE_DIR" | cut -f1)
    echo "💾 プロジェクトディスク使用量: $disk_usage" | tee -a "$CHECK_LOG"
}

# 4. 依存関係・競合チェック
check_dependencies() {
    echo "🔗 依存関係チェック開始" | tee -a "$CHECK_LOG"
    
    # tmux確認
    if command -v tmux >/dev/null 2>&1; then
        echo "✅ tmux インストール済み" | tee -a "$CHECK_LOG"
    else
        echo "❌ tmux 未インストール" | tee -a "$CHECK_LOG"
        ((ISSUES_FOUND++))
    fi
    
    # 重複プロセス確認
    local duplicate_processes=$(pgrep -f "ai-agents" | wc -l)
    if [ "$duplicate_processes" -gt 10 ]; then
        echo "⚠️ AI関連プロセス過多: $duplicate_processes個" | tee -a "$CHECK_LOG"
        ((ISSUES_FOUND++))
    fi
}

# 5. 設定ファイル検証
check_configurations() {
    echo "⚙️ 設定ファイル検証開始" | tee -a "$CHECK_LOG"
    
    # cursor rules構文確認
    find "$BASE_DIR/.cursor/rules" -name "*.mdc" -type f | while read config; do
        if grep -q "^---" "$config"; then
            echo "✅ $(basename $config) 設定形式正常" | tee -a "$CHECK_LOG"
        else
            echo "⚠️ $(basename $config) 設定形式要確認" | tee -a "$CHECK_LOG"
        fi
    done
    
    # 環境変数確認
    if [ -f "$BASE_DIR/.env" ]; then
        echo "✅ .env 環境設定存在" | tee -a "$CHECK_LOG"
    else
        echo "⚠️ .env 環境設定未存在" | tee -a "$CHECK_LOG"
    fi
}

# 6. セキュリティチェック
check_security() {
    echo "🔒 セキュリティチェック開始" | tee -a "$CHECK_LOG"
    
    # 権限チェック
    find "$BASE_DIR/ai-agents" -name "*.sh" -type f ! -executable | while read script; do
        echo "⚠️ 実行権限なし: $(basename $script)" | tee -a "$CHECK_LOG"
    done
    
    # 機密情報漏洩チェック
    if grep -r "sk-" "$BASE_DIR" --include="*.sh" --include="*.md" >/dev/null 2>&1; then
        echo "🚨 APIキー漏洩の可能性" | tee -a "$CHECK_LOG"
        ((ISSUES_FOUND++))
    fi
}

# 7. パフォーマンス・安定性チェック
check_performance() {
    echo "📈 パフォーマンスチェック開始" | tee -a "$CHECK_LOG"
    
    # ログサイズ確認
    local log_size=$(du -sh "$BASE_DIR/logs" 2>/dev/null | cut -f1 || echo "0")
    echo "📋 ログサイズ: $log_size" | tee -a "$CHECK_LOG"
    
    # 一時ファイル確認
    local temp_files=$(find "$BASE_DIR" -name "*.tmp" -o -name "*.pid" -o -name "nohup.out" | wc -l)
    echo "🗄️ 一時ファイル数: $temp_files" | tee -a "$CHECK_LOG"
}

# 8. Git状態確認
check_git_status() {
    echo "📦 Git状態確認開始" | tee -a "$CHECK_LOG"
    
    cd "$BASE_DIR"
    
    # 変更ファイル確認
    local modified_files=$(git status --porcelain | wc -l)
    echo "📝 変更ファイル数: $modified_files" | tee -a "$CHECK_LOG"
    
    # ブランチ確認
    local current_branch=$(git branch --show-current)
    echo "🌿 現在のブランチ: $current_branch" | tee -a "$CHECK_LOG"
    
    # コミット準備状況
    if [ "$modified_files" -gt 0 ]; then
        echo "⚠️ 未コミット変更あり" | tee -a "$CHECK_LOG"
    else
        echo "✅ Git状態クリーン" | tee -a "$CHECK_LOG"
    fi
}

# メイン実行
main() {
    echo "🚀 AI最強組織として徹底的なシステムチェックを実行中..." | tee -a "$CHECK_LOG"
    
    check_file_integrity
    check_script_syntax
    check_system_resources
    check_dependencies
    check_configurations
    check_security
    check_performance
    check_git_status
    
    echo "════════════════════════════════════════" | tee -a "$CHECK_LOG"
    echo "🎯 システムチェック完了 - $(date)" | tee -a "$CHECK_LOG"
    echo "📊 検出された問題: $ISSUES_FOUND個" | tee -a "$CHECK_LOG"
    echo "📋 詳細ログ: $CHECK_LOG" | tee -a "$CHECK_LOG"
    
    if [ "$ISSUES_FOUND" -eq 0 ]; then
        echo "✅ システムは健全です - Gitプッシュ準備完了" | tee -a "$CHECK_LOG"
        return 0
    else
        echo "⚠️ 問題が検出されました - 修正が必要" | tee -a "$CHECK_LOG"
        return 1
    fi
}

# 実行
main "$@"