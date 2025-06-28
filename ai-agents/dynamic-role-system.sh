#!/bin/bash

# 🔄 動的役職変更システム
# AI組織の最大の利点：必要に応じて役職を柔軟に変更

# 役職定義（拡張可能）
declare -A ROLES=(
    ["frontend"]="💻フロントエンド"
    ["backend"]="🔧バックエンド"
    ["uiux"]="🎨UI/UXデザイン"
    ["devops"]="⚙️DevOps"
    ["security"]="🔐セキュリティ"
    ["data"]="📊データ分析"
    ["ai"]="🤖AI/ML"
    ["qa"]="🧪QA/テスト"
    ["product"]="📋プロダクト"
    ["research"]="🔬リサーチ"
    ["mobile"]="📱モバイル"
    ["api"]="🔌API開発"
)

# ステータス定義
declare -A STATUSES=(
    ["waiting"]="🟡待機中"
    ["working"]="🔵作業中"
    ["completed"]="✅完了"
    ["thinking"]="🧠思考中"
    ["analyzing"]="🔍分析中"
    ["coding"]="⌨️コーディング中"
    ["testing"]="🧪テスト中"
    ["reviewing"]="👀レビュー中"
)

# 役職変更関数
change_role() {
    local worker_id=$1
    local role_key=$2
    local status_key=${3:-"waiting"}
    
    if [ -z "$worker_id" ] || [ -z "$role_key" ]; then
        echo "使用方法: change_role [worker_id] [role_key] [status_key]"
        echo "例: change_role 1 security working"
        return 1
    fi
    
    if [ ! "${ROLES[$role_key]}" ]; then
        echo "❌ 無効な役職: $role_key"
        echo "利用可能な役職: ${!ROLES[@]}"
        return 1
    fi
    
    if [ ! "${STATUSES[$status_key]}" ]; then
        echo "❌ 無効なステータス: $status_key"
        echo "利用可能なステータス: ${!STATUSES[@]}"
        return 1
    fi
    
    local role="${ROLES[$role_key]}"
    local status="${STATUSES[$status_key]}"
    local title="$status $role"
    
    echo "🔄 WORKER$worker_id の役職変更: $title"
    tmux select-pane -t multiagent:0.$worker_id -T "$title"
    
    # 変更ログ記録
    echo "$(date): WORKER$worker_id -> $title" >> /tmp/role-changes.log
    echo "✅ 役職変更完了: WORKER$worker_id"
}

# プロジェクト専用役職セット
set_project_roles() {
    local project_type=$1
    
    case $project_type in
        "webapp")
            echo "🌐 ウェブアプリ開発チーム編成"
            change_role 1 frontend working
            change_role 2 backend working  
            change_role 3 uiux working
            ;;
        "mobile")
            echo "📱 モバイルアプリ開発チーム編成"
            change_role 1 mobile working
            change_role 2 api working
            change_role 3 uiux working
            ;;
        "security")
            echo "🔐 セキュリティ監査チーム編成"
            change_role 1 security analyzing
            change_role 2 devops analyzing
            change_role 3 qa testing
            ;;
        "data")
            echo "📊 データ分析チーム編成"
            change_role 1 data analyzing
            change_role 2 ai working
            change_role 3 research thinking
            ;;
        *)
            echo "利用可能なプロジェクト: webapp, mobile, security, data"
            ;;
    esac
}

# 全員ステータス更新
update_all_status() {
    local status_key=$1
    
    if [ ! "${STATUSES[$status_key]}" ]; then
        echo "❌ 無効なステータス: $status_key"
        return 1
    fi
    
    echo "🔄 全ワーカーステータス更新: ${STATUSES[$status_key]}"
    
    for i in {1..3}; do
        local current_title=$(tmux display-message -t multiagent:0.$i -p "#{pane_title}")
        local current_role=$(echo "$current_title" | sed 's/^[^ ]* //')
        local new_title="${STATUSES[$status_key]} $current_role"
        
        tmux select-pane -t multiagent:0.$i -T "$new_title"
    done
    
    echo "✅ 全ワーカーステータス更新完了"
}

# 役職リスト表示
show_roles() {
    echo "📋 利用可能な役職:"
    for key in "${!ROLES[@]}"; do
        echo "  $key: ${ROLES[$key]}"
    done
    echo ""
    echo "📊 利用可能なステータス:"
    for key in "${!STATUSES[@]}"; do
        echo "  $key: ${STATUSES[$key]}"
    done
}

# 現在の役職表示
show_current_roles() {
    echo "👥 現在の役職編成:"
    echo "  BOSS1: $(tmux display-message -t multiagent:0.0 -p "#{pane_title}")"
    for i in {1..3}; do
        echo "  WORKER$i: $(tmux display-message -t multiagent:0.$i -p "#{pane_title}")"
    done
}

# 使用方法
case "$1" in
    "change")
        change_role "$2" "$3" "$4"
        ;;
    "project")
        set_project_roles "$2"
        ;;
    "status")
        update_all_status "$2"
        ;;
    "show")
        show_current_roles
        ;;
    "list")
        show_roles
        ;;
    *)
        echo "🔄 動的役職変更システム"
        echo ""
        echo "使用方法:"
        echo "  $0 change [worker_id] [role] [status]   # 個別役職変更"
        echo "  $0 project [type]                        # プロジェクト専用編成"
        echo "  $0 status [status]                       # 全員ステータス更新"
        echo "  $0 show                                   # 現在の役職表示"
        echo "  $0 list                                   # 利用可能役職一覧"
        echo ""
        echo "例:"
        echo "  $0 change 1 security working             # WORKER1をセキュリティ担当に"
        echo "  $0 project webapp                        # ウェブアプリ開発チーム編成"
        echo "  $0 status completed                      # 全員完了ステータス"
        ;;
esac