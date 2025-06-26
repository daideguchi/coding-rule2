# 🚀 AI 開発支援ツール「CodingRule2」

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
├── status-checker.sh         # 設定状況確認スクリプト

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

# Claude Code 設定確認（パターン 2・3）
cat .claude-project

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
.claude-project               # Claude Code 設定
claude-cursor-sync.sh         # 同期スクリプト
CLAUDE.md                     # プロジェクト情報
```

### パターン 3: 完全設定

```
ai-agents/
├── instructions/             # AI 役割設定
├── logs/                     # ログファイル
├── sessions/                 # セッション管理
└── manage.sh                 # 管理スクリプト
```

---

## 🔧 基本操作

### 設定状況の確認

```bash
# 現在の設定状況をチェック
./status-checker.sh check

# 設定状況を表示
cat STATUS.md

# setup.sh メニューから確認
./setup.sh
# → 's' を選択して設定状況確認
```

### Cursor Rules （全パターン）

設定後、Cursor を再起動すると AI 支援機能が有効になります。

### Claude Code 連携（パターン 2・3）

```bash
# 作業状況を記録
./claude-cursor-sync.sh record

# Claude Code で共有
./claude-cursor-sync.sh share
```

### AI 組織システム（パターン 3）

```bash
# 🚀 4画面AI組織システム起動（推奨）
./ai-agents/manage.sh start

# 📊 システム状況確認
./ai-agents/manage.sh status

# 🤖 個別AI対話（手動起動の場合）
./ai-agents/manage.sh president # プレジデント対話
./ai-agents/manage.sh boss      # ボス対話
./ai-agents/manage.sh worker    # ワーカー対話

# 🧹 システムクリア
./ai-agents/manage.sh clean     # セッション・ログクリア
```

**4 画面システムの使い方:**

1. `./ai-agents/manage.sh start` で 4 つのターミナルタブが自動起動
2. 各タブで役割別 AI（プレジデント/ボス/ワーカー ×2）と対話
3. 対話中のコマンド: `help`, `status`, `clear`, `exit`

---

## 🔄 更新・メンテナンス

### 設定状況の定期確認

```bash
# 設定状況を定期的にチェック
./status-checker.sh check
```

### 設定リセット

```bash
# 完全リセット
rm -rf .cursor/ .claude-project ai-agents/ claude-cursor-sync.sh CLAUDE.md

# 再セットアップ
./setup.sh
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
# 同期実行
./claude-cursor-sync.sh record
./claude-cursor-sync.sh share

# 設定確認
cat .claude-project
```

**Q: AI 組織システムが動作しない**

```bash
# 権限確認
ls -la ai-agents/manage.sh

# ログ確認
tail -f ai-agents/logs/system.log
```

**Q: 権限エラーが出る**

```bash
chmod +x *.sh
chmod +x ai-agents/*.sh
```

---

## 📞 サポート

- **GitHub Issues**: [バグ報告・質問](https://github.com/your-org/coding-rule2/issues)
- **Discord**: [リアルタイムサポート](https://discord.gg/coding-rule2)

---

**🎯 シンプルなセットアップで、強力な AI 開発環境を構築しましょう！**

_Last updated: $(date +'%Y-%m-%d %H:%M')_
