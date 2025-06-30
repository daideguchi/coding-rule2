#!/bin/bash
# 自律稼働システム起動スクリプト
cd "$(dirname "$0")/../../.."
./ai-agents/scripts/core/AUTONOMOUS_GROWTH_ENGINE.sh start_daemon
