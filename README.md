# 🚀 AI組織システム - 複数AIチーム開発プラットフォーム

## 📋 概要

**5つのAIが協調して開発**する革新的なマルチエージェントシステムです。

```bash
./ai-team.sh      # 🎯 メインスクリプト（全機能統合）
```

## ✅ 必要環境

- **macOS/Linux** (WindowsはWSL推奨)
- **Git** + **tmux** + **Claude Code**

```bash
# macOS
brew install tmux

# Ubuntu/Debian  
sudo apt install tmux
```

## 🎮 使い方（3ステップ）

### 1. ダウンロード
```bash
git clone https://github.com/daideguchi/coding-rule2.git
cd coding-rule2
```

### 2. 起動
```bash
./ai-team.sh
```

### 3. メニューから選択
1. 🚀 AI組織起動
2. ⚙️ 初回セットアップ  
3. ⚡ クイック起動
4. 🔧 設定変更
5. 🆘 トラブルシューティング

## 🤖 AI組織構造

```
👑 PRESIDENT (統括) - [president]
  └── 👔 BOSS1 (リーダー) - [0.0]
      ├── 💻 WORKER1 - [0.1] 
      ├── 🔧 WORKER2 - [0.2]
      └── 🎨 WORKER3 - [0.3]
```

## 🎯 特徴

- **本物のAI**: Claude Code AIが実際に動作
- **4画面同時**: tmuxマルチペイン監視
- **階層ガバナンス**: 指揮系統による統制
- **並列処理**: 複数AI同時作業
- **リアルタイム**: 作業状況即座表示

## 🚀 AI組織システム起動

```bash
# システム起動
./ai-agents/manage.sh claude-auth

# 画面操作
tmux attach-session -t president    # PRESIDENT画面
tmux attach-session -t multiagent   # チーム画面(4分割)
```

## 🛠️ トラブルシューティング

**Q: 認証エラー**
```bash
./ai-team.sh → 4) 設定変更
```

**Q: AIが動かない**
```bash
./ai-agents/manage.sh clean
./ai-agents/manage.sh claude-auth
```

**Q: 画面が見にくい**
```bash
./ai-agents/manage.sh restore-ui
```

## 📁 主要ファイル

```
coding-rule2/
├── ai-team.sh              # 🎯 メインスクリプト
├── ai-agents/              # 🤖 AI組織システム
│   ├── manage.sh          # システム管理
│   └── instructions/      # AI役割定義
├── .cursor/rules/         # 🧠 AI開発ルール
└── docs/                  # 📚 ドキュメント
```

## 🎁 実現できること

### 個人開発者
- AI支援開発で効率3-5倍向上
- 単調作業のAI自動化

### チーム開発
- 統一AI開発環境
- 自動コードレビュー  

### 上級者・企業
- 大規模プロジェクト並列開発
- 24時間AI継続開発体制

## 🌟 対象ユーザー

- **AI支援を試したい** → 基本機能
- **本格AI開発したい** → 開発環境連携
- **AIチームに任せたい** → AI組織システム

---

## 📞 サポート

### 基本コマンド
```bash
./ai-team.sh                        # メイン
./ai-agents/manage.sh claude-auth   # AI組織起動
./ai-agents/manage.sh clean         # リセット
```

### 緊急時
```bash
./ai-agents/manage.sh clean         # 全リセット
./ai-team.sh                        # 再セットアップ
```

---

**🎉 完成！ プロ級AI開発環境をお楽しみください**

```bash
./ai-team.sh  # 今すぐ開始
```

_AI組織統治開発プラットフォーム - 2025_