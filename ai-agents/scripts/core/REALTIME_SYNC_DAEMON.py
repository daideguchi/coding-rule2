#!/usr/bin/env python3
"""
リアルタイム Issue 同期デーモン
GitHub Issues ↔ AI組織システム ↔ tmux の完全同期
"""

import asyncio
import json
import aiofiles
import subprocess
import websockets
import aiohttp
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from pathlib import Path
import logging
import signal
import sys

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class SyncEvent:
    """同期イベント"""
    event_id: str
    timestamp: datetime
    source: str  # github, tmux, ai_org
    event_type: str  # issue_created, issue_assigned, worker_progress, etc.
    data: Dict[str, Any]

@dataclass
class WorkerSync:
    """ワーカー同期状態"""
    worker_id: str
    tmux_pane: str
    github_assignee: Optional[str]
    current_issue: Optional[int]
    last_sync: datetime
    status: str
    pending_updates: List[str]

class RealtimeSyncDaemon:
    """リアルタイム同期デーモン"""
    
    def __init__(self, project_root: str = None):
        if project_root is None:
            # 動的にプロジェクトルートを取得
            script_dir = Path(__file__).parent
            self.project_root = script_dir.parent.parent.parent
        else:
            self.project_root = Path(project_root)
        self.ai_agents_dir = self.project_root / "ai-agents"
        self.sync_state_file = self.ai_agents_dir / "sync_state.json"
        self.event_log_file = self.ai_agents_dir / "logs" / "sync_events.jsonl"
        
        # 同期状態
        self.workers: Dict[str, WorkerSync] = {}
        self.sync_interval = 5  # 秒
        self.github_poll_interval = 30  # 秒
        self.running = True
        
        # WebSocket 接続
        self.mcp_connection: Optional[websockets.WebSocketClientProtocol] = None
        
        # イベントキュー
        self.event_queue: asyncio.Queue = asyncio.Queue()
        
        # 初期化
        self._init_sync_state()
    
    def _init_sync_state(self):
        """同期状態初期化"""
        worker_configs = {
            "boss": WorkerSync("boss", "multiagent:0.0", None, None, datetime.now(), "idle", []),
            "worker1": WorkerSync("worker1", "multiagent:0.1", None, None, datetime.now(), "idle", []),
            "worker2": WorkerSync("worker2", "multiagent:0.2", None, None, datetime.now(), "idle", []),
            "worker3": WorkerSync("worker3", "multiagent:0.3", None, None, datetime.now(), "idle", [])
        }
        
        self.workers = worker_configs
        logger.info(f"同期状態初期化完了: {len(self.workers)}ワーカー")
    
    async def start(self):
        """デーモン開始"""
        logger.info("🔄 リアルタイム同期デーモン開始")
        
        # 並列タスク開始
        tasks = [
            asyncio.create_task(self._sync_loop()),
            asyncio.create_task(self._github_polling_loop()),
            asyncio.create_task(self._tmux_monitoring_loop()),
            asyncio.create_task(self._event_processing_loop()),
            asyncio.create_task(self._mcp_bridge_connection()),
            asyncio.create_task(self._periodic_state_save())
        ]
        
        try:
            # シグナルハンドラ設定
            signal.signal(signal.SIGINT, self._signal_handler)
            signal.signal(signal.SIGTERM, self._signal_handler)
            
            await asyncio.gather(*tasks)
        except asyncio.CancelledError:
            logger.info("🛑 同期デーモン停止中...")
        finally:
            await self._cleanup()
    
    def _signal_handler(self, signum, frame):
        """シグナルハンドラ"""
        logger.info(f"シグナル受信: {signum}")
        self.running = False
        
        # 現在実行中のタスクをキャンセル
        for task in asyncio.all_tasks():
            if not task.done():
                task.cancel()
    
    async def _sync_loop(self):
        """メイン同期ループ"""
        while self.running:
            try:
                await self._perform_sync_cycle()
                await asyncio.sleep(self.sync_interval)
            except Exception as e:
                logger.error(f"同期サイクルエラー: {e}")
                await asyncio.sleep(5)  # エラー時は少し長めに待機
    
    async def _perform_sync_cycle(self):
        """同期サイクル実行"""
        logger.debug("🔄 同期サイクル実行中...")
        
        # 1. tmux ペイン状態チェック
        await self._sync_tmux_state()
        
        # 2. GitHub Issue 状態チェック
        await self._sync_github_state()
        
        # 3. 差分検出と同期
        await self._resolve_sync_conflicts()
        
        # 4. ステータス更新
        await self._update_all_statuses()
    
    async def _sync_tmux_state(self):
        """tmux 状態同期"""
        try:
            for worker_id, worker in self.workers.items():
                # ペイン内容取得
                cmd = ["tmux", "capture-pane", "-t", worker.tmux_pane, "-p"]
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    pane_content = result.stdout
                    
                    # ステータス判定
                    new_status = self._analyze_pane_content(pane_content)
                    
                    # Issue番号抽出
                    current_issue = self._extract_issue_from_content(pane_content)
                    
                    # 変更検出
                    if (worker.status != new_status or 
                        worker.current_issue != current_issue):
                        
                        # 同期イベント作成
                        event = SyncEvent(
                            event_id=f"tmux_{worker_id}_{datetime.now().timestamp()}",
                            timestamp=datetime.now(),
                            source="tmux",
                            event_type="worker_status_change",
                            data={
                                "worker_id": worker_id,
                                "old_status": worker.status,
                                "new_status": new_status,
                                "old_issue": worker.current_issue,
                                "new_issue": current_issue
                            }
                        )
                        
                        await self.event_queue.put(event)
                        
                        # 状態更新
                        worker.status = new_status
                        worker.current_issue = current_issue
                        worker.last_sync = datetime.now()
                        
        except Exception as e:
            logger.error(f"tmux状態同期エラー: {e}")
    
    def _analyze_pane_content(self, content: str) -> str:
        """ペイン内容からステータス分析"""
        content_lower = content.lower()
        
        if any(keyword in content_lower for keyword in 
               ["stewing", "brewing", "doing", "working", "processing"]):
            return "working"
        elif any(keyword in content_lower for keyword in 
                ["completed", "finished", "done", "success"]):
            return "completed"
        elif any(keyword in content_lower for keyword in 
                ["error", "failed", "issue", "problem"]):
            return "error"
        elif "welcome to claude code" in content_lower or "cwd:" in content_lower:
            return "active"
        else:
            return "idle"
    
    def _extract_issue_from_content(self, content: str) -> Optional[int]:
        """内容からIssue番号抽出"""
        import re
        matches = re.findall(r'Issue #(\d+)', content)
        return int(matches[-1]) if matches else None
    
    async def _sync_github_state(self):
        """GitHub 状態同期"""
        try:
            # 最近更新されたIssueを取得
            cmd = ["gh", "issue", "list", "--state", "all", "--limit", "50", 
                   "--json", "number,title,assignees,state,updatedAt"]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                issues = json.loads(result.stdout)
                
                for issue in issues:
                    issue_number = issue["number"]
                    assignees = [a["login"] for a in issue["assignees"]]
                    
                    # AI組織ワーカーへの割り当て検出
                    for worker_id, worker in self.workers.items():
                        # GitHubアサイニーとワーカーのマッピング確認
                        if self._is_assigned_to_worker(assignees, worker_id):
                            if worker.current_issue != issue_number:
                                # 新しい割り当て検出
                                event = SyncEvent(
                                    event_id=f"github_{issue_number}_{datetime.now().timestamp()}",
                                    timestamp=datetime.now(),
                                    source="github",
                                    event_type="issue_assigned",
                                    data={
                                        "issue_number": issue_number,
                                        "worker_id": worker_id,
                                        "assignees": assignees
                                    }
                                )
                                await self.event_queue.put(event)
                        
                        # 割り当て解除検出
                        elif worker.current_issue == issue_number and not assignees:
                            event = SyncEvent(
                                event_id=f"github_unassign_{issue_number}_{datetime.now().timestamp()}",
                                timestamp=datetime.now(),
                                source="github",
                                event_type="issue_unassigned",
                                data={
                                    "issue_number": issue_number,
                                    "worker_id": worker_id
                                }
                            )
                            await self.event_queue.put(event)
                            
        except Exception as e:
            logger.error(f"GitHub状態同期エラー: {e}")
    
    def _is_assigned_to_worker(self, assignees: List[str], worker_id: str) -> bool:
        """GitHubアサイニーがワーカーに対応するか判定"""
        # AI組織ユーザー名マッピング
        ai_user_mapping = {
            "boss": ["ai-boss", "boss-ai", "ai-organization-boss"],
            "worker1": ["ai-worker1", "frontend-ai", "ai-frontend"],
            "worker2": ["ai-worker2", "backend-ai", "ai-backend"],
            "worker3": ["ai-worker3", "design-ai", "ai-design"]
        }
        
        mapped_users = ai_user_mapping.get(worker_id, [])
        return any(assignee in mapped_users for assignee in assignees)
    
    async def _github_polling_loop(self):
        """GitHub ポーリングループ"""
        while self.running:
            try:
                await self._poll_github_events()
                await asyncio.sleep(self.github_poll_interval)
            except Exception as e:
                logger.error(f"GitHubポーリングエラー: {e}")
                await asyncio.sleep(10)
    
    async def _poll_github_events(self):
        """GitHub イベントポーリング"""
        try:
            # 最近のIssueイベント取得（gh コマンド拡張が必要）
            # 簡易実装: 最近更新されたIssueをチェック
            
            cutoff_time = datetime.now() - timedelta(minutes=5)
            cmd = ["gh", "issue", "list", "--state", "all", 
                   "--json", "number,updatedAt,state,assignees"]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                issues = json.loads(result.stdout)
                
                for issue in issues:
                    updated_at = datetime.fromisoformat(issue["updatedAt"].replace('Z', '+00:00'))
                    
                    if updated_at > cutoff_time:
                        # 最近更新されたIssue
                        event = SyncEvent(
                            event_id=f"github_update_{issue['number']}_{datetime.now().timestamp()}",
                            timestamp=datetime.now(),
                            source="github",
                            event_type="issue_updated",
                            data=issue
                        )
                        await self.event_queue.put(event)
                        
        except Exception as e:
            logger.error(f"GitHubイベントポーリングエラー: {e}")
    
    async def _tmux_monitoring_loop(self):
        """tmux 監視ループ"""
        while self.running:
            try:
                await self._monitor_tmux_changes()
                await asyncio.sleep(3)  # より頻繁な監視
            except Exception as e:
                logger.error(f"tmux監視エラー: {e}")
                await asyncio.sleep(5)
    
    async def _monitor_tmux_changes(self):
        """tmux 変更監視"""
        try:
            # 各ペインのタイトル変更を監視
            for worker_id, worker in self.workers.items():
                cmd = ["tmux", "display-message", "-t", worker.tmux_pane, "-p", "#{pane_title}"]
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    current_title = result.stdout.strip()
                    
                    # タイトルからステータス・Issue番号抽出
                    new_status, issue_number = self._parse_pane_title(current_title)
                    
                    # 変更検出
                    if worker.status != new_status or worker.current_issue != issue_number:
                        event = SyncEvent(
                            event_id=f"tmux_title_{worker_id}_{datetime.now().timestamp()}",
                            timestamp=datetime.now(),
                            source="tmux",
                            event_type="pane_title_change",
                            data={
                                "worker_id": worker_id,
                                "old_status": worker.status,
                                "new_status": new_status,
                                "old_issue": worker.current_issue,
                                "new_issue": issue_number,
                                "title": current_title
                            }
                        )
                        await self.event_queue.put(event)
                        
        except Exception as e:
            logger.error(f"tmux変更監視エラー: {e}")
    
    def _parse_pane_title(self, title: str) -> tuple:
        """ペインタイトルからステータスとIssue番号を解析"""
        import re
        
        # ステータス判定
        if "🔥作業中" in title:
            status = "working"
        elif "🟢完了" in title:
            status = "completed"
        elif "🔴エラー" in title:
            status = "error"
        elif "🟡待機中" in title:
            status = "idle"
        else:
            status = "unknown"
        
        # Issue番号抽出
        issue_match = re.search(r'Issue #(\d+)', title)
        issue_number = int(issue_match.group(1)) if issue_match else None
        
        return status, issue_number
    
    async def _event_processing_loop(self):
        """イベント処理ループ"""
        while self.running:
            try:
                # イベント取得（タイムアウト付き）
                event = await asyncio.wait_for(self.event_queue.get(), timeout=1.0)
                await self._process_sync_event(event)
                await self._log_sync_event(event)
            except asyncio.TimeoutError:
                # タイムアウトは正常（イベントがない状態）
                continue
            except Exception as e:
                logger.error(f"イベント処理エラー: {e}")
    
    async def _process_sync_event(self, event: SyncEvent):
        """同期イベント処理"""
        logger.info(f"同期イベント処理: {event.event_type} from {event.source}")
        
        try:
            if event.event_type == "issue_assigned":
                await self._handle_issue_assignment(event)
            elif event.event_type == "worker_status_change":
                await self._handle_worker_status_change(event)
            elif event.event_type == "issue_updated":
                await self._handle_issue_update(event)
            elif event.event_type == "pane_title_change":
                await self._handle_pane_title_change(event)
            else:
                logger.debug(f"未処理イベントタイプ: {event.event_type}")
                
        except Exception as e:
            logger.error(f"イベント処理エラー ({event.event_type}): {e}")
    
    async def _handle_issue_assignment(self, event: SyncEvent):
        """Issue割り当てイベント処理"""
        data = event.data
        worker_id = data["worker_id"]
        issue_number = data["issue_number"]
        
        worker = self.workers.get(worker_id)
        if not worker:
            return
        
        # tmux ペインに Issue 情報送信
        await self._send_issue_to_tmux_pane(worker.tmux_pane, issue_number)
        
        # ワーカー状態更新
        worker.current_issue = issue_number
        worker.status = "working"
        worker.last_sync = datetime.now()
        
        logger.info(f"Issue #{issue_number} を {worker_id} に同期割り当て")
    
    async def _handle_worker_status_change(self, event: SyncEvent):
        """ワーカーステータス変更イベント処理"""
        data = event.data
        worker_id = data["worker_id"]
        new_status = data["new_status"]
        new_issue = data.get("new_issue")
        
        # GitHub側への同期が必要か判定
        if new_status == "completed" and new_issue:
            # Issue完了をGitHubに同期
            await self._sync_completion_to_github(new_issue, worker_id)
        elif new_status == "working" and new_issue:
            # 進捗をGitHubに同期
            await self._sync_progress_to_github(new_issue, worker_id)
    
    async def _handle_issue_update(self, event: SyncEvent):
        """Issue更新イベント処理"""
        issue_data = event.data
        issue_number = issue_data["number"]
        
        # 該当ワーカーを特定
        assigned_worker = None
        for worker in self.workers.values():
            if worker.current_issue == issue_number:
                assigned_worker = worker
                break
        
        if assigned_worker:
            # tmux ペインにも更新を反映
            await self._update_tmux_pane_for_issue(assigned_worker.tmux_pane, issue_number)
    
    async def _handle_pane_title_change(self, event: SyncEvent):
        """ペインタイトル変更イベント処理"""
        data = event.data
        worker_id = data["worker_id"]
        new_status = data["new_status"]
        new_issue = data.get("new_issue")
        
        worker = self.workers.get(worker_id)
        if worker:
            worker.status = new_status
            worker.current_issue = new_issue
            worker.last_sync = datetime.now()
    
    async def _send_issue_to_tmux_pane(self, tmux_pane: str, issue_number: int):
        """tmux ペインに Issue 情報送信"""
        try:
            # Issue詳細取得
            cmd = ["gh", "issue", "view", str(issue_number), "--json", "title,body"]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                issue_data = json.loads(result.stdout)
                
                prompt = f"""🔄 **リアルタイム同期 Issue 割り当て**

Issue #{issue_number}: {issue_data['title']}

{issue_data['body']}

このIssueはリアルタイム同期システムから割り当てられました。
進捗は自動的にGitHubと同期されます。"""

                # tmux ペインに送信
                cmd_send = ["tmux", "send-keys", "-t", tmux_pane, prompt, "C-m"]
                subprocess.run(cmd_send)
                
        except Exception as e:
            logger.error(f"tmux ペイン送信エラー: {e}")
    
    async def _sync_completion_to_github(self, issue_number: int, worker_id: str):
        """完了状態をGitHubに同期"""
        try:
            comment = f"""✅ **AI組織システム完了報告**

{worker_id.upper()} がIssue #{issue_number} の処理を完了しました。

- 完了時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- リアルタイム同期システムによる自動報告

このIssueをクローズします。"""

            cmd = ["gh", "issue", "comment", str(issue_number), "--body", comment]
            subprocess.run(cmd, cwd=self.project_root)
            
            cmd_close = ["gh", "issue", "close", str(issue_number)]
            subprocess.run(cmd_close, cwd=self.project_root)
            
            logger.info(f"Issue #{issue_number} 完了をGitHubに同期")
            
        except Exception as e:
            logger.error(f"GitHub完了同期エラー: {e}")
    
    async def _sync_progress_to_github(self, issue_number: int, worker_id: str):
        """進捗をGitHubに同期"""
        try:
            comment = f"""📊 **自動進捗報告**

{worker_id.upper()} がIssue #{issue_number} を処理中です。

- 報告時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- リアルタイム同期システムによる自動報告

進捗は継続的に監視・同期されています。"""

            cmd = ["gh", "issue", "comment", str(issue_number), "--body", comment]
            subprocess.run(cmd, cwd=self.project_root)
            
        except Exception as e:
            logger.error(f"GitHub進捗同期エラー: {e}")
    
    async def _update_tmux_pane_for_issue(self, tmux_pane: str, issue_number: int):
        """Issue更新をtmux ペインに反映"""
        try:
            # ペインタイトル更新
            cmd = ["tmux", "select-pane", "-t", tmux_pane, "-T", 
                   f"🔄同期更新 │ Issue #{issue_number}"]
            subprocess.run(cmd)
            
        except Exception as e:
            logger.error(f"tmux ペイン更新エラー: {e}")
    
    async def _mcp_bridge_connection(self):
        """MCP ブリッジ接続維持"""
        while self.running:
            try:
                if not self.mcp_connection or self.mcp_connection.closed:
                    # MCP ブリッジに接続
                    self.mcp_connection = await websockets.connect("ws://localhost:8765")
                    logger.info("🔗 MCP ブリッジに接続")
                
                # 定期的にステータス同期
                await self._sync_with_mcp_bridge()
                await asyncio.sleep(10)
                
            except (websockets.exceptions.ConnectionClosed, 
                    websockets.exceptions.InvalidURI,
                    ConnectionRefusedError):
                logger.debug("MCP ブリッジ接続待機中...")
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"MCP ブリッジ接続エラー: {e}")
                await asyncio.sleep(10)
    
    async def _sync_with_mcp_bridge(self):
        """MCP ブリッジとの同期"""
        try:
            if self.mcp_connection and not self.mcp_connection.closed:
                # AI組織ステータス要求
                request = {
                    "jsonrpc": "2.0",
                    "id": f"sync_{datetime.now().timestamp()}",
                    "method": "ai_org/get_status",
                    "params": {}
                }
                
                await self.mcp_connection.send(json.dumps(request))
                response = await asyncio.wait_for(self.mcp_connection.recv(), timeout=5.0)
                
                # レスポンス処理
                response_data = json.loads(response)
                if "result" in response_data:
                    await self._process_mcp_status_update(response_data["result"])
                    
        except asyncio.TimeoutError:
            logger.debug("MCP ブリッジタイムアウト")
        except Exception as e:
            logger.error(f"MCP ブリッジ同期エラー: {e}")
    
    async def _process_mcp_status_update(self, mcp_status: Dict):
        """MCP ステータス更新処理"""
        try:
            if mcp_status.get("success") and "workers" in mcp_status:
                mcp_workers = mcp_status["workers"]
                
                for worker_id, mcp_worker_data in mcp_workers.items():
                    if worker_id in self.workers:
                        worker = self.workers[worker_id]
                        
                        # MCP からの状態と比較
                        mcp_status_val = mcp_worker_data.get("status", "unknown")
                        mcp_issue = mcp_worker_data.get("current_issue")
                        
                        # 差分があれば同期イベント生成
                        if (worker.status != mcp_status_val or 
                            worker.current_issue != mcp_issue):
                            
                            event = SyncEvent(
                                event_id=f"mcp_sync_{worker_id}_{datetime.now().timestamp()}",
                                timestamp=datetime.now(),
                                source="mcp",
                                event_type="mcp_status_sync",
                                data={
                                    "worker_id": worker_id,
                                    "mcp_status": mcp_status_val,
                                    "mcp_issue": mcp_issue,
                                    "current_status": worker.status,
                                    "current_issue": worker.current_issue
                                }
                            )
                            await self.event_queue.put(event)
                            
        except Exception as e:
            logger.error(f"MCP ステータス更新処理エラー: {e}")
    
    async def _resolve_sync_conflicts(self):
        """同期競合解決"""
        # 簡易実装: 最新タイムスタンプ優先
        for worker in self.workers.values():
            if worker.pending_updates:
                # 保留中の更新を処理
                worker.pending_updates.clear()
    
    async def _update_all_statuses(self):
        """全ステータス更新"""
        try:
            # ペインタイトル一括更新
            for worker_id, worker in self.workers.items():
                if worker.current_issue:
                    title = f"🔄同期中 {worker.specialization} │ Issue #{worker.current_issue}"
                else:
                    title = f"🟡待機中 {worker.specialization}"
                
                cmd = ["tmux", "select-pane", "-t", worker.tmux_pane, "-T", title]
                subprocess.run(cmd)
                
        except Exception as e:
            logger.error(f"ステータス更新エラー: {e}")
    
    async def _periodic_state_save(self):
        """定期的な状態保存"""
        while self.running:
            try:
                await self._save_sync_state()
                await asyncio.sleep(60)  # 1分間隔
            except Exception as e:
                logger.error(f"状態保存エラー: {e}")
                await asyncio.sleep(10)
    
    async def _save_sync_state(self):
        """同期状態保存"""
        try:
            state_data = {
                "timestamp": datetime.now().isoformat(),
                "workers": {
                    worker_id: {
                        "tmux_pane": worker.tmux_pane,
                        "current_issue": worker.current_issue,
                        "status": worker.status,
                        "last_sync": worker.last_sync.isoformat()
                    }
                    for worker_id, worker in self.workers.items()
                }
            }
            
            # 非同期ファイル書き込み
            async with aiofiles.open(self.sync_state_file, 'w') as f:
                await f.write(json.dumps(state_data, indent=2))
                
        except Exception as e:
            logger.error(f"状態保存エラー: {e}")
    
    async def _log_sync_event(self, event: SyncEvent):
        """同期イベントログ"""
        try:
            log_entry = {
                "timestamp": event.timestamp.isoformat(),
                "event_id": event.event_id,
                "source": event.source,
                "event_type": event.event_type,
                "data": event.data
            }
            
            # 非同期ログ書き込み
            async with aiofiles.open(self.event_log_file, 'a') as f:
                await f.write(json.dumps(log_entry) + '\n')
                
        except Exception as e:
            logger.error(f"イベントログエラー: {e}")
    
    async def _cleanup(self):
        """クリーンアップ"""
        logger.info("🧹 同期デーモンクリーンアップ中...")
        
        # MCP 接続クローズ
        if self.mcp_connection and not self.mcp_connection.closed:
            await self.mcp_connection.close()
        
        # 最終状態保存
        await self._save_sync_state()
        
        logger.info("✅ クリーンアップ完了")

# メイン実行
async def main():
    """メインエントリーポイント"""
    daemon = RealtimeSyncDaemon()
    
    try:
        await daemon.start()
    except KeyboardInterrupt:
        logger.info("🛑 同期デーモン停止")
    except Exception as e:
        logger.error(f"同期デーモン致命的エラー: {e}")

if __name__ == "__main__":
    # ログディレクトリ作成（動的パス）
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent.parent
    logs_dir = project_root / "ai-agents" / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    
    # デーモン実行
    asyncio.run(main())