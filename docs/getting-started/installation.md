# 🛠️ TeamAI インストールガイド

## 📋 システム要件

### 最小要件
| 項目 | 要件 | 推奨 |
|------|------|------|
| **OS** | macOS 10.15+ / Ubuntu 18.04+ | macOS 12+ / Ubuntu 20.04+ |
| **RAM** | 4GB | 8GB以上 |
| **ストレージ** | 2GB空き容量 | 5GB以上 |
| **CPU** | 2コア | 4コア以上 |
| **ネットワーク** | インターネット接続必須 | 安定した高速接続 |

### 必要なソフトウェア
- **tmux** 3.0以上
- **Git** 2.20以上  
- **curl** または **wget**
- **Claude Code** CLI（最新版）

## 🚀 自動インストール（推奨）

### ワンコマンドインストール
```bash
# 全自動セットアップ（約5分）
curl -sSL https://raw.githubusercontent.com/your-repo/teamai/main/install.sh | bash

# 実行内容：
# 1. 依存関係のチェック・インストール
# 2. TeamAI プロジェクトのクローン
# 3. 設定ファイルの初期化
# 4. 権限設定
# 5. 初回起動テスト
```

### カスタムディレクトリでのインストール
```bash
# インストール先を指定
export TEAMAI_INSTALL_DIR="$HOME/my-ai-workspace"
curl -sSL https://raw.githubusercontent.com/your-repo/teamai/main/install.sh | bash
```

## 🔧 手動インストール

### ステップ 1: 依存関係のインストール

#### macOS (Homebrew)
```bash
# Homebrew がない場合は先にインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 必要なパッケージをインストール
brew install tmux git curl

# Claude Code CLI をインストール
brew install claude-code
# または
curl -sSL https://install.claude.ai | bash
```

#### Ubuntu/Debian
```bash
# パッケージリストを更新
sudo apt update

# 必要なパッケージをインストール
sudo apt install -y tmux git curl build-essential

# Claude Code CLI をインストール  
curl -sSL https://install.claude.ai | bash
# パスを通す
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

#### CentOS/RHEL/Fedora
```bash
# Fedora/CentOS 8+
sudo dnf install -y tmux git curl gcc

# CentOS 7
sudo yum install -y tmux git curl gcc

# Claude Code CLI をインストール
curl -sSL https://install.claude.ai | bash
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

### ステップ 2: TeamAI プロジェクトの取得
```bash
# プロジェクトをクローン
git clone https://github.com/your-repo/teamai.git
cd teamai

# ブランチ確認（安定版を使用）
git checkout main

# サブモジュールがある場合
git submodule update --init --recursive
```

### ステップ 3: 設定ファイルの準備
```bash
# 設定テンプレートをコピー
cp config/config.template.json config/config.json
cp config/.env.template config/.env

# API キーを設定
nano config/.env
# 以下を編集
# ANTHROPIC_API_KEY=your-api-key-here
# OPENAI_API_KEY=optional-openai-key
```

### ステップ 4: 権限設定と初期化
```bash
# スクリプトに実行権限を付与
chmod +x scripts/*.sh

# ログディレクトリを作成
mkdir -p logs/{ai-agents/{president,boss1,boss2,worker1,worker2,worker3},system}

# 初期化スクリプトを実行
./scripts/init.sh
```

## ⚙️ 設定のカスタマイズ

### 基本設定 (config/config.json)
```json
{
  "ai_organization": {
    "max_agents": 6,
    "session_timeout": 3600,
    "auto_recovery": true,
    "log_level": "INFO"
  },
  "tmux": {
    "session_name": "teamai-org",
    "base_index": 1,
    "escape_time": 0
  },
  "resources": {
    "max_memory_mb": 2048,
    "max_cpu_percent": 80,
    "disk_space_warning_gb": 1
  }
}
```

### 環境変数 (config/.env)
```bash
# AI API 設定
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=your-openai-key

# システム設定
TEAMAI_HOME=/path/to/teamai
LOG_LEVEL=INFO
DEBUG_MODE=false

# セキュリティ設定
ENABLE_AUTH=true
SESSION_SECRET=your-secret-key
ALLOWED_ORIGINS=localhost:3000,your-domain.com
```

## 🧪 インストール確認

### 基本動作テスト
```bash
# システム全体の健全性チェック
./scripts/health-check.sh

# 期待される出力:
✅ tmux: インストール済み (v3.2)
✅ Git: インストール済み (v2.34)  
✅ Claude Code: インストール済み (v1.2.3)
✅ 設定ファイル: 正常
✅ 権限設定: 正常
✅ ログディレクトリ: 作成済み
✅ API 接続: 正常

🎉 TeamAI インストール完了！
```

### AI組織の起動テスト
```bash
# テスト起動（30秒後に自動停止）
./scripts/test-startup.sh

# 手動起動・確認・停止
./scripts/start-ai-organization.sh
./scripts/check-status.sh
./scripts/stop-ai-organization.sh
```

## 🐛 トラブルシューティング

### 一般的な問題

#### 問題1: `tmux: command not found`
```bash
# 解決法
# macOS
brew install tmux

# Ubuntu
sudo apt install tmux

# CentOS
sudo yum install tmux
```

#### 問題2: Claude Code API接続エラー
```bash
# API キー確認
echo $ANTHROPIC_API_KEY

# 接続テスト
claude auth status

# 再認証
claude auth login
```

#### 問題3: 権限エラー
```bash
# ファイル権限修正
chmod +x scripts/*.sh
chmod -R 755 logs/

# ディレクトリ所有者修正
sudo chown -R $USER:$USER /path/to/teamai
```

#### 問題4: ポート競合
```bash
# 使用中ポートの確認
lsof -i :3000
lsof -i :8000

# プロセス終了
kill -9 [PID]

# または設定変更
nano config/config.json
# ポート番号を変更
```

### 高度なトラブルシューティング

#### ログファイルの確認
```bash
# システムログ
tail -f logs/system/install.log
tail -f logs/system/startup.log

# AI エージェントログ
tail -f logs/ai-agents/president/latest.log
```

#### 完全なアンインストール・再インストール
```bash
# プロジェクト削除
rm -rf /path/to/teamai

# tmux セッション削除
tmux kill-server

# 再インストール
curl -sSL https://raw.githubusercontent.com/your-repo/teamai/main/install.sh | bash
```

## 🚀 次のステップ

### 1. 基本的な使用方法を学ぶ
- [クイックスタート](./README.md) - 5分で始める
- [初回セットアップ](./first-steps.md) - 詳細な初期設定
- [基本操作](./basic-usage.md) - 基本的な使い方

### 2. 設定のカスタマイズ
- [設定ガイド](../technical/configuration.md) - 詳細設定
- [セキュリティ設定](../security/security-guide.md) - セキュリティ強化
- [パフォーマンス調整](../operations/performance-tuning.md) - 最適化

### 3. 高度な活用
- [API 連携](../technical/api-reference.md) - 外部システム連携
- [カスタム拡張](../technical/extensions.md) - 機能拡張
- [運用・監視](../operations/monitoring.md) - 本格運用

---

**🎉 インストール完了！**  
TeamAI AI組織システムが正常にインストールされました。[クイックスタートガイド](./README.md) で実際の使用を始めましょう！