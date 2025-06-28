#!/bin/bash

# =============================================================================
# 要件定義書更新管理スクリプト
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REQUIREMENTS_FILE="docs/REQUIREMENTS_SPECIFICATION.md"
BACKUP_DIR="archive/requirements-backups"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

show_menu() {
    clear
    echo -e "${BLUE}📋 要件定義書管理システム${NC}"
    echo "============================="
    echo ""
    echo "1) TODO更新 - タスク状況更新"
    echo "2) 進捗更新 - プロジェクト進捗反映"
    echo "3) 機能追加 - 新機能要件追加"
    echo "4) バージョン更新 - 版数管理"
    echo "5) バックアップ作成 - 履歴保存"
    echo "6) 差分確認 - 変更点確認"
    echo "0) 終了"
    echo ""
}

backup_requirements() {
    log_info "要件定義書をバックアップ中..."
    
    # バックアップディレクトリ作成
    mkdir -p "$BACKUP_DIR"
    
    # タイムスタンプ付きバックアップ
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="${BACKUP_DIR}/requirements_${timestamp}.md"
    
    cp "$REQUIREMENTS_FILE" "$backup_file"
    log_success "バックアップ完了: $backup_file"
}

update_todo() {
    log_info "TODO管理セクションを更新中..."
    
    echo "現在のTODO状況を入力してください："
    echo ""
    echo "🔥 緊急度: 高"
    read -p "新規緊急タスク: " urgent_task
    
    echo "⚠️ 緊急度: 中"
    read -p "新規中程度タスク: " medium_task
    
    echo "📈 緊急度: 低"
    read -p "新規低緊急度タスク: " low_task
    
    echo "✅ 完了タスク"
    read -p "完了したタスク: " completed_task
    
    # TODO更新日時を記録
    current_date=$(date +"%Y-%m-%d")
    
    log_success "TODO更新完了"
    echo "手動でファイルを編集して反映してください: $REQUIREMENTS_FILE"
}

update_progress() {
    log_info "プロジェクト進捗を更新中..."
    
    echo "プロジェクト進捗情報を入力："
    read -p "完了した機能: " completed_feature
    read -p "進行中の作業: " in_progress_work
    read -p "次のマイルストーン: " next_milestone
    
    log_success "進捗情報更新完了"
}

add_feature() {
    log_info "新機能要件を追加中..."
    
    echo "新機能の詳細を入力："
    read -p "機能名: " feature_name
    read -p "要件ID (REQ-XXX): " requirement_id
    read -p "優先度 (必須/高/中/低): " priority
    read -p "説明: " description
    
    echo ""
    echo "新機能要件:"
    echo "名前: $feature_name"
    echo "ID: $requirement_id"
    echo "優先度: $priority"
    echo "説明: $description"
    
    log_success "新機能要件準備完了"
    echo "手動でファイルに追加してください: $REQUIREMENTS_FILE"
}

update_version() {
    log_info "バージョン情報を更新中..."
    
    # 現在のバージョンを取得
    current_version=$(grep "**バージョン**:" "$REQUIREMENTS_FILE" | sed 's/.*: //')
    echo "現在のバージョン: $current_version"
    
    read -p "新しいバージョン: " new_version
    read -p "変更内容: " change_description
    
    # バックアップ後、バージョン更新
    backup_requirements
    
    # バージョン情報更新
    current_date=$(date +"%Y-%m-%d")
    
    log_success "バージョン更新準備完了"
    echo "手動でバージョン情報を更新してください:"
    echo "- バージョン: $new_version"
    echo "- 更新日: $current_date"
    echo "- 変更内容: $change_description"
}

show_diff() {
    log_info "最新の変更点を確認中..."
    
    if [ -d "$BACKUP_DIR" ]; then
        latest_backup=$(ls -t "$BACKUP_DIR"/*.md | head -1)
        if [ -f "$latest_backup" ]; then
            echo "最新バックアップとの差分:"
            echo "========================"
            diff "$latest_backup" "$REQUIREMENTS_FILE" || true
        else
            log_warning "バックアップファイルが見つかりません"
        fi
    else
        log_warning "バックアップディレクトリが存在しません"
    fi
}

# メイン処理
main() {
    while true; do
        show_menu
        read -p "選択してください [0-6]: " choice
        echo ""
        
        case $choice in
            1) update_todo;;
            2) update_progress;;
            3) add_feature;;
            4) update_version;;
            5) backup_requirements;;
            6) show_diff;;
            0) 
                log_success "要件定義書管理を終了します"
                exit 0
                ;;
            *)
                echo "無効な選択です。0-6を入力してください。"
                ;;
        esac
        
        echo ""
        read -p "Enterキーでメニューに戻る..."
    done
}

# 実行
main "$@"