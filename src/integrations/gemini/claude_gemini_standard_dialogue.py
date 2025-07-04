#!/usr/bin/env python3
"""
Claude-Gemini 標準対話システム
簡単で確実なAI間対話を実現する標準化されたインターフェース
"""

import subprocess
import json
import time
from datetime import datetime
from pathlib import Path
import sys

class ClaudeGeminiDialogue:
    def __init__(self):
        self.dialogue_dir = Path(__file__).parent / "dialogue_logs"
        self.dialogue_dir.mkdir(exist_ok=True)
        
    def send_to_gemini(self, message: str) -> dict:
        """
        Geminiにメッセージを送信し、応答を取得
        
        Args:
            message (str): Geminiに送信するメッセージ
            
        Returns:
            dict: 対話結果（応答、タイムスタンプ、状態）
        """
        try:
            print(f"📤 Claude → Gemini: {message[:100]}...")
            
            # Gemini CLIを実行
            process = subprocess.run(
                ['npx', '@google/gemini-cli'],
                input=message,
                text=True,
                capture_output=True,
                timeout=60
            )
            
            if process.returncode == 0:
                response = process.stdout.strip()
                
                result = {
                    "timestamp": datetime.now().isoformat(),
                    "claude_message": message,
                    "gemini_response": response,
                    "status": "success",
                    "response_length": len(response)
                }
                
                print(f"✅ Gemini → Claude: {response[:200]}...")
                print(f"📊 応答長: {len(response)}文字")
                
                return result
            else:
                error_result = {
                    "timestamp": datetime.now().isoformat(),
                    "claude_message": message,
                    "error": process.stderr,
                    "status": "error"
                }
                return error_result
                
        except subprocess.TimeoutExpired:
            return {
                "timestamp": datetime.now().isoformat(),
                "claude_message": message,
                "error": "Timeout after 60 seconds",
                "status": "timeout"
            }
        except Exception as e:
            return {
                "timestamp": datetime.now().isoformat(),
                "claude_message": message,
                "error": str(e),
                "status": "error"
            }
    
    def save_dialogue(self, dialogue_data: dict, session_name: str = None) -> str:
        """
        対話ログを保存
        
        Args:
            dialogue_data (dict): 対話データ
            session_name (str): セッション名（任意）
            
        Returns:
            str: 保存ファイルパス
        """
        if session_name:
            filename = f"{session_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        else:
            filename = f"dialogue_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        file_path = self.dialogue_dir / filename
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(dialogue_data, f, indent=2, ensure_ascii=False)
            
            print(f"💾 対話ログ保存: {file_path}")
            return str(file_path)
        except Exception as e:
            print(f"❌ 保存エラー: {e}")
            return ""
    
    def quick_chat(self, message: str, save_log: bool = True, session_name: str = None) -> str:
        """
        簡単チャット - 応答テキストのみを返却
        
        Args:
            message (str): メッセージ
            save_log (bool): ログ保存するかどうか
            session_name (str): セッション名
            
        Returns:
            str: Geminiの応答テキスト
        """
        result = self.send_to_gemini(message)
        
        if save_log:
            self.save_dialogue(result, session_name)
        
        if result.get('status') == 'success':
            return result.get('gemini_response', 'No response')
        else:
            return f"Error: {result.get('error', 'Unknown error')}"
    
    def interactive_session(self):
        """
        インタラクティブセッション開始
        """
        print("🚀 Claude-Gemini 対話セッション開始")
        print("💡 'exit'で終了、'save'で現在のセッション保存")
        print("-" * 60)
        
        session_log = []
        session_id = f"interactive_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        while True:
            try:
                user_input = input("\n👤 You → Gemini: ")
                
                if user_input.lower() == 'exit':
                    if session_log:
                        self.save_dialogue({
                            "session_id": session_id,
                            "dialogues": session_log,
                            "session_type": "interactive"
                        }, "interactive_session")
                    print("🎯 セッション終了")
                    break
                
                if user_input.lower() == 'save':
                    if session_log:
                        self.save_dialogue({
                            "session_id": session_id,
                            "dialogues": session_log,
                            "session_type": "interactive"
                        }, "interactive_session")
                        print("💾 セッション保存完了")
                    continue
                
                if not user_input.strip():
                    continue
                
                result = self.send_to_gemini(user_input)
                session_log.append(result)
                
                if result.get('status') == 'success':
                    print(f"\n🤖 Gemini: {result['gemini_response']}")
                else:
                    print(f"\n❌ エラー: {result.get('error')}")
                    
            except KeyboardInterrupt:
                print("\n\n🛑 中断されました")
                if session_log:
                    self.save_dialogue({
                        "session_id": session_id,
                        "dialogues": session_log,
                        "session_type": "interactive"
                    }, "interrupted_session")
                break

def main():
    """メイン実行関数"""
    dialogue = ClaudeGeminiDialogue()
    
    if len(sys.argv) < 2:
        print("🔧 Claude-Gemini 標準対話システム")
        print("\n使用方法:")
        print("  python claude_gemini_standard_dialogue.py 'メッセージ'")
        print("  python claude_gemini_standard_dialogue.py interactive")
        print("  python claude_gemini_standard_dialogue.py test")
        return
    
    if sys.argv[1] == "interactive":
        dialogue.interactive_session()
    elif sys.argv[1] == "test":
        print("🧪 システムテスト実行中...")
        test_message = "こんにちは！Claude-Gemini標準対話システムのテストです。簡潔に応答してください。"
        response = dialogue.quick_chat(test_message, save_log=True, session_name="system_test")
        print(f"\n✅ テスト完了\n応答: {response}")
    else:
        message = " ".join(sys.argv[1:])
        response = dialogue.quick_chat(message, save_log=True, session_name="quick_chat")
        print(f"\n📝 応答:\n{response}")

if __name__ == "__main__":
    main()