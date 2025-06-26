#!/bin/bash
# 🔄 Cursor Rules Auto Sync System
# cursor-rulesと.cursor/rulesの自動同期スクリプト

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[SYNC]\033[0m $1"
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

# 基本設定
SOURCE_DIR="cursor-rules"
TARGET_DIR=".cursor/rules"
BACKUP_DIR=".cursor/rules-backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ディレクトリ存在確認
check_directories() {
    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "ソースディレクトリが存在しません: $SOURCE_DIR"
        exit 1
    fi
    
    if [ ! -d ".cursor" ]; then
        log_warn ".cursorディレクトリが存在しません。作成します..."
        mkdir -p .cursor
    fi
    
    if [ ! -d "$TARGET_DIR" ]; then
        log_warn "ターゲットディレクトリが存在しません。作成します..."
        mkdir -p "$TARGET_DIR"
    fi
}

# バックアップ作成
create_backup() {
    if [ -d "$TARGET_DIR" ] && [ "$(ls -A $TARGET_DIR 2>/dev/null)" ]; then
        log_info "既存ファイルのバックアップ作成中..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$TARGET_DIR" "$BACKUP_DIR/rules_$TIMESTAMP"
        log_success "バックアップ作成完了: $BACKUP_DIR/rules_$TIMESTAMP"
    fi
}

# 差分確認
check_differences() {
    if [ -d "$TARGET_DIR" ]; then
        if ! diff -q -r "$SOURCE_DIR" "$TARGET_DIR" > /dev/null 2>&1; then
            log_info "差分が検出されました。同期が必要です。"
            return 0
        else
            log_info "ファイルは既に同期されています。"
            return 1
        fi
    else
        log_info "ターゲットディレクトリが存在しません。初回同期を実行します。"
        return 0
    fi
}

# 同期実行
sync_files() {
    log_info "同期実行中: $SOURCE_DIR → $TARGET_DIR"
    
    # ターゲットディレクトリをクリア
    if [ -d "$TARGET_DIR" ]; then
        rm -rf "$TARGET_DIR"/*
    fi
    
    # ファイルコピー
    cp -r "$SOURCE_DIR"/* "$TARGET_DIR"/
    
    # 権限設定
    find "$TARGET_DIR" -type f -name "*.mdc" -exec chmod 644 {} \;
    find "$TARGET_DIR" -type f -name "*.md" -exec chmod 644 {} \;
    
    log_success "同期完了: $(ls -la $TARGET_DIR | wc -l) ファイル"
}

# 同期後検証
verify_sync() {
    log_info "同期検証中..."
    
    if diff -q -r "$SOURCE_DIR" "$TARGET_DIR" > /dev/null 2>&1; then
        log_success "✅ 同期検証完了：ファイルが正しく同期されました"
        return 0
    else
        log_error "❌ 同期検証失敗：ファイルが正しく同期されていません"
        return 1
    fi
}

# ファイル統計表示
show_stats() {
    echo ""
    echo "📊 同期統計："
    echo "  ソース: $SOURCE_DIR ($(find $SOURCE_DIR -type f | wc -l) ファイル)"
    echo "  ターゲット: $TARGET_DIR ($(find $TARGET_DIR -type f | wc -l) ファイル)"
    echo "  更新日時: $(date)"
    echo ""
    
    echo "📁 同期されたファイル："
    find "$TARGET_DIR" -type f -name "*.mdc" -o -name "*.md" | sort | sed 's/^/  /'
    echo ""
}

# Git自動コミット（オプション） - cursor-rulesのみ対象
auto_commit() {
    if [ "$1" = "--commit" ]; then
        log_info "Git自動コミット実行中..."
        git add cursor-rules/
        if git diff --staged --quiet; then
            log_info "変更がないため、コミットはスキップされます"
        else
            git commit -m "🔄 Update cursor-rules template - $(date +'%Y-%m-%d %H:%M:%S')"
            log_success "Git自動コミット完了"
        fi
    fi
}

# メイン処理
main() {
    log_info "🔄 Cursor Rules 自動同期開始"
    echo ""
    
    check_directories
    
    if check_differences; then
        create_backup
        sync_files
        
        if verify_sync; then
            show_stats
            auto_commit "$1"
            log_success "🎯 同期処理が正常に完了しました"
        else
            log_error "同期に失敗しました"
            exit 1
        fi
    else
        log_info "同期の必要がありません"
    fi
    
    echo ""
}

# ヘルプ表示
show_help() {
    echo "🔄 Cursor Rules Auto Sync System"
    echo "================================"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/sync-cursor-rules.sh [オプション]"
    echo ""
    echo "オプション:"
    echo "  --commit    同期後にGit自動コミット実行"
    echo "  --help      このヘルプを表示"
    echo "  --force     強制同期（差分確認をスキップ）"
    echo ""
    echo "例："
    echo "  ./scripts/sync-cursor-rules.sh          # 基本同期"
    echo "  ./scripts/sync-cursor-rules.sh --commit # 同期+Git自動コミット"
    echo ""
}

# 強制同期
force_sync() {
    log_warn "🔄 強制同期実行中..."
    check_directories
    create_backup
    sync_files
    verify_sync
    show_stats
    auto_commit "$2"
    log_success "🎯 強制同期完了"
}

# コマンドライン引数処理
case "${1:-sync}" in
    "help"|"--help"|"-h")
        show_help
        ;;
    "--force")
        force_sync "$@"
        ;;
    "--commit")
        main --commit
        ;;
    "sync"|"")
        main
        ;;
    *)
        echo "不明なオプション: $1"
        show_help
        exit 1
        ;;
esac 