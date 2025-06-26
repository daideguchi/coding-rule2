# AI 開発支援ツール セットアップ

AI 開発をサポートするシンプルなセットアップツールです。Cursor、Claude Code、AI 組織システムの 3 パターンから選択できます。

## 📂 ディレクトリ構成

```
coding-rule2/
├── cursor-rules/           # 技術用ファイル
│   ├── dev-rules/         # 開発関連ルール
│   ├── globals.mdc        # グローバルルール
│   ├── rules.mdc          # プロジェクトルール
│   ├── todo.mdc           # タスク管理
│   └── uiux.mdc           # UI/UX関連
├── setup.sh               # セットアップスクリプト
├── README.md              # 説明書（このファイル）
└── .spellright.json       # mdスペルチェック無効化
```

## 🚀 使用方法

### 1. セットアップスクリプト実行

```bash
./setup.sh
```

### 2. パターン選択

スクリプト実行後、以下の 3 パターンから選択できます：

#### パターン 1: 基本設定

- Cursor Rules 設定のみ
- 軽量で最小限の構成
- 初心者や軽量使用に適している

#### パターン 2: 開発環境設定

- Cursor Rules + Claude Code 設定
- 開発作業に必要な基本環境
- 通常の開発作業に最適

#### パターン 3: 完全設定

- 全機能 + AI 組織システム
- 高度な開発・分析環境
- 高度な開発やチーム作業に適している

## 📋 各パターンの詳細

### パターン 1 で設定されるもの

- `.cursor/rules/` - Cursor 用ルールファイル
- `.cursor/rules.md` - メインルールファイル

### パターン 2 で追加されるもの

- `.claude-project` - Claude Code 設定
- `claude-cursor-sync.sh` - Cursor-Claude 同期スクリプト

### パターン 3 で追加されるもの

- `ai-agents/` - AI 組織システム
- `ai-agents/instructions/` - 各 AI 役割の指示書
- `ai-agents/manage.sh` - AI 組織管理スクリプト

## 🔧 セットアップ後の操作

### 基本設定後

```bash
# Cursorを再起動してRulesを反映
```

### 開発環境設定後

```bash
# Cursor作業状況を記録
./claude-cursor-sync.sh record

# 記録した状況をClaude Codeで確認
./claude-cursor-sync.sh share
```

### 完全設定後

```bash
# AI組織システム開始
./ai-agents/manage.sh start

# AI組織システム状況確認
./ai-agents/manage.sh status
```

## 🎯 重要事項

- **機能の勝手な変更禁止**: 明示的に指示されていない変更は行いません
- **日本語コミュニケーション**: 全て日本語で対応します
- **ユーザー最優先**: ユーザーの要求を最優先に処理します
- **シンプル構成**: 必要最小限のファイル構成を維持します

## 📞 サポート

設定や使用方法で不明な点がある場合は、セットアップスクリプトの選択メニューから適切なパターンを選択し直してください。

---

_Last updated: 2025-01-22_
