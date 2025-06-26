# 🚀 AI 開発支援ツール「CodingRule2」

## ⚡ 3 分クイックスタート

### 1️⃣ 初期設定（1 分）

```bash
./setup.sh
```

**3 つから選ぶだけ！**

- `1` → 基本版（Cursor 強化のみ）
- `2` → 開発版（+ Claude 連携）
- `3` → 完全版（+ AI 組織 4 画面）

### 2️⃣ 使い始める（1 分）

**基本版・開発版を選んだ場合**

```bash
# Cursorを再起動 → 完了！
```

**完全版（AI 組織システム）を選んだ場合**

```bash
# 基本的な3ステップ操作
1. ./ai-agents/manage.sh auto           # AI組織システム自動起動
2. （プレジデント画面でコマンド送信）      # エージェントに指示を出す
3. tmux attach-session -t multiagent   # 4画面の動きを監視
```

---

## 🌟 概要

**CodingRule2** は、AI 開発環境を簡単にセットアップできるツールです。  
特に **AI 組織システム**では、Claude Code AI を使った階層型マルチエージェント組織が利用できます。

---

## 🎛️ 選べる 3 パターン

### 🟢 パターン 1: 基本設定

- **内容**: Cursor Rules のみ
- **対象**: 個人開発・初心者

### 🟡 パターン 2: 開発環境設定

- **内容**: Cursor Rules + Claude Code 連携
- **対象**: チーム開発・実務

### 🔴 パターン 3: 完全設定

- **内容**: 全機能 + **AI 組織システム**
- **対象**: 高度な開発・研究

---

## 🤖 AI 組織システム（パターン 3）

### 🎯 エージェント構成

```
📊 PRESIDENT セッション
└── PRESIDENT: プロジェクト統括責任者（Claude Code AI）

📊 multiagent セッション（4画面）
├── BOSS1: チームリーダー（Claude Code AI）
├── WORKER1: 実行担当者A（Claude Code AI）
├── WORKER2: 実行担当者B（Claude Code AI）
└── WORKER3: 実行担当者C（Claude Code AI）
```

### 🚀 基本操作（3 ステップ）

#### ステップ 1: AI 組織システム自動起動

```bash
./ai-agents/manage.sh auto
```

- PRESIDENT 画面で Claude Code 自動起動
- 「あなたは president です。指示書に従って」が自動入力
- 4 画面も自動起動される

#### ステップ 2: プレジデント画面でコマンド送信

PRESIDENT 画面で以下のようなコマンドを送信：

```bash
# Hello Worldプロジェクトの例
tmux send-keys -t multiagent:0.0 "あなたはboss1です。Hello World プロジェクト開始指示。worker1,2,3に作業分担し、./tmp/ディレクトリにファイル作成を指示してください" C-m
```

#### ステップ 3: 4 画面の動きを監視

```bash
tmux attach-session -t multiagent
```

- BOSS1 と WORKER1-3 の活動を監視
- 日本語対応でエージェント同士がコミュニケーション
- 実際のファイル作成や作業が進行する

### 💡 使用例

**1. プロジェクト開始**

```bash
# ステップ1
./ai-agents/manage.sh auto

# ステップ2（PRESIDENT画面で）
tmux send-keys -t multiagent:0.0 "あなたはboss1です。新しいWebアプリケーションプロジェクトを開始してください。worker1,2,3に役割分担し、./tmp/ディレクトリに設計書を作成指示してください" C-m

# ステップ3
tmux attach-session -t multiagent
```

**2. コード作成プロジェクト**

```bash
# PRESIDENT画面で
tmux send-keys -t multiagent:0.0 "あなたはboss1です。Python Flask APIプロジェクトを開始。worker1はAPI設計、worker2はデータベース設計、worker3はテスト設計を担当してください" C-m
```

### 🔧 セッション操作

```bash
# PRESIDENT画面を開く
./ai-agents/manage.sh president

# 4画面確認
./ai-agents/manage.sh multiagent

# セッション削除
./ai-agents/manage.sh clean

# システム状況確認
./ai-agents/manage.sh status
```

---

## 📦 ファイル構成

```
coding-rule2/
├── cursor-rules/              # AI 開発ルール集
│   ├── dev-rules/            # 開発ガイドライン
│   ├── globals.mdc           # 基本設定
│   ├── rules.mdc             # プロジェクトルール
│   ├── todo.mdc              # タスク管理
│   └── uiux.mdc              # UI/UX ガイド
├── ai-agents/                # AI 組織システム
│   ├── instructions/         # エージェント指示書（日本語対応）
│   ├── logs/                 # ログファイル
│   └── manage.sh             # 管理スクリプト
├── setup.sh                  # セットアップスクリプト
└── README.md                 # このファイル
```

---

## 🛠️ トラブルシューティング

### よくある問題

**Q: AI 組織システムが動作しない**

```bash
# 権限確認
chmod +x ai-agents/manage.sh

# 再起動
./ai-agents/manage.sh clean
./ai-agents/manage.sh auto
```

**Q: Claude Code が起動しない**

```bash
# 正しい起動コマンド（パターン3必須）
claude --dangerously-skip-permissions
```

**Q: エージェントが日本語で応答しない**

```bash
# 指示書確認
cat ai-agents/instructions/president.md
cat ai-agents/instructions/boss.md
cat ai-agents/instructions/worker.md
```

---

## 🎯 参考リポジトリ

- [Claude Code Communication](https://github.com/Akira-Papa/Claude-Code-Communication)
- 階層型マルチエージェント組織システムの参考実装

---

**🎯 シンプルな 3 ステップで、強力な AI 組織システムを体験しましょう！**

_Last updated: $(date +'%Y-%m-%d %H:%M')_
