# 🚀 Claude-Gemini 統合対話システム

AI自動操縦システム統合プロダクトにおけるClaude-Gemini間の効率的な対話を実現するシステムです。

## 🎯 システム概要

### 三位一体開発原則
- **ユーザー**: 戦略立案・意思決定
- **Claude**: 品質管理・レビュー・システム実行
- **Gemini**: コンテンツ創造・執筆・アイデア生成

## 📋 利用可能なツール

### 1. 標準対話システム
```bash
# 簡単な対話
python claude_gemini_standard_dialogue.py "メッセージ"

# インタラクティブセッション
python claude_gemini_standard_dialogue.py interactive

# システムテスト
python claude_gemini_standard_dialogue.py test
```

### 2. 従来のブリッジシステム
```bash
# MCP経由
python claude_gemini_mcp_bridge.py "メッセージ"

# 直接CLI
echo "メッセージ" | npx @google/gemini-cli
```

## 📂 ディレクトリ構造

```
integrations/gemini/
├── README.md                           # このファイル
├── claude_gemini_standard_dialogue.py  # 標準対話システム
├── claude_gemini_mcp_bridge.py        # MCP統合ブリッジ
├── dialogue_logs/                      # 対話ログ保存場所
├── standard_scripts/                   # 標準化スクリプト
├── workflow_templates/                 # ワークフローテンプレート
├── ai_collaboration/                   # AI協働ファイル
└── legacy/                            # 従来システム
    ├── claude_gemini_bridge.py
    ├── claude_gemini_direct_bridge.py
    ├── claude_gemini_focus_bridge.py
    └── claude_gemini_tmux_bridge.py
```

## 🔄 ワークフロー例

### Kindle本生産5フェーズワークフロー
1. **戦略・企画** (ユーザー主導)
2. **構成案作成** (Gemini → Claude レビュー)
3. **本文執筆** (Gemini)
4. **レビュー・編集** (Claude)
5. **最終化・出版** (ユーザー)

## 🎮 実行例

### 基本対話
```bash
python claude_gemini_standard_dialogue.py "AIツールの副業について教えて"
```

### セッション例
```
👤 You → Gemini: Kindle本の構成案を作って
🤖 Gemini: [詳細な構成案を生成]
👤 You → Gemini: 第1章をもっと詳しく
🤖 Gemini: [第1章の詳細を展開]
```

## 📊 成功指標
- **対話成功率**: 95%以上
- **応答時間**: 平均5秒以内
- **Kindle本生産**: 24冊/日目標
- **収益目標**: ¥12,000/日

## 🚨 注意事項
- Gemini API制限: 60リクエスト/分、1000リクエスト/日
- 全ての対話ログは自動保存されます
- 機密情報の送信は避けてください

## 🔧 依存関係
```bash
# 必須
npm install -g @google/gemini-cli
npm install @modelcontextprotocol/sdk

# オプション
npm install @choplin/mcp-gemini-cli
```

## 📈 拡張予定
- [ ] タスクキューシステム統合
- [ ] 自動バッチ処理
- [ ] リアルタイム監視ダッシュボード
- [ ] KDP自動出版連携