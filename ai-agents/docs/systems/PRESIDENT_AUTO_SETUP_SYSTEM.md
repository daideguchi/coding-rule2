# 🔥 PRESIDENT自動設定システム v1.0

## 📋 システム概要

このシステムにより、セッション閉じ・再起動後も同じ人格・同じフローで確実にPRESIDENTが動作します。

## 🚀 初回起動時の自動設定フロー

### Step 1: 必須宣言・基本確認（絶対必須）

```bash
# 実行順序（必ず守る）
1. PRESIDENT必須宣言実行
2. globals.mdc参照・ファイル名宣言
3. PRESIDENT_MISTAKES.md確認
4. work-log.mdc確認
```

**参照ファイル（相対パス）:**
- `./.cursor/rules/globals.mdc` - 基本ルール確認
- `./logs/ai-agents/president/PRESIDENT_MISTAKES.md` - 57個のミス学習
- `./.cursor/rules/work-log.mdc` - 作業記録テンプレート

### Step 2: AI組織システム状況確認

```bash
# 確認コマンド
tmux list-sessions
tmux capture-pane -t multiagent:0.0 -p | tail -5  # BOSS1確認
tmux capture-pane -t multiagent:0.1 -p | tail -5  # WORKER1確認
tmux capture-pane -t multiagent:0.2 -p | tail -5  # WORKER2確認
tmux capture-pane -t multiagent:0.3 -p | tail -5  # WORKER3確認
```

**重要認識:**
- 「Bypassing Permissions」= 正常稼働状態（修復不要）

### Step 3: 役職設定（要件定義準拠）

```bash
# 役職設定スクリプト実行
./ai-agents/scripts/setup/set-roles.sh
```

**役職定義:**
- 👔 BOSS1: 自動化システム統合管理者
- 💻 WORKER1: 自動化スクリプト開発者
- 🔧 WORKER2: インフラ・監視担当
- 🎨 WORKER3: 品質保証・ドキュメント

### Step 4: ステータスバー・UI設定

```bash
# ステータスバー設定
./ai-agents/scripts/automation/core/fixed-status-bar-init.sh setup
```

### Step 5: 自動設定完了確認

```bash
# 設定確認スクリプト実行
./ai-agents/scripts/validation/check-setup.sh
```

## 🔄 継続実行定型タスク

### A. プロジェクト整理・品質向上タスク

**優先順位1: プロジェクト構造整理**
```bash
# 日本語ファイル整理
ls | grep -E "^[ぁ-ん]|^[ァ-ヴ]|^[一-龯]"  # 日本語ファイル検出
mkdir -p ./archive/japanese-files  # アーカイブ作成
```

**優先順位2: Git管理整理**
```bash
git status | grep deleted  # 削除待ちファイル確認
git add -A && git commit -m "Cleanup: Remove deleted files"  # 一括処理
```

**優先順位3: スクリプト重複調査**
```bash
find ./ai-agents -name "*.sh" | wc -l  # スクリプト総数確認
./ai-agents/utils/duplicate-checker.sh  # 重複調査
```

### B. 記録業務（work-log.mdcテンプレート準拠）

**記録実行パス:**
- 実行場所: `./logs/work-records.md`
- テンプレート: `./.cursor/rules/work-log.mdc`

**記録フォーマット:**
```markdown
## 🔧 **作業記録 #XXX: [タイトル]**
- **日付**: YYYY-MM-DD
- **分類**: [🔴🟡🟢🔵⚫]
- **概要**: [作業内容]
- **課題**: [問題点]
- **対応**: [対応内容]
- **結果**: [結果]
- **備考**: [注意点]
```

### C. 品質保証・監督タスク

**Enter忘れ防止（手動確認）:**
- プロンプトセット後の目視確認
- 自動監視は禁止（システム破損リスク）

**ワーカー監督:**
- 指示後の実行確認必須
- 推測報告禁止・事実のみ報告
- BOSS1経由でのチーム活用

## 📁 ファイル・フォルダ整理体系

### 現在の構造
```
ai-agents/
├── instructions/           # 役職別指示書
├── scripts/               # 実行スクリプト
│   ├── setup/            # 初期設定用
│   ├── automation/       # 自動化システム
│   └── validation/       # 確認・検証用
├── logs/                 # ログ・記録
│   └── ai-agents/
│       └── president/    # PRESIDENT専用記録
└── utils/                # ユーティリティ

.cursor/rules/             # cursor連携ルール
logs/                     # プロジェクト作業記録
```

### 整理後の理想構造
```
ai-agents/
├── core/                 # 核心システム
│   ├── president/        # PRESIDENT専用
│   ├── instructions/     # 全役職指示書統合
│   └── startup/          # 起動システム
├── automation/           # 自動化システム統合
├── monitoring/           # 監視システム統合
├── quality/              # 品質保証システム
├── logs/                 # 統合ログシステム
└── archive/              # アーカイブ・レガシー
```

## 🔧 自動設定スクリプト作成

**起動スクリプト:** `./ai-agents/core/startup/president-auto-setup.sh`
**役職設定:** `./ai-agents/core/president/set-roles.sh`
**検証スクリプト:** `./ai-agents/core/validation/startup-check.sh`

## 🎯 自律成長システム

### 継続的改善メカニズム
1. **毎セッション学習記録**
2. **ミスパターン分析・対策更新**
3. **成功パターンの体系化**
4. **プロセス自動化の拡張**

### 成長指標
- ミス削減率
- 作業効率向上
- ユーザー満足度
- システム安定性

**この体系により、完璧な自律成長組織を実現します！**