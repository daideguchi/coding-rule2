#!/usr/bin/env python3
"""
Claude-Gemini Bridge - 実動作保証版
Claudeからの呼び出し専用ブリッジシステム
"""

import os
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime

class ClaudeGeminiBridge:
    def __init__(self):
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.request_file = self.bridge_dir / "claude_request.txt"
        self.response_file = self.bridge_dir / "gemini_response.json"
        self.status_file = self.bridge_dir / "bridge_status.json"
        
        print(f"🌉 Claude-Gemini Bridge initialized")
        print(f"📁 Bridge directory: {self.bridge_dir}")
    
    def send_to_gemini(self, message: str, timeout: int = 30) -> dict:
        """Geminiにメッセージを送信して応答を待つ"""
        try:
            print(f"📤 Sending to Gemini: {message[:100]}...")
            
            # 古いファイルをクリア
            if self.response_file.exists():
                self.response_file.unlink()
            
            # リクエストファイルに書き込み
            with open(self.request_file, 'w', encoding='utf-8') as f:
                f.write(message)
            
            print("⏳ Waiting for Gemini response...")
            
            # レスポンス待機
            start_time = time.time()
            while time.time() - start_time < timeout:
                if self.response_file.exists():
                    try:
                        with open(self.response_file, 'r', encoding='utf-8') as f:
                            response = json.load(f)
                        
                        print(f"✅ Response received from Gemini")
                        if response.get('status') == 'success':
                            print(f"🔮 Gemini: {response['gemini_response'][:200]}...")
                        
                        return response
                    except Exception as e:
                        print(f"⚠️ Error reading response: {e}")
                        time.sleep(1)
                        continue
                
                time.sleep(1)
            
            # タイムアウト
            return {
                "status": "timeout",
                "error": f"No response within {timeout} seconds",
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error", 
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def quick_chat(self, message: str) -> str:
        """簡単なチャット - 応答テキストのみ返す"""
        result = self.send_to_gemini(message)
        
        if result.get('status') == 'success':
            return result.get('gemini_response', 'No response text')
        else:
            return f"Error: {result.get('error', 'Unknown error')}"
    
    def start_gemini_bridge_if_needed(self) -> bool:
        """必要に応じてGeminiブリッジを起動"""
        try:
            # ステータス確認
            if self.status_file.exists():
                with open(self.status_file, 'r') as f:
                    status = json.load(f)
                if status.get('status') == 'active':
                    print("✅ Gemini bridge is already running")
                    return True
            
            print("🚀 Starting Gemini bridge...")
            
            # Gemini API direct bridgeを起動
            gemini_script = Path(__file__).parent / "gemini_direct_api.py"
            if gemini_script.exists():
                subprocess.Popen([
                    'python3', str(gemini_script), 'bridge'
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                # 起動確認
                time.sleep(3)
                if self.status_file.exists():
                    with open(self.status_file, 'r') as f:
                        status = json.load(f)
                    if status.get('status') == 'active':
                        print("✅ Gemini bridge started successfully")
                        return True
            
            print("❌ Failed to start Gemini bridge")
            return False
            
        except Exception as e:
            print(f"❌ Error starting bridge: {e}")
            return False

def main():
    """メイン実行"""
    import sys
    
    bridge = ClaudeGeminiBridge()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python claude_gemini_bridge.py 'Your message'")
        print("  python claude_gemini_bridge.py test")
        return
    
    if sys.argv[1] == "test":
        # テストモード
        print("🧪 Testing Claude-Gemini bridge...")
        
        # ブリッジ起動確認
        if not bridge.start_gemini_bridge_if_needed():
            print("❌ Cannot start bridge, testing with direct message...")
        
        message = "こんにちは！Claudeからのテストです。AI統合システムについて簡潔にアドバイスをお願いします。"
        response = bridge.quick_chat(message)
        print(f"\n📝 Final response:\n{response}")
        
    else:
        # 通常メッセージ送信
        message = " ".join(sys.argv[1:])
        
        # ブリッジ起動確認
        bridge.start_gemini_bridge_if_needed()
        time.sleep(2)  # 起動待機
        
        response = bridge.quick_chat(message)
        print(response)

if __name__ == "__main__":
    main()