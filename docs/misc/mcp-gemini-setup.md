# 🚀 緊急指令実行: MCP経由でGemini CLI対話確立

## 現状分析

要件定義書に基づくAI自動操縦システム統合プロダクトにおいて、Claude（自動操縦エンジン）とGemini（YOLO自動操縦）の連携が必要。現在はGemini CLIとの直接対話ができていない状況。

## 緊急実装計画

### Phase 1: MCP Server Setup（即時実行）

1. **claude_desktop_config.json設定**
```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "github:RLabs-Inc/gemini-mcp"],
      "env": {
        "GEMINI_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

2. **環境確認**
- Node.js 16以上
- Gemini API キー
- Claude Desktop最新版

### Phase 2: 統合テスト

1. **基本対話確立**
   - Claude → MCP → Gemini CLI
   - 応答確認とレイテンシ測定

2. **AI組織システム統合**
   - shared-state.jsonとの連携
   - 既存ワークフローとの整合性

### Phase 3: 自動操縦システム統合

1. **claude_autopilot.js修正**
   - MCP経由でのGemini呼び出し実装
   - エラーハンドリング強化

2. **gemini_yolo.py実装**
   - MCP対応版の作成
   - --yolo自動承認モードの実装

## 緊急実行フロー

1. 【即時】Claude Desktop設定変更
2. 【即時】接続テスト実行
3. 【5分以内】基本対話確立
4. 【10分以内】AI組織システム統合完了
5. 【15分以内】自動操縦システム稼働開始

## 成功指標

- [x] MCP Server稼働確認
- [ ] Gemini CLI対話確立
- [ ] shared-state.json統合
- [ ] 自動操縦システム連携
- [ ] 24冊/日生産体制復旧

## 次のアクション

PRESIDENT として、この緊急指令を AI 組織システム（BOSS1-WORKER3）に即座に配布し、並行作業で最速実装を実現する。