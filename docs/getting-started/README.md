# 🚀 TeamAI クイックスタートガイド

TeamAIへようこそ！このガイドでは、初めての方でも5分でTeamAI AI組織システムを起動し、実際にタスクを実行できるよう、段階的にご案内します。

## 📋 必要な準備（2分）

### 1. 動作環境の確認
```bash
# macOS / Linux の確認
uname -a

# 必要なツールの確認
which tmux    # tmux がインストールされているか
which git     # Git がインストールされているか
which curl    # curl がインストールされているか
```

### 2. Claude Code の準備
```bash
# Claude Code がインストールされているか確認
claude --version

# もしインストールされていない場合は
curl -sSL https://install.claude.ai | bash
```

### 3. プロジェクトの取得
```bash
# プロジェクトをクローン
git clone [YOUR_REPO_URL] teamai
cd teamai

# 権限設定
chmod +x scripts/*.sh
```

## ⚡️ 3ステップ起動（2分）

### ステップ 1: 環境の初期化
```bash
# セットアップスクリプトを実行
./scripts/setup.sh

# 成功すると以下のメッセージが表示されます
✅ TeamAI セットアップ完了！
🧠 PRESIDENT: 待機中
👔 BOSS1: 準備完了  
👔 BOSS2: 準備完了
🔧 WORKER1-3: スタンバイ
```

### ステップ 2: AI組織システムの起動
```bash
# AI組織を起動
./scripts/start-ai-organization.sh

# または、個別起動の場合
tmux new-session -d -s "ai-org"
# President を起動
# BOSS1, BOSS2 を起動  
# WORKER1, WORKER2, WORKER3 を起動
```

### ステップ 3: 動作確認
```bash
# システム状態の確認
./scripts/check-status.sh

# 期待される出力例
🧠 PRESIDENT  : ✅ ACTIVE (CPU: 12%, MEM: 45MB)
👔 BOSS1      : ✅ ACTIVE (CPU: 8%, MEM: 32MB)
👔 BOSS2      : ✅ ACTIVE (CPU: 7%, MEM: 28MB)  
🔧 WORKER1    : ✅ ACTIVE (CPU: 5%, MEM: 21MB)
🔧 WORKER2    : ✅ ACTIVE (CPU: 4%, MEM: 19MB)
🔧 WORKER3    : ✅ ACTIVE (CPU: 6%, MEM: 24MB)

🎉 TeamAI AI組織システム正常稼働中！
```

## 🎯 初回タスクの実行（1分）

### 簡単なタスクを試してみましょう
```bash
# PRESIDENT にタスクを依頼
echo "簡単なWelcomeページを作成してください" | ./scripts/send-task.sh

# または、対話形式で
./scripts/interactive-mode.sh
> こんにちは、TeamAIです。何かお手伝いできることはありますか？
> ユーザー: 簡単なHTMLページを作成してほしいです
> PRESIDENT: 承知いたしました。BOSS1にフロントエンド作業を指示し、作成いたします。
```

### 進捗の確認方法
```bash
# リアルタイムログの確認
tail -f logs/ai-agents/president/latest.log

# または、ダッシュボード表示（将来機能）
# ./scripts/dashboard.sh
```

## 🎨 視覚的な理解

### AI組織構造
```
        🧠 PRESIDENT (統合管理者)
        /                    \
   👔 BOSS1                👔 BOSS2
   (フロントエンド統括)      (バックエンド統括)  
   /      \                 /      \
🔧 WORKER1  🔧 WORKER3    🔧 WORKER2  🔧 WORKER3
(UI/UX)    (テスト)       (API)      (ドキュメント)
```

### タスクフロー例
```
ユーザー要求 → PRESIDENT → 分析・計画
                ↓
           タスク分散 (BOSS1 & BOSS2)
                ↓
        並列作業 (WORKER1, WORKER2, WORKER3)
                ↓
           統合・品質チェック (BOSS)
                ↓
            最終確認 (PRESIDENT)
                ↓
              完了・納品
```

## ⚠️ よくある問題と解決法

### 問題1: tmux セッションが作成されない
```bash
# 原因確認
tmux list-sessions

# 解決方法
sudo apt-get install tmux  # Ubuntu
brew install tmux          # macOS
```

### 問題2: Claude API エラー
```bash
# API キーの確認
echo $ANTHROPIC_API_KEY

# 設定方法
export ANTHROPIC_API_KEY="your-api-key-here"
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
```

### 問題3: 権限エラー
```bash
# スクリプトに実行権限を付与
chmod +x scripts/*.sh

# ディレクトリの権限確認
ls -la scripts/
```

## 🎯 次のステップ

### 1. 基本的な使い方を学ぶ
- [ユーザーガイド](../user-guides/user-guide.md) - 詳細な使用方法
- [FAQ](../user-guides/faq.md) - よくある質問35項目
- [ベストプラクティス](../user-guides/best-practices.md) - 効率的な活用法

### 2. 高度な機能を探索
- [技術仕様](../technical/architecture.md) - システム構成の詳細
- [カスタマイズガイド](../technical/customization.md) - 独自の拡張方法
- [API リファレンス](../technical/api-reference.md) - プログラマー向け

### 3. トラブルが発生した場合
- [トラブルシューティング](../user-guides/troubleshooting.md) - 詳細な問題解決ガイド
- [セキュリティガイド](../security/security-guide.md) - 安全な運用方法

## 💡 ヒント

### 💪 効率的な使い方
- **段階的な依頼**: 複雑なタスクは小さく分けて依頼
- **具体的な指示**: 曖昧な要求より具体的な指示が効果的
- **品質重視**: 速度より品質を重視した設計

### 🔧 カスタマイズのススメ
- **設定ファイル**: `config/` ディレクトリで動作をカスタマイズ
- **エージェント追加**: 新しいWORKERの追加も可能
- **ワークフロー**: 独自のタスクフローを定義

### 🌟 コミュニティ参加
- **GitHub Issues**: バグ報告や機能要望
- **Discussions**: 質問や活用事例の共有
- **貢献**: コードやドキュメントの改善提案

---

**🎉 おめでとうございます！**  
これでTeamAI AI組織システムの基本的な使用が可能になりました。さらに詳しい情報は、各専門ガイドをご覧ください。

何か困ったことがあれば、[FAQ](../user-guides/faq.md) や [トラブルシューティング](../user-guides/troubleshooting.md) をご確認いただくか、コミュニティにお気軽にご質問ください！