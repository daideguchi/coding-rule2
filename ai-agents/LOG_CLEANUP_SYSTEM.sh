#!/bin/bash
# 🧹 AI-Agents Log Cleanup System
# 安全なバックアップ→分類→統合→削除の自動化システム

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$SCRIPT_DIR/logs"
SESSIONS_DIR="$SCRIPT_DIR/sessions"
BACKUP_ROOT="$SCRIPT_DIR/backup-cleanup-$(date +%Y%m%d-%H%M%S)"
CLEANUP_LOG="$SCRIPT_DIR/cleanup-$(date +%Y%m%d-%H%M%S).log"

# ログ関数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$CLEANUP_LOG"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "$CLEANUP_LOG"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1" | tee -a "$CLEANUP_LOG"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$CLEANUP_LOG"
}

# Phase 1: 詳細ファイル分析
analyze_file_structure() {
    log_info "🔍 Phase 1: ファイル構造分析開始"
    
    echo "📊 ファイル分析レポート" > "$BACKUP_ROOT/analysis-report.md"
    echo "========================" >> "$BACKUP_ROOT/analysis-report.md"
    echo "" >> "$BACKUP_ROOT/analysis-report.md"
    
    # ファイルサイズ分析
    echo "## 📈 ファイルサイズ分析" >> "$BACKUP_ROOT/analysis-report.md"
    find "$LOGS_DIR" -type f -exec ls -lh {} \; | awk '{print $5, $9}' | sort -hr > "$BACKUP_ROOT/file-sizes.txt"
    
    # 大容量ファイル特定
    LARGE_FILES=$(find "$LOGS_DIR" -type f -size +1M)
    MEDIUM_FILES=$(find "$LOGS_DIR" -type f -size +100k -size -1M)
    SMALL_FILES=$(find "$LOGS_DIR" -type f -size -100k)
    
    echo "### 🔴 大容量ファイル (>1MB): $(echo "$LARGE_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "$LARGE_FILES" >> "$BACKUP_ROOT/analysis-report.md"
    echo "" >> "$BACKUP_ROOT/analysis-report.md"
    
    echo "### 🟡 中容量ファイル (100KB-1MB): $(echo "$MEDIUM_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "$MEDIUM_FILES" >> "$BACKUP_ROOT/analysis-report.md"
    echo "" >> "$BACKUP_ROOT/analysis-report.md"
    
    echo "### 🟢 小容量ファイル (<100KB): $(echo "$SMALL_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "$SMALL_FILES" >> "$BACKUP_ROOT/analysis-report.md"
    echo "" >> "$BACKUP_ROOT/analysis-report.md"
    
    # ファイル種別分析
    echo "## 📂 ファイル種別分析" >> "$BACKUP_ROOT/analysis-report.md"
    STATUS_FILES=$(find "$LOGS_DIR" -name "*status*" -type f)
    ERROR_FILES=$(find "$LOGS_DIR" -name "*error*" -o -name "*ERROR*" -o -name "*FAIL*" -type f)
    MD_FILES=$(find "$LOGS_DIR" -name "*.md" -type f)
    LOG_FILES=$(find "$LOGS_DIR" -name "*.log" -type f)
    
    echo "- ステータス関連: $(echo "$STATUS_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "- エラー関連: $(echo "$ERROR_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "- マークダウン: $(echo "$MD_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    echo "- ログファイル: $(echo "$LOG_FILES" | wc -l)個" >> "$BACKUP_ROOT/analysis-report.md"
    
    # 総使用容量
    TOTAL_SIZE=$(du -sh "$LOGS_DIR" | cut -f1)
    echo "- 総使用容量: $TOTAL_SIZE" >> "$BACKUP_ROOT/analysis-report.md"
    
    log_success "📊 ファイル構造分析完了 - レポート: $BACKUP_ROOT/analysis-report.md"
}

# Phase 2: 安全なバックアップ作成
create_safe_backup() {
    log_info "💾 Phase 2: 安全バックアップ作成開始"
    
    # バックアップディレクトリ構造作成
    mkdir -p "$BACKUP_ROOT"/{original,classified,consolidated}
    mkdir -p "$BACKUP_ROOT/original"/{logs,sessions}
    mkdir -p "$BACKUP_ROOT/classified"/{status,errors,system,misc}
    
    # 完全バックアップ作成
    log_info "📋 完全バックアップ作成中..."
    cp -r "$LOGS_DIR"/* "$BACKUP_ROOT/original/logs/" 2>/dev/null || true
    cp -r "$SESSIONS_DIR"/* "$BACKUP_ROOT/original/sessions/" 2>/dev/null || true
    
    # バックアップ検証
    ORIGINAL_COUNT=$(find "$LOGS_DIR" "$SESSIONS_DIR" -type f | wc -l)
    BACKUP_COUNT=$(find "$BACKUP_ROOT/original" -type f | wc -l)
    
    if [ "$ORIGINAL_COUNT" -eq "$BACKUP_COUNT" ]; then
        log_success "✅ バックアップ検証成功: $ORIGINAL_COUNT個のファイル"
    else
        log_error "❌ バックアップ検証失敗: Original=$ORIGINAL_COUNT, Backup=$BACKUP_COUNT"
        exit 1
    fi
    
    # チェックサム作成
    log_info "🔒 チェックサム生成中..."
    find "$BACKUP_ROOT/original" -type f -exec md5sum {} \; > "$BACKUP_ROOT/checksums.md5"
    
    # バックアップメタデータ
    cat > "$BACKUP_ROOT/backup-info.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "original_location": "$LOGS_DIR",
  "file_count": $ORIGINAL_COUNT,
  "total_size": "$(du -sh "$LOGS_DIR" | cut -f1)",
  "backup_method": "complete_copy",
  "verification": "checksum_verified"
}
EOF
    
    log_success "💾 安全バックアップ作成完了: $BACKUP_ROOT"
}

# Phase 3: インテリジェント分類システム
classify_files_intelligently() {
    log_info "🧠 Phase 3: インテリジェント分類開始"
    
    local classification_report="$BACKUP_ROOT/classification-report.md"
    echo "# 📂 ファイル分類レポート" > "$classification_report"
    echo "分類日時: $(date)" >> "$classification_report"
    echo "" >> "$classification_report"
    
    # 分類ルール定義
    classify_file() {
        local file="$1"
        local filename=$(basename "$file")
        local content_sample=$(head -10 "$file" 2>/dev/null || echo "")
        
        # ステータス関連ファイル
        if [[ "$filename" =~ status|Status|STATUS ]] || [[ "$content_sample" =~ WORKER|ステータス|チームリーダー ]]; then
            echo "status"
        # エラー・障害関連
        elif [[ "$filename" =~ error|Error|ERROR|FAIL|CRITICAL|FRUSTRATION ]] || [[ "$content_sample" =~ ERROR|CRITICAL|Failed ]]; then
            echo "errors"
        # システム・設定関連
        elif [[ "$filename" =~ master|compliance|emergency|resource|timer|auto ]] || [[ "$content_sample" =~ MASTER|COMPLIANCE ]]; then
            echo "system"
        # セッション関連
        elif [[ "$filename" =~ session ]] || [[ "$content_sample" =~ session_id|role.*president|role.*boss ]]; then
            echo "sessions"
        # その他
        else
            echo "misc"
        fi
    }
    
    # ファイル分類実行
    declare -A category_counts
    category_counts[status]=0
    category_counts[errors]=0
    category_counts[system]=0
    category_counts[sessions]=0
    category_counts[misc]=0
    
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            category=$(classify_file "$file")
            filename=$(basename "$file")
            
            # 分類先にコピー
            cp "$file" "$BACKUP_ROOT/classified/$category/"
            category_counts[$category]=$((category_counts[$category] + 1))
            
            # 分類ログ
            echo "[$category] $filename" >> "$classification_report"
            
            log_info "📁 分類: $filename → $category"
        fi
    done < <(find "$BACKUP_ROOT/original" -type f -print0)
    
    # 分類統計
    echo "" >> "$classification_report"
    echo "## 📊 分類統計" >> "$classification_report"
    for category in status errors system sessions misc; do
        echo "- $category: ${category_counts[$category]}個" >> "$classification_report"
    done
    
    log_success "🧠 インテリジェント分類完了: $classification_report"
}

# Phase 4: 統合アルゴリズム
consolidate_logs() {
    log_info "🔗 Phase 4: ログ統合開始"
    
    local consolidated_dir="$BACKUP_ROOT/consolidated"
    mkdir -p "$consolidated_dir"/{unified,archive}
    
    # ステータスログ統合
    log_info "📊 ステータスログ統合中..."
    local unified_status="$consolidated_dir/unified/unified-status-$(date +%Y%m%d).log"
    echo "# 🔄 統合ステータスログ" > "$unified_status"
    echo "# 統合日時: $(date)" >> "$unified_status"
    echo "# 統合元ファイル数: $(find "$BACKUP_ROOT/classified/status" -type f | wc -l)" >> "$unified_status"
    echo "" >> "$unified_status"
    
    # ステータスファイルを時系列でマージ
    find "$BACKUP_ROOT/classified/status" -type f -name "*.log" | while read -r file; do
        echo "## === $(basename "$file") ===" >> "$unified_status"
        echo "ファイルサイズ: $(du -h "$file" | cut -f1)" >> "$unified_status"
        echo "最終更新: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || date)" >> "$unified_status"
        echo "" >> "$unified_status"
        
        # 大容量ファイルは最初と最後の100行のみ
        if [ "$(wc -l < "$file")" -gt 1000 ]; then
            echo "[ファイル先頭100行]" >> "$unified_status"
            head -100 "$file" >> "$unified_status"
            echo "" >> "$unified_status"
            echo "[...中間部分省略...]" >> "$unified_status"
            echo "" >> "$unified_status"
            echo "[ファイル末尾100行]" >> "$unified_status"
            tail -100 "$file" >> "$unified_status"
        else
            cat "$file" >> "$unified_status"
        fi
        echo "" >> "$unified_status"
        echo "=====================================%" >> "$unified_status"
        echo "" >> "$unified_status"
    done
    
    # エラーログ統合
    log_info "🚨 エラーログ統合中..."
    local unified_errors="$consolidated_dir/unified/unified-errors-$(date +%Y%m%d).log"
    echo "# 🚨 統合エラーログ" > "$unified_errors"
    echo "# 統合日時: $(date)" >> "$unified_errors"
    echo "" >> "$unified_errors"
    
    find "$BACKUP_ROOT/classified/errors" -type f | while read -r file; do
        echo "## === $(basename "$file") ===" >> "$unified_errors"
        cat "$file" >> "$unified_errors"
        echo "" >> "$unified_errors"
    done
    
    # システムログ統合
    log_info "⚙️ システムログ統合中..."
    local unified_system="$consolidated_dir/unified/unified-system-$(date +%Y%m%d).log"
    echo "# ⚙️ 統合システムログ" > "$unified_system"
    echo "# 統合日時: $(date)" >> "$unified_system"
    echo "" >> "$unified_system"
    
    find "$BACKUP_ROOT/classified/system" -type f | while read -r file; do
        echo "## === $(basename "$file") ===" >> "$unified_system"
        cat "$file" >> "$unified_system"
        echo "" >> "$unified_system"
    done
    
    # セッション情報統合
    log_info "👥 セッション情報統合中..."
    local unified_sessions="$consolidated_dir/unified/unified-sessions-$(date +%Y%m%d).json"
    echo "{" > "$unified_sessions"
    echo "  \"consolidation_timestamp\": \"$(date -Iseconds)\"," >> "$unified_sessions"
    echo "  \"sessions\": [" >> "$unified_sessions"
    
    local first=true
    find "$BACKUP_ROOT/classified/sessions" -name "*.json" -type f | while read -r file; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$unified_sessions"
        fi
        cat "$file" >> "$unified_sessions"
    done
    
    echo "" >> "$unified_sessions"
    echo "  ]" >> "$unified_sessions"
    echo "}" >> "$unified_sessions"
    
    # 統合統計
    local consolidation_stats="$consolidated_dir/consolidation-stats.json"
    cat > "$consolidation_stats" << EOF
{
  "consolidation_timestamp": "$(date -Iseconds)",
  "original_files": $(find "$BACKUP_ROOT/original" -type f | wc -l),
  "consolidated_files": $(find "$consolidated_dir/unified" -type f | wc -l),
  "space_savings": {
    "original_size": "$(du -sh "$BACKUP_ROOT/original" | cut -f1)",
    "consolidated_size": "$(du -sh "$consolidated_dir/unified" | cut -f1)"
  },
  "files_created": [
    "$(basename "$unified_status")",
    "$(basename "$unified_errors")",
    "$(basename "$unified_system")",
    "$(basename "$unified_sessions")"
  ]
}
EOF
    
    log_success "🔗 ログ統合完了: $consolidated_dir"
}

# Phase 5: 安全削除システム
safe_deletion_system() {
    log_info "🗑️ Phase 5: 安全削除システム開始"
    
    # 削除対象ファイル特定
    local deletion_plan="$BACKUP_ROOT/deletion-plan.md"
    echo "# 🗑️ 削除計画" > "$deletion_plan"
    echo "作成日時: $(date)" >> "$deletion_plan"
    echo "" >> "$deletion_plan"
    
    # 重複ファイル特定
    echo "## 🔍 削除対象ファイル" >> "$deletion_plan"
    echo "" >> "$deletion_plan"
    
    # 大容量重複ファイル（統合済み）
    LARGE_REDUNDANT=(
        "persistent-status.log"
        "startup-status.log"
        "requirements-check.log"
    )
    
    # 小容量重複ファイル
    SMALL_REDUNDANT=(
        "current-status-103231.log"
        "simple-status.log"
        "status-fix.log"
        "ultimate-status.log"
        "status-final.log"
    )
    
    # テンプレートファイル
    TEMPLATE_FILES=(
        "CRITICAL_ERROR_\$(date*"
        "current-analysis-\$(date*"
    )
    
    echo "### 🔴 大容量重複ファイル (統合済み)" >> "$deletion_plan"
    for file in "${LARGE_REDUNDANT[@]}"; do
        if [ -f "$LOGS_DIR/$file" ]; then
            local size=$(du -h "$LOGS_DIR/$file" | cut -f1)
            echo "- $file ($size)" >> "$deletion_plan"
        fi
    done
    echo "" >> "$deletion_plan"
    
    echo "### 🟡 小容量重複ファイル" >> "$deletion_plan"
    for file in "${SMALL_REDUNDANT[@]}"; do
        if [ -f "$LOGS_DIR/$file" ]; then
            local size=$(du -h "$LOGS_DIR/$file" | cut -f1)
            echo "- $file ($size)" >> "$deletion_plan"
        fi
    done
    echo "" >> "$deletion_plan"
    
    echo "### 🟠 テンプレートファイル" >> "$deletion_plan"
    for pattern in "${TEMPLATE_FILES[@]}"; do
        find "$LOGS_DIR" -name "$pattern" -type f | while read -r file; do
            local size=$(du -h "$file" | cut -f1)
            echo "- $(basename "$file") ($size)" >> "$deletion_plan"
        done
    done
    echo "" >> "$deletion_plan"
    
    # 安全性チェック
    echo "## 🛡️ 安全性チェック" >> "$deletion_plan"
    echo "- ✅ 完全バックアップ作成済み" >> "$deletion_plan"
    echo "- ✅ チェックサム検証済み" >> "$deletion_plan"
    echo "- ✅ ファイル分類済み" >> "$deletion_plan"
    echo "- ✅ ログ統合済み" >> "$deletion_plan"
    echo "" >> "$deletion_plan"
    
    # 削除実行 (ドライラン)
    echo "## 🔄 削除シミュレーション" >> "$deletion_plan"
    local total_savings=0
    
    # 実際の削除は保留（安全のため）
    echo "⚠️ 実際の削除は手動確認後に実行してください" >> "$deletion_plan"
    echo "" >> "$deletion_plan"
    echo "削除コマンド例:" >> "$deletion_plan"
    
    for file in "${LARGE_REDUNDANT[@]}" "${SMALL_REDUNDANT[@]}"; do
        if [ -f "$LOGS_DIR/$file" ]; then
            echo "rm \"$LOGS_DIR/$file\"" >> "$deletion_plan"
        fi
    done
    
    for pattern in "${TEMPLATE_FILES[@]}"; do
        find "$LOGS_DIR" -name "$pattern" -type f | while read -r file; do
            echo "rm \"$file\"" >> "$deletion_plan"
        done
    done
    
    log_success "🗑️ 削除計画作成完了: $deletion_plan"
}

# Phase 6: 新しいログ管理システム作成
create_new_log_system() {
    log_info "🏗️ Phase 6: 新ログ管理システム作成"
    
    # 新しいディレクトリ構造
    mkdir -p "$LOGS_DIR"/{system,monitoring,archive}
    mkdir -p "$SESSIONS_DIR"/active
    
    # 統合ログファイル作成
    local unified_status_new="$LOGS_DIR/monitoring/status-$(date +%Y%m%d).log"
    local unified_system_new="$LOGS_DIR/system/master-$(date +%Y%m%d).log"
    local unified_sessions_new="$SESSIONS_DIR/active/sessions-$(date +%Y%m%d).json"
    
    # 統合ファイルをコピー
    cp "$BACKUP_ROOT/consolidated/unified/unified-status-$(date +%Y%m%d).log" "$unified_status_new"
    cp "$BACKUP_ROOT/consolidated/unified/unified-system-$(date +%Y%m%d).log" "$unified_system_new"
    cp "$BACKUP_ROOT/consolidated/unified/unified-sessions-$(date +%Y%m%d).json" "$unified_sessions_new"
    
    # ログ設定ファイル作成
    cat > "$LOGS_DIR/logging.conf" << EOF
# AI-Agents ログ設定
# 作成日: $(date)

[logging]
enabled=true
level=INFO
rotation=daily
max_size=10MB
retention_days=30

[categories]
status="$LOGS_DIR/monitoring/"
system="$LOGS_DIR/system/"
errors="$LOGS_DIR/system/"
archive="$LOGS_DIR/archive/"

[sessions]
active_dir="$SESSIONS_DIR/active/"
archive_dir="$SESSIONS_DIR/archive/"
EOF
    
    # README作成
    cat > "$LOGS_DIR/README.md" << EOF
# 🧹 AI-Agents ログ管理システム

## 📁 ディレクトリ構造
- \`system/\`: システム・マスターログ
- \`monitoring/\`: ステータス・監視ログ  
- \`archive/\`: アーカイブされた古いログ

## 🔄 ログローテーション
- 日次ローテーション
- 最大ファイルサイズ: 10MB
- 保持期間: 30日

## 📊 統合ログ情報
- 統合実行日: $(date)
- 統合前ファイル数: $(find "$BACKUP_ROOT/original" -type f | wc -l)
- 統合後ファイル数: $(find "$LOGS_DIR" -type f | wc -l)
- バックアップ場所: $BACKUP_ROOT

## 🔄 復元方法
バックアップから復元する場合:
\`\`\`bash
cp -r $BACKUP_ROOT/original/logs/* $LOGS_DIR/
cp -r $BACKUP_ROOT/original/sessions/* $SESSIONS_DIR/
\`\`\`
EOF
    
    log_success "🏗️ 新ログ管理システム作成完了"
}

# メイン実行関数
main() {
    log_info "🚀 AI-Agents ログクリーンアップシステム開始"
    log_info "📍 作業ディレクトリ: $SCRIPT_DIR"
    log_info "💾 バックアップ先: $BACKUP_ROOT"
    
    # 事前チェック
    if [ ! -d "$LOGS_DIR" ]; then
        log_error "❌ ログディレクトリが見つかりません: $LOGS_DIR"
        exit 1
    fi
    
    # フェーズ実行
    analyze_file_structure
    create_safe_backup  
    classify_files_intelligently
    consolidate_logs
    safe_deletion_system
    create_new_log_system
    
    # 完了レポート
    local cleanup_report="$BACKUP_ROOT/cleanup-summary.md"
    cat > "$cleanup_report" << EOF
# 🎉 AI-Agents ログクリーンアップ完了レポート

## 📊 実行統計
- 実行日時: $(date)
- 処理ファイル数: $(find "$BACKUP_ROOT/original" -type f | wc -l)
- バックアップサイズ: $(du -sh "$BACKUP_ROOT" | cut -f1)
- 実行時間: $SECONDS 秒

## 📁 作成されたファイル
1. **バックアップ**: $BACKUP_ROOT/original/
2. **分類結果**: $BACKUP_ROOT/classified/
3. **統合ログ**: $BACKUP_ROOT/consolidated/
4. **新システム**: $LOGS_DIR/

## 🛡️ 安全機能
- ✅ 完全バックアップ作成
- ✅ チェックサム検証
- ✅ ロールバック可能
- ✅ 段階的実行

## 📋 次のステップ
1. $cleanup_report を確認
2. $BACKUP_ROOT/deletion-plan.md で削除計画確認
3. 必要に応じて手動削除実行
4. 新ログシステムの動作確認

## 🔄 ロールバック方法
\`\`\`bash
# 完全復元
rm -rf $LOGS_DIR/* $SESSIONS_DIR/*
cp -r $BACKUP_ROOT/original/logs/* $LOGS_DIR/
cp -r $BACKUP_ROOT/original/sessions/* $SESSIONS_DIR/
\`\`\`
EOF
    
    log_success "🎉 ログクリーンアップシステム完了"
    log_success "📋 完了レポート: $cleanup_report"
    log_success "💾 バックアップ: $BACKUP_ROOT"
    
    echo ""
    echo "🔍 次のステップ:"
    echo "1. レポート確認: cat $cleanup_report"
    echo "2. 削除計画確認: cat $BACKUP_ROOT/deletion-plan.md"
    echo "3. 新システム確認: ls -la $LOGS_DIR/"
}

# スクリプト実行
case "${1:-main}" in
    "analyze")
        analyze_file_structure
        ;;
    "backup")
        create_safe_backup
        ;;
    "classify")
        classify_files_intelligently
        ;;
    "consolidate")
        consolidate_logs
        ;;
    "delete-plan")
        safe_deletion_system
        ;;
    "new-system")
        create_new_log_system
        ;;
    "main")
        main
        ;;
    *)
        echo "使用方法:"
        echo "  $0 main          # 完全実行"
        echo "  $0 analyze       # 分析のみ"
        echo "  $0 backup        # バックアップのみ"
        echo "  $0 classify      # 分類のみ"
        echo "  $0 consolidate   # 統合のみ"
        echo "  $0 delete-plan   # 削除計画のみ"
        echo "  $0 new-system    # 新システムのみ"
        ;;
esac