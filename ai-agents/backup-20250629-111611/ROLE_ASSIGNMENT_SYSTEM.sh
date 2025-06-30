#!/bin/bash
# 🎯 要件定義に基づく役職割り当てシステム

# 正確な役職設定
set_precise_roles() {
    echo "🎯 要件定義準拠の役職設定開始"
    
    # 1. PRESIDENT - 最高責任者
    tmux select-pane -t president -T "🟢作業中 👑PRESIDENT・最高責任者 │ 全体統括中"
    
    # 2. BOSS1 - 開発チームリーダー  
    tmux select-pane -t multiagent:0.0 -T "🟢作業中 👔BOSS1・チームリーダー │ 開発指示中"
    
    # 3. WORKER1 - フロントエンドエンジニア
    tmux select-pane -t multiagent:0.1 -T "🟡待機中 💻WORKER1・FEエンジニア │ 開発待機"
    
    # 4. WORKER2 - バックエンドエンジニア
    tmux select-pane -t multiagent:0.2 -T "🟡待機中 🔧WORKER2・BEエンジニア │ 開発待機"
    
    # 5. WORKER3 - UI/UXデザイナー
    tmux select-pane -t multiagent:0.3 -T "🟡待機中 🎨WORKER3・UI/UXデザイナー │ デザイン待機"
    
    echo "✅ 役職設定完了"
}

# チーム協業開始
start_team_collaboration() {
    echo "🤝 チーム協業開始"
    
    # BOSS1からWORKERへの具体的指示
    tmux send-keys -t multiagent:0.0 "👔BOSS1として開発チームを統括します。各メンバーに役職に応じた作業を指示します。WORKER1はフロント開発、WORKER2はバック開発、WORKER3はUI/UX設計を担当してください。" C-m
    
    sleep 3
    
    # 各WORKERの役職確認と応答
    tmux send-keys -t multiagent:0.1 "💻WORKER1・フロントエンドエンジニアです。React/Vue.js等のフロント開発を担当します。指示をお待ちしています。" C-m
    
    tmux send-keys -t multiagent:0.2 "🔧WORKER2・バックエンドエンジニアです。API/DB設計等のバック開発を担当します。指示をお待ちしています。" C-m
    
    tmux send-keys -t multiagent:0.3 "🎨WORKER3・UI/UXデザイナーです。インターフェース設計・UX改善を担当します。指示をお待ちしています。" C-m
    
    echo "✅ チーム協業開始完了"
}

# 実行
set_precise_roles
start_team_collaboration