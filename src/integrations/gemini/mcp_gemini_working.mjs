import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

async function geminiDialogue() {
  console.log('🚀 MCP Gemini CLI 実稼働システム');
  
  try {
    // トランスポート作成
    const transport = new StdioClientTransport({
      command: 'npx',
      args: ['@choplin/mcp-gemini-cli']
    });
    
    // クライアント作成
    const client = new Client({
      name: 'ai-autopilot-system',
      version: '1.0.0'
    }, {
      capabilities: {}
    });
    
    // 接続
    await client.connect(transport);
    console.log('✅ MCP Gemini接続成功');
    
    // 三位一体開発原則による対話
    const prompt = `
AI自動操縦システムの統合について、以下の観点から具体的な提案をしてください：

現在のシステム構成:
1. Claude自動操縦システム (claude_autopilot.js) - 品質管理・レビュー担当
2. Gemini YOLOシステム (gemini_yolo.py) - コンテンツ創造・執筆担当
3. 三位一体開発原則 - ユーザー意思決定+Claude実行+Gemini助言

課題:
- Kindle本の大量生産（目標24冊/日）
- 収益目標¥12,000/日の達成
- 完全自動化による24時間稼働

提案してほしいこと:
1. システム統合の最適化方法
2. 自動対話の効率化
3. 生産性向上のための具体的な改善点
4. 実装すべき機能の優先順位

具体的で実行可能な提案をお願いします。
`;
    
    console.log('🤖 Geminiに三位一体開発原則の相談中...');
    
    const result = await client.callTool({
      name: 'geminiChat',
      arguments: {
        prompt: prompt,
        yolo: true,
        model: 'gemini-2.5-pro'
      }
    });
    
    console.log('\n✅ Gemini応答受信:');
    console.log('='.repeat(80));
    console.log(result.content[0].text);
    console.log('='.repeat(80));
    
    // 応答を保存
    const response_data = {
      timestamp: new Date().toISOString(),
      session_id: `trinity_mcp_${Date.now()}`,
      prompt: prompt,
      response: result.content[0].text,
      status: 'success'
    };
    
    await import('fs').then(fs => {
      fs.writeFileSync('gemini_mcp_response.json', JSON.stringify(response_data, null, 2));
    });
    
    console.log('\n📁 応答を gemini_mcp_response.json に保存');
    
    // Phase 2: 実装計画の詳細化
    const followUp = `
前回の提案を踏まえて、今すぐ実行できる具体的なアクションプランを作成してください：

1. 即座に実行できるタスク（1時間以内）
2. 短期実装項目（24時間以内）
3. 必要なコードやコマンドの具体例

特に重視したいのは：
- 実際のKindle本生産の自動化
- Claude-Gemini間の効率的な対話システム
- 収益最大化のための戦略

実装可能な具体的な手順を教えてください。
`;
    
    console.log('\n🔄 フォローアップ質問を実行中...');
    
    const followUpResult = await client.callTool({
      name: 'geminiChat',
      arguments: {
        prompt: followUp,
        yolo: true,
        model: 'gemini-2.5-pro'
      }
    });
    
    console.log('\n✅ フォローアップ応答:');
    console.log('='.repeat(80));
    console.log(followUpResult.content[0].text);
    console.log('='.repeat(80));
    
    // 統合結果保存
    const complete_dialogue = {
      session_id: response_data.session_id,
      dialogue_type: 'trinity_development_principle',
      phase1: {
        prompt: prompt,
        response: result.content[0].text
      },
      phase2: {
        prompt: followUp,
        response: followUpResult.content[0].text
      },
      timestamp: new Date().toISOString(),
      status: 'completed'
    };
    
    await import('fs').then(fs => {
      fs.writeFileSync('trinity_mcp_dialogue.json', JSON.stringify(complete_dialogue, null, 2));
    });
    
    console.log('\n🎯 三位一体開発原則による対話完了');
    console.log('📊 統合結果を trinity_mcp_dialogue.json に保存');
    
    // 切断
    await client.close();
    
  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
}

geminiDialogue();