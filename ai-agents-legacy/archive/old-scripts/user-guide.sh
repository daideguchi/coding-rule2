#!/bin/bash
# 🎯 初心者向けAI組織立ち上げガイド
# 誰でも迷わずAI組織システムを立ち上げられる案内システム

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
show_welcome_header() {
    clear
    echo ""
    echo "🎯 =========================================="
    echo "👋 初心者向けAI組織立ち上げガイド"
    echo "🎯 =========================================="
    echo ""
    echo "💡 このガイドで、誰でも簡単にAI組織システムを立ち上げられます！"
    echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# 現在の状況確認
check_current_status() {
    echo "🔍 =========================================="
    echo "📋 Step 1: 現在の状況確認"
    echo "🔍 =========================================="
    echo ""
    
    log_info "🔍 現在のAI組織システム状況を確認中..."
    
    # tmuxセッション確認
    if command -v tmux &> /dev/null; then
        tmux_sessions=$(tmux list-sessions 2>/dev/null || echo "なし")
        
        president_running=false
        multiagent_running=false
        
        if echo "$tmux_sessions" | grep -q "president"; then
            president_running=true
        fi
        
        if echo "$tmux_sessions" | grep -q "multiagent"; then
            multiagent_running=true
        fi
        
        echo "📊 現在の状況:"
        echo "   👑 PRESIDENT: $([ "$president_running" = true ] && echo "🟢 稼働中" || echo "🔴 停止中")"
        echo "   👥 4人チーム: $([ "$multiagent_running" = true ] && echo "🟢 稼働中" || echo "🔴 停止中")"
        echo ""
        
        if [ "$president_running" = true ] && [ "$multiagent_running" = true ]; then
            echo "🎉 すでにAI組織システムが稼働中です！"
            echo ""
            echo "💡 次のアクション:"
            echo "   1. ./ai-agents/manage.sh president    # PRESIDENT画面を見る"
            echo "   2. ./ai-agents/manage.sh multiagent   # 4人チームを見る"
            echo "   3. プレジデントに仕事を依頼する"
            echo ""
            read -p "🚀 ガイドを続けますか？ [Enter] 続ける / [q] 終了: " choice
            if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
                echo "👋 AI組織システムをお楽しみください！"
                exit 0
            fi
        else
            echo "📋 AI組織システムを立ち上げる必要があります"
        fi
    else
        log_error "❌ tmux がインストールされていません"
        echo "💡 tmux をインストールしてください: brew install tmux"
        exit 1
    fi
    echo ""
}

# 立ち上げ手順説明
explain_startup_process() {
    echo "📚 =========================================="
    echo "📋 Step 2: 立ち上げ手順の説明"
    echo "📚 =========================================="
    echo ""
    
    echo "🎯 これから以下の手順でAI組織システムを立ち上げます:"
    echo ""
    echo "   📋 手順 1: AI組織システム起動コマンド実行"
    echo "   ⏳ 手順 2: PRESIDENT と 4人チームの自動起動（約1-2分）"
    echo "   👑 手順 3: PRESIDENT 画面確認"
    echo "   👥 手順 4: 4人チーム画面確認"
    echo "   🎉 手順 5: 完了・使い方案内"
    echo ""
    echo "💡 途中で問題が起きても、このガイドが解決方法を案内します"
    echo ""
    
    read -p "🚀 準備はいいですか？ [Enter] で開始: " 
    echo ""
}

# 実際に起動実行
execute_startup() {
    echo "🚀 =========================================="
    echo "📋 Step 3: AI組織システム起動実行"
    echo "🚀 =========================================="
    echo ""
    
    log_info "🎯 AI組織システムを起動中..."
    echo ""
    echo "⏳ 実行コマンド: ./ai-agents/manage.sh start"
    echo "⏳ 約1-2分で PRESIDENT と 4人チームが立ち上がります"
    echo "⏳ 自動で Claude Code が起動して、AI組織が活動開始します"
    echo ""
    
    read -p "🚀 実行してもよろしいですか？ [Enter] 実行 / [n] スキップ: " confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        echo "⏸️ 実行をスキップしました"
        echo "💡 手動実行する場合: ./ai-agents/manage.sh start"
        return
    fi
    
    echo ""
    log_info "🚀 AI組織システム起動中... しばらくお待ちください"
    echo ""
    
    # 実際に起動実行（統一コマンド使用）
    if ./ai-agents/manage.sh start; then
        log_success "✅ AI組織システム起動完了！"
    else
        log_error "❌ 起動中にエラーが発生しました"
        echo ""
        echo "🔧 トラブルシューティング:"
        echo "   1. ターミナルを再起動してもう一度試す"
        echo "   2. ./ai-agents/manage.sh clean でリセット後に再実行"
        echo "   3. Claude Code の認証設定を確認"
        return 1
    fi
    echo ""
}

# 画面確認ガイド
guide_screen_check() {
    echo "👀 =========================================="
    echo "📋 Step 4: 画面確認ガイド"
    echo "👀 =========================================="
    echo ""
    
    echo "🎯 AI組織システムが起動しました！画面を確認してみましょう"
    echo ""
    
    read -p "👑 まず PRESIDENT 画面を見ますか？ [Enter] 見る / [s] スキップ: " choice
    
    if [[ "$choice" != "s" && "$choice" != "S" ]]; then
        echo ""
        log_info "👑 PRESIDENT 画面を開いています..."
        echo "💡 PRESIDENT は AI組織のリーダーです"
        echo "💡 画面を閉じるには: Ctrl+B → D"
        echo ""
        sleep 2
        tmux attach-session -t president || echo "⚠️ PRESIDENT セッションが見つかりません"
        echo ""
        echo "👋 PRESIDENT 画面から戻ってきました"
    fi
    
    echo ""
    read -p "👥 次に 4人チーム画面を見ますか？ [Enter] 見る / [s] スキップ: " choice
    
    if [[ "$choice" != "s" && "$choice" != "S" ]]; then
        echo ""
        log_info "👥 4人チーム画面を開いています..."
        echo "💡 BOSS・WORKER1・WORKER2・WORKER3 の4人が協力します"
        echo "💡 クリックで画面を移動できます"
        echo "💡 画面を閉じるには: Ctrl+B → D"
        echo ""
        sleep 2
        tmux attach-session -t multiagent || echo "⚠️ multiagent セッションが見つかりません"
        echo ""
        echo "👋 4人チーム画面から戻ってきました"
    fi
    echo ""
}

# 使い方案内
show_usage_guide() {
    echo "🎉 =========================================="
    echo "📋 Step 5: 使い方案内・完了"
    echo "🎉 =========================================="
    echo ""
    
    log_success "🎉 AI組織システムの立ち上げが完了しました！"
    echo ""
    
    echo "🚀 今すぐできること:"
    echo "   1. PRESIDENT に仕事を依頼する"
    echo "      → ./ai-agents/manage.sh president"
    echo "      → 「ウェブサイトを作って」「プログラムを書いて」など"
    echo ""
    echo "   2. チーム作業を見学する"
    echo "      → ./ai-agents/manage.sh multiagent"
    echo "      → 4人のAIが協力して作業する様子を観察"
    echo ""
    echo "   3. システム状況を確認する"
    echo "      → ./ai-agents/manage.sh help（全コマンド確認）"
    echo ""
    
    echo "💡 便利コマンド:"
    echo "   ./ai-agents/manage.sh president     # PRESIDENT 画面"
    echo "   ./ai-agents/manage.sh multiagent    # 4人チーム画面"
    echo "   ./ai-agents/manage.sh monitoring    # システム監視開始"
    echo "   ./ai-agents/manage.sh clean         # システムリセット"
    echo ""
    
    echo "🔧 トラブルが起きたら:"
    echo "   ./ai-agents/manage.sh clean         # 完全リセット"
    echo "   ./ai-agents/manage.sh start --guide # ガイド付きで再実行"
    echo ""
    
    echo "🎯 AI組織システムの活用方法:"
    echo "   ✅ PRESIDENT に大きなタスクを依頼"
    echo "   ✅ チームが自動で役割分担して作業"
    echo "   ✅ 複雑なプロジェクトも協力して完成"
    echo "   ✅ 人間は完成品を受け取るだけ"
    echo ""
    
    log_success "🎊 準備完了！AI組織システムをお楽しみください！"
    echo ""
}

# クイックスタートモード
quick_start() {
    echo "⚡ =========================================="
    echo "📋 クイックスタート（上級者向け）"
    echo "⚡ =========================================="
    echo ""
    
    echo "🚀 クイックスタートを実行します"
    echo "⏳ ./ai-agents/manage.sh start を実行中..."
    echo ""
    
    if ./ai-agents/manage.sh start; then
        echo ""
        log_success "⚡ クイックスタート完了！"
        echo ""
        echo "💡 次のアクション:"
        echo "   ./ai-agents/manage.sh president     # PRESIDENT 画面"
        echo "   ./ai-agents/manage.sh multiagent    # 4人チーム画面"
        echo ""
    else
        log_error "❌ クイックスタート失敗"
        echo "💡 詳細ガイド: ./ai-agents/manage.sh start --guide"
    fi
}

# ヘルプモード
show_help() {
    echo "💡 =========================================="
    echo "📋 初心者向けAI組織立ち上げガイド - ヘルプ"
    echo "💡 =========================================="
    echo ""
    echo "🎯 使用方法:"
    echo "   ./ai-agents/user-guide.sh              # フルガイド（推奨）"
    echo "   ./ai-agents/user-guide.sh quick        # クイックスタート"
    echo "   ./ai-agents/user-guide.sh status       # 現在の状況確認のみ"
    echo "   ./ai-agents/user-guide.sh help         # このヘルプ"
    echo ""
    echo "🎯 目的:"
    echo "   初心者でも迷わずAI組織システムを立ち上げられるガイド"
    echo ""
    echo "🎯 フルガイドの流れ:"
    echo "   Step 1: 現在の状況確認"
    echo "   Step 2: 立ち上げ手順説明"
    echo "   Step 3: AI組織システム起動実行"
    echo "   Step 4: 画面確認ガイド"
    echo "   Step 5: 使い方案内・完了"
    echo ""
}

# メイン処理
main() {
    case "${1:-full}" in
        "quick"|"q")
            show_welcome_header
            quick_start
            ;;
        "status"|"s")
            show_welcome_header
            check_current_status
            ;;
        "help"|"h"|"-h"|"--help")
            show_help
            ;;
        "full"|*)
            show_welcome_header
            check_current_status
            explain_startup_process
            execute_startup
            guide_screen_check
            show_usage_guide
            ;;
    esac
}

# スクリプト実行
main "$@" 