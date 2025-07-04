#!/usr/bin/env python3
"""
Direct Gemini API Integration - 実動作保証版
Claude-Gemini対話システム
"""

import os
import json
import time
import requests
from datetime import datetime
from pathlib import Path

class GeminiDirectAPI:
    def __init__(self, api_key=None):
        self.api_key = api_key or os.getenv('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not found. Set environment variable or pass api_key.")
        
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"
        self.model = "gemini-1.5-pro"
        self.conversation_log = []
        
        # 通信ファイルパス
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.request_file = self.bridge_dir / "claude_request.txt"
        self.response_file = self.bridge_dir / "gemini_response.json"
        self.status_file = self.bridge_dir / "bridge_status.json"
        
        print(f"✅ Gemini Direct API initialized")
        print(f"📁 Bridge directory: {self.bridge_dir}")
    
    def send_message(self, message: str, conversation_id: str = None) -> dict:
        """Geminiにメッセージを送信"""
        try:
            # API URL構築
            url = f"{self.base_url}/{self.model}:generateContent?key={self.api_key}"
            
            # リクエストペイロード
            payload = {
                "contents": [{
                    "parts": [{
                        "text": message
                    }]
                }],
                "generationConfig": {
                    "temperature": 0.7,
                    "topK": 40,
                    "topP": 0.95,
                    "maxOutputTokens": 2048,
                }
            }
            
            print(f"🤖 Sending to Gemini: {message[:100]}...")
            
            # API呼び出し
            response = requests.post(
                url, 
                headers={"Content-Type": "application/json"},
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                
                # レスポンス抽出
                if 'candidates' in result and len(result['candidates']) > 0:
                    gemini_response = result['candidates'][0]['content']['parts'][0]['text']
                    
                    # 会話ログに追加
                    conversation_entry = {
                        "timestamp": datetime.now().isoformat(),
                        "conversation_id": conversation_id or f"conv_{int(time.time())}",
                        "human_message": message,
                        "gemini_response": gemini_response,
                        "status": "success"
                    }
                    
                    self.conversation_log.append(conversation_entry)
                    
                    print(f"✅ Gemini response received ({len(gemini_response)} chars)")
                    print(f"🔮 Gemini: {gemini_response[:200]}...")
                    
                    return conversation_entry
                else:
                    raise Exception("No candidates in response")
                    
            else:
                raise Exception(f"API Error: {response.status_code} - {response.text}")
                
        except Exception as e:
            error_entry = {
                "timestamp": datetime.now().isoformat(),
                "conversation_id": conversation_id or f"error_{int(time.time())}",
                "human_message": message,
                "error": str(e),
                "status": "error"
            }
            
            self.conversation_log.append(error_entry)
            print(f"❌ Error: {e}")
            return error_entry
    
    def start_bridge_mode(self):
        """ブリッジモード開始 - ファイル監視"""
        print("🌉 Starting bridge mode - monitoring for requests...")
        
        self.update_status("active", "Bridge mode started")
        
        try:
            while True:
                # リクエストファイル確認
                if self.request_file.exists():
                    print("📨 New request detected!")
                    
                    # リクエスト読み込み
                    try:
                        with open(self.request_file, 'r', encoding='utf-8') as f:
                            request_content = f.read().strip()
                        
                        if request_content:
                            print(f"📝 Processing request: {request_content[:100]}...")
                            
                            # Geminiに送信
                            result = self.send_message(request_content)
                            
                            # レスポンスファイルに保存
                            with open(self.response_file, 'w', encoding='utf-8') as f:
                                json.dump(result, f, indent=2, ensure_ascii=False)
                            
                            # リクエストファイル削除
                            self.request_file.unlink()
                            
                            self.update_status("ready", f"Processed request at {datetime.now().strftime('%H:%M:%S')}")
                            print("✅ Request processed and response saved")
                        
                    except Exception as e:
                        print(f"❌ Error processing request: {e}")
                        self.update_status("error", str(e))
                
                time.sleep(2)  # 2秒間隔でチェック
                
        except KeyboardInterrupt:
            print("\n🛑 Bridge mode stopped")
            self.update_status("stopped", "Bridge mode manually stopped")
    
    def update_status(self, status: str, message: str = ""):
        """ステータス更新"""
        status_data = {
            "status": status,
            "message": message,
            "timestamp": datetime.now().isoformat(),
            "pid": os.getpid()
        }
        
        try:
            with open(self.status_file, 'w', encoding='utf-8') as f:
                json.dump(status_data, f, indent=2)
        except Exception as e:
            print(f"⚠️ Failed to update status: {e}")
    
    def save_conversation_log(self):
        """会話ログ保存"""
        log_file = self.bridge_dir / f"conversation_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.conversation_log, f, indent=2, ensure_ascii=False)
            print(f"💾 Conversation log saved: {log_file}")
        except Exception as e:
            print(f"❌ Failed to save log: {e}")

def main():
    """メイン実行"""
    import sys
    
    # API key check
    api_key = os.getenv('GEMINI_API_KEY')
    if not api_key:
        print("❌ GEMINI_API_KEY not found in environment variables")
        print("Set it with: export GEMINI_API_KEY='your_api_key_here'")
        return
    
    gemini = GeminiDirectAPI(api_key)
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "bridge":
            # ブリッジモード
            gemini.start_bridge_mode()
        elif sys.argv[1] == "test":
            # テストモード
            message = "こんにちは！Claudeからのテストメッセージです。AI統合システムについて何かアドバイスをお願いします。"
            result = gemini.send_message(message)
            gemini.save_conversation_log()
        else:
            # 直接メッセージ送信
            message = " ".join(sys.argv[1:])
            result = gemini.send_message(message)
            gemini.save_conversation_log()
    else:
        print("Usage:")
        print("  python gemini_direct_api.py test                    # Test mode")
        print("  python gemini_direct_api.py bridge                  # Bridge mode")
        print("  python gemini_direct_api.py 'Your message here'     # Direct message")

if __name__ == "__main__":
    main()