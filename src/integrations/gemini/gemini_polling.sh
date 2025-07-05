#!/bin/bash
# Gemini応答の自動ポーリングスクリプト

RESPONSE_FILE="gemini_response.txt"
PROCESSED_FLAG=".processed"

while true; do
    if [ -f "$RESPONSE_FILE" ] && [ ! -f "$PROCESSED_FLAG" ]; then
        echo "🔍 新しいGemini応答を検出"
        python3 gemini_cli_direct_integration.py process
        touch "$PROCESSED_FLAG"
        
        # 処理後、次の対話のためにファイルをリネーム
        mv "$RESPONSE_FILE" "gemini_response_$(date +%Y%m%d_%H%M%S).txt"
        rm "$PROCESSED_FLAG"
    fi
    
    sleep 5
done
