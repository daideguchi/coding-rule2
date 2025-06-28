#!/bin/bash
# ファイル不存在エラー修正スクリプト
file_path="$1"
echo "ファイル作成を試行: ${file_path}"
# ディレクトリ作成とファイル作成
mkdir -p "$(dirname "${file_path}")"
touch "${file_path}"
exit 0
