#!/bin/bash
# ファイル検証システムセットアップ
# Pre-commitフックとIDE統合の自動設定

set -e

echo "🚀 厳格ファイル作成検証システムセットアップ"

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# 1. Pre-commitフック設定
echo "📌 Pre-commitフック設定中..."

# .pre-commit-config.yaml作成
cat > "$PROJECT_ROOT/.pre-commit-config.yaml" << 'EOF'
# 厳格ファイル作成検証設定
repos:
  # ファイル名検証
  - repo: local
    hooks:
      - id: validate-file-creation
        name: Validate File Creation Rules
        entry: python3 scripts/validate-file-creation.py
        language: system
        pass_filenames: true
        types: [file]
        stages: [commit]

  # 標準的な検証
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      # ファイルシステム検証
      - id: check-case-conflict
      - id: check-symlinks
      - id: destroyed-symlinks
      
      # ファイル名検証
      - id: check-added-large-files
        args: ['--maxkb=1024']
      
      # セキュリティ基本チェック
      - id: detect-private-key
      
      # 構造検証
      - id: check-json
      - id: check-yaml
      - id: check-xml
      
      # 行末処理
      - id: end-of-file-fixer
      - id: trailing-whitespace

  # セキュリティスキャン
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  # Pythonコード品質
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        files: \.py$

  # シェルスクリプト検証
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
        files: \.sh$
EOF

# 2. Git設定
echo "🔧 Git設定中..."

# カスタムフックディレクトリ設定
git config core.hooksPath .githooks

# ファイル作成時の自動検証
cat > "$PROJECT_ROOT/.githooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commitフック - ファイル検証

# 新規ファイル検出と検証
for file in $(git diff --cached --name-only --diff-filter=A); do
    if ! python3 scripts/validate-file-creation.py "$file"; then
        echo "❌ File validation failed for: $file"
        echo "Run 'python3 scripts/validate-file-creation.py \"$file\" --fix' for suggestions"
        exit 1
    fi
done

# pre-commitツール実行
if command -v pre-commit &> /dev/null; then
    pre-commit run --files $(git diff --cached --name-only)
fi
EOF

chmod +x "$PROJECT_ROOT/.githooks/pre-commit"

# 3. VSCode設定
echo "📝 VSCode設定生成中..."

mkdir -p "$PROJECT_ROOT/.vscode"

cat > "$PROJECT_ROOT/.vscode/settings.json" << 'EOF'
{
  "files.associations": {
    "*.md": "markdown",
    "*.sh": "shellscript",
    "*.yml": "yaml"
  },
  
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/*.pyc": true
  },
  
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },
  
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  },
  
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  
  "task.autoDetect": "on",
  
  "terminal.integrated.env.osx": {
    "FILE_VALIDATION_ENABLED": "true"
  },
  
  "terminal.integrated.env.linux": {
    "FILE_VALIDATION_ENABLED": "true"
  }
}
EOF

# タスク定義
cat > "$PROJECT_ROOT/.vscode/tasks.json" << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Validate File Creation",
      "type": "shell",
      "command": "python3",
      "args": [
        "${workspaceFolder}/scripts/validate-file-creation.py",
        "${file}"
      ],
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      },
      "problemMatcher": []
    },
    {
      "label": "Fix File Name",
      "type": "shell",
      "command": "python3",
      "args": [
        "${workspaceFolder}/scripts/validate-file-creation.py",
        "${file}",
        "--fix"
      ],
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      },
      "problemMatcher": []
    }
  ]
}
EOF

# 4. 検証ルールサマリー生成
echo "📋 検証ルールサマリー生成中..."

cat > "$PROJECT_ROOT/FILE_CREATION_RULES.md" << 'EOF'
# 📌 ファイル作成クイックリファレンス

## ✅ 命名ルール
- **文字**: 小文字英数字とハイフンのみ `[a-z0-9-]`
- **形式**: `kebab-case-only`
- **長さ**: ファイル名 ≤ 50文字、フォルダ名 ≤ 40文字

## ✅ 配置ルール
```
scripts/ → .sh, .py のみ
docs/    → .md, .txt, .rst のみ
config/  → .json, .yml, .yaml, .toml のみ
src/     → .py, .js, .ts, .jsx, .tsx のみ
```

## ✅ 禁止事項
- ❌ 大文字（UserService.py）
- ❌ アンダースコア（user_service.py）
- ❌ スペース（user service.py）
- ❌ 数字開始（1service.py）
- ❌ 機密語（password.txt, secret-key.json）

## 🔧 検証コマンド
```bash
# 検証実行
python3 scripts/validate-file-creation.py <file-path>

# 自動修正提案
python3 scripts/validate-file-creation.py <file-path> --fix

# VSCodeタスク
Cmd+Shift+P → "Tasks: Run Task" → "Validate File Creation"
```
EOF

# 5. インストール確認
echo "🔍 セットアップ検証中..."

# pre-commit インストール確認
if ! command -v pre-commit &> /dev/null; then
    echo "⚠️  pre-commit not installed. Installing..."
    pip install pre-commit
fi

# pre-commitフックインストール
pre-commit install

# 6. テスト実行
echo "🧪 検証テスト実行中..."

# テストケース作成
TEST_DIR="$PROJECT_ROOT/.test-validation"
mkdir -p "$TEST_DIR"

# 正しい例
echo "Testing valid file..."
if python3 "$PROJECT_ROOT/scripts/validate-file-creation.py" "$TEST_DIR/valid-file-name.py" --fix; then
    echo "✅ Valid file test passed"
fi

# 間違った例
echo -e "\nTesting invalid file..."
if ! python3 "$PROJECT_ROOT/scripts/validate-file-creation.py" "$TEST_DIR/Invalid_File_Name.py" 2>/dev/null; then
    echo "✅ Invalid file correctly rejected"
fi

# クリーンアップ
rm -rf "$TEST_DIR"

echo ""
echo "✅ セットアップ完了！"
echo ""
echo "📌 次のステップ:"
echo "1. 新規ファイル作成時は自動検証されます"
echo "2. 手動検証: python3 scripts/validate-file-creation.py <file>"
echo "3. ルール確認: cat FILE_CREATION_RULES.md"
echo "4. VSCodeタスクも利用可能です"
echo ""
echo "🔒 厳格ファイル作成ルールが有効になりました"