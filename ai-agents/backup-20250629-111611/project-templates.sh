#!/bin/bash

# 🎯 プロジェクト別編成テンプレートシステム
# 最強チーム構成の自動編成

# プロジェクトテンプレート定義関数
get_project_name() {
    case $1 in
        "webapp") echo "🌐ウェブアプリ開発" ;;
        "mobile") echo "📱モバイルアプリ開発" ;;
        "security") echo "🔐セキュリティ監査" ;;
        "data") echo "📊データ分析・AI" ;;
        "devops") echo "⚙️DevOps・インフラ" ;;
        "optimization") echo "⚡パフォーマンス最適化" ;;
        "research") echo "🔬研究・イノベーション" ;;
        "integration") echo "🔗システム統合" ;;
        "migration") echo "🚚システム移行" ;;
        "audit") echo "📋品質監査" ;;
        *) echo "" ;;
    esac
}

# 利用可能プロジェクト一覧
get_available_projects() {
    echo "webapp mobile security data devops optimization research integration migration audit"
}

# 詳細編成テンプレート
setup_project_team() {
    local project_type=$1
    local project_name=${2:-"新規プロジェクト"}
    
    if [ -z "$project_type" ]; then
        echo "使用方法: setup_project_team [project_type] [project_name]"
        echo "利用可能プロジェクト: $(get_available_projects)"
        return 1
    fi
    
    local project_display_name=$(get_project_name "$project_type")
    if [ -z "$project_display_name" ]; then
        echo "❌ 無効なプロジェクトタイプ: $project_type"
        echo "利用可能: $(get_available_projects)"
        return 1
    fi
    
    echo "🚀 $project_display_name チーム編成開始"
    echo "📋 プロジェクト: $project_name"
    echo ""
    
    case $project_type in
        "webapp")
            setup_webapp_team "$project_name"
            ;;
        "mobile")
            setup_mobile_team "$project_name"
            ;;
        "security")
            setup_security_team "$project_name"
            ;;
        "data")
            setup_data_team "$project_name"
            ;;
        "devops")
            setup_devops_team "$project_name"
            ;;
        "optimization")
            setup_optimization_team "$project_name"
            ;;
        "research")
            setup_research_team "$project_name"
            ;;
        "integration")
            setup_integration_team "$project_name"
            ;;
        "migration")
            setup_migration_team "$project_name"
            ;;
        "audit")
            setup_audit_team "$project_name"
            ;;
        *)
            echo "❌ 未対応のプロジェクトタイプ"
            return 1
            ;;
    esac
    
    echo ""
    echo "✅ $project_display_name チーム編成完了"
    
    # チーム編成記録
    log_team_setup "$project_type" "$project_name"
}

# ウェブアプリ開発チーム
setup_webapp_team() {
    local project_name=$1
    echo "🌐 ウェブアプリ開発チーム編成"
    
    # BOSS1をプロジェクトマネージャーに
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour238,fg=colour15] 🔵作業中 👔プロジェクトマネージャー │ $project_name統括 #[default]"
    
    # 専門チーム編成
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour238,fg=colour15] 🔵作業中 💻フロントエンドリード │ React・UI実装 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour238,fg=colour15] 🔵作業中 🔧バックエンドリード │ API・DB設計 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour238,fg=colour15] 🔵作業中 🎨UX/UIリード │ デザイン・UX最適化 #[default]"
    
    # 初期タスク配布（Enter2回実行保証）
    tmux send-keys -t multiagent:0.0 ">👔【チーム統括】$project_name のプロジェクト開始。チーム統括をお願いします" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.0 C-m
    
    tmux send-keys -t multiagent:0.1 ">💻【フロントエンド】フロントエンド設計・実装計画を作成してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.1 C-m
    
    tmux send-keys -t multiagent:0.2 ">🔧【バックエンド】バックエンドアーキテクチャ設計をお願いします" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.2 C-m
    
    tmux send-keys -t multiagent:0.3 ">🎨【UX/UI】UX/UI設計方針を策定してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.3 C-m
}

# モバイルアプリ開発チーム
setup_mobile_team() {
    local project_name=$1
    echo "📱 モバイルアプリ開発チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔モバイルPM │ $project_name統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔵作業中 📱モバイル開発リード │ iOS・Android開発 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🔵作業中 🔌API開発リード │ モバイルAPI設計 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 🔵作業中 🎨モバイルUXリード │ モバイルUX設計 #[default]"
}

# セキュリティ監査チーム
setup_security_team() {
    local project_name=$1
    echo "🔐 セキュリティ監査チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔セキュリティマネージャー │ $project_name監査統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔍分析中 🔐セキュリティアナリスト │ 脆弱性分析 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🔍分析中 ⚙️DevSecOps │ インフラセキュリティ #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 🧪テスト中 🧪ペネトレーションテスター │ 侵入テスト #[default]"
    
    # セキュリティ監査タスク配布（Enter2回実行保証）
    tmux send-keys -t multiagent:0.0 ">🔐【監査統括】$project_name のセキュリティ監査を統括してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.0 C-m
    
    tmux send-keys -t multiagent:0.1 ">🔍【脆弱性分析】システムの脆弱性分析を実施してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.1 C-m
    
    tmux send-keys -t multiagent:0.2 ">⚙️【インフラセキュリティ】インフラのセキュリティ状況を確認してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.2 C-m
    
    tmux send-keys -t multiagent:0.3 ">🧪【侵入テスト】ペネトレーションテストを実行してください" C-m
    sleep 0.5 && tmux send-keys -t multiagent:0.3 C-m
}

# データ分析・AIチーム
setup_data_team() {
    local project_name=$1
    echo "📊 データ分析・AIチーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔データサイエンスマネージャー │ $project_name分析統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔍分析中 📊データサイエンティスト │ データ分析・統計 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🤖作業中 🤖AI/MLエンジニア │ 機械学習・AI開発 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 🧠思考中 🔬リサーチャー │ 研究・アルゴリズム設計 #[default]"
}

# DevOps・インフラチーム
setup_devops_team() {
    local project_name=$1
    echo "⚙️ DevOps・インフラチーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔インフラマネージャー │ $project_name基盤統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] ⚙️設定中 ⚙️DevOpsエンジニア │ CI/CD・自動化 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] ☁️構築中 ☁️クラウドアーキテクト │ AWS・インフラ設計 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 📊監視中 📊SREエンジニア │ 監視・信頼性向上 #[default]"
}

# パフォーマンス最適化チーム
setup_optimization_team() {
    local project_name=$1
    echo "⚡ パフォーマンス最適化チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔最適化マネージャー │ $project_name性能向上統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔍分析中 🔧バックエンド最適化 │ サーバー性能改善 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🔍分析中 💻フロントエンド最適化 │ UI性能改善 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 📊分析中 📊データベース最適化 │ DB性能チューニング #[default]"
}

# 研究・イノベーションチーム
setup_research_team() {
    local project_name=$1
    echo "🔬 研究・イノベーションチーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔リサーチマネージャー │ $project_name研究統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🧠思考中 🔬技術リサーチャー │ 先端技術調査 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🧠思考中 🤖AIリサーチャー │ AI・機械学習研究 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 💡企画中 📋プロダクトイノベーター │ 新機能・戦略企画 #[default]"
}

# システム統合チーム
setup_integration_team() {
    local project_name=$1
    echo "🔗 システム統合チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔統合マネージャー │ $project_name統合統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔗連携中 🔗システム統合エンジニア │ API連携・統合 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🏗️設計中 🏗️アーキテクチャデザイナー │ システム設計 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 🧪テスト中 🧪統合テスター │ 結合テスト・検証 #[default]"
}

# システム移行チーム
setup_migration_team() {
    local project_name=$1
    echo "🚚 システム移行チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔移行マネージャー │ $project_name移行統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 📦移行中 📦データマイグレーター │ データ移行 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🔄変換中 🔄システム変換エンジニア │ システム変換 #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] ✅検証中 ✅移行検証エンジニア │ 移行検証・テスト #[default]"
}

# 品質監査チーム
setup_audit_team() {
    local project_name=$1
    echo "📋 品質監査チーム編成"
    
    tmux select-pane -t multiagent:0.0 -T "#[bg=colour236,fg=colour15] 🔵作業中 👔品質マネージャー │ $project_name品質統括 #[default]"
    tmux select-pane -t multiagent:0.1 -T "#[bg=colour236,fg=colour15] 🔍監査中 📋品質監査員 │ コード品質監査 #[default]"
    tmux select-pane -t multiagent:0.2 -T "#[bg=colour236,fg=colour15] 🧪テスト中 🧪QAエンジニア │ 総合品質テスト #[default]"
    tmux select-pane -t multiagent:0.3 -T "#[bg=colour236,fg=colour15] 📊分析中 📊品質アナリスト │ 品質メトリクス分析 #[default]"
}

# チーム編成ログ記録
log_team_setup() {
    local project_type=$1
    local project_name=$2
    local project_display_name=$(get_project_name "$project_type")
    
    echo "$(date): $project_display_name チーム編成 - $project_name" >> /tmp/team-setups.log
}

# 利用可能プロジェクト一覧
list_projects() {
    echo "🎯 利用可能なプロジェクトテンプレート:"
    echo ""
    for project in $(get_available_projects); do
        echo "  $project: $(get_project_name "$project")"
    done
    echo ""
    echo "使用例: $0 setup webapp 'ECサイト開発'"
}

# 現在のチーム編成表示
show_current_team() {
    echo "👥 現在のチーム編成:"
    echo "  👑 PRESIDENT: $(tmux display-message -t president:0 -p "#{pane_title}")"
    echo "  👔 BOSS1: $(tmux display-message -t multiagent:0.0 -p "#{pane_title}")"
    echo "  🔸 WORKER1: $(tmux display-message -t multiagent:0.1 -p "#{pane_title}")"
    echo "  🔸 WORKER2: $(tmux display-message -t multiagent:0.2 -p "#{pane_title}")"
    echo "  🔸 WORKER3: $(tmux display-message -t multiagent:0.3 -p "#{pane_title}")"
}

# 使用方法
case "$1" in
    "setup")
        setup_project_team "$2" "$3"
        ;;
    "list")
        list_projects
        ;;
    "show")
        show_current_team
        ;;
    *)
        echo "🎯 プロジェクト別編成テンプレートシステム"
        echo ""
        echo "使用方法:"
        echo "  $0 setup [project_type] [project_name]     # プロジェクトチーム編成"
        echo "  $0 list                                     # 利用可能プロジェクト一覧"
        echo "  $0 show                                     # 現在のチーム編成表示"
        echo ""
        echo "例:"
        echo "  $0 setup webapp 'ECサイト開発'"
        echo "  $0 setup security 'セキュリティ監査'"
        echo "  $0 setup data 'データ分析プロジェクト'"
        ;;
esac