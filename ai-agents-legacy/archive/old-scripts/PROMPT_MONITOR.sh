#!/bin/bash
# プロンプト停止定期監視
monitor_all_prompts() {
    while true; do
        for i in {0..3}; do
            local status=$(bash /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_RECOVERY_SYSTEM.sh detect "multiagent:0.$i" "WORKER$i")
            
            if [[ "$status" == "stuck" ]]; then
                echo "🚨 WORKER$i 停止検知・自動復旧"
                bash /Users/dd/Desktop/1_dev/coding-rule2/ai-agents/PROMPT_RECOVERY_SYSTEM.sh recover "multiagent:0.$i" "WORKER$i"
            fi
        done
        
        sleep 30  # 30秒間隔
    done
}
