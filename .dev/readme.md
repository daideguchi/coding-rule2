# Development Environment Configuration

このディレクトリには開発環境の設定ファイルが統合されています。

## Directory Structure

```
.dev/
├── cursor/           # Cursor IDE settings
├── vscode/          # Visual Studio Code settings  
├── jetbrains/       # JetBrains IDEs (IntelliJ, PyCharm, etc.)
├── vim/             # Vim/Neovim configuration
└── common/          # IDE共通設定
```

## IDE Settings Migration

### Before (散在状態)
```
.cursor/             # Cursor設定
.vscode/             # VSCode設定
.idea/               # JetBrains設定
.vimrc               # Vim設定
```

### After (統合状態)
```
.dev/
├── cursor/          # 全Cursor設定
├── vscode/          # 全VSCode設定
├── jetbrains/       # 全JetBrains設定
└── vim/             # 全Vim設定
```

## Symbolic Links

各IDEが期待する場所にシンボリックリンクを作成：

```bash
# Cursor
ln -sf .dev/cursor .cursor

# VSCode  
ln -sf .dev/vscode .vscode

# JetBrains
ln -sf .dev/jetbrains .idea

# Vim
ln -sf .dev/vim/.vimrc .vimrc
```

## Benefits

1. **集約管理**: すべてのIDE設定を一箇所で管理
2. **バージョン管理**: 開発環境設定の履歴追跡
3. **チーム共有**: 統一された開発環境設定
4. **ポータブル性**: プロジェクト間での設定再利用

## Usage

### 新しいIDEサポート追加
1. `.dev/new-ide/`ディレクトリ作成
2. 設定ファイル配置
3. 必要に応じてシンボリックリンク作成

### 設定の同期
```bash
# 設定をリポジトリに反映
git add .dev/
git commit -m "Update IDE configurations"

# 他の環境で設定を取得
git pull
./scripts/setup-dev-environment.sh
```