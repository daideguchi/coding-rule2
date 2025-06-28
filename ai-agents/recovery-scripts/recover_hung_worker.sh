#!/bin/bash
# ワーカー復旧スクリプト
worker="$1"
session="multiagent:0.${worker: -1}"
echo "ワーカー復旧を試行: ${worker}"
tmux send-keys -t "${session}" C-c C-c
sleep 2
tmux send-keys -t "${session}" "clear" C-m
exit 0
