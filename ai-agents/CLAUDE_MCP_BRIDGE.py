#!/usr/bin/env python3
"""
Claude Code + MCP統合ブリッジシステム
AI組織とMCPプロトコルの高度統合
"""

import asyncio
import json
import subprocess
import websockets
import aiohttp
import logging
from datetime import datetime
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, asdict
from pathlib import Path
import os

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class MCPMessage:
    """MCP プロトコルメッセージ"""
    jsonrpc: str = "2.0"
    id: Optional[str] = None
    method: Optional[str] = None
    params: Optional[Dict] = None
    result: Optional[Any] = None
    error: Optional[Dict] = None

@dataclass
class AIWorker:
    """AI ワーカー状態"""
    worker_id: str
    tmux_pane: str
    specialization: str
    status: str = "idle"
    current_issue: Optional[int] = None
    mcp_session: Optional[str] = None
    last_activity: datetime = None

class ClaudeMCPBridge:
    """Claude Code と MCP の統合ブリッジ"""
    
    def __init__(self, project_root: str = "/Users/dd/Desktop/1_dev/coding-rule2"):
        self.project_root = Path(project_root)
        self.ai_agents_dir = self.project_root / "ai-agents"
        self.workers: Dict[str, AIWorker] = {}
        self.mcp_servers: Dict[str, subprocess.Popen] = {}
        self.websocket_connections: Dict[str, websockets.WebSocketServerProtocol] = {}
        self.message_handlers: Dict[str, Callable] = {}
        
        # ワーカー初期化
        self._init_workers()
        self._setup_message_handlers()
    
    def _init_workers(self):
        """AI ワーカー初期化"""
        worker_configs = {
            "boss": AIWorker("boss", "multiagent:0.0", "management"),
            "worker1": AIWorker("worker1", "multiagent:0.1", "frontend"),
            "worker2": AIWorker("worker2", "multiagent:0.2", "backend"),
            "worker3": AIWorker("worker3", "multiagent:0.3", "ui_ux")
        }
        
        for worker_id, worker in worker_configs.items():
            worker.last_activity = datetime.now()
            self.workers[worker_id] = worker
        
        logger.info(f"AI ワーカー初期化完了: {len(self.workers)}個")
    
    def _setup_message_handlers(self):
        """MCP メッセージハンドラー設定"""
        self.message_handlers = {
            "initialize": self._handle_initialize,
            "github/list_issues": self._handle_list_issues,
            "github/create_issue": self._handle_create_issue,
            "github/assign_issue": self._handle_assign_issue,
            "github/update_progress": self._handle_update_progress,
            "tmux/send_to_pane": self._handle_send_to_pane,
            "tmux/capture_pane": self._handle_capture_pane,
            "tmux/update_title": self._handle_update_title,
            "workflow/start_parallel": self._handle_start_parallel,
            "workflow/monitor_progress": self._handle_monitor_progress,
            "ai_org/get_status": self._handle_get_ai_status,
            "ai_org/optimize_assignment": self._handle_optimize_assignment
        }
    
    async def start_mcp_server(self, port: int = 8765):
        """MCP WebSocket サーバー起動"""
        logger.info(f"MCP Bridge Server starting on port {port}")
        
        async def handle_client(websocket, path):
            try:
                client_id = f"client_{len(self.websocket_connections)}"
                self.websocket_connections[client_id] = websocket
                logger.info(f"New MCP client connected: {client_id}")
                
                async for message in websocket:
                    await self._handle_mcp_message(client_id, message)
                    
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"MCP client disconnected: {client_id}")
            except Exception as e:
                logger.error(f"MCP client error: {e}")
            finally:
                if client_id in self.websocket_connections:
                    del self.websocket_connections[client_id]
        
        return await websockets.serve(handle_client, "localhost", port)
    
    async def _handle_mcp_message(self, client_id: str, message_text: str):
        """MCP メッセージ処理"""
        try:
            message_data = json.loads(message_text)
            mcp_msg = MCPMessage(**message_data)
            
            logger.info(f"MCP Message: {mcp_msg.method} from {client_id}")
            
            # メソッド処理
            if mcp_msg.method in self.message_handlers:
                result = await self.message_handlers[mcp_msg.method](mcp_msg.params or {})
                
                # レスポンス送信
                response = MCPMessage(
                    id=mcp_msg.id,
                    result=result
                )
                
                await self.websocket_connections[client_id].send(
                    json.dumps(asdict(response), default=str)
                )
            else:
                # 未知のメソッド
                error_response = MCPMessage(
                    id=mcp_msg.id,
                    error={
                        "code": -32601,
                        "message": f"Method not found: {mcp_msg.method}"
                    }
                )
                await self.websocket_connections[client_id].send(
                    json.dumps(asdict(error_response))
                )
                
        except Exception as e:
            logger.error(f"MCP message processing error: {e}")
    
    # === MCP メッセージハンドラー ===
    
    async def _handle_initialize(self, params: Dict) -> Dict:
        """MCP 初期化"""
        return {
            "capabilities": {
                "tools": [
                    "github/list_issues", "github/create_issue", "github/assign_issue",
                    "tmux/send_to_pane", "tmux/capture_pane", "tmux/update_title",
                    "workflow/start_parallel", "workflow/monitor_progress",
                    "ai_org/get_status", "ai_org/optimize_assignment"
                ],
                "contexts": ["ai_organization", "github_integration", "tmux_control"]
            },
            "serverInfo": {
                "name": "claude-mcp-bridge",
                "version": "1.0.0"
            }
        }
    
    async def _handle_list_issues(self, params: Dict) -> Dict:
        """GitHub Issues 一覧取得"""
        try:
            cmd = ["gh", "issue", "list", "--json", "number,title,labels,assignees,state"]
            
            # フィルター適用
            if params.get("assignee"):
                cmd.extend(["--assignee", params["assignee"]])
            if params.get("state"):
                cmd.extend(["--state", params["state"]])
            if params.get("labels"):
                cmd.extend(["--label", ",".join(params["labels"])])
            
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
    
    async def _handle_create_issue(self, params: Dict) -> Dict:
        """GitHub Issue 作成"""
        try:
            cmd = ["gh", "issue", "create", 
                   "--title", params["title"],
                   "--body", params["body"]]
            
            if params.get("labels"):
                cmd.extend(["--label", ",".join(params["labels"])])
            if params.get("assignees"):
                for assignee in params["assignees"]:
                    cmd.extend(["--assignee", assignee])
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                issue_url = result.stdout.strip()
                issue_number = int(issue_url.split('/')[-1])
                return {
                    "success": True,
                    "issue_number": issue_number,
                    "url": issue_url
                }
            else:
                return {"success": False, "error": result.stderr}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_assign_issue(self, params: Dict) -> Dict:
        """Issue を AI ワーカーに割り当て"""
        try:
            issue_number = params["issue_number"]
            worker_id = params.get("worker_id")
            
            # 最適ワーカー自動選択
            if not worker_id:
                worker_id = await self._select_optimal_worker(issue_number)
            
            if worker_id not in self.workers:
                return {"success": False, "error": f"Invalid worker: {worker_id}"}
            
            worker = self.workers[worker_id]
            
            # ワーカー状態更新
            worker.status = "working"
            worker.current_issue = issue_number
            worker.last_activity = datetime.now()
            
            # tmux ペインに Issue 送信
            await self._send_issue_to_worker(worker, issue_number)
            
            # GitHub コメント追加
            await self._add_assignment_comment(issue_number, worker)
            
            return {
                "success": True,
                "worker_id": worker_id,
                "tmux_pane": worker.tmux_pane,
                "issue_number": issue_number
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_send_to_pane(self, params: Dict) -> Dict:
        """tmux ペインにメッセージ送信"""
        try:
            pane = params["pane"]
            message = params["message"]
            
            cmd = ["tmux", "send-keys", "-t", pane, message, "C-m"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return {"success": result.returncode == 0}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_capture_pane(self, params: Dict) -> Dict:
        """tmux ペイン内容取得"""
        try:
            pane = params["pane"]
            
            cmd = ["tmux", "capture-pane", "-t", pane, "-p"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return {"success": True, "content": result.stdout}
            else:
                return {"success": False, "error": result.stderr}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_start_parallel(self, params: Dict) -> Dict:
        """並列ワークフロー開始"""
        try:
            issues = params.get("issues", [])
            
            if not issues:
                # 未割り当てIssueを自動取得
                issues_result = await self._handle_list_issues({
                    "state": "open",
                    "assignee": ""
                })
                if issues_result["success"]:
                    issues = [issue["number"] for issue in issues_result["issues"][:4]]
            
            # 各ワーカーに並列割り当て
            assignments = []
            available_workers = [w for w in self.workers.values() if w.status == "idle"]
            
            for i, issue_number in enumerate(issues):
                if i < len(available_workers):
                    worker = available_workers[i]
                    assignment_result = await self._handle_assign_issue({
                        "issue_number": issue_number,
                        "worker_id": worker.worker_id
                    })
                    assignments.append(assignment_result)
            
            return {
                "success": True,
                "assignments": assignments,
                "parallel_count": len(assignments)
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_get_ai_status(self, params: Dict) -> Dict:
        """AI 組織状況取得"""
        try:
            status = {}
            
            for worker_id, worker in self.workers.items():
                # tmux ペイン活動状況確認
                pane_result = await self._handle_capture_pane({"pane": worker.tmux_pane})
                pane_active = False
                
                if pane_result["success"]:
                    content = pane_result["content"]
                    pane_active = "Welcome to Claude Code" in content or "cwd:" in content
                
                status[worker_id] = {
                    "specialization": worker.specialization,
                    "status": worker.status,
                    "current_issue": worker.current_issue,
                    "tmux_pane": worker.tmux_pane,
                    "pane_active": pane_active,
                    "last_activity": worker.last_activity.isoformat()
                }
            
            return {"success": True, "workers": status}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    # === ヘルパーメソッド ===
    
    async def _select_optimal_worker(self, issue_number: int) -> str:
        """Issue に最適なワーカーを AI 選択"""
        try:
            # Issue 詳細取得
            cmd = ["gh", "issue", "view", str(issue_number), "--json", "title,body,labels"]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode != 0:
                return "boss"  # デフォルト
            
            issue_data = json.loads(result.stdout)
            title = issue_data["title"].lower()
            body = issue_data["body"].lower()
            labels = [label["name"].lower() for label in issue_data["labels"]]
            
            # ラベルベース判定
            if any(label in ["frontend", "ui", "ux", "react", "vue"] for label in labels):
                return "worker1"
            elif any(label in ["backend", "api", "database", "server"] for label in labels):
                return "worker2"
            elif any(label in ["design", "wireframe", "mockup"] for label in labels):
                return "worker3"
            
            # タイトル・本文ベース判定
            content = f"{title} {body}"
            if any(keyword in content for keyword in ["frontend", "ui", "component", "style"]):
                return "worker1"
            elif any(keyword in content for keyword in ["backend", "api", "database", "server"]):
                return "worker2"
            elif any(keyword in content for keyword in ["design", "user experience", "wireframe"]):
                return "worker3"
            
            return "boss"  # デフォルト（管理・調整）
            
        except Exception as e:
            logger.error(f"Worker selection error: {e}")
            return "boss"
    
    async def _send_issue_to_worker(self, worker: AIWorker, issue_number: int):
        """ワーカーに Issue を送信"""
        try:
            # Issue 詳細取得
            cmd = ["gh", "issue", "view", str(issue_number), "--json", "title,body,labels"]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode != 0:
                return
            
            issue_data = json.loads(result.stdout)
            
            # AI 指示文生成
            prompt = f"""🎯 **MCP統合 Issue割り当て**

**Issue #{issue_number}: {issue_data['title']}**

**説明:**
{issue_data['body']}

**ラベル:** {', '.join([label['name'] for label in issue_data['labels']])}
**専門分野:** {worker.specialization}

**MCP プロトコル利用可能:**
- GitHub操作: gh issue comment {issue_number} --body "進捗報告"
- tmux統合: ペイン間連携可能
- 並列処理: 他のワーカーと協調動作

**指示:**
1. Issue を分析し実装計画を立案
2. 段階的実装とテスト実行
3. 定期的な進捗報告
4. 完了時の自動クローズ

MCP統合システムで効率的に作業を進めてください。"""

            # tmux ペインに送信
            await self._handle_send_to_pane({
                "pane": worker.tmux_pane,
                "message": prompt
            })
            
            # ペイン タイトル更新
            await self._handle_update_title({
                "pane": worker.tmux_pane,
                "title": f"🔥作業中 {worker.specialization} │ Issue #{issue_number}"
            })
            
        except Exception as e:
            logger.error(f"Send issue to worker error: {e}")
    
    async def _add_assignment_comment(self, issue_number: int, worker: AIWorker):
        """GitHub Issue に割り当てコメント追加"""
        try:
            comment = f"""🤖 **AI組織 MCP統合システム割り当て**

- **担当AI:** {worker.worker_id.upper()} ({worker.specialization})
- **TMUXペイン:** `{worker.tmux_pane}`
- **割り当て時刻:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **統合プロトコル:** MCP + Claude Code

このIssueはAI組織システムで並列処理されます。
進捗はリアルタイムで追跡・報告されます。"""

            cmd = ["gh", "issue", "comment", str(issue_number), "--body", comment]
            subprocess.run(cmd, cwd=self.project_root)
            
        except Exception as e:
            logger.error(f"Add assignment comment error: {e}")
    
    async def _handle_update_title(self, params: Dict) -> Dict:
        """tmux ペイン タイトル更新"""
        try:
            pane = params["pane"]
            title = params["title"]
            
            cmd = ["tmux", "select-pane", "-t", pane, "-T", title]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return {"success": result.returncode == 0}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_update_progress(self, params: Dict) -> Dict:
        """進捗更新処理"""
        try:
            issue_number = params["issue_number"]
            worker_id = params["worker_id"]
            progress_type = params.get("progress_type", "progress")
            
            worker = self.workers.get(worker_id)
            if not worker:
                return {"success": False, "error": f"Worker not found: {worker_id}"}
            
            # ペイン内容取得
            pane_result = await self._handle_capture_pane({"pane": worker.tmux_pane})
            pane_content = pane_result.get("content", "")[-500:]  # 最新500文字
            
            # 進捗コメント作成
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            if progress_type == "complete":
                comment = f"""✅ **作業完了報告**

**担当AI:** {worker_id.upper()}
**完了時刻:** {timestamp}

Issue #{issue_number} の処理が完了しました。
MCP統合システムによる自動処理が正常に終了しています。"""
                
                # ワーカー状態リセット
                worker.status = "idle"
                worker.current_issue = None
                
                # ペイン タイトル リセット
                await self._handle_update_title({
                    "pane": worker.tmux_pane,
                    "title": f"🟡待機中 {worker.specialization}"
                })
                
            else:
                comment = f"""📊 **進捗報告**

**担当AI:** {worker_id.upper()}
**報告時刻:** {timestamp}

最新の作業状況:
```
{pane_content}
```"""
            
            # GitHub コメント追加
            cmd = ["gh", "issue", "comment", str(issue_number), "--body", comment]
            result = subprocess.run(cmd, cwd=self.project_root)
            
            return {"success": result.returncode == 0}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_monitor_progress(self, params: Dict) -> Dict:
        """進捗監視"""
        try:
            active_workers = {
                worker_id: worker for worker_id, worker in self.workers.items()
                if worker.status == "working"
            }
            
            progress_report = {
                "timestamp": datetime.now().isoformat(),
                "active_workers": len(active_workers),
                "workers": {}
            }
            
            for worker_id, worker in active_workers.items():
                # ペイン活動確認
                pane_result = await self._handle_capture_pane({"pane": worker.tmux_pane})
                
                progress_report["workers"][worker_id] = {
                    "current_issue": worker.current_issue,
                    "specialization": worker.specialization,
                    "last_activity": worker.last_activity.isoformat(),
                    "pane_active": pane_result["success"]
                }
            
            return {"success": True, "progress": progress_report}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _handle_optimize_assignment(self, params: Dict) -> Dict:
        """AI 駆動最適割り当て"""
        try:
            # 開いているIssueを分析
            issues_result = await self._handle_list_issues({"state": "open"})
            if not issues_result["success"]:
                return issues_result
            
            issues = issues_result["issues"]
            optimized_assignments = []
            
            # 各Issueの最適ワーカー計算
            for issue in issues:
                if not issue.get("assignees"):  # 未割り当てのみ
                    optimal_worker = await self._select_optimal_worker(issue["number"])
                    
                    # ワーカーが利用可能か確認
                    if self.workers[optimal_worker].status == "idle":
                        optimized_assignments.append({
                            "issue_number": issue["number"],
                            "optimal_worker": optimal_worker,
                            "confidence": 0.85,  # 簡易信頼度
                            "reason": f"Specialized in {self.workers[optimal_worker].specialization}"
                        })
            
            return {
                "success": True,
                "optimized_assignments": optimized_assignments,
                "total_analyzed": len(issues),
                "optimization_suggestions": len(optimized_assignments)
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}

# メイン実行
async def main():
    """メインエントリーポイント"""
    bridge = ClaudeMCPBridge()
    
    logger.info("🚀 Claude Code + MCP統合ブリッジシステム起動中...")
    
    # MCP WebSocket サーバー起動
    server = await bridge.start_mcp_server(8765)
    
    logger.info("🔗 MCP Bridge Server is running on ws://localhost:8765")
    logger.info("📊 AI組織システム統合完了")
    
    # サーバー実行継続
    await server.wait_closed()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 MCP Bridge Server停止中...")
    except Exception as e:
        logger.error(f"Fatal error: {e}")