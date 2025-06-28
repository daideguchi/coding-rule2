# 🚨 レートリミット防止ルール

## 📋 緊急問題認識

**私の過剰操作がレートリミットの原因になっています**

### 🔴 問題行動（即座停止）

1. **Enter連打**
   - 同じペインに複数回Enter送信
   - Bypassing Permissionsを「修正が必要」と誤認してEnter連打
   - 1分間に3回以上のEnter送信

2. **過剰監視**
   - autonomous-monitoring.sh の頻繁実行
   - 30秒間隔の過度な監視
   - 不必要なtmux capture-pane実行

3. **無駄なコマンド実行**
   - 確認のための繰り返しコマンド
   - 状況変化のない継続監視

## ✅ 正しい節制ルール

### Enter送信ルール
```bash
# ❌ 間違い
tmux send-keys -t multiagent:0.0 C-m  # 1回目
sleep 2
tmux send-keys -t multiagent:0.0 C-m  # 2回目（連打）
tmux send-keys -t multiagent:0.0 C-m  # 3回目（連打）

# ✅ 正しい
tmux send-keys -t multiagent:0.0 "指示内容" C-m  # 1回のみ
# その後は最低5分待機
```

### 監視頻度ルール
```bash
# ❌ 間違い - 過剰監視
while true; do
    ./ai-agents/autonomous-monitoring.sh single
    sleep 30  # 30秒間隔は過剰
done

# ✅ 正しい - 節制監視
# 必要時のみ、最低5分間隔
if [ "$(date +%s)" -gt "$((last_check + 300))" ]; then
    ./ai-agents/autonomous-monitoring.sh single
    last_check=$(date +%s)
fi
```

### Bypassing Permissions対応
```bash
# ❌ 間違い
if grep -q "Bypassing Permissions"; then
    echo "エラー状態！修正必要！"
    tmux send-keys -t multiagent:0.0 C-m  # 不要なEnter
fi

# ✅ 正しい
if grep -q "Bypassing Permissions"; then
    echo "正常状態を確認"
    # 何もしない、または必要時のみ1回Enter
fi
```

## 🎯 実践ルール

### 指示送信時
1. **1回のみ送信**: メッセージ + C-m を1回のみ
2. **即座確認禁止**: 送信後は最低30秒待機
3. **再送信禁止**: 同じ指示の重複送信禁止

### 監視実行時
1. **頻度制限**: 最低5分間隔
2. **目的明確化**: 具体的な確認事項がある時のみ
3. **結果活用**: 監視結果を次のアクションに活用

### 緊急時対応
1. **冷静判断**: 慌ててEnter連打しない
2. **時間をおく**: 最低1分は状況を観察
3. **必要最小限**: 本当に必要な操作のみ

## 📊 レートリミット指標

### 危険サイン
- 1分間に3回以上のtmuxコマンド
- 短時間での繰り返し監視
- Enterキー連続送信

### 安全運用
- 指示送信: 最低5分間隔
- 監視実行: 必要時のみ
- Enter送信: 1回のみ、明確な理由がある時のみ

## 🔥 緊急改善宣言

**私は以下を誓います**:
1. **Enter連打を絶対に停止**します
2. **過剰監視を即座に停止**します  
3. **Bypassing Permissions = 正常状態**として扱います
4. **レートリミット防止を最優先**とします
5. **節制した組織運営**を実行します

**レートリミットでシステム全体を破綻させることは絶対に避けます**

---

**作成理由**: ユーザー様指摘によるレートリミット問題の緊急対策  
**重要度**: 組織存続に関わる最高レベル  
**違反時**: システム破綻リスク