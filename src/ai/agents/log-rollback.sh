#!/bin/bash
# 🔄 ログクリーンアップロールバックシステム
# 緊急復元・部分復元・完全復元機能

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

# バックアップディレクトリ検索
find_backup_directories() {
    find "$SCRIPT_DIR" -maxdepth 1 -name "backup-cleanup-*" -type d | sort -r
}

# 最新バックアップ選択
select_backup() {
    local backups=($(find_backup_directories))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_error "❌ バックアップディレクトリが見つかりません"
        exit 1
    fi
    
    log_info "📁 利用可能なバックアップ:"
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local backup_date=$(basename "$backup" | sed 's/backup-cleanup-//')
        local backup_size=$(du -sh "$backup" | cut -f1)
        local file_count=$(find "$backup/original" -type f 2>/dev/null | wc -l || echo "0")
        
        echo "  [$((i+1))] $backup_date ($backup_size, ${file_count}ファイル)"
    done
    
    if [ "$1" = "auto" ]; then
        echo "${backups[0]}"
    else
        echo ""
        read -p "復元するバックアップを選択してください (1-${#backups[@]}): " choice
        
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#backups[@]}" ]; then
            echo "${backups[$((choice-1))]}"
        else
            log_error "❌ 無効な選択です"
            exit 1
        fi
    fi
}

# バックアップ検証
verify_backup() {
    local backup_dir="$1"
    
    log_info "🔍 バックアップ検証中: $(basename "$backup_dir")"
    
    # 基本構造確認
    if [ ! -d "$backup_dir/original" ]; then
        log_error "❌ original ディレクトリが見つかりません"
        return 1
    fi
    
    # チェックサム検証
    if [ -f "$backup_dir/checksums.md5" ]; then
        log_info "🔒 チェックサム検証中..."
        if (cd "$backup_dir" && md5sum -c checksums.md5 --quiet 2>/dev/null); then
            log_success "✅ チェックサム検証成功"
        else
            log_warn "⚠️ チェックサム検証失敗 - 一部ファイルが変更されている可能性"
        fi
    else
        log_warn "⚠️ チェックサムファイルが見つかりません"
    fi
    
    # ファイル数確認
    local backup_count=$(find "$backup_dir/original" -type f | wc -l)
    log_info "📊 バックアップファイル数: $backup_count"
    
    # バックアップ情報表示
    if [ -f "$backup_dir/backup-info.json" ]; then
        log_info "📋 バックアップ情報:"
        if command -v jq >/dev/null 2>&1; then
            jq -r '"  - 作成日時: " + .timestamp' "$backup_dir/backup-info.json" 2>/dev/null || echo "  - 情報読み取りエラー"
            jq -r '"  - ファイル数: " + (.file_count | tostring)' "$backup_dir/backup-info.json" 2>/dev/null || echo ""
            jq -r '"  - 総サイズ: " + .total_size' "$backup_dir/backup-info.json" 2>/dev/null || echo ""
        else
            cat "$backup_dir/backup-info.json" | grep -E '"timestamp"|"file_count"|"total_size"' | sed 's/.*".*": *"*\(.*\)"*,*/  - \1/'
        fi
    fi
    
    return 0
}

# 緊急復元 (完全復元)
emergency_restore() {
    local backup_dir="$1"
    
    log_warn "🚨 緊急復元モード - 完全復元実行中"
    
    # 現在の状態をバックアップ
    local emergency_backup="$SCRIPT_DIR/emergency-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$emergency_backup"
    
    if [ -d "$LOGS_DIR" ]; then
        cp -r "$LOGS_DIR" "$emergency_backup/" 2>/dev/null || true
    fi
    if [ -d "$SESSIONS_DIR" ]; then
        cp -r "$SESSIONS_DIR" "$emergency_backup/" 2>/dev/null || true
    fi
    
    log_info "💾 現在の状態をバックアップ: $emergency_backup"
    
    # 完全復元実行
    log_info "🔄 完全復元実行中..."
    
    # ディレクトリクリア
    rm -rf "$LOGS_DIR"/* 2>/dev/null || true
    rm -rf "$SESSIONS_DIR"/* 2>/dev/null || true
    
    # 復元実行
    if [ -d "$backup_dir/original/logs" ]; then
        cp -r "$backup_dir/original/logs"/* "$LOGS_DIR/" 2>/dev/null || true
        log_success "✅ ログディレクトリ復元完了"
    fi
    
    if [ -d "$backup_dir/original/sessions" ]; then
        cp -r "$backup_dir/original/sessions"/* "$SESSIONS_DIR/" 2>/dev/null || true
        log_success "✅ セッションディレクトリ復元完了"
    fi
    
    # 復元検証
    local restored_count=$(find "$LOGS_DIR" "$SESSIONS_DIR" -type f 2>/dev/null | wc -l)
    local original_count=$(find "$backup_dir/original" -type f 2>/dev/null | wc -l)
    
    if [ "$restored_count" -eq "$original_count" ]; then
        log_success "🎉 緊急復元成功: ${restored_count}個のファイルを復元"
    else
        log_warn "⚠️ 復元ファイル数が一致しません: 復元=$restored_count, 元=$original_count"
    fi
    
    log_info "📍 緊急バックアップ保存場所: $emergency_backup"
}

# 部分復元
partial_restore() {
    local backup_dir="$1"
    local category="$2"
    
    log_info "🔧 部分復元モード: $category"
    
    case "$category" in
        "status")
            log_info "📊 ステータスログ部分復元中..."
            find "$backup_dir/original/logs" -name "*status*" -type f | while read -r file; do
                cp "$file" "$LOGS_DIR/"
                log_info "復元: $(basename "$file")"
            done
            ;;
        "errors")
            log_info "🚨 エラーログ部分復元中..."
            find "$backup_dir/original/logs" -name "*error*" -o -name "*ERROR*" -o -name "*FAIL*" -type f | while read -r file; do
                cp "$file" "$LOGS_DIR/"
                log_info "復元: $(basename "$file")"
            done
            ;;
        "system")
            log_info "⚙️ システムログ部分復元中..."
            find "$backup_dir/original/logs" -name "*master*" -o -name "*compliance*" -o -name "*emergency*" -type f | while read -r file; do
                cp "$file" "$LOGS_DIR/"
                log_info "復元: $(basename "$file")"
            done
            ;;
        "sessions")
            log_info "👥 セッション部分復元中..."
            if [ -d "$backup_dir/original/sessions" ]; then
                cp -r "$backup_dir/original/sessions"/* "$SESSIONS_DIR/" 2>/dev/null || true
            fi
            ;;
        "large")
            log_info "📈 大容量ファイル部分復元中..."
            find "$backup_dir/original/logs" -type f -size +1M | while read -r file; do
                cp "$file" "$LOGS_DIR/"
                local size=$(du -h "$file" | cut -f1)
                log_info "復元: $(basename "$file") ($size)"
            done
            ;;
        *)
            log_error "❌ 無効なカテゴリ: $category"
            exit 1
            ;;
    esac
    
    log_success "✅ 部分復元完了: $category"
}

# ファイル個別復元
restore_specific_file() {
    local backup_dir="$1"
    local filename="$2"
    
    log_info "📄 個別ファイル復元: $filename"
    
    # ファイル検索
    local found_file=$(find "$backup_dir/original" -name "$filename" -type f | head -1)
    
    if [ -z "$found_file" ]; then
        log_error "❌ ファイルが見つかりません: $filename"
        return 1
    fi
    
    # 復元先判定
    local dest_dir
    if [[ "$found_file" =~ /logs/ ]]; then
        dest_dir="$LOGS_DIR"
    elif [[ "$found_file" =~ /sessions/ ]]; then
        dest_dir="$SESSIONS_DIR"
    else
        dest_dir="$LOGS_DIR"
    fi
    
    # 既存ファイル確認
    if [ -f "$dest_dir/$filename" ]; then
        local backup_existing="$dest_dir/$filename.backup-$(date +%H%M%S)"
        mv "$dest_dir/$filename" "$backup_existing"
        log_info "📦 既存ファイルをバックアップ: $backup_existing"
    fi
    
    # 復元実行
    cp "$found_file" "$dest_dir/"
    log_success "✅ ファイル復元完了: $filename → $dest_dir/"
}

# 復元状況確認
check_restore_status() {
    log_info "📊 復元状況確認"
    
    echo "## 📁 現在のディレクトリ状況"
    echo "ログディレクトリ:"
    if [ -d "$LOGS_DIR" ]; then
        local log_count=$(find "$LOGS_DIR" -type f | wc -l)
        local log_size=$(du -sh "$LOGS_DIR" | cut -f1)
        echo "  - ファイル数: $log_count"
        echo "  - 総サイズ: $log_size"
    else
        echo "  - ディレクトリなし"
    fi
    
    echo ""
    echo "セッションディレクトリ:"
    if [ -d "$SESSIONS_DIR" ]; then
        local session_count=$(find "$SESSIONS_DIR" -type f | wc -l)
        local session_size=$(du -sh "$SESSIONS_DIR" | cut -f1)
        echo "  - ファイル数: $session_count"
        echo "  - 総サイズ: $session_size"
    else
        echo "  - ディレクトリなし"
    fi
    
    echo ""
    echo "## 📋 利用可能なバックアップ"
    local backups=($(find_backup_directories))
    for backup in "${backups[@]}"; do
        local backup_date=$(basename "$backup" | sed 's/backup-cleanup-//')
        local backup_size=$(du -sh "$backup" | cut -f1)
        echo "  - $backup_date ($backup_size)"
    done
    
    echo ""
    echo "## 🔧 AI組織システム状況"
    if tmux has-session -t president 2>/dev/null; then
        echo "  - President セッション: 🟢 アクティブ"
    else
        echo "  - President セッション: 🔴 停止中"
    fi
    
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "  - Multiagent セッション: 🟢 アクティブ"
    else
        echo "  - Multiagent セッション: 🔴 停止中"
    fi
}

# 対話式復元
interactive_restore() {
    log_info "🎯 対話式復元モード"
    
    # バックアップ選択
    local backup_dir=$(select_backup)
    
    # バックアップ検証
    if ! verify_backup "$backup_dir"; then
        log_error "❌ バックアップ検証に失敗しました"
        exit 1
    fi
    
    echo ""
    echo "復元オプションを選択してください:"
    echo "1. 🚨 緊急復元 (完全復元)"
    echo "2. 📊 ステータスログのみ復元"
    echo "3. 🚨 エラーログのみ復元"
    echo "4. ⚙️ システムログのみ復元"
    echo "5. 👥 セッションのみ復元"
    echo "6. 📈 大容量ファイルのみ復元"
    echo "7. 📄 個別ファイル復元"
    echo "8. 📊 復元状況確認のみ"
    echo ""
    
    read -p "選択してください (1-8): " choice
    
    case "$choice" in
        1)
            echo ""
            log_warn "⚠️ 完全復元により現在のログが全て置き換えられます"
            read -p "続行しますか？ (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                emergency_restore "$backup_dir"
            else
                log_info "復元をキャンセルしました"
            fi
            ;;
        2) partial_restore "$backup_dir" "status" ;;
        3) partial_restore "$backup_dir" "errors" ;;
        4) partial_restore "$backup_dir" "system" ;;
        5) partial_restore "$backup_dir" "sessions" ;;
        6) partial_restore "$backup_dir" "large" ;;
        7)
            echo ""
            read -p "復元するファイル名を入力してください: " filename
            restore_specific_file "$backup_dir" "$filename"
            ;;
        8) check_restore_status ;;
        *)
            log_error "❌ 無効な選択です"
            exit 1
            ;;
    esac
}

# メイン実行
main() {
    echo "🔄 AI-Agents ログロールバックシステム"
    echo "======================================"
    echo ""
    
    # 基本チェック
    if [ ! -d "$SCRIPT_DIR" ]; then
        log_error "❌ スクリプトディレクトリが見つかりません"
        exit 1
    fi
    
    # バックアップ存在確認
    local backup_count=$(find_backup_directories | wc -l)
    if [ "$backup_count" -eq 0 ]; then
        log_error "❌ 復元可能なバックアップが見つかりません"
        echo ""
        echo "バックアップを作成するには:"
        echo "  ./ai-agents/LOG_CLEANUP_SYSTEM.sh backup"
        exit 1
    fi
    
    log_info "📁 ${backup_count}個のバックアップが利用可能です"
    
    # 対話式復元実行
    interactive_restore
    
    echo ""
    log_success "🎉 ロールバック操作完了"
    
    # 最終状況確認
    echo ""
    check_restore_status
}

# コマンドライン引数処理
case "${1:-main}" in
    "emergency")
        # 緊急復元（最新バックアップから完全復元）
        backup_dir=$(select_backup auto)
        emergency_restore "$backup_dir"
        ;;
    "status")
        check_restore_status
        ;;
    "list")
        echo "📁 利用可能なバックアップ:"
        find_backup_directories | while read -r backup; do
            echo "  - $(basename "$backup")"
        done
        ;;
    "verify")
        if [ -n "$2" ]; then
            verify_backup "$2"
        else
            backup_dir=$(select_backup auto)
            verify_backup "$backup_dir"
        fi
        ;;
    "main")
        main
        ;;
    *)
        echo "🔄 ログロールバックシステム"
        echo ""
        echo "使用方法:"
        echo "  $0 main       # 対話式復元"
        echo "  $0 emergency  # 緊急完全復元"
        echo "  $0 status     # 現在の状況確認"
        echo "  $0 list       # バックアップ一覧"
        echo "  $0 verify     # バックアップ検証"
        echo ""
        echo "例:"
        echo "  $0                    # 対話式復元開始"
        echo "  $0 emergency          # 最新バックアップから緊急復元"
        echo "  $0 status            # 復元状況確認"
        ;;
esac