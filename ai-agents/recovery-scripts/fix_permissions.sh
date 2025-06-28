#!/bin/bash
# 権限エラー修正スクリプト
target="$1"
echo "権限修正を試行: ${target}"
chmod +x "${target}" 2>/dev/null || true
exit 0
