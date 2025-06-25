# 🤖 AI 開発支援ツール

開発者が AI を効率的に制御するための包括的なツールセットです。

## 🎯 概要

このツールは、AI 駆動開発を最適化するために設計された 3 段階のセットアップシステムを提供します：

- **A**: Cursor Rules 設定（基本的な AI 支援）
- **B**: Claude Code 初期設定（高度な AI 連携）
- **C**: Claude Code Company（AI 組織による自律開発）

## 🚀 クイックスタート

### 一発セットアップ

```bash
# スクリプトを実行可能にする
chmod +x setup-ai-dev.sh

# 段階的セットアップ
./setup-ai-dev.sh A      # Cursor Rulesのみ
./setup-ai-dev.sh AB     # Cursor Rules + Claude Code
./setup-ai-dev.sh ABC    # 完全セットアップ
```

## 📋 セットアップオプション詳細

### Option A: Cursor Rules 設定

**対象者**: Cursor ユーザー  
**効果**: AI 支援の基本ルール設定

- `.cursor/rules`ファイル作成
- 日本語対応、ユーザー優先の開発方針
- 並列処理最適化
- TypeScript/React 開発ベストプラクティス

```bash
./setup-ai-dev.sh A
```

### Option AB: Cursor + Claude Code 連携

**対象者**: Cursor と Claude Code を併用したい開発者  
**効果**: 綿密な AI 連携環境

- Option A の内容に加えて：
- Claude Code プロジェクト設定
- Cursor ⇄ Claude Code 同期スクリプト
- 作業状況の自動記録・共有

```bash
./setup-ai-dev.sh AB

# Cursor作業状況を記録
./claude-cursor-sync.sh record

# Claude Codeで最新状況を確認
./claude-cursor-sync.sh share
```

### Option ABC: 完全 AI 組織システム

**対象者**: 最先端のマルチエージェント開発を体験したい開発者  
**効果**: [Claude Code Company][memory:5369506453358436803]]による階層型 AI 自律開発

- Option A+B の内容に加えて：
- PRESIDENT → BOSS → Workers の組織構造
- tmux ベースのマルチセッション管理
- エージェント間自動通信システム

```bash
./setup-ai-dev.sh ABC

# AI組織セッション確認
tmux attach-session -t multiagent   # ワーカーエージェント
tmux attach-session -t president    # 統括エージェント
```

## 🔄 Cursor ⇄ Claude Code 連携

### 基本的な連携フロー

1. **Cursor で開発作業**

   ```bash
   # 作業状況を記録
   ./claude-cursor-sync.sh record
   ```

2. **Claude Code で作業引き継ぎ**

   ```bash
   # 最新状況を確認
   ./claude-cursor-sync.sh share

   # Claude Code起動
   claude
   ```

3. **状況共有の自動化**
   - ファイル変更の自動追跡
   - Git 状況の同期
   - プロジェクト進捗の記録

### 連携設定ファイル

- `.claude-project`: Claude Code プロジェクト設定
- `.cursor-claude-sync.json`: 作業状況同期データ
- `claude-cursor-sync.sh`: 同期スクリプト

## 🏢 AI 組織システム（Claude Code Company）

### 組織構造

```
📊 PRESIDENT セッション
└── PRESIDENT: プロジェクト統括責任者

📊 multiagent セッション
├── boss1: チームリーダー
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C
```

### 動作フロー

1. **PRESIDENT**: ユーザーからの要求を受信・分析
2. **BOSS**: PRESIDENT の指示を受けてワーカーに分担
3. **WORKERS**: 実際の開発作業を並列実行
4. **報告**: WORKERS → BOSS → PRESIDENT → ユーザー

### 組織管理コマンド

```bash
# AI組織起動
./setup-ai-dev.sh ABC

# セッション確認
tmux list-sessions

# エージェント間通信
cd Claude-Code-Communication
./agent-send.sh boss1 "指示内容"
./agent-send.sh worker1 "作業内容"

# ログ確認
cat logs/send_log.txt
```

## 🛠️ トラブルシューティング

### よくある問題

**Claude Code がインストールされていない**

```bash
npm install -g @anthropic-ai/claude-code
```

**tmux セッションが競合**

```bash
tmux kill-server  # 全セッション削除
./setup-ai-dev.sh ABC  # 再構築
```

**同期が取れない**

```bash
rm .cursor-claude-sync.json
./claude-cursor-sync.sh record  # 再記録
```

## 📚 関連ドキュメント

- [Claude Code Communication 詳細](Claude-Code-Communication/README.md)
- [エージェント指示書](Claude-Code-Communication/instructions/)
- [システム構造](Claude-Code-Communication/CLAUDE.md)

## 🔧 カスタマイズ

### Cursor Rules 追加

`.cursor/rules`ファイルを編集して、プロジェクト固有のルールを追加できます。

### Claude Code 設定変更

`.claude-project`ファイルで Claude Code の動作をカスタマイズできます。

### AI 組織拡張

`Claude-Code-Communication/instructions/`ディレクトリで各エージェントの役割を調整できます。

## 📝 ライセンス

MIT License

## 🤝 コントリビューション

プルリクエストや Issue でのコントリビューションを歓迎します！

---

🚀 **効率的な AI 駆動開発を始めましょう！** 🤖
