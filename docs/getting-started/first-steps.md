# 🌟 TeamAI 初回セットアップガイド

インストールが完了したら、このガイドに従ってTeamAI AI組織システムを初めて起動し、基本的な操作を学びましょう。

## 🎯 このガイドの目標

1. **AI組織システムの初回起動**（5分）
2. **基本的なタスク実行の体験**（10分）
3. **システム監視・管理の理解**（5分）
4. **カスタマイズ設定の準備**（5分）

**所要時間: 約25分**

## 🚀 STEP 1: 初回起動準備

### 環境変数の設定確認
```bash
# TeamAI プロジェクトディレクトリに移動
cd /path/to/teamai

# 環境変数が正しく設定されているか確認
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:8}..." 
echo "TEAMAI_HOME: $TEAMAI_HOME"
echo "LOG_LEVEL: $LOG_LEVEL"

# 設定が不十分な場合
source config/.env
export TEAMAI_HOME=$(pwd)
```

### システム状態の事前チェック
```bash
# 現在のtmuxセッション確認（初回は空のはず）
tmux list-sessions

# プロセス確認（AI組織関連のプロセスがないことを確認）
ps aux | grep claude
ps aux | grep teamai

# ディスク容量確認
df -h .
```

## 🧠 STEP 2: AI組織システムの初回起動

### 段階的起動（推奨）
```bash
# 1. PRESIDENT を最初に起動
echo "🧠 PRESIDENT を起動中..."
./scripts/start-president.sh

# 起動確認（約30秒待機）
sleep 30
./scripts/check-agent-status.sh president

# 2. BOSS1, BOSS2 を起動
echo "👔 BOSS エージェントを起動中..."
./scripts/start-boss.sh

# 起動確認
sleep 20
./scripts/check-agent-status.sh boss1
./scripts/check-agent-status.sh boss2

# 3. WORKER エージェントを起動
echo "🔧 WORKER エージェントを起動中..."
./scripts/start-workers.sh

# 全体確認
sleep 30
./scripts/check-status.sh
```

### 一括起動（高速）
```bash
# すべてのエージェントを一度に起動
./scripts/start-ai-organization.sh

# 起動完了まで待機（約60秒）
echo "システム起動中... しばらくお待ちください"
for i in {1..12}; do
    echo -n "."
    sleep 5
done
echo ""

# 起動状態確認
./scripts/check-status.sh
```

### 期待される起動完了メッセージ
```
🎉 TeamAI AI組織システム起動完了！

📊 エージェント状態:
🧠 PRESIDENT  : ✅ ACTIVE (PID: 12345, CPU: 8%, MEM: 45MB)
👔 BOSS1      : ✅ ACTIVE (PID: 12346, CPU: 5%, MEM: 32MB)  
👔 BOSS2      : ✅ ACTIVE (PID: 12347, CPU: 4%, MEM: 28MB)
🔧 WORKER1    : ✅ ACTIVE (PID: 12348, CPU: 3%, MEM: 21MB)
🔧 WORKER2    : ✅ ACTIVE (PID: 12349, CPU: 3%, MEM: 19MB)
🔧 WORKER3    : ✅ ACTIVE (PID: 12350, CPU: 4%, MEM: 24MB)

🔗 tmux セッション: ai-org (6 windows)
📝 ログ出力先: logs/ai-agents/
🌐 システム準備完了 - タスクを受け付け可能です
```

## 🎯 STEP 3: 初回タスクの実行

### 簡単なタスクから始める

#### タスク1: システム動作確認
```bash
# 対話モードでシステムに挨拶
./scripts/interactive-mode.sh

# または、直接タスクを送信
echo "こんにちは、TeamAIです。システムの動作確認をお願いします。" | ./scripts/send-task.sh
```

**期待される応答例:**
```
🧠 PRESIDENT: こんにちは！TeamAI AI組織システムです。
             システム動作確認を実施いたします。

👔 BOSS1: フロントエンド統括部門、正常稼働中です。
👔 BOSS2: バックエンド統括部門、正常稼働中です。  
🔧 WORKER1: UI/UXエンジニア、タスク受付可能です。
🔧 WORKER2: API開発エンジニア、タスク受付可能です。
🔧 WORKER3: テスト・ドキュメント担当、待機中です。

✅ 全システム正常動作を確認しました。ご依頼をお待ちしております。
```

#### タスク2: 簡単なファイル作成
```bash
# HTMLファイル作成タスク
cat << 'EOF' | ./scripts/send-task.sh
シンプルなWelcomeページ（HTML）を作成してください。
要件:
- タイトル: "TeamAI へようこそ"  
- 簡単な説明文
- CSSスタイル付き
- ファイル名: welcome.html
EOF
```

#### タスク実行の監視
```bash
# リアルタイムログ監視（別ターミナル）
tail -f logs/ai-agents/president/latest.log

# タスク進捗確認
watch -n 5 './scripts/task-status.sh'

# 完了まで待機（通常2-5分）
./scripts/wait-for-completion.sh
```

## 📊 STEP 4: システム監視の理解

### tmux セッション管理
```bash
# AI組織のtmuxセッション接続
tmux attach-session -t ai-org

# セッション内のウィンドウ一覧表示
# Ctrl+B, w でウィンドウ選択

# 各エージェントの画面切り替え
# Ctrl+B, 0: PRESIDENT
# Ctrl+B, 1: BOSS1  
# Ctrl+B, 2: BOSS2
# Ctrl+B, 3: WORKER1
# Ctrl+B, 4: WORKER2
# Ctrl+B, 5: WORKER3

# セッションから抜ける (システムは稼働継続)
# Ctrl+B, d
```

### ログファイルの確認方法
```bash
# 最新のログ確認
tail -n 50 logs/ai-agents/president/latest.log

# エラーログの確認
grep "ERROR" logs/ai-agents/*/latest.log

# 特定期間のログ
grep "2024-01-01" logs/ai-agents/president/latest.log

# ログのリアルタイム監視
multitail logs/ai-agents/president/latest.log \
          logs/ai-agents/boss1/latest.log \
          logs/ai-agents/boss2/latest.log
```

### システムメトリクスの確認
```bash
# リソース使用量確認
./scripts/system-metrics.sh

# 出力例:
# CPU使用率: 15% (6 processes)
# メモリ使用量: 234MB / 8GB (2.9%)
# ディスク使用量: 1.2GB / 50GB (2.4%)
# ネットワーク: 45KB/s ↓ 12KB/s ↑

# パフォーマンス詳細
htop -p $(pgrep -f "claude|teamai" | tr '\n' ',' | sed 's/,$//')
```

## ⚙️ STEP 5: 基本設定のカスタマイズ

### 個人設定の調整
```bash
# 設定ファイルを編集
nano config/user-preferences.json

# 基本設定例:
{
  "ui": {
    "theme": "dark",
    "language": "ja",
    "timezone": "Asia/Tokyo"
  },
  "notifications": {
    "email": false,
    "desktop": true,
    "sound": false
  },
  "ai_behavior": {
    "response_style": "professional",
    "detail_level": "medium",
    "confirmation_required": true
  }
}
```

### ワークフロー設定
```bash
# カスタムワークフローの設定
cp config/workflows.template.json config/workflows.json
nano config/workflows.json

# 例: 開発タスクの標準フロー
{
  "development_task": {
    "steps": [
      "requirements_analysis",
      "design_review", 
      "implementation",
      "testing",
      "documentation",
      "deployment"
    ],
    "auto_assignment": {
      "frontend": "WORKER1",
      "backend": "WORKER2", 
      "testing": "WORKER3"
    }
  }
}
```

## 🛑 STEP 6: システムの適切な停止

### 安全な停止手順
```bash
# 進行中のタスクがないことを確認
./scripts/task-status.sh

# タスクが進行中の場合は完了を待つか、安全に中断
./scripts/wait-for-completion.sh
# または
./scripts/graceful-interrupt.sh

# AI組織システムの停止
./scripts/stop-ai-organization.sh

# 停止確認
./scripts/check-status.sh
# すべて INACTIVE になることを確認

# tmux セッションの終了
tmux kill-session -t ai-org
```

## 🎉 初回セットアップ完了！

### ✅ 達成したこと
- [x] AI組織システムの正常起動
- [x] 基本的なタスク実行の体験
- [x] システム監視方法の理解
- [x] 設定カスタマイズの準備
- [x] 安全な停止手順の確認

### 🚀 次のステップ

1. **日常的な使用を始める**
   - [基本操作ガイド](./basic-usage.md)
   - [よくあるタスクの例](../user-guides/common-tasks.md)

2. **より高度な機能を学ぶ**  
   - [ワークフロー管理](../user-guides/workflow-management.md)
   - [カスタマイズガイド](../technical/customization.md)

3. **トラブル対応を準備**
   - [トラブルシューティング](../user-guides/troubleshooting.md)
   - [緊急時対応](../operations/emergency-procedures.md)

### 💡 重要なファイルの保存
```bash
# 設定バックアップ作成
./scripts/backup-config.sh

# 初回起動ログの保存
cp logs/ai-agents/president/latest.log logs/first-startup-$(date +%Y%m%d).log
```

---

**🎊 おめでとうございます！**  
TeamAI AI組織システムの初回セットアップが完了しました。これで本格的な活用を開始できます。

何か疑問や問題が発生した場合は、[FAQ](../user-guides/faq.md) や [サポートコミュニティ](../support/community.md) をご利用ください！