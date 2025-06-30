# 🚨 PRESIDENT 立ち上げ必須チェックリスト

## 🔥 絶対必須の立ち上げ手順（毎回実行）

### Step 1: 基本システム起動
```bash
# 1. 全ワーカー起動（エンター付きコマンド）
tmux send-keys -t multiagent:0.0 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t multiagent:0.1 "claude --dangerously-skip-permissions" C-m  
tmux send-keys -t multiagent:0.2 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t multiagent:0.3 "claude --dangerously-skip-permissions" C-m

# 2. 役割指示送信
tmux send-keys -t multiagent:0.0 "あなたはBOSS1です。./ai-agents/instructions/boss1.mdの指示書を参照してください。" C-m
tmux send-keys -t multiagent:0.1 "あなたはWORKER1です。./ai-agents/instructions/worker1.mdの指示書を参照してください。" C-m
tmux send-keys -t multiagent:0.2 "あなたはWORKER2です。./ai-agents/instructions/worker2.mdの指示書を参照してください。" C-m
tmux send-keys -t multiagent:0.3 "あなたはWORKER3です。./ai-agents/instructions/worker3.mdの指示書を参照してください。" C-m
```

### Step 2: 🚨 絶対必須システム起動
```bash
# 0. tmuxステータスバー表示設定（毎回必須）
tmux set-option -g pane-border-status top

# 1. ステータスバー表示システム起動
./ai-agents/AUTO_STATUS_DETECTION.sh update

# 2. 各ワーカー宣言実行
tmux send-keys -t multiagent:0.0 "私は👔BOSS1です。チームリーダーとして準備完了しました。プロジェクト進行を開始します。" C-m
tmux send-keys -t multiagent:0.1 "私は💻WORKER1です。フロントエンド開発者として準備完了しました。UI/UX実装準備OK。" C-m
tmux send-keys -t multiagent:0.2 "私は🔧WORKER2です。バックエンド開発者として準備完了しました。API・DB設計準備OK。" C-m
tmux send-keys -t multiagent:0.3 "私は🎨WORKER3です。UI/UXデザイナーとして準備完了しました。デザインシステム準備OK。" C-m

# 3. 自律監視システム起動
./ai-agents/autonomous-monitoring.sh continuous &
```

### Step 3: プロジェクト分析・役職適正配置
```bash
# 1. 要件定義・仕様書確認
# 2. プロジェクト特性に応じた役職再配置
# 3. 具体的タスク指示をBOSS1に送信
```

## 🚨 絶対に忘れてはいけない項目

### ✅ 必須確認項目
- [ ] ステータス情報表示確認（./ai-agents/status-check.sh実行）
- [ ] 全ワーカー宣言完了確認  
- [ ] 自律監視システム稼働確認
- [ ] プロジェクト要件に応じた役職配置確認
- [ ] BOSS1への具体的指示送信完了

### 🚨 ステータス確認の絶対ルール
- UIを勝手に変更しない（pane-border-status off維持）
- ./ai-agents/status-check.sh で非侵襲的にステータス確認
- ユーザーが要求した場合のみ、事前承認後にUI調整

### ❌ 絶対禁止項目
- ステータスバー表示なしでの作業開始
- ワーカー宣言なしでの作業開始
- 監視システムなしでの作業開始
- 要件確認なしでの役職固定配置

## 🎯 自律成長への道

**最強のプレジデントとして**：
- 毎回このチェックリストを100%実行
- ミスを絶対に繰り返さない
- ユーザーの信頼を獲得し続ける
- 組織の実力を最大限発揮

**この手順を守らない場合、過去の重大ミスを繰り返す可能性が極めて高い**