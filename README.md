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

**基本版を選んだ場合**

```bash
# Cursorを再起動 → 完了！
```

**開発版を選んだ場合**

```bash
# Cursorを再起動
# Claude Codeを開く → 完了！
```

**完全版を選んだ場合**

```bash
# AI組織システム起動
./ai-agents/manage.sh start

# 完了！4画面でAI組織と対話開始
```

### 3️⃣ 確認（30 秒）

```bash
# 現在の設定確認
cat STATUS.md
```

---

## 🌟 概要

**CodingRule2** は、AI 開発環境を簡単にセットアップできるツールです。  
Cursor、Claude Code、AI 組織システムを 3 パターンから選択して導入できます。

---

## 🎛️ 選べる 3 パターン

### 🟢 パターン 1: 基本設定

- **内容**: Cursor Rules のみ
- **対象**: 個人開発・初心者
- **時間**: 1 分

### 🟡 パターン 2: 開発環境設定

- **内容**: Cursor Rules + Claude Code 連携
- **対象**: チーム開発・実務
- **時間**: 2 分

### 🔴 パターン 3: 完全設定

- **内容**: 全機能 + AI 組織システム
- **対象**: 高度な開発・研究
- **時間**: 3 分

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
├── setup.sh                  # セットアップスクリプト
├── scripts/                   # 管理スクリプト
├── STATUS.md                 # 現在の設定状況（自動生成）
└── README.md                 # このファイル
```

---

## 🚀 使用方法

### 1. セットアップ実行

```bash
chmod +x setup.sh
./setup.sh
```

### 2. パターン選択

```
選択してください:
1) 基本設定 (Cursor Rules のみ)
2) 開発環境設定 (Cursor + Claude Code)
3) 完全設定 (全機能 + AI 組織システム)

番号を入力してください (1-3):
```

### 3. 完了後の確認

```bash
# 設定確認
ls -la .cursor/

# Claude Code 起動確認
# パターン2: claude
# パターン3: claude --dangerously-skip-permissions

# AI 組織システム確認（パターン 3）
ls -la ai-agents/
```

---

## 📋 各パターンで作成されるファイル

### パターン 1: 基本設定

```
.cursor/
├── rules/                    # ルールファイル
└── rules.md                  # メイン設定
```

### パターン 2: 開発環境設定

```
ai-agents/docs/CLAUDE.md      # プロジェクト情報
# Claude Code起動: claude（通常）
# 自動連携: CursorとClaude Codeがリアルタイム同期
```

### パターン 3: 完全設定

```
ai-agents/
├── instructions/             # AI 役割設定
├── logs/                     # ログファイル
├── sessions/                 # セッション管理
└── manage.sh                 # 管理スクリプト
# Claude Code起動: claude --dangerously-skip-permissions（必須）
```

---

## 🔧 基本操作

### 設定状況の確認

```bash
# 現在の設定状況をチェック
./scripts/status-checker.sh check

# 設定状況を表示
cat STATUS.md

# setup.sh メニューから確認
./setup.sh
# → 's' を選択して設定状況確認
```

### Cursor Rules （全パターン）

設定後、Cursor を再起動すると AI 支援機能が有効になります。

### Claude Code 連携（パターン 2・3）

**⚠️ 重要: Claude Code の起動コマンド**

```bash
# パターン2（開発環境設定）: 通常起動
claude

# パターン3（完全設定）: 必須オプション
claude --dangerously-skip-permissions
```

**自動連携機能**

Claude Code と Cursor は自動的に連携されており、リアルタイムでファイル変更と Git 状況を共有します。手動での操作は不要です。

### AI 組織システム（パターン 3）

**tmux 環境**での階層型マルチエージェント対話システム：

#### 🎯 エージェント構成

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括責任者

📊 multiagent セッション (4ペイン)
├── boss1: チームリーダー
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C
```

#### 🚀 超簡単！1 コマンド起動

```bash
# AI組織システム起動
./ai-agents/manage.sh start

# 完了！4画面でAI組織と対話開始
```

#### 🔧 詳細設定・高度な使い方

**基本的な使い方は [QUICKSTART.md](QUICKSTART.md) を参照**

##### Claude Code 一括起動

```bash
# 全セッションでClaude Code起動（権限スキップ）
./ai-agents/manage.sh claude-setup

# Claude Codeが各セッションで自動起動
# 起動コマンド: claude --dangerously-skip-permissions（パターン3必須）
# PRESIDENTで指示開始: "指示書に従って"
```

##### Hello World デモ実行

```bash
# デモ実行（推奨フロー体験）
./ai-agents/manage.sh demo

# 期待される動作フロー確認
./ai-agents/agent-send.sh --logs
```

#### 📋 セッション確認・操作

```bash
# セッション確認
tmux attach-session -t president    # PRESIDENT画面
tmux attach-session -t multiagent   # 4ペイン画面

# システム状況確認
./ai-agents/manage.sh status

# セッションクリア
./ai-agents/manage.sh clean
```

#### 🤖 エージェント通信

```bash
# 直接メッセージ送信
./ai-agents/agent-send.sh boss1 "Hello World プロジェクト開始"
./ai-agents/agent-send.sh worker1 "作業完了しました"
./ai-agents/agent-send.sh president "最終報告です"

# システム状況・ログ確認
./ai-agents/agent-send.sh --status
./ai-agents/agent-send.sh --logs

# エージェント一覧
./ai-agents/agent-send.sh --list
```

#### 📊 期待される動作フロー

```
1. PRESIDENT → boss1: "Hello World プロジェクト開始指示"
2. boss1 → workers: "作業開始指示"
3. workers → 作業実行・完了ファイル作成
4. 最後のworker → boss1: "完了報告"
5. boss1 → PRESIDENT: "全員完了報告"
```

---

## 🔄 更新・メンテナンス

### 設定状況の定期確認

```bash
# 設定状況を定期的にチェック
./scripts/status-checker.sh check
```

### 設定リセット

```bash
# 完全リセット
rm -rf .cursor/ ai-agents/

# 再セットアップ
./setup.sh
```

---

---

---

## 🔧 困ったときは

```bash
# 設定リセット
rm -rf .cursor/ ai-agents/
./setup.sh

# Claude Code 正しい起動
# パターン2: claude
# パターン3: claude --dangerously-skip-permissions

# ログ確認
tail -f logs/system/current.log
```

---

## 🛠️ トラブルシューティング

### よくある問題

**Q: Cursor がルールを認識しない**

```bash
# 設定確認
cat .cursor/rules.md

# Cursor を完全再起動
```

**Q: Claude Code で連携できない**

```bash
# 正しい起動コマンドで起動
# パターン2: claude
# パターン3: claude --dangerously-skip-permissions

# 自動連携済み（手動操作不要）

# 自動連携確認（ファイル変更が即座に反映される）
```

**Q: AI 組織システムが動作しない**

```bash
# 権限確認
ls -la ai-agents/manage.sh

# ログ確認
tail -f logs/ai-agents/system.log
```

**Q: 権限エラーが出る**

```bash
chmod +x *.sh
chmod +x ai-agents/*.sh
```

---

**🎯 シンプルなセットアップで、強力な AI 開発環境を構築しましょう！**

_Last updated: $(date +'%Y-%m-%d %H:%M')_
