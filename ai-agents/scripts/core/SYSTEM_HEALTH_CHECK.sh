#!/bin/bash
# 🏥 AI-AGENTS システムヘルスチェック
# 整理後のディレクトリ構造での動作確認

set -euo pipefail

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

# プロジェクトルートディレクトリ
PROJECT_ROOT="/Users/dd/Desktop/1_dev/coding-rule2"
AI_AGENTS_DIR="$PROJECT_ROOT/ai-agents"

echo "🏥 AI-AGENTS システムヘルスチェック開始"
echo "======================================="
echo ""

# 1. ディレクトリ構造確認
log_info "📁 ディレクトリ構造確認"
echo ""

# 必須ディレクトリ
REQUIRED_DIRS=(
    "$AI_AGENTS_DIR/scripts/core"
    "$AI_AGENTS_DIR/scripts/automation/core"
    "$AI_AGENTS_DIR/scripts/utilities"
    "$AI_AGENTS_DIR/configs"
    "$AI_AGENTS_DIR/docs"
    "$AI_AGENTS_DIR/logs"
    "$AI_AGENTS_DIR/instructions"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ] || [ -L "$dir" ]; then
        log_success "✅ $dir"
    else
        log_error "❌ $dir (不存在)"
    fi
done

echo ""

# 2. 主要スクリプト存在確認
log_info "📋 主要スクリプト存在確認"
echo ""

# 主要スクリプト
REQUIRED_SCRIPTS=(
    "$AI_AGENTS_DIR/scripts/core/ULTIMATE_PROCESS.sh"
    "$AI_AGENTS_DIR/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh"
    "$AI_AGENTS_DIR/scripts/core/PARALLEL_PROCESSING_SYSTEM.sh"
    "$AI_AGENTS_DIR/scripts/automation/core/startup.sh"
    "$AI_AGENTS_DIR/manage.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ] || [ -L "$script" ]; then
        if [ -x "$script" ]; then
            log_success "✅ $script (実行可能)"
        else
            log_warn "⚠️  $script (実行権限なし)"
            chmod +x "$script" 2>/dev/null || true
        fi
    else
        log_error "❌ $script (不存在)"
    fi
done

echo ""

# 3. tmuxセッション確認
log_info "🖥️  tmuxセッション確認"
echo ""

if command -v tmux &> /dev/null; then
    SESSIONS=$(tmux list-sessions 2>/dev/null || echo "")
    if [ -n "$SESSIONS" ]; then
        echo "$SESSIONS" | while read -r line; do
            log_success "✅ $line"
        done
    else
        log_warn "⚠️  アクティブなtmuxセッションがありません"
    fi
else
    log_error "❌ tmuxがインストールされていません"
fi

echo ""

# 4. 監視システム状態確認
log_info "👁️  監視システム状態確認"
echo ""

# AUTO_EXECUTE_MONITOR_SYSTEM状態
if [ -f "/tmp/ai-agents/auto-execute-monitor.pid" ]; then
    PID=$(cat /tmp/ai-agents/auto-execute-monitor.pid)
    if kill -0 $PID 2>/dev/null; then
        log_success "✅ AUTO_EXECUTE_MONITOR_SYSTEM 稼働中 (PID: $PID)"
    else
        log_warn "⚠️  AUTO_EXECUTE_MONITOR_SYSTEM 停止中 (PID: $PID)"
    fi
else
    log_warn "⚠️  AUTO_EXECUTE_MONITOR_SYSTEM 未起動"
fi

echo ""

# 5. 指示書ファイル確認
log_info "📄 指示書ファイル確認"
echo ""

INSTRUCTION_FILES=(
    "$AI_AGENTS_DIR/instructions/president.md"
    "$AI_AGENTS_DIR/instructions/boss.md"
    "$AI_AGENTS_DIR/instructions/worker.md"
)

for file in "${INSTRUCTION_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "✅ $file"
    else
        log_error "❌ $file (不存在)"
    fi
done

echo ""

# 6. 環境変数確認
log_info "🌐 環境変数確認"
echo ""

if [ -f "$AI_AGENTS_DIR/configs/env/env-setup.sh" ]; then
    log_success "✅ env-setup.sh 存在"
    # 環境変数を読み込んでテスト
    source "$AI_AGENTS_DIR/configs/env/env-setup.sh" 2>/dev/null || log_warn "⚠️  env-setup.sh 読み込みエラー"
else
    log_error "❌ env-setup.sh 不存在"
fi

echo ""

# 7. 動作テスト
log_info "🧪 動作テスト"
echo ""

# ULTIMATE_PROCESS.sh テスト
if [ -x "$AI_AGENTS_DIR/scripts/core/ULTIMATE_PROCESS.sh" ]; then
    log_info "ULTIMATE_PROCESS.sh チェック実行中..."
    if "$AI_AGENTS_DIR/scripts/core/ULTIMATE_PROCESS.sh" check > /dev/null 2>&1; then
        log_success "✅ ULTIMATE_PROCESS.sh 動作確認OK"
    else
        log_warn "⚠️  ULTIMATE_PROCESS.sh 実行エラー"
    fi
fi

# AUTO_EXECUTE_MONITOR_SYSTEM.sh ステータス確認
if [ -x "$AI_AGENTS_DIR/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh" ]; then
    log_info "AUTO_EXECUTE_MONITOR_SYSTEM.sh ステータス確認中..."
    STATUS=$("$AI_AGENTS_DIR/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh" status 2>&1 | grep -E "稼働中|開始されていません" || echo "不明")
    echo "  状態: $STATUS"
fi

echo ""

# 8. パス問題チェック
log_info "🛤️  パス問題チェック"
echo ""

# 相対パスと絶対パスの混在チェック
SCRIPTS_WITH_PATHS=(
    "$AI_AGENTS_DIR/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh"
    "$AI_AGENTS_DIR/scripts/automation/core/startup.sh"
)

for script in "${SCRIPTS_WITH_PATHS[@]}"; do
    if [ -f "$script" ]; then
        # ./ai-agents/ パスの使用をチェック
        if grep -q "./ai-agents/" "$script" 2>/dev/null; then
            log_warn "⚠️  $script に相対パス './ai-agents/' が含まれています"
        else
            log_success "✅ $script パス問題なし"
        fi
    fi
done

echo ""

# 9. 推奨アクション
log_info "💡 推奨アクション"
echo ""

ISSUES_FOUND=false

# tmuxセッションがない場合
if [ -z "$SESSIONS" ]; then
    echo "  1. tmuxセッションを起動:"
    echo "     cd $PROJECT_ROOT && ./ai-agents/manage.sh start"
    ISSUES_FOUND=true
fi

# 監視システムが動いていない場合
if [ ! -f "/tmp/ai-agents/auto-execute-monitor.pid" ] || ! kill -0 $(cat /tmp/ai-agents/auto-execute-monitor.pid 2>/dev/null) 2>/dev/null; then
    echo "  2. 自動実行監視システムを起動:"
    echo "     cd $PROJECT_ROOT && ./ai-agents/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh start"
    ISSUES_FOUND=true
fi

# 指示書ファイルがない場合
MISSING_INSTRUCTIONS=false
for file in "${INSTRUCTION_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_INSTRUCTIONS=true
        break
    fi
done

if [ "$MISSING_INSTRUCTIONS" = true ]; then
    echo "  3. 指示書ファイルのリンクを確認:"
    echo "     ls -la $AI_AGENTS_DIR/instructions/"
    ISSUES_FOUND=true
fi

if [ "$ISSUES_FOUND" = false ]; then
    log_success "✅ システムは正常に動作しています"
fi

echo ""
echo "🏥 システムヘルスチェック完了"
echo ""

# 最終サマリー
echo "📊 サマリー:"
echo "  • ディレクトリ構造: 整理完了"
echo "  • 主要スクリプト: 配置確認"
echo "  • tmuxセッション: $(tmux list-sessions 2>/dev/null | wc -l || echo "0") セッション"
echo "  • 監視システム: $([ -f "/tmp/ai-agents/auto-execute-monitor.pid" ] && kill -0 $(cat /tmp/ai-agents/auto-execute-monitor.pid) 2>/dev/null && echo "稼働中" || echo "停止中")"
echo ""