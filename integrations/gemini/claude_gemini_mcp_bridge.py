#!/usr/bin/env python3
"""
Claude-Gemini MCP Bridge - 実動作版
既存のMCP Gemini CLIを活用したブリッジシステム
"""

import os
import json
import time
import subprocess
import asyncio
from pathlib import Path
from datetime import datetime

class ClaudeGeminiMCPBridge:
    def __init__(self):
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.conversation_log = []
        
        print(f"🌉 Claude-Gemini MCP Bridge initialized")
    
    async def send_to_gemini_mcp(self, message: str) -> dict:
        """MCP Gemini CLIを使用してメッセージ送信"""
        try:
            print(f"📤 Sending via MCP to Gemini: {message[:100]}...")
            
            # MCPコマンド構築
            mcp_input = {
                "role": "user",
                "content": message
            }
            
            # NPX経由でMCP Gemini CLIを実行
            cmd = ['npx', '@choplin/mcp-gemini-cli']
            
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # 入力送信
            input_data = json.dumps(mcp_input)
            stdout, stderr = process.communicate(input=input_data, timeout=30)
            
            if process.returncode == 0 and stdout.strip():
                # 応答解析
                try:
                    response_data = json.loads(stdout.strip())
                    gemini_response = response_data.get('content', stdout.strip())
                except:
                    gemini_response = stdout.strip()
                
                result = {
                    "status": "success",
                    "human_message": message,
                    "gemini_response": gemini_response,
                    "timestamp": datetime.now().isoformat(),
                    "method": "mcp_cli"
                }
                
                print(f"✅ MCP Response received ({len(gemini_response)} chars)")
                print(f"🔮 Gemini: {gemini_response[:200]}...")
                
                self.conversation_log.append(result)
                return result
                
            else:
                raise Exception(f"MCP CLI error: {stderr or 'No output'}")
                
        except subprocess.TimeoutExpired:
            return {
                "status": "timeout",
                "error": "MCP CLI timeout after 30 seconds",
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            error_result = {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            self.conversation_log.append(error_result)
            return error_result
    
    def send_to_gemini_sync(self, message: str) -> dict:
        """同期版メッセージ送信"""
        return asyncio.run(self.send_to_gemini_mcp(message))
    
    def quick_chat(self, message: str) -> str:
        """簡単チャット - レスポンステキストのみ返却"""
        result = self.send_to_gemini_sync(message)
        
        if result.get('status') == 'success':
            return result.get('gemini_response', 'No response')
        else:
            return f"Error: {result.get('error', 'Unknown error')}"
    
    def test_mcp_availability(self) -> bool:
        """MCP Gemini CLIの利用可能性テスト"""
        try:
            process = subprocess.run(
                ['npx', '@choplin/mcp-gemini-cli', '--help'],
                capture_output=True,
                text=True,
                timeout=10
            )
            return process.returncode == 0
        except:
            return False
    
    def save_conversation_log(self):
        """会話ログ保存"""
        if not self.conversation_log:
            return
            
        log_file = self.bridge_dir / f"mcp_conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.conversation_log, f, indent=2, ensure_ascii=False)
            print(f"💾 Conversation log saved: {log_file}")
        except Exception as e:
            print(f"❌ Failed to save log: {e}")

def main():
    """メイン実行"""
    import sys
    
    bridge = ClaudeGeminiMCPBridge()
    
    # MCP CLI利用可能性チェック
    print("🔍 Checking MCP Gemini CLI availability...")
    if not bridge.test_mcp_availability():
        print("❌ MCP Gemini CLI not available. Install with: npm install -g @choplin/mcp-gemini-cli")
        return
    
    print("✅ MCP Gemini CLI is available")
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python claude_gemini_mcp_bridge.py 'Your message'")
        print("  python claude_gemini_mcp_bridge.py test")
        return
    
    if sys.argv[1] == "test":
        # テストモード
        print("🧪 Testing Claude-Gemini MCP bridge...")
        
        message = "こんにちは！Claudeからのテストです。AI統合システムについて簡潔にアドバイスをお願いします。"
        response = bridge.quick_chat(message)
        print(f"\n📝 Final response:\n{response}")
        
        bridge.save_conversation_log()
        
    else:
        # 通常メッセージ送信
        message = " ".join(sys.argv[1:])
        response = bridge.quick_chat(message)
        print(response)
        
        bridge.save_conversation_log()

if __name__ == "__main__":
    main()