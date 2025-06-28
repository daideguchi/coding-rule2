# 🎯 TeamAI ユーザーガイド

## 🌟 はじめに
**TeamAI**は、AI開発支援ツールの統合プラットフォームです。  
初心者から上級者まで、あなたのレベルに合わせた設定で、最高のAI開発体験を提供します。

---

## 🚀 クイックスタート

### 📥 1. インストール
```bash
# リポジトリをクローン
git clone https://github.com/[your-repo]/team-ai.git
cd team-ai

# 実行権限を付与
chmod +x setup.sh
```

### ⚡ 2. セットアップ開始
```bash
./setup.sh
```

### 🎮 3. レベル選択

画面に表示されるメニューから選択してください：

```
🤖 AI開発支援ツール セットアップ
==================================

1) 基本設定 🟢
   - Cursor Rules設定のみ
   - 軽量で最小限の構成
   ✅ 初心者・お試し利用におすすめ

2) 開発環境設定 🟡  
   - Cursor Rules + Claude Code設定
   - 開発作業に必要な基本環境
   ✅ 本格的な開発作業におすすめ

3) 完全設定 🔴
   - 全機能 + AI組織システム
   - 高度な開発・分析環境
   ✅ 上級者・チーム開発におすすめ
```

---

## 📋 各設定の詳細

### 🟢 基本設定（レベル1）
**対象**: 初心者・AI支援を試したい方

**含まれるもの**:
- Cursor Rules自動設定
- 基本的なAI開発ガイドライン
- コード品質チェック

**使い方**:
1. セットアップ完了後、Cursorを再起動
2. 新しいプロジェクトを開く
3. AI支援が自動的に適用される

### 🟡 開発環境設定（レベル2）
**対象**: 中級者・本格的な開発をしたい方

**含まれるもの**:
- 基本設定の全機能
- Claude Code連携
- 自動同期機能
- 高度なコード分析

**使い方**:
1. セットアップ完了後、以下を実行:
   ```bash
   # Cursor再起動
   # 新しいターミナルで
   claude --dangerously-skip-permissions
   ```

### 🔴 完全設定（レベル3）
**対象**: 上級者・AI組織システムを活用したい方

**含まれるもの**:
- レベル2の全機能
- 階層型AI組織システム
- 並列処理機能
- 高度な分析・監視

**使い方**:
1. セットアップ完了後:
   ```bash
   # AI組織システム起動
   ./ai-agents/manage.sh quick-start
   ```

---

## 🎨 視覚的な使い方

### 📊 AI組織システムの構造
```
     👑 PRESIDENT
     (統括責任者)
          │
          ▼
     👔 BOSS1
     (チームリーダー)
          │
    ┌─────┼─────┐
    ▼     ▼     ▼
 👷‍♂️W1  👷‍♀️W2  🎨W3
(実行) (実行) (UI/UX)
```

### 🖥️ ターミナル画面の見方
```
┌─────────────────────────────────────┐
│ 🤖 AI組織システム    2025-06-27 10:30 │
├─────────────────────────────────────┤
│ 👑 PRESIDENT・統括責任者 [ACTIVE]      │
│                                     │
│ Welcome to Claude Code              │
│ AI開発支援を開始します...             │
│                                     │
│ cwd: /Users/you/project            │
│ What would you like to do?         │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔧 基本操作

### 🎯 AI組織システムの操作

#### 💬 AIエージェントに指示を送る
```bash
# 特定のエージェントに指示
./ai-agents/agent-send.sh worker1 "ファイル構造を分析してください"

# 複数のエージェントに同時指示
./ai-agents/agent-send.sh boss "チーム全体でコードレビューを実行"
```

#### 📊 システム状態の確認
```bash
# 現在の状態確認
./ai-agents/manage.sh status

# 詳細な健康状態チェック
./ai-agents/manage.sh health-check
```

#### 🎨 視覚テーマの適用
```bash
# 美しいターミナル表示に切り替え
./scripts/visual-improvements.sh --apply-theme
```

### 🎮 基本的なワークフロー

#### 🔥 新しいプロジェクト開始
1. **準備**:
   ```bash
   cd your-project
   # TeamAI設定を適用
   cp -r /path/to/team-ai/cursor-rules .
   ```

2. **AI支援開始**:
   ```bash
   # Cursor起動
   cursor .
   
   # Claude Code起動（レベル2以上）
   claude --dangerously-skip-permissions
   ```

3. **AI組織活用**（レベル3）:
   ```bash
   # AI組織システム起動
   ./ai-agents/manage.sh quick-start
   
   # 作業指示
   ./ai-agents/agent-send.sh boss "新機能の設計を検討してください"
   ```

---

## 🎯 実践的な使用例

### 🌟 シナリオ1: 「新しい機能を追加したい」

#### レベル1（基本設定）の場合:
1. Cursorでプロジェクトを開く
2. 新しいファイルを作成
3. AIアシスタントに「新機能のコードを書いて」と指示
4. 自動的に品質チェックが適用される

#### レベル2（開発環境）の場合:
1. Cursorでコード編集
2. Claude Codeで詳細な分析
3. 2つのAIが連携して最適な実装を提案

#### レベル3（完全設定）の場合:
1. BOSSに「新機能の設計」を指示
2. WORKER1が技術仕様を作成
3. WORKER2が実装を担当
4. WORKER3がUI/UXを最適化
5. 自動的に並列処理で高速開発

### 🌟 シナリオ2: 「コードレビューをしたい」

```bash
# レベル1-2の場合
# Cursor/Claude Codeで手動レビュー

# レベル3の場合
./ai-agents/agent-send.sh boss "プロジェクト全体のコードレビューを実行"
# → 複数AIが同時に異なる観点からレビュー
```

---

## 💡 効果的な使い方のコツ

### 🎯 AI指示のベストプラクティス

#### ✅ 良い指示の例:
```bash
# 具体的で明確な指示
./ai-agents/agent-send.sh worker1 "React componentsディレクトリの全ファイルでTypeScriptエラーを修正してください"

# 役割を明確にした指示
./ai-agents/agent-send.sh worker3 "ユーザビリティの観点からログイン画面を改善してください"
```

#### ❌ 避けるべき指示:
```bash
# 曖昧すぎる指示
./ai-agents/agent-send.sh worker1 "何かいい感じにして"

# 範囲が広すぎる指示
./ai-agents/agent-send.sh boss "プロジェクト全体を完璧にして"
```

### 🔥 生産性向上のテクニック

#### 📊 監視とログ活用:
```bash
# リアルタイム監視
./ai-agents/monitoring-dashboard.sh

# ログ分析
./ai-agents/log-check.sh
```

#### 🎨 視覚化活用:
```bash
# 美しいターミナル表示
./scripts/visual-improvements.sh --apply-theme

# 動的ステータス更新
./scripts/visual-improvements.sh --start-dynamic
```

---

## 🎉 まとめ

**TeamAI**は、あなたの開発スタイルに合わせて成長する、柔軟なAI開発支援プラットフォームです。

### 🎯 次のステップ
1. **まずは基本設定**から始めて、AI支援を体験
2. **慣れてきたら開発環境設定**でパワーアップ
3. **最終的には完全設定**でAI組織システムを活用

### 🚀 さらなる情報
- 詳細な設定: [PRODUCT_SPECIFICATION.md](../PRODUCT_SPECIFICATION.md)
- トラブルシューティング: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- セキュリティ: [docs/SECURITY.md](../docs/SECURITY.md)

---

*🎯 Happy Coding with AI! 🤖*