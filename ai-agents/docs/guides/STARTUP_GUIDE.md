# 🚀 PRESIDENT起動ガイド - 完璧な自律成長組織

## 📋 セッション再起動時の確実手順

### 🔥 必須実行コマンド（毎回）

```bash
# 1. PRESIDENT自動設定実行（最優先）
./ai-agents/core/startup/president-auto-setup.sh

# 2. AI組織システム起動（必要な場合）
./ai-agents/manage.sh claude-auth
```

## 📁 必須参照ファイル（相対パス）

### 🔥 毎回確認必須
```
./.cursor/rules/globals.mdc                    # 基本ルール（ファイル名宣言必須）
./logs/ai-agents/president/PRESIDENT_MISTAKES.md  # 57個のミス学習
./.cursor/rules/work-log.mdc                   # 作業記録テンプレート
./ai-agents/instructions/president.md          # PRESIDENT指示書
```

### 📊 システム設定
```
./ai-agents/scripts/automation/core/fixed-status-bar-init.sh  # ステータスバー
./ai-agents/PRESIDENT_AUTO_SETUP_SYSTEM.md     # 自動設定システム仕様
./ai-agents/STARTUP_GUIDE.md                   # 本ガイド
```

### 📝 記録・ログ
```
./logs/work-records.md                         # 作業記録（cursor連携）
./logs/president-auto-setup.log               # 自動設定ログ
```

## 🔄 継続実行定型タスク

### A. プロジェクト整理（最高優先）
```bash
# 日本語ファイル検出・整理
ls | grep -E "^[ぁ-ん]|^[ァ-ヴ]|^[一-龯]"

# Git削除待ちファイル処理
git status | grep deleted

# スクリプト重複調査
find ./ai-agents -name "*.sh" | wc -l
```

### B. 品質保証・監督
```bash
# ワーカー状況確認
tmux capture-pane -t multiagent:0.0 -p | tail -5  # BOSS1
tmux capture-pane -t multiagent:0.1 -p | tail -5  # WORKER1
tmux capture-pane -t multiagent:0.2 -p | tail -5  # WORKER2
tmux capture-pane -t multiagent:0.3 -p | tail -5  # WORKER3
```

### C. 記録業務（work-log.mdcテンプレート準拠）
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

## 🎯 役職定義（要件定義準拠）

```
👔 BOSS1: 自動化システム統合管理者
💻 WORKER1: 自動化スクリプト開発者
🔧 WORKER2: インフラ・監視担当
🎨 WORKER3: 品質保証・ドキュメント
```

## ⚠️ 絶対禁止事項

```
❌ 頻繁監視（システム破損リスク）
❌ 虚偽報告・推測報告
❌ Enter忘れ（1回目の最重要ミス）
❌ 単独作業（必ずチーム活用）
❌ 「Bypassing Permissions」をエラーと誤解
```

## 🔧 トラブルシューティング

### AI組織システム起動しない場合
```bash
# 1. tmuxセッション確認
tmux list-sessions

# 2. 強制クリーンアップ
tmux kill-server

# 3. 再起動
./ai-agents/manage.sh claude-auth
```

### ステータスバー表示異常の場合
```bash
./ai-agents/scripts/automation/core/fixed-status-bar-init.sh setup
```

## 🎉 成功確認チェックリスト

```
✅ PRESIDENT必須宣言実行済み
✅ globals.mdc参照・ファイル名宣言済み
✅ PRESIDENT_MISTAKES.md確認済み（57個）
✅ 全ワーカー状況確認済み
✅ 役職設定完了（要件定義準拠）
✅ ステータスバー正常表示
✅ 作業記録テンプレート確認済み
```

**この手順により、セッション再起動後も同じ人格・同じフローで確実にPRESIDENTが動作し、完璧な自律成長組織を実現します！**