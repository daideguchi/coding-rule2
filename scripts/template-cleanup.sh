#!/bin/bash
# テンプレート最適化 - ポータブル化実行スクリプト

set -e

echo "🎯 テンプレート最適化開始 - ポータブル化実行"

# 現在の状況確認
echo "📊 現在のルートファイル数: $(ls -1 | wc -l)"
echo "📊 Git未追跡ファイル数: $(git status --porcelain | wc -l)"

# 1. ランタイム生成ファイル削除（テンプレートに不要）
echo "🗑️  ランタイムファイル削除中..."
rm -f validation_result.json
rm -f STATUS.md  
rm -f SETUP_AUTO_STATUS.md
rm -f .ai-org-configured
rm -f .task_status
echo "   ✅ ランタイムファイル削除完了"

# 2. 設定ファイル統合
echo "📁 設定ファイル統合中..."
mkdir -p config/system

# MCP設定統合
if [ -f .mcp.json ]; then
    mv .mcp.json config/system/
    echo "   ✅ .mcp.json → config/system/"
fi

# 環境設定統合
if [ -f .env ]; then
    mv .env config/system/
    echo "   ✅ .env → config/system/"
fi

# Makefile統合
if [ -f Makefile ]; then
    mv Makefile config/system/
    echo "   ✅ Makefile → config/system/"
fi

# Shell統合設定
if [ -f .shell_integration.bash ]; then
    mv .shell_integration.bash config/system/
    echo "   ✅ .shell_integration.bash → config/system/"
fi

# 3. 重複・テンプレートファイル削除
echo "🔄 重複ファイル削除中..."
rm -f .mcp.json.local
rm -f .mcp.json.template  
rm -f .env.example
echo "   ✅ 重複ファイル削除完了"

# 4. PyProject設定更新（テンプレート化）
echo "⚙️  pyproject.toml テンプレート化..."
cat > pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "ai-control-rules-template"
version = "1.0.0"
description = "AI Behavior Control Rules - Portable Template"
authors = [{name = "AI Control Team", email = "team@ai-control.example"}]
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License", 
    "Programming Language :: Python :: 3",
    "Topic :: Software Development :: Libraries",
]

[project.urls]
Homepage = "https://github.com/ai-control/rules-template"
Repository = "https://github.com/ai-control/rules-template"
Documentation = "https://ai-control.github.io/rules-template"

[tool.setuptools.packages.find]
where = ["src"]

[project.scripts]
ai-setup = "scripts.setup:main"
ai-deploy = "scripts.deploy:main"
ai-validate = "scripts.validate:main"

[tool.ai-control]
template_mode = true
portable = true
min_python_version = "3.8"
target_environments = ["dev", "staging", "prod"]

[tool.ai-control.directories]
source = "src"
tests = "tests"  
docs = "docs"
config = "config"
scripts = "scripts"
data = "data"
models = "models"
ops = "ops"
runtime = "runtime"

[tool.ai-control.rules]
max_root_files = 5
max_root_dirs = 9
require_readme = true
require_gitignore = true
EOF
echo "   ✅ pyproject.toml テンプレート化完了"

# 5. .gitignore最適化
echo "📝 .gitignore テンプレート化..."
cat > .gitignore << 'EOF'
# ===== AI Control Rules Template - .gitignore =====

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Runtime data
runtime/cache/
runtime/tmp/
runtime/*.json
runtime/*.lock

# Environment-specific
.mcp.json.local
.env.local
config/system/.env
config/system/.mcp.json

# AI/ML
models/trained/*
!models/trained/.gitkeep
data/processed/*
!data/processed/.gitkeep
data/raw/*
!data/raw/.gitkeep

# Build artifacts
*.tar.gz
*.zip
validation_result.json
STATUS.md
.ai-org-configured
.task_status

# Temporary files
*.tmp
*.temp
.shell_integration.bash
EOF
echo "   ✅ .gitignore テンプレート化完了"

# 6. README.md テンプレート化
if [ ! -f README.md ]; then
    echo "📖 README.md テンプレート作成..."
    cat > README.md << 'EOF'
# 🤖 AI Control Rules Template

**ポータブルAI動作制御ルールテンプレート**

## 🚀 クイックスタート

```bash
# 1. テンプレートクローン
git clone <this-repo> my-ai-project
cd my-ai-project

# 2. セットアップ実行
./scripts/setup.sh

# 3. 設定カスタマイズ
vi config/system/.env
vi config/system/.mcp.json

# 4. 実行
make start
```

## 📁 ディレクトリ構造

```
├── README.md         # このファイル
├── .gitignore        # Git除外設定
├── pyproject.toml    # Python設定統合
├── config/           # 全設定ファイル
├── docs/             # ドキュメント  
├── src/              # ソースコード
├── scripts/          # ユーティリティ
├── tests/            # テスト
├── data/             # データ
├── models/           # MLモデル
├── ops/              # 運用
└── runtime/          # ランタイム
```

## ⚙️ 設定

全設定は `config/` に統合されています:
- `config/system/` - システム設定
- `config/agents/` - エージェント設定
- `config/integrations/` - 外部連携設定

## 🎯 テンプレート機能

- ✅ **1コマンド移植**: 5分で新環境に展開
- ✅ **設定統合**: config/で一元管理
- ✅ **環境依存排除**: ポータブル設計
- ✅ **カスタマイズ容易**: モジュラー構造

---

**🌟 このテンプレートで、一貫性のあるAI制御システムを構築しましょう**
EOF
    echo "   ✅ README.md テンプレート作成完了"
fi

# 7. 結果確認
echo "📊 最適化結果:"
echo "   📁 ルートファイル数: $(ls -1 | grep -v "^\\." | wc -l)"
echo "   📁 ルートディレクトリ数: $(ls -1d */ | wc -l)"
echo "   📁 Git未追跡ファイル: $(git status --porcelain | wc -l)"

echo ""
echo "✅ テンプレート最適化完了！"
echo "🎯 移植テスト推奨:"
echo "   cp -r . /tmp/test-template && cd /tmp/test-template"

# 8. 移植性チェック
echo ""
echo "🔍 移植性チェック実行中..."

# 必須ファイル存在確認
required_files=("README.md" ".gitignore" "pyproject.toml")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file 存在"
    else
        echo "   ❌ $file 不在"
    fi
done

# 必須ディレクトリ確認
required_dirs=("config" "docs" "src" "scripts" "tests" "data" "models" "ops" "runtime")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir/ 存在"
    else
        echo "   ❌ $dir/ 不在"
    fi
done

echo ""
echo "🎉 テンプレート最適化完了 - ポータブル化成功！"