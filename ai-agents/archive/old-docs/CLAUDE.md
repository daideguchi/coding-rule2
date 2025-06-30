# Claude Code Company - tmux 並列組織システム

## 🎯 プロジェクト概要

Cursor + Claude Code 連携開発環境での並列 AI 組織システム

## 🤖 エージェント構成

### ターミナル分割構成（デフォルト 4 ペイン）

- **PRESIDENT** (別セッション): 統括責任者・対話スペース
- **multiagent セッション（3 ペイン分割）**:
  - **boss1** (multiagent:0.0): チームリーダー
  - **worker1** (multiagent:0.1): 実行担当 1
  - **worker2** (multiagent:0.2): 実行担当 2
  - **worker3** (multiagent:0.3): 実行担当 3

## 📋 役割定義

- **PRESIDENT**: `ai-agents/instructions/president.md`
- **boss1**: `ai-agents/instructions/boss.md`
- **worker1,2,3**: `ai-agents/instructions/worker.md`

## 🚀 基本セットアップ

### tmux 環境起動

```bash
# 4画面AI組織システム起動
./ai-agents/manage.sh start

# tmuxセッション確認
tmux list-sessions
```

### pane 構成確認

```bash
# pane ID確認（実際の番号は環境により異なる）
tmux list-panes -F "#{pane_index}: #{pane_id} #{pane_current_command} #{pane_active}"
```

### Claude Code 一括起動

```bash
# 全セッションでClaude Code起動（権限スキップ）
./ai-agents/manage.sh claude-setup

# または個別起動
./ai-agents/agent-send.sh --claude-setup
```

## 💬 報連相システム

### メッセージ送信

```bash
# エージェント間通信
./ai-agents/agent-send.sh [相手] "[メッセージ]"

# 例
./ai-agents/agent-send.sh boss1 "Hello World プロジェクト開始"
./ai-agents/agent-send.sh worker1 "作業完了しました"
```

### tmux send-keys 直接操作

```bash
# 部下からメインへの報告形式（エージェントが使用）
tmux send-keys -t %22 '[pane番号] 報告内容' && sleep 0.1 && tmux send-keys -t %22 Enter
```

## 🔧 トークン管理

### /clear コマンド実行

```bash
# 個別クリア
tmux send-keys -t %27 "/clear" && sleep 0.1 && tmux send-keys -t %27 Enter

# 並列クリア
tmux send-keys -t %27 "/clear" && sleep 0.1 && tmux send-keys -t %27 Enter & \
tmux send-keys -t %28 "/clear" && sleep 0.1 && tmux send-keys -t %28 Enter & \
wait
```

### 実行タイミング

- タスク完了時（新しいタスクに集中）
- トークン使用量が高くなった時
- エラーが頻発している時
- 複雑 → 単純作業切り替え時

## 📊 状況確認

### pane 状況確認

```bash
# 各paneの最新状況
tmux capture-pane -t %27 -p | tail -10

# 全pane一括確認
for pane in %27 %28 %25 %29 %26; do
    echo "=== $pane ==="
    tmux capture-pane -t $pane -p | tail -5
done
```

### システム状況

```bash
# AI組織システム状況確認
./ai-agents/manage.sh status

# tmuxセッション確認
./ai-agents/agent-send.sh --status
```

## 🎬 デモ実行

### Hello World デモ

```bash
# デモ実行
./ai-agents/agent-send.sh --demo

# ログ確認
./ai-agents/agent-send.sh --logs
```

### 期待フロー

1. PRESIDENT → boss1: プロジェクト開始指示
2. boss1 → workers: 作業開始指示
3. workers → 作業実行・完了ファイル作成
4. worker → boss1: 完了報告
5. boss1 → PRESIDENT: 全員完了報告

## ✅ ベストプラクティス

### 明確な役割分担

- pane 番号を必ず伝達
- 担当タスクを具体的に指示
- エラー時の報告方法を明記

### 効率的なコミュニケーション

- ワンライナー形式での報告徹底
- [pane 番号]プレフィックス必須
- 具体的なエラー内容の報告

### トークン使用量管理

- 定期的な/clear 実行
- 大量トークン消費の監視
- ccusage での使用量確認

## ⚠️ 注意事項

- 部下は直接/clear できない（tmux 経由でのみ可能）
- 報告は必ずワンライナー形式で
- pane 番号の確認を怠らない
- トークン使用量の定期確認
- 複雑な指示は段階的に分割

## 📈 活用例

### 大規模タスクの分散処理

1. **資料作成**: 各 pane で異なる章を担当
2. **エラー解決**: 各 pane で異なる角度から調査
3. **知見共有**: 成功事例の文書化と横展開
4. **品質管理**: 並列でのファイル修正と確認

---

**参考**: [Claude Code を並列組織化して Claude Code "Company"にする tmux コマンド集](https://zenn.dev/kazuph/articles/beb87d102bd4f5)

## 📝 記録履歴

- 2025/06/26: tmux 並列組織システム実装完了
- Claude Code 起動時 `--dangerously-skip-permissions` フラグ適用
- 4 画面自動起動システム（macOS Terminal.app + Cursor 対応）
- 役割別対話機能・セッション管理・ログ機能実装
