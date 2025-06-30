# 🔧 MCP (Model Context Protocol) セットアップガイド

## 📋 概要

このプロジェクトではMCP (Model Context Protocol) を使用してClaude Codeの機能を拡張し、以下の統合を実現しています：

- **o3-search-mcp**: OpenAI API統合による高度検索機能
- **AI組織GitHub統合**: Issue管理とワークフロー自動化
- **tmux統合**: AI組織セッション管理
- **filesystem MCP**: プロジェクトファイル操作

## 🚀 セットアップ完了状況

### ✅ 完了済み設定

1. **o3-search-mcp パッケージインストール**
   ```bash
   npm install -g o3-search-mcp
   # インストール場所: /opt/homebrew/bin/o3-search-mcp
   ```

2. **OpenAI API Key設定**
   ```bash
   export OPENAI_API_KEY=sk-proj-z8...
   # 環境変数設定済み
   ```

3. **MCP設定ファイル (.mcp.json)**
   ```json
   {
     "mcpServers": {
       "o3-search": {
         "command": "/opt/homebrew/bin/o3-search-mcp",
         "args": [],
         "env": {
           "OPENAI_API_KEY": "${OPENAI_API_KEY}",
           "SEARCH_CONTEXT_SIZE": "medium",
           "REASONING_EFFORT": "high"
         }
       },
       "ai-organization-github": {
         "command": "python3",
         "args": ["/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/CLAUDE_MCP_BRIDGE.py"],
         "env": {
           "GITHUB_TOKEN": "${GITHUB_TOKEN}",
           "PROJECT_ROOT": "/Users/dd/Desktop/1_dev/coding-rule2"
         }
       },
       "tmux-integration": {
         "command": "node",
         "args": ["/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/mcp/tools/tmux_mcp.js"],
         "env": {
           "TMUX_SESSION": "multiagent"
         }
       },
       "filesystem": {
         "command": "python3",
         "args": ["/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/mcp/tools/filesystem_mcp.py"],
         "env": {
           "PROJECT_ROOT": "/Users/dd/Desktop/1_dev/coding-rule2"
         }
       }
     }
   }
   ```

## 🔧 利用方法

### 1. Claude Desktop再起動
MCP設定を反映するため、Claude Desktopアプリケーションを再起動してください。

### 2. o3-search機能の利用
Claude Code内で以下のような検索クエリが可能になります：
- 高度なコード検索
- プロジェクト内容の意味的検索
- OpenAI APIを活用した推論ベース検索

### 3. AI組織GitHub統合
```bash
# GitHub統合ブリッジ起動
python3 ./ai-agents/CLAUDE_MCP_BRIDGE.py &

# WebSocket API利用可能 (ws://localhost:8765)
```

### 4. ファイルシステム操作
```bash
# ファイルシステムMCPサーバー起動
python3 ./ai-agents/mcp/tools/filesystem_mcp.py &

# プロジェクト内ファイルの安全な操作が可能
```

## 🧪 動作確認

### 設定ファイル確認
```bash
# MCP設定確認
cat .mcp.json

# Claude設定ディレクトリ
ls -la ~/Library/Application\ Support/Claude/
```

### サーバー起動テスト
```bash
# o3-search-mcp動作確認
/opt/homebrew/bin/o3-search-mcp --version

# OpenAI API Key確認
echo $OPENAI_API_KEY | head -c 20
```

## 📊 統合システム状況

| コンポーネント | 状態 | 説明 |
|---------------|------|------|
| o3-search-mcp | ✅ 設定完了 | OpenAI API統合済み |
| GitHub統合 | 🔄 実装済み | Issue管理自動化 |
| tmux統合 | 🔄 実装済み | AI組織セッション管理 |
| filesystem MCP | ✅ 実装済み | 安全なファイル操作 |

## 🚨 トラブルシューティング

### MCP接続エラー
```bash
# Claude Desktop設定確認
ls -la ~/Library/Application\ Support/Claude/

# MCP設定再読み込み (Claude Desktop再起動)
```

### o3-search-mcp問題
```bash
# パッケージ再インストール
npm uninstall -g o3-search-mcp
npm install -g o3-search-mcp

# 実行パス確認
which o3-search-mcp
```

### API Key問題
```bash
# 環境変数確認
echo $OPENAI_API_KEY

# 永続化設定 (~/.zshrc or ~/.bashrc)
echo 'export OPENAI_API_KEY=sk-proj-z8...' >> ~/.zshrc
```

## 📈 パフォーマンス設定

### o3-search最適化
```json
{
  "env": {
    "SEARCH_CONTEXT_SIZE": "large",    // small/medium/large
    "REASONING_EFFORT": "high",        // low/medium/high
    "MAX_SEARCH_RESULTS": "10"         // 検索結果数制限
  }
}
```

### 同時接続数制限
```json
{
  "mcpServers": {
    "max_concurrent_connections": 4,
    "timeout_seconds": 30
  }
}
```

## 🔄 運用・メンテナンス

### 日次確認
```bash
# MCP統合状況確認
python3 -c "
import json
with open('.mcp.json') as f:
    config = json.load(f)
print(f'MCP サーバー数: {len(config[\"mcpServers\"])}')
"
```

### 週次メンテナンス
```bash
# パッケージ更新
npm update -g o3-search-mcp

# 設定バックアップ
cp .mcp.json .mcp.json.backup
```

---

**⚙️ システム開発担当**  
**📅 更新日**: 2025-06-29  
**🔖 バージョン**: 1.0.0  
**✅ ステータス**: 設定完了・運用可能