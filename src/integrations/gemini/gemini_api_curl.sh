#!/bin/bash
# Gemini API直接呼び出しスクリプト

API_KEY="AIzaSyDSfkfjFZMo7MYbgXJ7CElGHNTEJJxfK_I"
PROMPT="$1"

# JSONエスケープ処理
ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "'"$ESCAPED_PROMPT"'"
      }]
    }]
  }' | python3 -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    if 'candidates' in data and len(data['candidates']) > 0:
        content = data['candidates'][0]['content']['parts'][0]['text']
        print(content)
    else:
        print('エラー:', data)
except Exception as e:
    print('解析エラー:', e)
"