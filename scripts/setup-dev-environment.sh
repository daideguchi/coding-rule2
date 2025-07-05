#!/bin/bash
"""
開発環境セットアップスクリプト
.dev/の設定を各IDEの期待する場所にシンボリックリンク
"""

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_DIR="$PROJECT_ROOT/.dev"

echo "🔧 開発環境セットアップ開始"
echo "📂 プロジェクトルート: $PROJECT_ROOT"
echo "⚙️ 設定ディレクトリ: $DEV_DIR"

# 既存の設定ディレクトリをバックアップ
backup_existing() {
    local target="$1"
    local backup_name="$2"
    
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "📦 バックアップ: $target -> ${target}.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "${target}.backup-$(date +%Y%m%d-%H%M%S)"
    elif [ -L "$target" ]; then
        echo "🔗 既存シンボリックリンク削除: $target"
        rm "$target"
    fi
}

# シンボリックリンク作成
create_symlink() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [ -d "$source" ]; then
        backup_existing "$target"
        ln -sf "$source" "$target"
        echo "✅ $description: $target -> $source"
    else
        echo "⚠️ スキップ (ソースなし): $description"
    fi
}

cd "$PROJECT_ROOT"

# Cursor IDE
create_symlink ".dev/cursor" ".cursor" "Cursor IDE"

# Visual Studio Code
create_symlink ".dev/vscode" ".vscode" "Visual Studio Code"

# JetBrains IDEs (IntelliJ, PyCharm, etc.)
if [ -d ".dev/jetbrains" ]; then
    create_symlink ".dev/jetbrains" ".idea" "JetBrains IDEs"
fi

# Vim/Neovim
if [ -f ".dev/vim/.vimrc" ]; then
    create_symlink ".dev/vim/.vimrc" ".vimrc" "Vim configuration"
fi

if [ -d ".dev/vim/.config/nvim" ]; then
    mkdir -p "$HOME/.config"
    create_symlink "$PROJECT_ROOT/.dev/vim/.config/nvim" "$HOME/.config/nvim" "Neovim configuration"
fi

# 共通設定の処理
if [ -d ".dev/common" ]; then
    echo "📋 共通設定の適用"
    
    # EditorConfig
    if [ -f ".dev/common/.editorconfig" ]; then
        create_symlink ".dev/common/.editorconfig" ".editorconfig" "EditorConfig"
    fi
    
    # Prettier
    if [ -f ".dev/common/.prettierrc" ]; then
        create_symlink ".dev/common/.prettierrc" ".prettierrc" "Prettier"
    fi
    
    # ESLint
    if [ -f ".dev/common/.eslintrc.js" ]; then
        create_symlink ".dev/common/.eslintrc.js" ".eslintrc.js" "ESLint"
    fi
fi

# 権限設定
echo "🔐 権限設定の調整"
find .dev -type f -name "*.sh" -exec chmod +x {} \;

# 検証
echo ""
echo "🔍 セットアップ検証"
echo "===================="

check_symlink() {
    local link="$1"
    local description="$2"
    
    if [ -L "$link" ]; then
        local target=$(readlink "$link")
        echo "✅ $description: $link -> $target"
    elif [ -e "$link" ]; then
        echo "⚠️ $description: $link (実ファイル/ディレクトリ)"
    else
        echo "❌ $description: $link (存在しない)"
    fi
}

check_symlink ".cursor" "Cursor"
check_symlink ".vscode" "VSCode"
check_symlink ".idea" "JetBrains"
check_symlink ".vimrc" "Vim"

echo ""
echo "✅ 開発環境セットアップ完了"
echo ""
echo "📝 次のステップ:"
echo "1. 各IDEを起動して設定を確認"
echo "2. 必要に応じて .dev/ 内の設定をカスタマイズ"
echo "3. git add .dev/ でバージョン管理に追加"
echo ""
echo "🔄 設定の同期:"
echo "git add .dev/ && git commit -m 'Update IDE configurations'"