#!/usr/bin/env python3
"""
シンプルなHTTPサーバー for Gemini Chat UI
ローカルでHTMLUIを動作させるための最小サーバー
"""

import http.server
import socketserver
import json
import subprocess
import sys
from pathlib import Path
import urllib.parse

class GeminiChatHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(Path(__file__).parent), **kwargs)
    
    def do_POST(self):
        if self.path == '/api/gemini-chat':
            self.handle_gemini_chat()
        else:
            self.send_error(404)
    
    def handle_gemini_chat(self):
        try:
            # リクエストボディを読み取り
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            message = data.get('message', '')
            if not message:
                self.send_json_response({'status': 'error', 'response': 'メッセージが空です'})
                return
            
            print(f"📤 Received: {message}")
            
            # Gemini CLIを実行
            try:
                process = subprocess.run(
                    ['npx', '@google/gemini-cli'],
                    input=message,
                    text=True,
                    capture_output=True,
                    timeout=30
                )
                
                if process.returncode == 0:
                    response = process.stdout.strip()
                    print(f"✅ Gemini response: {response[:100]}...")
                    
                    self.send_json_response({
                        'status': 'success',
                        'response': response
                    })
                else:
                    error_msg = process.stderr or 'Unknown error'
                    print(f"❌ Error: {error_msg}")
                    
                    self.send_json_response({
                        'status': 'error',
                        'response': f'Geminiエラー: {error_msg}'
                    })
                    
            except subprocess.TimeoutExpired:
                self.send_json_response({
                    'status': 'error',
                    'response': 'タイムアウト: Geminiの応答に時間がかかりすぎています'
                })
            except FileNotFoundError:
                self.send_json_response({
                    'status': 'error',
                    'response': 'Gemini CLIが見つかりません。npm install -g @google/gemini-cli を実行してください'
                })
            except Exception as e:
                self.send_json_response({
                    'status': 'error',
                    'response': f'実行エラー: {str(e)}'
                })
                
        except json.JSONDecodeError:
            self.send_json_response({'status': 'error', 'response': 'JSONデコードエラー'})
        except Exception as e:
            self.send_json_response({'status': 'error', 'response': f'サーバーエラー: {str(e)}'})
    
    def send_json_response(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        
        response = json.dumps(data, ensure_ascii=False)
        self.wfile.write(response.encode('utf-8'))
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def main():
    PORT = 8000
    
    print("🚀 Gemini Chat UI サーバー起動中...")
    print(f"📡 ポート: {PORT}")
    print(f"🌐 URL: http://localhost:{PORT}/gemini_chat_ui.html")
    print("🛑 停止: Ctrl+C")
    print("-" * 50)
    
    try:
        with socketserver.TCPServer(("", PORT), GeminiChatHandler) as httpd:
            print(f"✅ サーバー起動完了")
            print(f"📂 ファイル: {Path(__file__).parent}/gemini_chat_ui.html")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 サーバー停止")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ ポート {PORT} は既に使用中です")
            print("他のポートを試すか、既存のプロセスを停止してください")
        else:
            print(f"❌ サーバーエラー: {e}")

if __name__ == "__main__":
    main()