#!/bin/bash
"""
自動ステータス表示のベストプラクティス実装
Git操作時・ディレクトリ移動時の自動表示設定
"""

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

echo "🔧 自動ステータス表示ベストプラクティス実装開始"
echo "📂 プロジェクトルート: $PROJECT_ROOT"

# 1. Git Hooks設定
setup_git_hooks() {
    echo ""
    echo "🔗 Git Hooks設定"
    echo "===================="
    
    HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
    
    # post-commit hook
    cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Auto-generate status after commit
cd "$(git rev-parse --show-toplevel)"
if [ -f "scripts/auto-status-display.py" ]; then
    echo ""
    echo "📋 Updated Project Status:"
    python3 scripts/auto-status-display.py --brief
    echo ""
fi
EOF
    chmod +x "$HOOKS_DIR/post-commit"
    echo "✅ post-commit hook installed"
    
    # post-merge hook
    cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/bin/bash
# Auto-generate status after pull/merge
cd "$(git rev-parse --show-toplevel)"
if [ -f "scripts/auto-status-display.py" ]; then
    echo ""
    echo "📋 Project Status (after merge):"
    python3 scripts/auto-status-display.py --brief
    echo ""
fi
EOF
    chmod +x "$HOOKS_DIR/post-merge"
    echo "✅ post-merge hook installed"
    
    # pre-push hook
    cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# Show status before push
cd "$(git rev-parse --show-toplevel)"
if [ -f "scripts/auto-status-display.py" ]; then
    echo ""
    echo "📋 Pre-push Status Check:"
    python3 scripts/auto-status-display.py --brief
    
    # WIP制限チェック
    if [ -f "runtime/kanban-board.json" ]; then
        IN_PROGRESS=$(python3 -c "
import json, sys
try:
    with open('runtime/kanban-board.json', 'r') as f:
        data = json.load(f)
        print(len(data.get('columns', {}).get('in_progress', [])))
except:
    print(0)
" 2>/dev/null || echo 0)
        
        if [ "$IN_PROGRESS" -ge 2 ]; then
            echo "⚠️ WARNING: WIP limit reached ($IN_PROGRESS/2 tasks in progress)"
            echo "Consider completing current tasks before pushing new work."
        fi
    fi
    echo ""
fi
EOF
    chmod +x "$HOOKS_DIR/pre-push"
    echo "✅ pre-push hook installed"
}

# 2. Shell統合設定ファイル生成
setup_shell_integration() {
    echo ""
    echo "🐚 Shell統合設定"
    echo "===================="
    
    # zsh用設定
    cat > "$PROJECT_ROOT/.shell_integration.zsh" << 'EOF'
# Auto-status display for this project
# Add to ~/.zshrc: source /path/to/project/.shell_integration.zsh

# Function to check if we're in the project directory
function _in_project_dir() {
    local current_dir="$PWD"
    local project_root=""
    
    # Find project root by looking for STATUS.md
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/STATUS.md" ]]; then
            project_root="$current_dir"
            break
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    [[ -n "$project_root" ]]
}

# Enhanced cd function
function cd() {
    builtin cd "$@"
    
    if _in_project_dir; then
        # Update status first
        if [[ -f "scripts/auto-status-display.py" ]]; then
            python3 scripts/auto-status-display.py > /dev/null 2>&1 || true
        fi
        
        # Show brief status
        if [[ -f ".task_status" ]]; then
            echo ""
            echo "$(cat .task_status)"
            echo ""
        fi
    fi
}

# Alias for quick status check
alias status='python3 scripts/auto-status-display.py --brief'
alias tasks='cat STATUS.md'
alias quicktask='cat .task_status'
EOF
    
    # bash用設定
    cat > "$PROJECT_ROOT/.shell_integration.bash" << 'EOF'
# Auto-status display for this project
# Add to ~/.bashrc: source /path/to/project/.shell_integration.bash

# Function to check if we're in the project directory
function _in_project_dir() {
    local current_dir="$PWD"
    local project_root=""
    
    # Find project root by looking for STATUS.md
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/STATUS.md" ]]; then
            project_root="$current_dir"
            break
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    [[ -n "$project_root" ]]
}

# Enhanced cd function
function cd() {
    builtin cd "$@"
    
    if _in_project_dir; then
        # Update status first
        if [[ -f "scripts/auto-status-display.py" ]]; then
            python3 scripts/auto-status-display.py > /dev/null 2>&1 || true
        fi
        
        # Show brief status
        if [[ -f ".task_status" ]]; then
            echo ""
            echo "$(cat .task_status)"
            echo ""
        fi
    fi
}

# Alias for quick status check
alias status='python3 scripts/auto-status-display.py --brief'
alias tasks='cat STATUS.md'
alias quicktask='cat .task_status'
EOF
    
    echo "✅ Shell integration files created:"
    echo "   .shell_integration.zsh (for zsh users)"
    echo "   .shell_integration.bash (for bash users)"
}

# 3. IDE統合設定
setup_ide_integration() {
    echo ""
    echo "🔧 IDE統合設定"
    echo "===================="
    
    # VSCode/Cursor設定
    mkdir -p "$PROJECT_ROOT/.dev/vscode"
    
    cat > "$PROJECT_ROOT/.dev/vscode/tasks.json" << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Update Task Status",
            "type": "shell",
            "command": "python3",
            "args": ["scripts/auto-status-display.py"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "silent",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "Show Quick Status",
            "type": "shell",
            "command": "python3",
            "args": ["scripts/auto-status-display.py", "--brief"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            },
            "problemMatcher": []
        }
    ]
}
EOF
    
    # VSCode設定でSTATUS.mdを自動表示
    cat > "$PROJECT_ROOT/.dev/vscode/settings.json" << 'EOF'
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/.hg/store/**": true
    },
    "workbench.editorAssociations": {
        "STATUS.md": "default"
    },
    "markdown.preview.openMarkdownLinks": "inEditor",
    "files.defaultLanguage": "markdown",
    "workbench.startupEditor": "none"
}
EOF
    
    echo "✅ IDE integration configured:"
    echo "   VSCode/Cursor tasks.json created"
    echo "   VSCode/Cursor settings.json created"
}

# 4. 自動更新スケジューラー
setup_auto_updater() {
    echo ""
    echo "⏰ 自動更新スケジューラー"
    echo "===================="
    
    cat > "$PROJECT_ROOT/scripts/status-updater-daemon.sh" << 'EOF'
#!/bin/bash
# Background status updater daemon

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$PROJECT_ROOT/runtime/status-updater.lock"
PID_FILE="$PROJECT_ROOT/runtime/status-updater.pid"

# Check if already running
if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "Status updater already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

# Create lock and PID files
echo $$ > "$PID_FILE"
touch "$LOCK_FILE"

# Cleanup on exit
cleanup() {
    rm -f "$LOCK_FILE" "$PID_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

echo "🔄 Status updater daemon started (PID: $$)"

cd "$PROJECT_ROOT"

# Update every 5 minutes while files are being modified
while true; do
    if [[ -f "scripts/auto-status-display.py" ]]; then
        # Check if any relevant files changed in last 5 minutes
        if find runtime/ scripts/ docs/ src/ -name "*.json" -o -name "*.py" -o -name "*.md" -newer "$LOCK_FILE" -print -quit | grep -q .; then
            python3 scripts/auto-status-display.py > /dev/null 2>&1 || true
            touch "$LOCK_FILE"
        fi
    fi
    
    sleep 300  # 5 minutes
done
EOF
    chmod +x "$PROJECT_ROOT/scripts/status-updater-daemon.sh"
    
    echo "✅ Auto-updater daemon created"
    echo "   Start with: ./scripts/status-updater-daemon.sh &"
    echo "   Stop with: pkill -f status-updater-daemon"
}

# 5. Makefile統合
setup_makefile_integration() {
    echo ""
    echo "🛠️ Makefile統合"
    echo "===================="
    
    if [[ ! -f "$PROJECT_ROOT/Makefile" ]]; then
        touch "$PROJECT_ROOT/Makefile"
    fi
    
    # Makefileにタスクステータス関連コマンド追加
    cat >> "$PROJECT_ROOT/Makefile" << 'EOF'

# Task Status Management
.PHONY: status status-brief status-update tasks

status:
	@python3 scripts/auto-status-display.py --brief

status-brief:
	@cat .task_status 2>/dev/null || echo "🎯 No active tasks"

status-update:
	@python3 scripts/auto-status-display.py

tasks:
	@cat STATUS.md

# Quick development workflow
.PHONY: dev-start dev-status dev-commit

dev-start:
	@echo "🚀 Development session starting..."
	@python3 scripts/auto-status-display.py --brief
	@echo "💡 Use 'make status' for quick task check"

dev-status:
	@python3 scripts/auto-status-display.py --brief

dev-commit:
	@python3 scripts/auto-status-display.py
	@echo "📝 Ready to commit. Current status updated."
EOF
    
    echo "✅ Makefile commands added:"
    echo "   make status       - Quick status check"
    echo "   make tasks        - Full task list"
    echo "   make dev-start    - Start development session"
}

# 6. 設定ガイド生成
generate_setup_guide() {
    echo ""
    echo "📋 設定ガイド生成"
    echo "===================="
    
    cat > "$PROJECT_ROOT/SETUP_AUTO_STATUS.md" << 'EOF'
# 🔧 Auto Status Setup Guide

このガイドに従って、開発時の自動タスク表示を設定してください。

## 1. 基本設定（必須）

既に設定済み：
- ✅ Git hooks (post-commit, post-merge, pre-push)
- ✅ Shell integration files
- ✅ IDE integration
- ✅ Makefile commands

## 2. Shell統合（推奨）

### zsh users:
```bash
echo "source $(pwd)/.shell_integration.zsh" >> ~/.zshrc
source ~/.zshrc
```

### bash users:
```bash
echo "source $(pwd)/.shell_integration.bash" >> ~/.bashrc
source ~/.bashrc
```

## 3. 使用方法

### 自動表示
- `cd` でディレクトリ移動時に自動表示
- `git commit` 後に自動表示
- `git pull` 後に自動表示

### 手動確認
```bash
make status          # 簡易表示
make tasks           # 詳細表示 (STATUS.md)
cat .task_status     # 一行表示
```

### IDE統合
- VSCode/Cursor: Ctrl+Shift+P → "Tasks: Run Task" → "Show Quick Status"

## 4. 自動更新（オプション）

バックグラウンドで定期更新:
```bash
./scripts/status-updater-daemon.sh &
```

停止:
```bash
pkill -f status-updater-daemon
```

## 5. 動作確認

```bash
cd ..
cd coding-rule2    # 自動表示されるか確認
make status        # 手動表示確認
```

## 6. トラブルシューティング

### 表示されない場合:
1. Python3が利用可能か確認: `python3 --version`
2. スクリプトが実行可能か確認: `ls -la scripts/auto-status-display.py`
3. runtime/ディレクトリが存在するか確認: `ls -la runtime/`

### Shell統合が効かない場合:
1. シェル設定が正しく読み込まれているか確認
2. `which cd` で組み込み関数が上書きされているか確認

### Git hooks が動かない場合:
1. `.git/hooks/` ディレクトリのファイル権限確認
2. `git config core.hooksPath` 設定確認
EOF
    
    echo "✅ Setup guide created: SETUP_AUTO_STATUS.md"
}

# メイン実行
main() {
    setup_git_hooks
    setup_shell_integration  
    setup_ide_integration
    setup_auto_updater
    setup_makefile_integration
    generate_setup_guide
    
    echo ""
    echo "🎉 ベストプラクティス実装完了！"
    echo "=" * 50
    echo ""
    echo "📋 次のステップ:"
    echo "1. Shell統合を有効化:"
    echo "   echo 'source $(pwd)/.shell_integration.zsh' >> ~/.zshrc"
    echo "   source ~/.zshrc"
    echo ""
    echo "2. 動作確認:"
    echo "   cd .."
    echo "   cd coding-rule2  # 自動表示されるか確認"
    echo ""
    echo "3. 詳細な設定方法:"
    echo "   cat SETUP_AUTO_STATUS.md"
    echo ""
    echo "🚀 開発効率が向上します！"
}

main