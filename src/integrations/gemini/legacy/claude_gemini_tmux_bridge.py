#!/usr/bin/env python3
"""
Claude-Gemini Tmux Bridge - 確実動作版
Tmuxセッション経由でGeminiに直接送信
"""

import os
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime

class ClaudeGeminiTmuxBridge:
    def __init__(self):
        self.bridge_dir = Path(__file__).parent / "gemini_bridge"
        self.bridge_dir.mkdir(exist_ok=True)
        
        self.conversation_log = []
        
        # Geminiプロセス情報
        self.gemini_session = None
        self.gemini_window = None
        
        print(f"🌉 Claude-Gemini Tmux Bridge initialized")
    
    def find_gemini_session(self) -> bool:
        """Geminiが実行されているtmuxセッションを検索"""
        try:
            # tmux list-sessions
            result = subprocess.run(['tmux', 'list-sessions'], 
                                    capture_output=True, text=True)
            
            if result.returncode != 0:
                print("❌ tmux is not running or no sessions found")
                return False
            
            sessions = result.stdout.strip().split('\n')
            print(f"📋 Found {len(sessions)} tmux sessions")
            
            # 各セッションでGeminiプロセスを検索
            for session_line in sessions:
                session_name = session_line.split(':')[0]
                
                # セッション内のウィンドウをチェック
                windows_result = subprocess.run([
                    'tmux', 'list-windows', '-t', session_name
                ], capture_output=True, text=True)
                
                if windows_result.returncode == 0:
                    for window_line in windows_result.stdout.strip().split('\n'):
                        # ウィンドウの内容をキャプチャしてGemini確認
                        window_parts = window_line.split()
                        if window_parts:
                            window_id = window_parts[0].rstrip(':')
                            
                            capture_result = subprocess.run([
                                'tmux', 'capture-pane', '-t', f"{session_name}:{window_id}", '-p'
                            ], capture_output=True, text=True)
                            
                            if capture_result.returncode == 0:
                                content = capture_result.stdout
                                if 'GEMINI' in content and 'YOLO mode' in content:
                                    self.gemini_session = session_name
                                    self.gemini_window = window_id
                                    print(f"✅ Found Gemini in session '{session_name}', window '{window_id}'")
                                    return True
            
            print("❌ No Gemini session found")
            return False
            
        except Exception as e:
            print(f"❌ Error finding Gemini session: {e}")
            return False
    
    def send_to_gemini_tmux(self, message: str) -> dict:
        """tmux経由でGeminiにメッセージ送信"""
        try:
            if not self.gemini_session:
                if not self.find_gemini_session():
                    return {
                        "status": "error",
                        "error": "Gemini session not found",
                        "timestamp": datetime.now().isoformat()
                    }
            
            target = f"{self.gemini_session}:{self.gemini_window}"
            print(f"📤 Sending to Gemini via tmux ({target}): {message[:100]}...")
            
            # 現在の画面をキャプチャ（送信前）
            before_capture = subprocess.run([
                'tmux', 'capture-pane', '-t', target, '-p'
            ], capture_output=True, text=True)
            
            # メッセージを送信
            subprocess.run([
                'tmux', 'send-keys', '-t', target, message, 'Enter'
            ], check=True)
            
            print("⏳ Waiting for Gemini response...")
            
            # 応答待機
            for i in range(15):  # 15秒待機
                time.sleep(1)
                
                # 現在の画面をキャプチャ
                after_capture = subprocess.run([
                    'tmux', 'capture-pane', '-t', target, '-p'
                ], capture_output=True, text=True)
                
                if after_capture.returncode == 0:
                    current_content = after_capture.stdout
                    
                    # 新しい内容があるかチェック
                    if before_capture.returncode == 0:
                        before_content = before_capture.stdout
                        if len(current_content) > len(before_content):
                            # 新しい内容を抽出
                            lines = current_content.split('\n')
                            
                            # Geminiの応答部分を探す
                            response_lines = []
                            found_response = False
                            
                            for line in lines:
                                if '>' in line and 'Type your message' in line:
                                    break  # 入力プロンプトに戻った
                                if found_response or any(keyword in line for keyword in ['AI', '提案', '統合', 'システム']):
                                    found_response = True
                                    if line.strip():
                                        response_lines.append(line.strip())
                            
                            if response_lines:
                                gemini_response = '\n'.join(response_lines)
                                
                                result = {
                                    "status": "success",
                                    "human_message": message,
                                    "gemini_response": gemini_response,
                                    "timestamp": datetime.now().isoformat(),
                                    "method": "tmux",
                                    "session": target
                                }
                                
                                print(f"✅ Response captured from Gemini ({len(gemini_response)} chars)")
                                print(f"🔮 Gemini: {gemini_response[:200]}...")
                                
                                self.conversation_log.append(result)
                                return result
            
            # タイムアウト - でも最新の画面内容を返す
            final_capture = subprocess.run([
                'tmux', 'capture-pane', '-t', target, '-p'
            ], capture_output=True, text=True)
            
            timeout_result = {
                "status": "timeout",
                "human_message": message,
                "screen_content": final_capture.stdout if final_capture.returncode == 0 else "",
                "timestamp": datetime.now().isoformat(),
                "method": "tmux",
                "session": target
            }
            
            self.conversation_log.append(timeout_result)
            return timeout_result
            
        except Exception as e:
            error_result = {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            self.conversation_log.append(error_result)
            return error_result
    
    def quick_chat(self, message: str) -> str:
        """簡単チャット"""
        result = self.send_to_gemini_tmux(message)
        
        if result.get('status') == 'success':
            return result.get('gemini_response', 'No response extracted')
        elif result.get('status') == 'timeout':
            return f"Timeout - Screen content:\n{result.get('screen_content', 'No content')}"
        else:
            return f"Error: {result.get('error', 'Unknown error')}"
    
    def save_conversation_log(self):
        """会話ログ保存"""
        if not self.conversation_log:
            return
            
        log_file = self.bridge_dir / f"tmux_conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.conversation_log, f, indent=2, ensure_ascii=False)
            print(f"💾 Conversation log saved: {log_file}")
        except Exception as e:
            print(f"❌ Failed to save log: {e}")

def main():
    """メイン実行"""
    import sys
    
    bridge = ClaudeGeminiTmuxBridge()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python claude_gemini_tmux_bridge.py 'Your message'")
        print("  python claude_gemini_tmux_bridge.py test")
        return
    
    if sys.argv[1] == "test":
        # テストモード
        print("🧪 Testing Claude-Gemini Tmux bridge...")
        
        message = "こんにちは！Claudeからのテストです。AI統合について一言お願いします。"
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