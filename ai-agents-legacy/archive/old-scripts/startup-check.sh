#!/bin/bash
# 🚀 AI作業開始時統合チェックシステム
# 毎回の作業開始時に必ず実行する必須チェックリスト

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
show_startup_header() {
    clear
    echo ""
    echo "🚀 =========================================="
    echo "📋 AI作業開始時統合チェックシステム"
    echo "🚀 =========================================="
    echo ""
    echo "📅 作業開始日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "💡 目的: 安全で効率的な作業開始のための必須チェック"
    echo ""
}

# Step 1: PRESIDENT_MISTAKES.md 必須確認
step1_president_mistakes() {
    echo "🚨 =========================================="
    echo "📋 Step 1: PRESIDENT_MISTAKES.md 必須確認"
    echo "🚨 =========================================="
    echo ""
    
    log_info "🔥 最重要ファイル確認中..."
    if [ -f "PRESIDENT_MISTAKES.md" ]; then
        echo "--- PRESIDENT重大ミス記録（実行前必読）---"
        cat PRESIDENT_MISTAKES.md
        echo ""
        echo "--- PRESIDENT_MISTAKES.md 確認完了 ---"
        echo ""
        log_success "✅ Step 1 完了: PRESIDENT_MISTAKES.md 確認済み"
    else
        log_error "❌ PRESIDENT_MISTAKES.md が見つかりません"
        return 1
    fi
    echo ""
    
    # 確認プロンプト
    echo "💡 上記の重大ミス記録を確認しましたか？"
    read -p "   確認完了なら [Enter]、スキップするなら [s] を入力: " confirm
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        log_warn "⚠️ PRESIDENT_MISTAKES.md の確認をスキップしました（非推奨）"
    else
        log_success "✅ PRESIDENT_MISTAKES.md の内容を確認しました"
    fi
    echo ""
}

# Step 2: 最新作業記録確認
step2_latest_work_records() {
    echo "📊 =========================================="
    echo "📋 Step 2: 最新作業記録確認"
    echo "📊 =========================================="
    echo ""
    
    log_info "📈 最新作業記録確認中..."
    if [ -f "logs/work-records.md" ]; then
        echo "--- 最新作業記録（直近3件）---"
        
        # 最新3件の作業記録タイトルを表示
        latest_records=$(grep "## 🔧 \*\*作業記録 #" logs/work-records.md | tail -3)
        echo "$latest_records"
        echo ""
        
        # 最新作業記録の詳細を表示
        latest_record_num=$(echo "$latest_records" | tail -1 | grep -o "#[0-9]\+" | tr -d '#')
        if [ -n "$latest_record_num" ]; then
            echo "--- 最新作業記録 #$latest_record_num 詳細 ---"
            grep -A 15 "## 🔧 \*\*作業記録 #$latest_record_num" logs/work-records.md | head -20
            echo "..."
        fi
        echo ""
        echo "--- 最新作業記録確認完了 ---"
        log_success "✅ Step 2 完了: 最新作業記録確認済み"
    else
        log_warn "⚠️ logs/work-records.md が見つかりません"
    fi
    echo ""
}

# Step 3: システム状況確認
step3_system_status() {
    echo "🤖 =========================================="
    echo "📋 Step 3: AI組織システム状況確認"
    echo "🤖 =========================================="
    echo ""
    
    log_info "📊 システム状況確認中..."
    
    # tmuxセッション確認
    if command -v tmux &> /dev/null; then
        tmux_sessions=$(tmux list-sessions 2>/dev/null || echo "なし")
        session_count=$(echo "$tmux_sessions" | grep -v "なし" | wc -l)
        
        echo "--- tmuxセッション状況 ---"
        echo "$tmux_sessions"
        echo ""
        echo "📊 稼働セッション数: $session_count"
        
        # 重要セッション確認
        president_status="🔴 停止中"
        multiagent_status="🔴 停止中"
        
        if echo "$tmux_sessions" | grep -q "president"; then
            president_status="🟢 稼働中"
        fi
        
        if echo "$tmux_sessions" | grep -q "multiagent"; then
            multiagent_status="🟢 稼働中"
        fi
        
        echo "👑 PRESIDENT セッション: $president_status"
        echo "👥 multiagent セッション: $multiagent_status"
        echo ""
        
        # 推奨アクション
        if [ "$president_status" = "🔴 停止中" ] && [ "$multiagent_status" = "🔴 停止中" ]; then
            echo "💡 推奨アクション:"
            echo "   ./ai-agents/manage.sh claude-auth    # AI組織システム起動"
            echo ""
        fi
        
        log_success "✅ Step 3 完了: システム状況確認済み"
    else
        log_error "❌ tmux がインストールされていません"
    fi
    echo ""
}

# Step 4: 作業記録準備
step4_work_record_preparation() {
    echo "📝 =========================================="
    echo "📋 Step 4: 作業記録準備"
    echo "📝 =========================================="
    echo ""
    
    log_info "📋 次の作業記録番号確認中..."
    
    if [ -f "logs/work-records.md" ]; then
        # 最新の作業記録番号を取得
        latest_num=$(grep "## 🔧 \*\*作業記録 #" logs/work-records.md | grep -o "#[0-9]\+" | tr -d '#' | sort -n | tail -1)
        next_num=$((latest_num + 1))
        
        echo "📊 現在の状況:"
        echo "   最新作業記録: #$latest_num"
        echo "   次の作業記録番号: #$next_num"
        echo ""
        
        echo "📝 作業記録テンプレート（#$next_num）:"
        echo "--- ここからコピー ---"
        cat << EOF
## 🔧 **作業記録 #$next_num: [作業タイトル]**

- **日付**: $(date '+%Y-%m-%d')
- **分類**: [🔴 緊急修正/🟡 機能改善/🟢 新機能/🔵 メンテナンス/⚫ 調査・分析]
- **概要**: [作業内容の概要]
- **課題**: [何が問題だったか]
- **対応**: [どう対応したか]
- **結果**: [結果どうなったか]
- **備考**: [今後の注意点・関連事項]
EOF
        echo "--- ここまでコピー ---"
        echo ""
        log_success "✅ Step 4 完了: 作業記録#$next_num 準備完了"
    else
        log_warn "⚠️ logs/work-records.md が見つかりません"
        echo "💡 新規作業記録ファイルを作成してください"
    fi
    echo ""
}

# Step 5: 作業開始チェックリスト
step5_checklist() {
    echo "✅ =========================================="
    echo "📋 Step 5: 作業開始チェックリスト"
    echo "✅ =========================================="
    echo ""
    
    echo "🔥 必須確認項目（PRESIDENT_MISTAKES.md準拠）:"
    echo "   □ 全ワーカー状況把握の準備はできていますか？"
    echo "   □ 指示送信後のEnter実行を忘れない準備はできていますか？"
    echo "   □ 完了まで監督継続する意識はありますか？"
    echo "   □ 推測・憶測ではなく確認済み事実のみ報告する準備はできていますか？"
    echo "   □ AI組織システムを活用する準備はできていますか？"
    echo "   □ トークン効率を考慮した作業計画はできていますか？"
    echo ""
    
    echo "💡 推奨コマンド:"
    echo "   ./ai-agents/manage.sh log-check          # 重要ログ再確認"
    echo "   ./ai-agents/manage.sh claude-auth        # AI組織システム起動"
    echo "   ./ai-agents/manage.sh monitoring         # 軽量監視開始"
    echo ""
    
    log_success "✅ Step 5 完了: 作業開始チェックリスト確認済み"
    echo ""
}

# 最終サマリー
show_final_summary() {
    echo "🎯 =========================================="
    echo "📋 作業開始準備完了サマリー"
    echo "🎯 =========================================="
    echo ""
    echo "✅ 完了したチェック項目:"
    echo "   📋 Step 1: PRESIDENT_MISTAKES.md 確認"
    echo "   📊 Step 2: 最新作業記録確認"
    echo "   🤖 Step 3: システム状況確認"
    echo "   📝 Step 4: 作業記録準備"
    echo "   ✅ Step 5: 作業開始チェックリスト"
    echo ""
    echo "🚀 作業開始準備が完了しました！"
    echo ""
    echo "📅 準備完了日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "💡 安全で効率的な作業をお楽しみください"
    echo ""
}

# メイン処理
main() {
    case "${1:-full}" in
        "quick"|"q")
            # クイックチェック（PRESIDENT_MISTAKES.md + システム状況のみ）
            show_startup_header
            step1_president_mistakes
            step3_system_status
            echo "⚡ クイックチェック完了"
            ;;
        "mistakes"|"m")
            # PRESIDENT_MISTAKES.mdのみ
            show_startup_header
            step1_president_mistakes
            ;;
        "records"|"r")
            # 作業記録のみ
            show_startup_header
            step2_latest_work_records
            step4_work_record_preparation
            ;;
        "full"|*)
            # フルチェック（全項目）
            show_startup_header
            step1_president_mistakes
            step2_latest_work_records
            step3_system_status
            step4_work_record_preparation
            step5_checklist
            show_final_summary
            ;;
    esac
}

# スクリプト実行
main "$@" 