# 🤖 CodingRule2 - AI 組織開発システム

**日本語対応の階層型マルチエージェント AI 組織で開発を革新**

## 🚀 **最速セットアップ（2 分）**

```bash
# 1. セットアップ実行
./setup.sh

# 2. 認証設定（重要！）
./setup.sh → a) 認証設定 → Proプラン または API Key を選択

# 3. AI組織システム起動
./ai-agents/manage.sh claude-auth
```

**これで完了！** PRESIDENT + 4 つのワーカー AI が自動起動します 🎉

---

## 🎯 **使い方（超簡単）**

### **Step 1: AI 組織システム起動**

```bash
./ai-agents/manage.sh claude-auth
```

- ✅ 認証設定を自動選択
- ✅ PRESIDENT 自動起動
- ✅ 4 ワーカー自動起動
- ✅ 全て日本語対応

### **Step 2: プロジェクト指示**

**PRESIDENT 画面**でプロジェクトを指示するだけ：

```
Hello Worldプロジェクトを作成してください
```

### **Step 3: AI 活動監視**

**ターミナル 2**で 4 つの AI の活動をリアルタイム監視：

```bash
tmux attach-session -t multiagent
```

---

## 🤖 **AI 組織構成**

```
👑 PRESIDENT（統括AI）
├── 🔹 プロジェクト全体統括
└── 🔹 日本語指示対応

👥 マルチエージェント（4画面）
├── 👔 BOSS1 - チームリーダーAI
├── 👷 WORKER1 - 実行担当AI
├── 👷 WORKER2 - 実行担当AI
└── 👷 WORKER3 - 実行担当AI
```

**実際にファイル作成・コード生成・実行を行います！**

---

## 🔐 **認証設定（重要）**

| 認証方法                    | 特徴                   | 推奨対象 |
| --------------------------- | ---------------------- | -------- |
| **🏆 claude.ai Pro プラン** | 高性能・安定・月額固定 | **推奨** |
| **🔑 ANTHROPIC_API_KEY**    | 従量課金・開発者向け   | テスト用 |

```bash
# 認証設定
./setup.sh → a) 認証設定 → 使いたい方法を選択

# 認証競合エラーが出た場合
./setup.sh → a) 認証設定 → 3) 現在の設定確認
```

---

## 🎬 **実際の使用例**

### **Web 開発プロジェクト**

```
PRESIDENT画面で指示:
「Python FlaskでTodoアプリを作成してください。API設計、フロントエンド、テストまで含めて」
```

### **データ分析プロジェクト**

```
PRESIDENT画面で指示:
「CSVファイルを読み込んで可視化するPythonスクリプトを作成してください」
```

**AI 同士が日本語で相談しながら、実際にファイルを作成します！**

---

## 🔧 **トラブルシューティング**

### **認証エラー**

```bash
# 1. 認証状況確認
./setup.sh → a) 認証設定 → 3) 現在の設定確認

# 2. 認証方法選択
./setup.sh → a) 認証設定 → 使いたい方法を選択
```

### **stdin Raw mode エラー**

```bash
# stdin エラー自動修正
./ai-agents/claude-stdin-fix.sh auto president 0

# エラー状況確認
./ai-agents/claude-stdin-fix.sh check president 0

# 手動修正（PTY使用）
./ai-agents/claude-stdin-fix.sh pty president 0
```

### **AI 組織システムが起動しない**

```bash
# 完全リセット
./ai-agents/manage.sh clean
./ai-agents/manage.sh claude-auth
```

---

## 🌟 **特徴**

- 🎯 **日本語完全対応** - 全 AI が日本語で対話
- 🚀 **ワンコマンド起動** - `claude-auth`で全自動
- 👥 **5 つの AI エージェント** - 階層型組織
- 🔧 **実際の開発支援** - ファイル作成・編集・実行

---

## 📦 **選べる 3 パターン**

```bash
./setup.sh
```

### 🟢 **パターン 1: 基本版**

- Cursor Rules のみ
- 個人開発・初心者向け

### 🟡 **パターン 2: 開発版**

- Cursor Rules + Claude Code 連携
- チーム開発・実務向け

### 🔴 **パターン 3: 完全版（AI 組織システム）**

- 全機能 + 5 つの AI エージェント組織
- **推奨** - 高度な開発・研究

---

<details>
<summary>🔽 その他のコマンド（上級者向け）</summary>

## 🛠️ **セッション操作コマンド**

```bash
# 画面確認・操作
./ai-agents/manage.sh president          # PRESIDENT画面
./ai-agents/manage.sh multiagent         # 4画面確認
tmux attach-session -t president         # PRESIDENT直接接続
tmux attach-session -t multiagent        # 4画面直接接続

# システム管理
./ai-agents/manage.sh clean              # 全セッション削除
./ai-agents/manage.sh status             # システム状況確認
./ai-agents/manage.sh auto               # 旧起動方法（非推奨）
```

## 📁 **ファイル構成**

```
coding-rule2/
├── 📁 cursor-rules/              # AI開発ルール集
├── 📁 ai-agents/                # AI組織システム
│   ├── instructions/            # エージェント指示書
│   ├── logs/                    # AI活動ログ
│   └── manage.sh                # 管理スクリプト
├── 📄 setup.sh                  # セットアップスクリプト
└── 📄 README.md                 # このファイル
```

## 🎯 **参考リポジトリ**

- [Claude Code Communication](https://github.com/Akira-Papa/Claude-Code-Communication)

</details>

---

**🚀 たった 3 ステップで、日本語対応 AI 組織システムを体験しよう！**

_Last updated: 2025-01-26 23:30_
