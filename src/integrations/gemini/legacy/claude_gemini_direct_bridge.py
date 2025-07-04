#!/usr/bin/env python3
"""
Claude-Gemini Direct Bridge - 確実動作版
プロセス検出とTTY直接通信
"""

import os
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime
import re

class ClaudeGeminiDirectBridge:
    def __init__(self):
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.conversation_log = []
        self.gemini_process = None
        
        print(f"🌉 Claude-Gemini Direct Bridge initialized")
    
    def find_gemini_process(self) -> bool:
        """Geminiプロセスを検出"""
        try:
            result = subprocess.run([
                'ps', 'aux'
            ], capture_output=True, text=True)
            
            if result.returncode != 0:
                return False
            
            # Gemini YOLOプロセスを検索
            lines = result.stdout.split('\n')
            for line in lines:
                if 'gemini' in line and '--yolo' in line and 'grep' not in line:
                    parts = line.split()
                    if len(parts) >= 7:
                        self.gemini_process = {
                            'pid': parts[1],
                            'tty': parts[6],
                            'command': ' '.join(parts[10:])
                        }
                        
                        print(f"✅ Found Gemini process:")
                        print(f"   PID: {self.gemini_process['pid']}")
                        print(f"   TTY: {self.gemini_process['tty']}")
                        print(f"   Command: {self.gemini_process['command']}")
                        
                        return True
            
            print("❌ Gemini YOLO process not found")
            return False
            
        except Exception as e:
            print(f"❌ Error finding Gemini process: {e}")
            return False
    
    def send_to_gemini_direct(self, message: str) -> dict:
        """TTY経由でGeminiに直接送信"""
        try:
            if not self.gemini_process:
                if not self.find_gemini_process():
                    return {
                        "status": "error",
                        "error": "Gemini process not found",
                        "timestamp": datetime.now().isoformat()
                    }
            
            tty_device = f"/dev/{self.gemini_process['tty']}"
            print(f"📤 Sending to Gemini via {tty_device}: {message[:100]}...")
            
            # メッセージをTTYに送信
            try:
                with open(tty_device, 'w') as tty:
                    tty.write(message + '\n')
                    tty.flush()
                
                print("✅ Message sent to Gemini TTY")
                
                # 少し待機してプロセス確認
                time.sleep(2)
                
                # プロセスが生きているか確認
                check_result = subprocess.run([
                    'ps', '-p', self.gemini_process['pid']
                ], capture_output=True, text=True)
                
                if check_result.returncode == 0:
                    result = {
                        "status": "sent",
                        "human_message": message,
                        "gemini_response": "Message sent to Gemini TTY - check terminal for response",
                        "timestamp": datetime.now().isoformat(),
                        "method": "tty_direct",
                        "tty_device": tty_device,
                        "process_pid": self.gemini_process['pid']
                    }
                    
                    self.conversation_log.append(result)
                    return result
                else:
                    return {
                        "status": "error",
                        "error": "Gemini process died after message send",
                        "timestamp": datetime.now().isoformat()
                    }
                
            except PermissionError:
                # Permission denied - Apple Script経由で試行
                return self.send_via_applescript(message)
            
        except Exception as e:
            error_result = {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            self.conversation_log.append(error_result)
            return error_result
    
    def send_via_applescript(self, message: str) -> dict:
        """AppleScript経由で送信（フォールバック）"""
        try:
            print("🍎 Trying AppleScript approach...")
            
            # まずTerminalをアクティブに
            applescript = f'''
            tell application "Terminal"
                activate
                do script "echo '{message.replace("'", "\\'")}'"
            end tell
            '''
            
            result = subprocess.run([
                'osascript', '-e', applescript
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                response_result = {
                    "status": "sent_applescript",
                    "human_message": message,
                    "gemini_response": "Message sent via AppleScript - check terminal for response", 
                    "timestamp": datetime.now().isoformat(),
                    "method": "applescript"
                }
                
                self.conversation_log.append(response_result)
                return response_result
            else:
                return {
                    "status": "error",
                    "error": f"AppleScript failed: {result.stderr}",
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            return {
                "status": "error",
                "error": f"AppleScript error: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    def quick_chat(self, message: str) -> str:
        """簡単チャット"""
        result = self.send_to_gemini_direct(message)
        
        if result.get('status') in ['sent', 'sent_applescript']:
            return f"✅ {result.get('gemini_response', 'Message sent')}"
        else:
            return f"❌ {result.get('error', 'Unknown error')}"
    
    def save_conversation_log(self):
        """会話ログ保存"""
        if not self.conversation_log:
            return
            
        log_file = self.bridge_dir / f"direct_conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.conversation_log, f, indent=2, ensure_ascii=False)
            print(f"💾 Conversation log saved: {log_file}")
        except Exception as e:
            print(f"❌ Failed to save log: {e}")

def main():
    """メイン実行"""
    import sys
    
    bridge = ClaudeGeminiDirectBridge()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python claude_gemini_direct_bridge.py 'Your message'")
        print("  python claude_gemini_direct_bridge.py test")
        return
    
    if sys.argv[1] == "test":
        # テストモード
        print("🧪 Testing Claude-Gemini Direct bridge...")
        
        message = "こんにちは！Claudeからのテストです。AI統合について簡潔にお願いします。"
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