# 🔧 TeamAI トラブルシューティングガイド

## 🚨 よくある問題と解決方法

---

## 📥 セットアップ関連の問題

### ❌ 問題1: `./setup.sh` が実行できない

#### 症状:
```bash
$ ./setup.sh
bash: ./setup.sh: Permission denied
```

#### 🔧 解決方法:
```bash
# 実行権限を付与
chmod +x setup.sh

# 再実行
./setup.sh
```

#### 🔍 原因:
ファイルに実行権限が設定されていない

---

### ❌ 問題2: セットアップ途中でエラーが発生

#### 症状:
```bash
[ERROR] 設定ファイルのコピーに失敗しました
[ERROR] cursor-rules directory not found
```

#### 🔧 解決方法:
```bash
# 1. 現在のディレクトリを確認
pwd
# 期待値: /path/to/team-ai

# 2. 必要なディレクトリの存在確認
ls -la cursor-rules/

# 3. もしディレクトリが無い場合、再クローン
cd ..
rm -rf team-ai
git clone [repository-url] team-ai
cd team-ai
./setup.sh
```

#### 🔍 原因:
不完全なクローンまたは間違ったディレクトリでの実行

---

## 🤖 AI組織システム関連の問題

### ❌ 問題3: AI組織システムが起動しない

#### 症状:
```bash
$ ./ai-agents/manage.sh quick-start
[ERROR] tmux command not found
```

#### 🔧 解決方法:

##### macOSの場合:
```bash
# Homebrewでtmuxをインストール
brew install tmux

# 再実行
./ai-agents/manage.sh quick-start
```

##### Linuxの場合:
```bash
# Ubuntu/Debian
sudo apt-get install tmux

# CentOS/RHEL
sudo yum install tmux

# 再実行
./ai-agents/manage.sh quick-start
```

#### 🔍 原因:
tmuxがシステムにインストールされていない

---

### ❌ 問題4: Claude Codeが起動しない

#### 症状:
```bash
[ERROR] claude command not found
[ERROR] Claude Code is not installed or not in PATH
```

#### 🔧 解決方法:

##### ステップ1: Claude Codeインストール確認
```bash
# Claude Codeがインストールされているかチェック
which claude

# もしインストールされていない場合
curl -fsSL https://claude.ai/install.sh | sh
```

##### ステップ2: 認証設定
```bash
# 認証設定（初回のみ）
./setup.sh
# → メニューで 'a) 認証設定' を選択
```

##### ステップ3: 権限設定
```bash
# 危険なスキップ権限で実行（注意が必要）
claude --dangerously-skip-permissions
```

#### 🔍 原因:
Claude Codeの未インストールまたは未認証

---

### ❌ 問題5: tmuxセッションが見つからない

#### 症状:
```bash
[ERROR] no server running on /tmp/tmux-501/default
[ERROR] session not found: president
```

#### 🔧 解決方法:
```bash
# 1. 既存セッションの確認
tmux list-sessions

# 2. すべてのセッションを終了
tmux kill-server

# 3. AI組織システムを再起動
./ai-agents/manage.sh quick-start

# 4. セッションの確認
tmux list-sessions
```

#### 🔍 原因:
tmuxセッションが予期せず終了した

---

## 🎨 視覚テーマ関連の問題

### ❌ 問題6: 視覚テーマが適用されない

#### 症状:
```bash
$ ./scripts/visual-improvements.sh --apply-theme
[WARN] ⚠️ AI組織システムのセッションが見つかりません
```

#### 🔧 解決方法:
```bash
# 1. 先にAI組織システムを起動
./ai-agents/manage.sh quick-start

# 2. 視覚テーマを適用
./scripts/visual-improvements.sh --apply-theme

# 3. 状態確認
./scripts/visual-improvements.sh --status
```

#### 🔍 原因:
AI組織システムが起動する前にテーマを適用しようとした

---

## 🔗 Cursor連携関連の問題

### ❌ 問題7: CursorでAI支援が動作しない

#### 症状:
- Cursorを起動してもAI支援が表示されない
- コード補完が期待通りに動作しない

#### 🔧 解決方法:

##### ステップ1: Cursor Rules確認
```bash
# プロジェクトディレクトリで確認
ls -la .cursorrules

# もしファイルが無い場合
cp /path/to/team-ai/cursor-rules/.cursorrules .
```

##### ステップ2: Cursor再起動
```bash
# Cursorを完全に終了してから再起動
# Command+Q (macOS) または Ctrl+Q (Linux)
```

##### ステップ3: 設定確認
1. Cursor > Settings > Rules
2. Rules が有効になっているか確認

#### 🔍 原因:
Cursor Rulesファイルが正しく配置されていない

---

## 🌐 ネットワーク関連の問題

### ❌ 問題8: インターネット接続エラー

#### 症状:
```bash
[ERROR] Failed to connect to claude.ai
[ERROR] Network timeout
```

#### 🔧 解決方法:

##### ステップ1: ネットワーク確認
```bash
# インターネット接続テスト
ping google.com

# Claude AIへの接続テスト
curl -I https://claude.ai
```

##### ステップ2: プロキシ設定（企業環境の場合）
```bash
# 環境変数設定
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080

# Claude Code再実行
claude --dangerously-skip-permissions
```

##### ステップ3: ファイアウォール確認
- 企業ファイアウォールでclaude.aiがブロックされていないか確認
- 必要に応じてIT部門に相談

#### 🔍 原因:
ネットワーク制限またはプロキシ設定の問題

---

## 🔐 権限関連の問題

### ❌ 問題9: ファイル作成権限エラー

#### 症状:
```bash
[ERROR] Permission denied: cannot create file
[ERROR] mkdir: cannot create directory
```

#### 🔧 解決方法:

##### ステップ1: 権限確認
```bash
# 現在のディレクトリの権限確認
ls -la .

# 所有者の確認
whoami
```

##### ステップ2: 権限修正
```bash
# ディレクトリの所有者を変更
sudo chown -R $(whoami) /path/to/team-ai

# 実行権限を付与
find . -name "*.sh" -exec chmod +x {} \;
```

#### 🔍 原因:
適切なファイルシステム権限が設定されていない

---

## 🎯 パフォーマンス関連の問題

### ❌ 問題10: システムが重い・遅い

#### 症状:
- AI組織システムの応答が遅い
- CPUやメモリ使用率が高い

#### 🔧 解決方法:

##### ステップ1: リソース使用状況確認
```bash
# プロセス確認
ps aux | grep -E "(claude|tmux)"

# メモリ使用量確認
free -h  # Linux
vm_stat  # macOS
```

##### ステップ2: 不要なセッション終了
```bash
# 古いtmuxセッションを終了
tmux kill-server

# Claude Codeプロセス終了
pkill -f claude
```

##### ステップ3: 軽量設定に変更
```bash
# 基本設定モードに戻す
./setup.sh
# → 1) 基本設定を選択
```

#### 🔍 原因:
複数のAIプロセスが同時実行されリソースを消費

---

## 🛠️ 高度なトラブルシューティング

### 🔍 デバッグモード

#### ログ確認:
```bash
# システムログ確認
./ai-agents/log-check.sh

# 特定のエージェントログ
tail -f logs/ai-agents/worker1.log
```

#### デバッグ実行:
```bash
# verbose モードで実行
bash -x ./setup.sh

# AI組織システムのデバッグ
DEBUG=true ./ai-agents/manage.sh quick-start
```

### 🔄 完全リセット

#### すべてをリセットして再開:
```bash
# 1. すべてのプロセス終了
tmux kill-server
pkill -f claude

# 2. 設定ファイル削除
rm -rf ~/.cursor-rules
rm -rf ~/.claude

# 3. 再セットアップ
./setup.sh
```

---

## 📞 サポート

### 🆘 問題が解決しない場合

1. **ログ収集**:
   ```bash
   # ログをまとめて出力
   ./ai-agents/log-check.sh > debug-info.txt
   ```

2. **環境情報収集**:
   ```bash
   # システム情報
   uname -a > system-info.txt
   
   # インストール済みツール
   which tmux claude cursor >> system-info.txt
   ```

3. **Issue報告**:
   - [GitHub Issues](https://github.com/[your-repo]/team-ai/issues)
   - 上記のログファイルを添付

### 🔗 参考リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/claude-code)
- [Cursor公式サポート](https://cursor.sh/docs)
- [tmux公式ドキュメント](https://github.com/tmux/tmux/wiki)

---

## 💡 予防策

### 🛡️ 安定した運用のために

1. **定期的なアップデート**:
   ```bash
   # 月1回の更新チェック
   git pull origin main
   ```

2. **ログローテーション**:
   ```bash
   # 古いログの削除
   find logs/ -name "*.log" -mtime +7 -delete
   ```

3. **バックアップ**:
   ```bash
   # 重要な設定のバックアップ
   cp -r cursor-rules/ backup/
   ```

---

*🔧 問題解決できましたか？Happy Coding! 🚀*