#!/usr/bin/env python3
"""
Claude-Gemini Focus Bridge - 既存セッション特定版
既存のGeminiターミナルにフォーカスして送信
"""

import os
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime

class ClaudeGeminiFocusBridge:
    def __init__(self):
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.conversation_log = []
        
        print(f"🌉 Claude-Gemini Focus Bridge initialized")
    
    def send_to_active_gemini(self, message: str) -> dict:
        """アクティブなGeminiセッションに送信"""
        try:
            print(f"📤 Sending to active Gemini: {message[:100]}...")
            
            # ステップ1: Terminalアプリをアクティブにする
            activate_script = '''
            tell application "Terminal"
                activate
            end tell
            '''
            
            subprocess.run(['osascript', '-e', activate_script], check=True)
            time.sleep(1)
            
            # ステップ2: Geminiが実行されているウィンドウを探してアクティブにする
            find_window_script = '''
            tell application "Terminal"
                set windowList to every window
                repeat with aWindow in windowList
                    try
                        set windowContent to (contents of aWindow as string)
                        if windowContent contains "GEMINI" and windowContent contains "YOLO" then
                            set index of aWindow to 1
                            return "Found Gemini window"
                        end if
                    end try
                end repeat
                return "Gemini window not found"
            end tell
            '''
            
            result = subprocess.run(['osascript', '-e', find_window_script], 
                                    capture_output=True, text=True)
            
            if "Found Gemini window" in result.stdout:
                print("✅ Found and activated Gemini window")
                time.sleep(0.5)
                
                # ステップ3: メッセージを入力
                type_script = f'''
                tell application "System Events"
                    keystroke "{message.replace('"', '\\"')}"
                    key code 36
                end tell
                '''
                
                subprocess.run(['osascript', '-e', type_script], check=True)
                
                result_data = {
                    "status": "sent_to_gemini",
                    "human_message": message,
                    "gemini_response": "Message sent to Gemini window - check for response",
                    "timestamp": datetime.now().isoformat(),
                    "method": "focus_bridge"
                }
                
                self.conversation_log.append(result_data)
                print("✅ Message sent to Gemini window")
                return result_data
                
            else:
                # フォールバック: 単純なキーストローク送信
                print("⚠️  Gemini window not found, trying direct keystroke...")
                
                simple_script = f'''
                tell application "System Events"
                    keystroke "{message.replace('"', '\\"')}"
                    key code 36
                end tell
                '''
                
                subprocess.run(['osascript', '-e', simple_script], check=True)
                
                fallback_result = {
                    "status": "sent_fallback",
                    "human_message": message,
                    "gemini_response": "Message sent via direct keystroke - check active window",
                    "timestamp": datetime.now().isoformat(),
                    "method": "direct_keystroke"
                }
                
                self.conversation_log.append(fallback_result)
                return fallback_result
                
        except Exception as e:
            error_result = {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            self.conversation_log.append(error_result)
            return error_result
    
    def send_via_window_title(self, message: str) -> dict:
        """ウィンドウタイトルでGemini検索"""
        try:
            print("🔍 Searching for Gemini window by title...")
            
            # 全てのウィンドウを取得してGeminiを探す
            window_search_script = '''
            tell application "System Events"
                set appList to every application process whose visible is true
                repeat with anApp in appList
                    try
                        set windowList to every window of anApp
                        repeat with aWindow in windowList
                            set windowTitle to (name of aWindow as string)
                            if windowTitle contains "gemini" or windowTitle contains "GEMINI" then
                                set frontmost of anApp to true
                                set index of aWindow to 1
                                return "Found: " & windowTitle
                            end if
                        end repeat
                    end try
                end repeat
                return "No Gemini window found"
            end tell
            '''
            
            result = subprocess.run(['osascript', '-e', window_search_script], 
                                    capture_output=True, text=True)
            
            if "Found:" in result.stdout:
                print(f"✅ {result.stdout.strip()}")
                time.sleep(1)
                
                # メッセージ送信
                send_script = f'''
                tell application "System Events"
                    keystroke "{message.replace('"', '\\"')}"
                    key code 36
                end tell
                '''
                
                subprocess.run(['osascript', '-e', send_script], check=True)
                
                return {
                    "status": "sent_by_title",
                    "human_message": message,
                    "gemini_response": f"Sent to window: {result.stdout.strip()}",
                    "timestamp": datetime.now().isoformat(),
                    "method": "window_title_search"
                }
            else:
                return {
                    "status": "window_not_found",
                    "error": "Gemini window not found by title",
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def quick_chat(self, message: str) -> str:
        """簡単チャット"""
        # 方法1: フォーカスブリッジ
        result = self.send_to_active_gemini(message)
        
        if result.get('status') == 'error':
            # 方法2: ウィンドウタイトル検索
            result = self.send_via_window_title(message)
        
        if result.get('status').startswith('sent'):
            return f"✅ {result.get('gemini_response', 'Message sent')}"
        else:
            return f"❌ {result.get('error', 'Unknown error')}"
    
    def save_conversation_log(self):
        """会話ログ保存"""
        if not self.conversation_log:
            return
            
        log_file = self.bridge_dir / f"focus_conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.conversation_log, f, indent=2, ensure_ascii=False)
            print(f"💾 Conversation log saved: {log_file}")
        except Exception as e:
            print(f"❌ Failed to save log: {e}")

def main():
    """メイン実行"""
    import sys
    
    bridge = ClaudeGeminiFocusBridge()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python claude_gemini_focus_bridge.py 'Your message'")
        print("  python claude_gemini_focus_bridge.py test")
        return
    
    if sys.argv[1] == "test":
        # テストモード
        print("🧪 Testing Claude-Gemini Focus bridge...")
        
        message = "こんにちは！Claudeからのフォーカステストです。AI統合システムについて教えてください。"
        response = bridge.quick_chat(message)
        print(f"\n📝 Result: {response}")
        
        bridge.save_conversation_log()
        
    else:
        # 通常メッセージ送信
        message = " ".join(sys.argv[1:])
        response = bridge.quick_chat(message)
        print(response)
        
        bridge.save_conversation_log()

if __name__ == "__main__":
    main()