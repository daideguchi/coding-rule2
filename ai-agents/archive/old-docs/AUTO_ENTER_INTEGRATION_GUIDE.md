# 🚀 統合自動エンターシステム v2.0 使用ガイド

## 概要

既存の4つの自動エンターシステムを統合し、エラーハンドリングを強化した改善版システムです。

### 統合された機能

1. **AUTO_ENTER_SYSTEM.sh** - 継続的監視・自動修正システム
2. **ENHANCED_DOUBLE_ENTER.sh** - 強化版ダブルエンターシステム  
3. **simple-enter.sh** - 簡単エンター送信機能
4. **PROMPT_RECOVERY_SYSTEM.sh** - プロンプト停止復旧・再発防止システム

## 主要な改善点

### ✅ 重複機能の整理
- 各システムの重複する機能を統合
- コードの簡潔化と保守性向上
- 統一的なログシステム実装

### ✅ エラーハンドリングの強化
- tmuxペイン存在チェック
- 段階的復旧アプローチ
- 詳細なエラーログ記録

### ✅ 統一的なプロンプト検知システム
- 複数の状態パターンに対応
- Bypassing Permissions検知
- Welcome to Claude Code検知
- エラー状態検知
- プロンプト（>）検知

### ✅ 確実なエンター送信機能
- ペインアクティブ化確認
- 送信結果の検証
- 自動リトライ機能

## システム構成

```
ai-agents/
├── UNIFIED_AUTO_ENTER_SYSTEM.sh  # 統合メインシステム
├── manage.sh                     # 管理システム（統合連携対応）
└── logs/                         # ログディレクトリ
    ├── unified-auto-enter.log    # メインログ
    ├── auto-enter-error.log      # エラーログ
    └── auto-enter-status.log     # 状態ログ
```

## 基本的な使い方

### 1. システム開始

```bash
# 統合システム開始（初期メッセージ配布）
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh start

# 継続的監視開始（バックグラウンド）
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh monitor &
```

### 2. manage.shとの連携

```bash
# AI組織システム全自動起動（統合システム自動連携）
./ai-agents/manage.sh auto

# Claude認証システム（統合システム自動連携）
./ai-agents/manage.sh claude-auth
```

### 3. 状況確認

```bash
# システム状況確認
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh status

# ワーカー状態確認
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh check president PRESIDENT
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh check multiagent:0.0 BOSS1
```

### 4. メッセージ送信

```bash
# 自動エンター付きメッセージ送信
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh send president "こんにちは" PRESIDENT

# 初期メッセージ一括配布
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh init-messages
```

### 5. 復旧・メンテナンス

```bash
# 指定ターゲットの自動復旧
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh recover multiagent:0.1 WORKER1

# 緊急プロンプト解消（全ワーカー対象）
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh emergency

# システム停止
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh stop
```

## 状態検知システム

### 検知可能な状態

| 状態 | 説明 | 対応 |
|------|------|------|
| `ready` | 準備完了状態 | 正常 |
| `stuck_with_input` | 入力フィールドに未処理テキスト | 自動復旧 |
| `stuck_with_prompt` | プロンプト停止状態 | 自動復旧 |
| `error_state` | エラー状態 | 強制復旧 |
| `pane_not_found` | ペインが存在しない | エラー報告 |
| `unknown` | 状態不明 | 監視継続 |

### 自動復旧プロセス

1. **現在状態の確認**
2. **段階的復旧アプローチ**
   - ダブルエンターによる復旧
   - エラー状態からの強制復旧
3. **復旧結果の検証**
4. **必要に応じてリトライ**

## ログシステム

### ログファイル

- **unified-auto-enter.log**: メインシステムログ
- **auto-enter-error.log**: エラー専用ログ
- **auto-enter-status.log**: 状態変化ログ

### ログレベル

- `[INFO]`: 情報メッセージ（緑色）
- `[SUCCESS]`: 成功メッセージ（青色）
- `[WARN]`: 警告メッセージ（黄色）
- `[ERROR]`: エラーメッセージ（赤色）

## トラブルシューティング

### よくある問題と解決策

#### 1. ワーカーが「状態不明」と表示される
```bash
# tmuxセッションが起動しているか確認
tmux list-sessions

# セッションが存在しない場合
./ai-agents/manage.sh start
```

#### 2. プロンプト停止が頻発する
```bash
# 緊急プロンプト解消実行
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh emergency

# 継続的監視を開始
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh monitor &
```

#### 3. システムが応答しない
```bash
# ログファイルを確認
tail -f ./ai-agents/logs/unified-auto-enter.log

# システム再起動
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh stop
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh start
```

#### 4. ログファイルが大きくなりすぎた
```bash
# ログファイル削除
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh clear-logs
```

## manage.shとの統合

### 自動連携機能

manage.shの以下のコマンドで統合システムが自動的に連携されます：

1. **auto**: 全自動起動時
2. **claude-auth**: Claude認証時
3. **quick-start**: 簡単起動時

### フォールバック機能

統合システムが利用できない場合、manage.shは従来の方式に自動的にフォールバックします。

## パフォーマンス最適化

### 監視間隔の調整

```bash
# 監視間隔を変更（デフォルト: 10秒）
./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh monitor 5  # 5秒間隔
```

### バックグラウンド実行

```bash
# システムをデーモンとして実行
nohup ./ai-agents/UNIFIED_AUTO_ENTER_SYSTEM.sh monitor > /dev/null 2>&1 &
```

## セキュリティ考慮事項

1. **権限確認**: tmuxセッションへのアクセス権限を確認
2. **ログ管理**: 機密情報がログに記録されないよう注意
3. **プロセス管理**: 不要なバックグラウンドプロセスを定期的に確認

## まとめ

統合自動エンターシステム v2.0は、既存の4つのシステムの機能を統合し、エラーハンドリングを強化したことで、より安定したAI組織システムの運用を可能にします。

管理システム（manage.sh）との連携により、ユーザーは特別な操作を行うことなく、改善されたシステムの恩恵を受けることができます。

---

**作成日**: 2025-06-30  
**バージョン**: v2.0  
**対象システム**: AI組織管理システム