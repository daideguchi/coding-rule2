#!/bin/bash
# 🚀 AI組織 GitHub Issues + MCP 統合システム
# tmux + Claude Code + GitHub Issues + MCP の革新的統合

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INTEGRATION_LOG="$SCRIPT_DIR/logs/integration-$(date +%Y%m%d-%H%M%S).log"
MCP_CONFIG_DIR="$SCRIPT_DIR/mcp"
GITHUB_CONFIG_DIR="$SCRIPT_DIR/github"
TMUX_SESSION_PREFIX="ai-org"

# 色付きログ関数
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1" | tee -a "$INTEGRATION_LOG"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1" | tee -a "$INTEGRATION_LOG"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" | tee -a "$INTEGRATION_LOG"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" | tee -a "$INTEGRATION_LOG"
}

# 初期化
init_integration_system() {
    log_info "🚀 AI組織統合システム初期化開始"
    
    # ディレクトリ構造作成
    mkdir -p "$SCRIPT_DIR"/{mcp,github,logs,sessions,config}
    mkdir -p "$MCP_CONFIG_DIR"/{servers,tools,contexts}
    mkdir -p "$GITHUB_CONFIG_DIR"/{templates,workflows,hooks}
    
    # ログディレクトリ作成
    mkdir -p "$SCRIPT_DIR/logs"
    
    log_success "✅ ディレクトリ構造作成完了"
}

# MCP設定ファイル作成
create_mcp_configuration() {
    log_info "🔧 MCP設定ファイル作成中..."
    
    # MCP Server設定
    cat > "$MCP_CONFIG_DIR/servers/github-server.json" << 'EOF'
{
  "name": "github-ai-organization",
  "version": "1.0.0",
  "description": "GitHub Issues integration for AI Organization",
  "tools": [
    {
      "name": "list_issues",
      "description": "List GitHub issues with filters",
      "parameters": {
        "type": "object",
        "properties": {
          "assignee": {"type": "string"},
          "labels": {"type": "array", "items": {"type": "string"}},
          "state": {"type": "string", "enum": ["open", "closed", "all"]},
          "sort": {"type": "string", "enum": ["created", "updated", "comments"]}
        }
      }
    },
    {
      "name": "create_issue",
      "description": "Create new GitHub issue",
      "parameters": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "body": {"type": "string"},
          "labels": {"type": "array", "items": {"type": "string"}},
          "assignees": {"type": "array", "items": {"type": "string"}}
        },
        "required": ["title", "body"]
      }
    },
    {
      "name": "update_issue",
      "description": "Update existing GitHub issue",
      "parameters": {
        "type": "object",
        "properties": {
          "issue_number": {"type": "integer"},
          "title": {"type": "string"},
          "body": {"type": "string"},
          "state": {"type": "string", "enum": ["open", "closed"]},
          "labels": {"type": "array", "items": {"type": "string"}}
        },
        "required": ["issue_number"]
      }
    },
    {
      "name": "add_comment",
      "description": "Add comment to GitHub issue",
      "parameters": {
        "type": "object",
        "properties": {
          "issue_number": {"type": "integer"},
          "body": {"type": "string"}
        },
        "required": ["issue_number", "body"]
      }
    },
    {
      "name": "assign_issue",
      "description": "Assign issue to AI worker",
      "parameters": {
        "type": "object",
        "properties": {
          "issue_number": {"type": "integer"},
          "worker_id": {"type": "string", "enum": ["boss", "worker1", "worker2", "worker3"]},
          "tmux_pane": {"type": "string"}
        },
        "required": ["issue_number", "worker_id"]
      }
    }
  ],
  "contexts": [
    {
      "name": "ai_organization_context",
      "description": "Current state of AI organization workers",
      "schema": {
        "type": "object",
        "properties": {
          "active_workers": {"type": "array"},
          "current_assignments": {"type": "object"},
          "pane_status": {"type": "object"},
          "project_context": {"type": "string"}
        }
      }
    }
  ]
}
EOF

    # MCP Tools Implementation
    cat > "$MCP_CONFIG_DIR/tools/github_integration.py" << 'EOF'
#!/usr/bin/env python3
"""
AI Organization GitHub MCP Tools
GitHub Issues と AI組織システムの統合ツール
"""

import asyncio
import json
import subprocess
import os
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime

@dataclass
class WorkerState:
    worker_id: str
    tmux_pane: str
    current_issue: Optional[int]
    status: str  # "idle", "working", "reviewing"
    last_activity: datetime

class AIOrganizationGitHubIntegration:
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.workers = {
            "boss": WorkerState("boss", "multiagent:0.0", None, "idle", datetime.now()),
            "worker1": WorkerState("worker1", "multiagent:0.1", None, "idle", datetime.now()),
            "worker2": WorkerState("worker2", "multiagent:0.2", None, "idle", datetime.now()),
            "worker3": WorkerState("worker3", "multiagent:0.3", None, "idle", datetime.now())
        }
    
    async def list_issues(self, assignee: str = None, labels: List[str] = None, 
                         state: str = "open", sort: str = "created") -> Dict[str, Any]:
        """GitHub Issues一覧取得"""
        cmd = ["gh", "issue", "list", "--json", "number,title,body,labels,assignees,state,createdAt"]
        
        if assignee:
            cmd.extend(["--assignee", assignee])
        if labels:
            cmd.extend(["--label", ",".join(labels)])
        if state != "all":
            cmd.extend(["--state", state])
            
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0:
                issues = json.loads(result.stdout)
                return {
                    "success": True,
                    "issues": issues,
                    "count": len(issues)
                }
            else:
                return {"success": False, "error": result.stderr}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def create_issue(self, title: str, body: str, labels: List[str] = None, 
                          assignees: List[str] = None) -> Dict[str, Any]:
        """GitHub Issue作成"""
        cmd = ["gh", "issue", "create", "--title", title, "--body", body]
        
        if labels:
            cmd.extend(["--label", ",".join(labels)])
        if assignees:
            for assignee in assignees:
                cmd.extend(["--assignee", assignee])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0:
                # 作成されたIssue URLを解析してIssue番号を取得
                issue_url = result.stdout.strip()
                issue_number = issue_url.split('/')[-1]
                return {
                    "success": True,
                    "issue_number": int(issue_number),
                    "url": issue_url
                }
            else:
                return {"success": False, "error": result.stderr}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def assign_issue_to_worker(self, issue_number: int, worker_id: str) -> Dict[str, Any]:
        """IssueをAIワーカーに割り当て"""
        if worker_id not in self.workers:
            return {"success": False, "error": f"Invalid worker_id: {worker_id}"}
        
        worker = self.workers[worker_id]
        
        # tmuxペインにIssue情報を送信
        await self._send_issue_to_pane(worker.tmux_pane, issue_number)
        
        # ワーカー状態更新
        worker.current_issue = issue_number
        worker.status = "working"
        worker.last_activity = datetime.now()
        
        # GitHub Issueに割り当てコメント追加
        comment_body = f"""🤖 **AI組織自動割り当て**

Issue #{issue_number} が {worker_id.upper()} に割り当てられました。

- 担当AI: {worker_id.upper()}
- TMUXペイン: {worker.tmux_pane}
- 割り当て時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

進捗状況はこのIssueで追跡されます。"""
        
        await self.add_comment(issue_number, comment_body)
        
        return {
            "success": True,
            "worker_id": worker_id,
            "tmux_pane": worker.tmux_pane,
            "issue_number": issue_number
        }
    
    async def _send_issue_to_pane(self, tmux_pane: str, issue_number: int):
        """tmuxペインにIssue情報を送信"""
        # Issue詳細取得
        cmd = ["gh", "issue", "view", str(issue_number), "--json", "title,body,labels,assignees"]
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
        
        if result.returncode == 0:
            issue_data = json.loads(result.stdout)
            
            # AIワーカーへの指示文作成
            prompt = f"""🎯 **新しいGitHub Issue割り当て**

**Issue #{issue_number}: {issue_data['title']}**

**説明:**
{issue_data['body']}

**ラベル:** {', '.join([label['name'] for label in issue_data['labels']])}

**あなたの役割:** この Issue を分析し、適切な対応を行ってください。
1. Issue の内容を理解する
2. 必要な調査・実装を行う
3. 進捗をコメントで報告する
4. 完了時にIssueをクローズする

作業を開始してください。"""

            # tmuxペインに送信
            subprocess.run([
                "tmux", "send-keys", "-t", tmux_pane, prompt, "C-m"
            ])
    
    async def add_comment(self, issue_number: int, body: str) -> Dict[str, Any]:
        """GitHub Issueにコメント追加"""
        cmd = ["gh", "issue", "comment", str(issue_number), "--body", body]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0:
                return {"success": True}
            else:
                return {"success": False, "error": result.stderr}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def get_worker_status(self) -> Dict[str, Any]:
        """AIワーカーの現在状態取得"""
        status = {}
        for worker_id, worker in self.workers.items():
            # tmuxペインの現在状態確認
            pane_content = await self._get_pane_content(worker.tmux_pane)
            
            status[worker_id] = {
                "tmux_pane": worker.tmux_pane,
                "current_issue": worker.current_issue,
                "status": worker.status,
                "last_activity": worker.last_activity.isoformat(),
                "pane_active": "Welcome to Claude Code" in pane_content or "cwd:" in pane_content
            }
        
        return {"success": True, "workers": status}
    
    async def _get_pane_content(self, tmux_pane: str) -> str:
        """tmuxペインの内容取得"""
        try:
            result = subprocess.run([
                "tmux", "capture-pane", "-t", tmux_pane, "-p"
            ], capture_output=True, text=True)
            return result.stdout if result.returncode == 0 else ""
        except:
            return ""

# MCP Server Entry Point
async def main():
    integration = AIOrganizationGitHubIntegration("/Users/dd/Desktop/1_dev/coding-rule2")
    
    # MCP Server implementation would go here
    # This is a simplified example
    print("AI Organization GitHub MCP Server starting...")
    
    # Example usage
    issues = await integration.list_issues(state="open")
    print(f"Found {issues.get('count', 0)} open issues")
    
    worker_status = await integration.get_worker_status()
    print("Worker Status:", worker_status)

if __name__ == "__main__":
    asyncio.run(main())
EOF

    chmod +x "$MCP_CONFIG_DIR/tools/github_integration.py"
    
    log_success "✅ MCP設定ファイル作成完了"
}

# tmux + GitHub Issues統合
create_tmux_github_integration() {
    log_info "🔄 tmux + GitHub Issues統合システム作成中..."
    
    cat > "$SCRIPT_DIR/tmux_github_bridge.sh" << 'EOF'
#!/bin/bash
# tmux と GitHub Issues の橋渡しシステム

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ワーカー定義
declare -A WORKERS=(
    ["boss"]="multiagent:0.0"
    ["worker1"]="multiagent:0.1" 
    ["worker2"]="multiagent:0.2"
    ["worker3"]="multiagent:0.3"
)

# Issue自動割り当て
auto_assign_issue() {
    local issue_number="$1"
    local preferred_worker="$2"
    
    echo "🎯 Issue #$issue_number の自動割り当て開始..."
    
    # Issueラベルに基づく自動判定
    local labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name' | tr '\n' ',')
    local worker_id=""
    
    if [[ "$labels" =~ frontend|ui|ux ]]; then
        worker_id="worker1"  # フロントエンド担当
    elif [[ "$labels" =~ backend|api|database ]]; then
        worker_id="worker2"  # バックエンド担当  
    elif [[ "$labels" =~ design|documentation ]]; then
        worker_id="worker3"  # デザイン・ドキュメント担当
    else
        worker_id="boss"     # 管理・調整
    fi
    
    # 指定があれば優先
    if [ -n "$preferred_worker" ] && [ -n "${WORKERS[$preferred_worker]}" ]; then
        worker_id="$preferred_worker"
    fi
    
    local tmux_pane="${WORKERS[$worker_id]}"
    
    # tmuxペインが存在するか確認
    if ! tmux has-session -t "multiagent" 2>/dev/null; then
        echo "❌ multiagentセッションが見つかりません"
        return 1
    fi
    
    # Issue詳細取得
    local issue_data=$(gh issue view "$issue_number" --json title,body,labels,assignees)
    local title=$(echo "$issue_data" | jq -r '.title')
    local body=$(echo "$issue_data" | jq -r '.body')
    local label_names=$(echo "$issue_data" | jq -r '.labels[].name' | paste -sd ',' -)
    
    # AIワーカーへの指示文生成
    local prompt="🎯 **新しいGitHub Issue割り当て**

**Issue #${issue_number}: ${title}**

**説明:**
${body}

**ラベル:** ${label_names}
**担当AI:** ${worker_id^^}

**指示:**
1. このIssueの内容を分析してください
2. 必要な調査・実装を行ってください  
3. 進捗を定期的にGitHubコメントで報告してください
4. 完了時にIssueをクローズしてください

作業を開始してください。GitHub CLI (\`gh\`)とMCPツールが利用可能です。"

    # tmuxペインに送信
    tmux send-keys -t "$tmux_pane" "$prompt" C-m
    
    # GitHub Issueに割り当てコメント
    local assignment_comment="🤖 **AI組織自動割り当て**

- 担当AI: **${worker_id^^}**
- TMUXペイン: \`${tmux_pane}\`
- 割り当て時刻: $(date '+%Y-%m-%d %H:%M:%S')

このIssueは自動的にAI組織システムに割り当てられました。進捗状況はこちらで追跡されます。"

    gh issue comment "$issue_number" --body "$assignment_comment"
    
    # ペインタイトル更新
    tmux select-pane -t "$tmux_pane" -T "🔥作業中 ${worker_id^^} │ Issue #${issue_number}"
    
    echo "✅ Issue #$issue_number を ${worker_id^^} (${tmux_pane}) に割り当て完了"
    
    # 状態記録
    echo "{\"issue_number\": $issue_number, \"worker_id\": \"$worker_id\", \"tmux_pane\": \"$tmux_pane\", \"assigned_at\": \"$(date -Iseconds)\"}" >> "$SCRIPT_DIR/logs/assignments.jsonl"
}

# 全ワーカーステータス確認
check_all_workers() {
    echo "👥 AI組織ワーカーステータス確認"
    echo "================================"
    
    for worker_id in "${!WORKERS[@]}"; do
        local pane="${WORKERS[$worker_id]}"
        local content=$(tmux capture-pane -t "$pane" -p 2>/dev/null || echo "PANE_NOT_FOUND")
        local status="🔴 非アクティブ"
        
        if [[ "$content" =~ "Welcome to Claude Code"|"cwd:" ]]; then
            status="🟢 アクティブ"
        elif [[ "$content" == "PANE_NOT_FOUND" ]]; then
            status="❌ ペイン未存在"
        fi
        
        echo "  ${worker_id^^}: $status ($pane)"
        
        # 現在の割り当て確認
        local current_issue=$(tail -1 "$SCRIPT_DIR/logs/assignments.jsonl" 2>/dev/null | jq -r "select(.worker_id == \"$worker_id\") | .issue_number" 2>/dev/null || echo "")
        if [ -n "$current_issue" ] && [ "$current_issue" != "null" ]; then
            echo "    📋 担当Issue: #$current_issue"
        fi
    done
}

# Issue進捗自動更新
update_issue_progress() {
    local issue_number="$1"
    local worker_id="$2"
    local progress_type="$3"  # start, progress, complete
    
    local pane="${WORKERS[$worker_id]}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$progress_type" in
        "start")
            local comment="🚀 **作業開始**

${worker_id^^} が Issue #${issue_number} の作業を開始しました。

- 開始時刻: $timestamp
- 担当AI: ${worker_id^^}
- TMUXペイン: \`$pane\`"
            ;;
        "progress")
            local pane_content=$(tmux capture-pane -t "$pane" -p | tail -10)
            local comment="📊 **進捗報告**

${worker_id^^} による進捗報告 ($timestamp):

\`\`\`
$pane_content
\`\`\`"
            ;;
        "complete")
            local comment="✅ **作業完了**

${worker_id^^} が Issue #${issue_number} の作業を完了しました。

- 完了時刻: $timestamp
- 担当AI: ${worker_id^^}

このIssueをクローズします。"
            ;;
    esac
    
    gh issue comment "$issue_number" --body "$comment"
    
    if [ "$progress_type" = "complete" ]; then
        gh issue close "$issue_number"
        # ペインタイトルリセット
        tmux select-pane -t "$pane" -T "🟡待機中 ${worker_id^^}"
    fi
}

# メイン処理
case "${1:-status}" in
    "assign")
        auto_assign_issue "$2" "$3"
        ;;
    "status")
        check_all_workers
        ;;
    "progress")
        update_issue_progress "$2" "$3" "$4"
        ;;
    "bulk-assign")
        # 未割り当てのIssueを一括割り当て
        gh issue list --state open --json number,title,assignees | jq -r '.[] | select(.assignees | length == 0) | .number' | while read -r issue_num; do
            auto_assign_issue "$issue_num"
            sleep 2  # API制限対策
        done
        ;;
    *)
        echo "使用方法:"
        echo "  $0 assign <issue_number> [worker_id]  # Issue割り当て"
        echo "  $0 status                             # ワーカー状況確認"
        echo "  $0 progress <issue_number> <worker_id> <type>  # 進捗更新"
        echo "  $0 bulk-assign                        # 一括割り当て"
        ;;
esac
EOF

    chmod +x "$SCRIPT_DIR/tmux_github_bridge.sh"
    
    log_success "✅ tmux GitHub統合システム作成完了"
}

# GitHub Webhooks設定
setup_github_webhooks() {
    log_info "🔗 GitHub Webhooks設定中..."
    
    # Webhook受信サーバー
    cat > "$GITHUB_CONFIG_DIR/webhook_server.py" << 'EOF'
#!/usr/bin/env python3
"""
GitHub Webhooks → AI組織システム連携サーバー
"""

import json
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GitHubWebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        # Webhook payload受信
        content_length = int(self.headers['Content-Length'])
        payload = self.rfile.read(content_length)
        
        try:
            data = json.loads(payload.decode('utf-8'))
            event_type = self.headers.get('X-GitHub-Event', 'unknown')
            
            logger.info(f"Received webhook: {event_type}")
            
            if event_type == 'issues':
                self.handle_issue_event(data)
            elif event_type == 'issue_comment':
                self.handle_comment_event(data)
            elif event_type == 'push':
                self.handle_push_event(data)
            
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
            
        except Exception as e:
            logger.error(f"Webhook処理エラー: {e}")
            self.send_response(500)
            self.end_headers()
    
    def handle_issue_event(self, data):
        """Issue イベント処理"""
        action = data['action']
        issue = data['issue']
        issue_number = issue['number']
        
        if action == 'opened':
            # 新しいIssueの自動割り当て
            logger.info(f"新Issue #{issue_number} を自動割り当て")
            subprocess.run([
                '/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/tmux_github_bridge.sh',
                'assign', str(issue_number)
            ])
        elif action == 'closed':
            # Issueクローズ時の後処理
            logger.info(f"Issue #{issue_number} がクローズされました")
    
    def handle_comment_event(self, data):
        """コメント イベント処理"""
        action = data['action']
        issue = data['issue']
        comment = data['comment']
        
        if action == 'created':
            # AI組織への指示チェック
            comment_body = comment['body'].lower()
            issue_number = issue['number']
            
            if '@ai-organization' in comment_body:
                # AI組織への直接指示
                logger.info(f"AI組織への指示を検出: Issue #{issue_number}")
                # 適切なワーカーに転送
    
    def handle_push_event(self, data):
        """Push イベント処理"""
        commits = data['commits']
        for commit in commits:
            message = commit['message']
            # Issue番号抽出
            import re
            issue_refs = re.findall(r'#(\d+)', message)
            for issue_num in issue_refs:
                logger.info(f"Commit が Issue #{issue_num} を参照")

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8080), GitHubWebhookHandler)
    print("GitHub Webhook Server starting on http://localhost:8080")
    server.serve_forever()
EOF

    chmod +x "$GITHUB_CONFIG_DIR/webhook_server.py"
    
    # systemd service file (Linux用)
    cat > "$GITHUB_CONFIG_DIR/ai-github-webhook.service" << 'EOF'
[Unit]
Description=AI Organization GitHub Webhook Server
After=network.target

[Service]
Type=simple
User=dd
WorkingDirectory=/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/github
ExecStart=/usr/bin/python3 webhook_server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    log_success "✅ GitHub Webhooks設定完了"
}

# Claude Code MCP統合
integrate_claude_code_mcp() {
    log_info "🧠 Claude Code + MCP統合中..."
    
    # Claude Code設定拡張
    cat > "$MCP_CONFIG_DIR/claude_code_config.json" << 'EOF'
{
  "mcp": {
    "servers": {
      "github-ai-organization": {
        "command": "python3",
        "args": ["/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/mcp/tools/github_integration.py"],
        "env": {
          "GITHUB_TOKEN": "${GITHUB_TOKEN}",
          "PROJECT_ROOT": "/Users/dd/Desktop/1_dev/coding-rule2"
        }
      },
      "tmux-integration": {
        "command": "node",
        "args": ["/Users/dd/Desktop/1_dev/coding-rule2/ai-agents/mcp/tools/tmux_mcp.js"],
        "env": {
          "TMUX_SESSION": "multiagent"
        }
      }
    }
  },
  "tools": {
    "github": {
      "enabled": true,
      "auto_assign": true,
      "default_labels": ["ai-organization", "automated"]
    },
    "tmux": {
      "enabled": true,
      "auto_status_update": true,
      "status_interval": 30
    }
  }
}
EOF

    # tmux MCP ツール
    cat > "$MCP_CONFIG_DIR/tools/tmux_mcp.js" << 'EOF'
#!/usr/bin/env node
/**
 * tmux MCP Integration Tool
 * tmux操作をMCPプロトコル経由で提供
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

class TMUXMCPServer {
    constructor() {
        this.sessionName = process.env.TMUX_SESSION || 'multiagent';
    }

    async listPanes() {
        try {
            const { stdout } = await execAsync(`tmux list-panes -t ${this.sessionName} -F "#{pane_index}:#{pane_title}:#{pane_active}"`);
            return stdout.trim().split('\n').map(line => {
                const [index, title, active] = line.split(':');
                return { index, title, active: active === '1' };
            });
        } catch (error) {
            return { error: error.message };
        }
    }

    async sendToPane(paneIndex, message) {
        try {
            await execAsync(`tmux send-keys -t ${this.sessionName}:0.${paneIndex} "${message}" C-m`);
            return { success: true };
        } catch (error) {
            return { error: error.message };
        }
    }

    async capturePane(paneIndex) {
        try {
            const { stdout } = await execAsync(`tmux capture-pane -t ${this.sessionName}:0.${paneIndex} -p`);
            return { content: stdout };
        } catch (error) {
            return { error: error.message };
        }
    }

    async updatePaneTitle(paneIndex, title) {
        try {
            await execAsync(`tmux select-pane -t ${this.sessionName}:0.${paneIndex} -T "${title}"`);
            return { success: true };
        } catch (error) {
            return { error: error.message };
        }
    }

    async getWorkerStatus() {
        const panes = await this.listPanes();
        const workers = {
            boss: { pane: 0, status: 'unknown' },
            worker1: { pane: 1, status: 'unknown' },
            worker2: { pane: 2, status: 'unknown' },
            worker3: { pane: 3, status: 'unknown' }
        };

        for (const [workerId, worker] of Object.entries(workers)) {
            const content = await this.capturePane(worker.pane);
            if (content.content) {
                if (content.content.includes('Welcome to Claude Code') || content.content.includes('cwd:')) {
                    worker.status = 'active';
                } else if (content.content.includes('Bypassing Permissions')) {
                    worker.status = 'starting';
                } else {
                    worker.status = 'inactive';
                }
            }
        }

        return workers;
    }
}

// MCP Server Protocol Implementation
const server = new TMUXMCPServer();

process.stdin.on('data', async (data) => {
    try {
        const request = JSON.parse(data.toString());
        let response;

        switch (request.method) {
            case 'list_panes':
                response = await server.listPanes();
                break;
            case 'send_to_pane':
                response = await server.sendToPane(request.params.pane, request.params.message);
                break;
            case 'capture_pane':
                response = await server.capturePane(request.params.pane);
                break;
            case 'update_pane_title':
                response = await server.updatePaneTitle(request.params.pane, request.params.title);
                break;
            case 'get_worker_status':
                response = await server.getWorkerStatus();
                break;
            default:
                response = { error: 'Unknown method' };
        }

        console.log(JSON.stringify({
            jsonrpc: '2.0',
            id: request.id,
            result: response
        }));
    } catch (error) {
        console.log(JSON.stringify({
            jsonrpc: '2.0',
            id: request?.id || null,
            error: { code: -1, message: error.message }
        }));
    }
});

console.log(JSON.stringify({
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
        serverInfo: {
            name: 'tmux-mcp-server',
            version: '1.0.0'
        }
    }
}));
EOF

    chmod +x "$MCP_CONFIG_DIR/tools/tmux_mcp.js"
    
    log_success "✅ Claude Code MCP統合完了"
}

# 統合システム起動
start_integrated_system() {
    log_info "🚀 統合システム起動中..."
    
    # 1. tmuxセッション確認・作成
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_info "multiagentセッション作成中..."
        "$SCRIPT_DIR/manage.sh" start
    fi
    
    if ! tmux has-session -t president 2>/dev/null; then
        log_info "presidentセッション作成中..."
        tmux new-session -d -s president -c "$PROJECT_ROOT"
    fi
    
    # 2. GitHub CLI認証確認
    if ! gh auth status >/dev/null 2>&1; then
        log_warn "⚠️ GitHub CLI認証が必要です: gh auth login"
    fi
    
    # 3. MCP Serverバックグラウンド起動
    if ! pgrep -f "github_integration.py" >/dev/null; then
        log_info "MCP GitHub Server起動中..."
        python3 "$MCP_CONFIG_DIR/tools/github_integration.py" &
        echo $! > "$SCRIPT_DIR/logs/mcp_github_server.pid"
    fi
    
    if ! pgrep -f "tmux_mcp.js" >/dev/null; then
        log_info "MCP tmux Server起動中..."
        node "$MCP_CONFIG_DIR/tools/tmux_mcp.js" &
        echo $! > "$SCRIPT_DIR/logs/mcp_tmux_server.pid"
    fi
    
    # 4. Webhook Server起動
    if ! pgrep -f "webhook_server.py" >/dev/null; then
        log_info "GitHub Webhook Server起動中..."
        python3 "$GITHUB_CONFIG_DIR/webhook_server.py" &
        echo $! > "$SCRIPT_DIR/logs/webhook_server.pid"
    fi
    
    # 5. AI組織にMCP機能を通知
    for pane in 0 1 2 3; do
        if tmux capture-pane -t "multiagent:0.$pane" -p 2>/dev/null | grep -q "Welcome to Claude Code\|cwd:"; then
            tmux send-keys -t "multiagent:0.$pane" "echo '🔗 MCP統合システムが利用可能になりました。GitHub IssuesとtmuxがMCPプロトコル経由で統合されています。'" C-m
        fi
    done
    
    log_success "✅ 統合システム起動完了"
    
    # システム状況表示
    echo ""
    echo "🎯 AI組織 GitHub + MCP 統合システム"
    echo "=================================="
    echo ""
    echo "📊 システム状況:"
    echo "  - tmux Sessions: $(tmux list-sessions 2>/dev/null | wc -l) active"
    echo "  - MCP Servers: $(pgrep -f 'github_integration.py\|tmux_mcp.js' | wc -l) running"
    echo "  - Webhook Server: $(pgrep -f 'webhook_server.py' | wc -l) running"
    echo ""
    echo "🔧 利用可能なコマンド:"
    echo "  ./tmux_github_bridge.sh assign <issue_number>     # Issue割り当て"
    echo "  ./tmux_github_bridge.sh status                    # ワーカー状況"
    echo "  ./tmux_github_bridge.sh bulk-assign               # 一括割り当て"
    echo ""
    echo "🌐 Webhook URL: http://localhost:8080"
    echo "📋 システムログ: tail -f $INTEGRATION_LOG"
}

# システム停止
stop_integrated_system() {
    log_info "🛑 統合システム停止中..."
    
    # MCP Servers停止
    if [ -f "$SCRIPT_DIR/logs/mcp_github_server.pid" ]; then
        kill "$(cat "$SCRIPT_DIR/logs/mcp_github_server.pid")" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/logs/mcp_github_server.pid"
    fi
    
    if [ -f "$SCRIPT_DIR/logs/mcp_tmux_server.pid" ]; then
        kill "$(cat "$SCRIPT_DIR/logs/mcp_tmux_server.pid")" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/logs/mcp_tmux_server.pid"
    fi
    
    # Webhook Server停止
    if [ -f "$SCRIPT_DIR/logs/webhook_server.pid" ]; then
        kill "$(cat "$SCRIPT_DIR/logs/webhook_server.pid")" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/logs/webhook_server.pid"
    fi
    
    # プロセス強制停止
    pkill -f "github_integration.py" 2>/dev/null || true
    pkill -f "tmux_mcp.js" 2>/dev/null || true
    pkill -f "webhook_server.py" 2>/dev/null || true
    
    log_success "✅ 統合システム停止完了"
}

# デモ実行
run_demo() {
    log_info "🎭 統合システムデモ実行中..."
    
    echo "1. GitHub Issue作成デモ..."
    gh issue create \
        --title "🤖 AI組織統合システムのテスト" \
        --body "このIssueはAI組織統合システムのテスト用です。自動的にAIワーカーに割り当てられます。" \
        --label "demo,ai-organization"
    
    echo "2. Issue一覧取得..."
    gh issue list --state open --limit 5
    
    echo "3. ワーカー状況確認..."
    "$SCRIPT_DIR/tmux_github_bridge.sh" status
    
    echo "4. 未割り当てIssue自動割り当て..."
    "$SCRIPT_DIR/tmux_github_bridge.sh" bulk-assign
    
    log_success "✅ デモ実行完了"
}

# メイン実行
main() {
    echo "🚀 AI組織 GitHub Issues + MCP 統合システム"
    echo "============================================="
    echo ""
    
    case "${1:-help}" in
        "init")
            init_integration_system
            create_mcp_configuration
            create_tmux_github_integration
            setup_github_webhooks
            integrate_claude_code_mcp
            ;;
        "start")
            start_integrated_system
            ;;
        "stop")
            stop_integrated_system
            ;;
        "demo")
            run_demo
            ;;
        "status")
            echo "📊 システム状況:"
            echo "  - MCP Servers: $(pgrep -f 'github_integration.py\|tmux_mcp.js' | wc -l) running"
            echo "  - Webhook Server: $(pgrep -f 'webhook_server.py' | wc -l) running"
            echo "  - tmux Sessions: $(tmux list-sessions 2>/dev/null | wc -l) active"
            "$SCRIPT_DIR/tmux_github_bridge.sh" status
            ;;
        "help"|*)
            echo "使用方法:"
            echo "  $0 init     # 統合システム初期化"
            echo "  $0 start    # 統合システム起動"
            echo "  $0 stop     # 統合システム停止"
            echo "  $0 demo     # デモ実行"
            echo "  $0 status   # システム状況確認"
            echo ""
            echo "統合機能:"
            echo "  - GitHub Issues ↔ tmux panes 自動連携"
            echo "  - MCP プロトコル統合"
            echo "  - 4ワーカー並列Issue処理"
            echo "  - リアルタイム進捗追跡"
            echo "  - Webhook自動化"
            ;;
    esac
}

# ログディレクトリ作成
mkdir -p "$SCRIPT_DIR/logs"

# スクリプト実行
main "$@"