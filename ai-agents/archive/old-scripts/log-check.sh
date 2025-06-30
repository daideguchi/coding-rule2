#!/bin/bash
# 🔍 AI向け重要ログ統合確認システム
# 毎回確認すべき重要ファイルを一元的に表示

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# ヘッダー表示
show_header() {
    echo ""
    echo "🔍 ========================================"
    echo "📋 AI向け重要ログ統合確認システム"
    echo "🔍 ========================================"
    echo ""
    echo "📅 確認日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# PRESIDENT_MISTAKES.md確認（最重要）
check_president_mistakes() {
    echo "🚨 =========================================="
    echo "📋 【最重要】PRESIDENT_MISTAKES.md 確認"
    echo "🚨 =========================================="
    echo ""
    
    if [ -f "PRESIDENT_MISTAKES.md" ]; then
        log_info "📖 PRESIDENT_MISTAKES.md の内容を表示中..."
        echo ""
        echo "--- PRESIDENT_MISTAKES.md (実行前必読) ---"
        cat PRESIDENT_MISTAKES.md
        echo ""
        echo "--- PRESIDENT_MISTAKES.md 確認完了 ---"
        echo ""
        log_success "✅ PRESIDENT_MISTAKES.md 確認完了（毎回必読）"
    else
        log_error "❌ PRESIDENT_MISTAKES.md が見つかりません"
    fi
    echo ""
}

# 作業記録確認
check_work_records() {
    echo "📊 =========================================="
    echo "📋 作業記録確認"
    echo "📊 =========================================="
    echo ""
    
    # 最新作業記録（last 3件）
    if [ -f "logs/work-records.md" ]; then
        log_info "📈 最新作業記録（直近3件）確認中..."
        echo ""
        echo "--- 最新作業記録 ---"
        grep -A 10 "## 🔧 \*\*作業記録 #" logs/work-records.md | tail -50
        echo ""
        echo "--- 最新作業記録 確認完了 ---"
        echo ""
        log_success "✅ 作業記録確認完了"
    else
        log_warn "⚠️ logs/work-records.md が見つかりません"
    fi
    
    # 統計情報
    if [ -f "logs/work-records.md" ]; then
        echo "📊 作業統計:"
        grep "総作業数\|最新作業" logs/work-records.md | sed 's/^/  /'
        echo ""
    fi
}

# .specstory確認
check_specstory() {
    echo "📝 =========================================="
    echo "📋 .specstory 仕様履歴確認"
    echo "📝 =========================================="
    echo ""
    
    if [ -d ".specstory" ]; then
        log_info "📋 .specstory ディレクトリ内容確認中..."
        echo ""
        echo "--- .specstory ファイル一覧 ---"
        ls -la .specstory/ 2>/dev/null || echo "  （空のディレクトリ）"
        echo ""
        
        # 最新ファイルがあれば表示
        latest_file=$(ls -t .specstory/*.md 2>/dev/null | head -1)
        if [ -n "$latest_file" ]; then
            echo "--- 最新仕様ファイル: $(basename "$latest_file") ---"
            head -20 "$latest_file"
            echo "..."
            echo "--- 最新仕様ファイル確認完了 ---"
        fi
        echo ""
        log_success "✅ .specstory 確認完了"
    else
        log_warn "⚠️ .specstory ディレクトリが見つかりません"
    fi
    echo ""
}

# cursor-rules状況確認
check_cursor_rules() {
    echo "🎯 =========================================="
    echo "📋 cursor-rules 状況確認"
    echo "🎯 =========================================="
    echo ""
    
    if [ -f ".cursor/rules/work-log.mdc" ]; then
        log_info "📋 cursor-rules 基本情報確認中..."
        echo ""
        echo "--- cursor-rules 状況 ---"
        echo "📁 .cursor/rules/work-log.mdc: ✅ 存在"
        echo "📁 cursor-rules/work-log.mdc: $([ -f "cursor-rules/work-log.mdc" ] && echo "✅ 存在" || echo "❌ 不存在")"
        
        # ファイルサイズ比較
        if [ -f "cursor-rules/work-log.mdc" ]; then
            size1=$(wc -c < ".cursor/rules/work-log.mdc")
            size2=$(wc -c < "cursor-rules/work-log.mdc")
            echo "📊 同期状況: .cursor/rules($size1 bytes) ⇔ cursor-rules($size2 bytes)"
            if [ "$size1" -eq "$size2" ]; then
                echo "🟢 同期OK"
            else
                echo "🟡 サイズ差異あり"
            fi
        fi
        echo ""
        echo "--- cursor-rules 確認完了 ---"
        echo ""
        log_success "✅ cursor-rules 確認完了"
    else
        log_warn "⚠️ .cursor/rules/work-log.mdc が見つかりません"
    fi
    echo ""
}

# AI組織システム状況確認
check_ai_system_status() {
    echo "🤖 =========================================="
    echo "📋 AI組織システム状況確認"
    echo "🤖 =========================================="
    echo ""
    
    log_info "📊 tmuxセッション状況確認中..."
    echo ""
    echo "--- tmuxセッション状況 ---"
    if command -v tmux &> /dev/null; then
        tmux_sessions=$(tmux list-sessions 2>/dev/null || echo "なし")
        echo "$tmux_sessions"
        
        # セッション数カウント
        session_count=$(echo "$tmux_sessions" | grep -v "なし" | wc -l)
        echo ""
        echo "📊 稼働セッション数: $session_count"
        
        # 重要セッション確認
        if echo "$tmux_sessions" | grep -q "president"; then
            echo "👑 PRESIDENT セッション: 🟢 稼働中"
        else
            echo "👑 PRESIDENT セッション: 🔴 停止中"
        fi
        
        if echo "$tmux_sessions" | grep -q "multiagent"; then
            echo "👥 multiagent セッション: 🟢 稼働中"
        else
            echo "👥 multiagent セッション: 🔴 停止中"
        fi
    else
        echo "❌ tmux がインストールされていません"
    fi
    echo ""
    echo "--- AI組織システム状況確認完了 ---"
    echo ""
    log_success "✅ AI組織システム状況確認完了"
    echo ""
}

# 重要な注意事項表示
show_important_notes() {
    echo "⚠️ =========================================="
    echo "📋 【重要】AI作業時の注意事項"
    echo "⚠️ =========================================="
    echo ""
    echo "🚨 絶対ルール:"
    echo "  1. PRESIDENT_MISTAKES.md を毎回確認（最重要）"
    echo "  2. 手動対処は絶対禁止（tmux send-keys等）"
    echo "  3. 自動化システムの修正・復旧を優先"
    echo "  4. 作業記録は必ず更新（logs/work-records.md）"
    echo "  5. 推測・憶測での報告は禁止"
    echo ""
    echo "💡 確認推奨コマンド:"
    echo "  ./ai-agents/log-check.sh              # このスクリプト"
    echo "  ./ai-agents/manage.sh status          # システム状況"
    echo "  ./ai-agents/manage.sh monitoring      # 軽量監視開始"
    echo ""
}

# サマリー表示
show_summary() {
    echo "📋 =========================================="
    echo "📋 確認完了サマリー"
    echo "📋 =========================================="
    echo ""
    echo "✅ 重要ファイル確認完了:"
    echo "  📋 PRESIDENT_MISTAKES.md (最重要)"
    echo "  📊 logs/work-records.md"
    echo "  📝 .specstory/"
    echo "  🎯 .cursor/rules/"
    echo "  🤖 AI組織システム状況"
    echo ""
    echo "🎯 次のアクション:"
    echo "  - PRESIDENT_MISTAKES.md の内容を厳守"
    echo "  - 作業開始前に必要な情報を収集"
    echo "  - 作業後は必ず記録を更新"
    echo ""
    echo "📅 確認日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# メイン処理
main() {
    case "${1:-all}" in
        "president-mistakes"|"mistakes")
            show_header
            check_president_mistakes
            ;;
        "work-records"|"records")
            show_header
            check_work_records
            ;;
        "specstory"|"spec")
            show_header
            check_specstory
            ;;
        "cursor-rules"|"rules")
            show_header
            check_cursor_rules
            ;;
        "system"|"status")
            show_header
            check_ai_system_status
            ;;
        "all"|*)
            show_header
            check_president_mistakes
            check_work_records
            check_specstory
            check_cursor_rules
            check_ai_system_status
            show_important_notes
            show_summary
            ;;
    esac
}

# スクリプト実行
main "$@" 