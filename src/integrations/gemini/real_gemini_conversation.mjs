import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

async function realConversation() {
  console.log('🎯 実際のGemini対話開始');
  
  try {
    const transport = new StdioClientTransport({
      command: 'npx',
      args: ['@choplin/mcp-gemini-cli']
    });
    
    const client = new Client({
      name: 'claude-gemini-live-chat',
      version: '1.0.0'
    }, {
      capabilities: {}
    });
    
    await client.connect(transport);
    console.log('✅ Gemini接続完了\n');
    
    // 実際の会話 - Claude側の質問
    console.log('🤖 Claude: Geminiさん、こんにちは！私はClaude、AI組織システムのPRESIDENTです。');
    console.log('今、AI自動操縦システムの開発を進めているのですが、あなたの意見を聞かせてください。');
    console.log('\n現在の課題：');
    console.log('- Kindle本を24冊/日生産したい');
    console.log('- 収益目標¥12,000/日を達成したい');
    console.log('- 完全自動化システムを構築したい');
    console.log('\nこの課題について、どんなアプローチが最も効果的だと思いますか？\n');
    
    const response1 = await client.callTool({
      name: 'geminiChat',
      arguments: {
        prompt: `Claude AI組織システムPRESIDENTです。

現在の課題：
- Kindle本を24冊/日生産したい
- 収益目標¥12,000/日を達成したい  
- 完全自動化システムを構築したい

この課題について、あなたの率直な意見と具体的なアドバイスをください。
特に気になる点や改善提案があれば教えてください。`,
        yolo: true,
        model: 'gemini-2.5-pro'
      }
    });
    
    console.log('🔮 Gemini: ' + response1.content[0].text);
    console.log('\n' + '='.repeat(80) + '\n');
    
    // Claude側の返答と次の質問
    console.log('🤖 Claude: なるほど、とても参考になります！');
    console.log('特に「段階的なスケールアップ」という考え方は重要ですね。');
    console.log('\n実は私たちは既に以下のシステムを構築済みです：');
    console.log('- claude_autopilot.js (品質管理)');
    console.log('- gemini_yolo.py (コンテンツ生成)');
    console.log('- 三位一体開発原則');
    console.log('\nこれらを統合して、どのような順序で改良していくべきでしょうか？');
    console.log('また、今すぐ実行できる「クイックウィン」はありますか？\n');
    
    const response2 = await client.callTool({
      name: 'geminiChat',
      arguments: {
        prompt: `既存システムについて：
- claude_autopilot.js (品質管理システム)
- gemini_yolo.py (コンテンツ生成システム)  
- 三位一体開発原則

これらを統合して改良していく順序と、今すぐ実行できる「クイックウィン」を提案してください。
実用的で実行しやすいアドバイスをお願いします。`,
        yolo: true,
        model: 'gemini-2.5-pro'
      }
    });
    
    console.log('🔮 Gemini: ' + response2.content[0].text);
    console.log('\n' + '='.repeat(80) + '\n');
    
    // 最終的な確認
    console.log('🤖 Claude: 素晴らしいアドバイスをありがとうございます！');
    console.log('最後に一つだけ質問があります。');
    console.log('\nこのような対話システム自体についてどう思いますか？');
    console.log('ClaudeとGeminiが直接対話できるこの仕組みは、AI開発にとって価値があると思いますか？\n');
    
    const response3 = await client.callTool({
      name: 'geminiChat',
      arguments: {
        prompt: `ClaudeとGeminiが直接対話できるこのMCPシステムについて、AI開発における価値や可能性をどう評価しますか？
また、このような異なるAI同士の協力について、あなたの率直な感想を聞かせてください。`,
        yolo: true,
        model: 'gemini-2.5-pro'
      }
    });
    
    console.log('🔮 Gemini: ' + response3.content[0].text);
    console.log('\n' + '='.repeat(80) + '\n');
    
    console.log('🤖 Claude: この対話を通じて、とても貴重な洞察を得ることができました。');
    console.log('ありがとう、Gemini！一緒に素晴らしいAIシステムを作っていきましょう。');
    
    // 対話ログを保存
    const conversation_log = {
      session_id: `live_chat_${Date.now()}`,
      timestamp: new Date().toISOString(),
      participants: ['Claude (AI組織システムPRESIDENT)', 'Gemini (via MCP)'],
      conversation: [
        {
          speaker: 'Claude',
          message: '課題提示と意見要請',
          response: response1.content[0].text
        },
        {
          speaker: 'Claude', 
          message: '既存システムの統合と改良順序について',
          response: response2.content[0].text
        },
        {
          speaker: 'Claude',
          message: 'AI対話システムの価値について',
          response: response3.content[0].text
        }
      ],
      status: 'completed'
    };
    
    await import('fs').then(fs => {
      fs.writeFileSync('live_conversation_log.json', JSON.stringify(conversation_log, null, 2));
    });
    
    console.log('\n📁 対話ログを live_conversation_log.json に保存しました');
    
    await client.close();
    
  } catch (error) {
    console.error('❌ 対話エラー:', error.message);
  }
}

realConversation();