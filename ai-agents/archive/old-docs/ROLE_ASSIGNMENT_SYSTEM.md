# 確実な役職設定システム

## 🎯 問題分析
現在役職が設定されていない原因:
1. ワーカー起動後の役職設定指示なし
2. 指示書確認の強制なし  
3. ステータスバー表示システム未稼働
4. 設定確認の怠慢

## ✅ 解決策

### 1. 起動時強制役職設定
```bash
# 各ワーカーに強制送信
tmux send-keys -t multiagent:0.0 "あなたはBOSS1です。👔チームリーダーとしてタスク分割・分担管理を担当。ai-agents/instructions/boss1.mdを確認してください。" C-m

tmux send-keys -t multiagent:0.1 "あなたはWORKER1です。💻フロントエンド開発・UI/UX実装担当。ai-agents/instructions/worker.mdを確認してください。" C-m

tmux send-keys -t multiagent:0.2 "あなたはWORKER2です。🔧バックエンド開発・API設計・DB設計担当。ai-agents/instructions/worker.mdを確認してください。" C-m

tmux send-keys -t multiagent:0.3 "あなたはWORKER3です。🎨UI/UXデザイナー・デザインシステム担当。ai-agents/instructions/worker.mdを確認してください。" C-m
```

### 2. ステータスバー強制表示
```bash
tmux set-option -g pane-border-status top
tmux set-option -g pane-border-format '#[bg=colour240,fg=colour15,bold] #{pane_title} '
```

### 3. 役職確認強制
各ワーカーに「自分の役職を宣言してください」を送信し、返答確認まで次の作業禁止

## 🔥 絶対実行フロー
1. 全ワーカー起動
2. 役職設定指示送信（4名全員）
3. ステータスバー設定
4. 役職宣言確認（4名全員）
5. 全て完了確認まで他作業禁止

## ⚠️ 失敗防止
- 推測での「設定完了」報告禁止
- 必ず実際の画面確認
- 1つでも未完了なら全体未完了