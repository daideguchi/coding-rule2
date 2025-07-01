#!/usr/bin/env python3
"""
Filesystem MCP Server for AI Organization
ファイルシステム操作MCP統合
"""

import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FileSystemMCPServer:
    """ファイルシステム MCP サーバー"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.allowed_paths = [self.project_root]
    
    def _is_allowed_path(self, path: Path) -> bool:
        """許可されたパス内かチェック"""
        try:
            resolved_path = path.resolve()
            return any(
                resolved_path.is_relative_to(allowed)
                for allowed in self.allowed_paths
            )
        except (OSError, ValueError):
            return False
    
    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """MCP リクエスト処理"""
        method = request.get("method")
        params = request.get("params", {})
        
        try:
            if method == "filesystem/read":
                return await self._read_file(params)
            elif method == "filesystem/write":
                return await self._write_file(params)
            elif method == "filesystem/list":
                return await self._list_directory(params)
            elif method == "filesystem/search":
                return await self._search_files(params)
            elif method == "filesystem/create_directory":
                return await self._create_directory(params)
            elif method == "filesystem/delete":
                return await self._delete_path(params)
            else:
                return {"error": {"code": -32601, "message": f"Method not found: {method}"}}
        except Exception as e:
            logger.error(f"Error handling {method}: {e}")
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _read_file(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ファイル読み込み"""
        file_path = Path(params.get("path", ""))
        
        if not self._is_allowed_path(file_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            if file_path.is_file():
                content = file_path.read_text(encoding='utf-8')
                return {
                    "result": {
                        "content": content,
                        "size": file_path.stat().st_size,
                        "modified": file_path.stat().st_mtime
                    }
                }
            else:
                return {"error": {"code": -32602, "message": "File not found"}}
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _write_file(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ファイル書き込み"""
        file_path = Path(params.get("path", ""))
        content = params.get("content", "")
        
        if not self._is_allowed_path(file_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            # ディレクトリが存在しない場合は作成
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            file_path.write_text(content, encoding='utf-8')
            return {
                "result": {
                    "success": True,
                    "size": file_path.stat().st_size
                }
            }
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _list_directory(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ディレクトリ一覧"""
        dir_path = Path(params.get("path", "."))
        
        if not self._is_allowed_path(dir_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            if dir_path.is_dir():
                items = []
                for item in dir_path.iterdir():
                    if item.name.startswith('.'):
                        continue  # 隠しファイルはスキップ
                    
                    items.append({
                        "name": item.name,
                        "type": "directory" if item.is_dir() else "file",
                        "size": item.stat().st_size if item.is_file() else 0,
                        "modified": item.stat().st_mtime
                    })
                
                return {"result": {"items": sorted(items, key=lambda x: x["name"])}}
            else:
                return {"error": {"code": -32602, "message": "Directory not found"}}
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _search_files(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ファイル検索"""
        pattern = params.get("pattern", "")
        search_path = Path(params.get("path", "."))
        
        if not self._is_allowed_path(search_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            matches = []
            for file_path in search_path.rglob(pattern):
                if self._is_allowed_path(file_path) and file_path.is_file():
                    matches.append({
                        "path": str(file_path.relative_to(self.project_root)),
                        "size": file_path.stat().st_size,
                        "modified": file_path.stat().st_mtime
                    })
            
            return {"result": {"matches": matches}}
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _create_directory(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ディレクトリ作成"""
        dir_path = Path(params.get("path", ""))
        
        if not self._is_allowed_path(dir_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            dir_path.mkdir(parents=True, exist_ok=True)
            return {"result": {"success": True}}
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}
    
    async def _delete_path(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """ファイル/ディレクトリ削除"""
        target_path = Path(params.get("path", ""))
        
        if not self._is_allowed_path(target_path):
            return {"error": {"code": -32602, "message": "Path not allowed"}}
        
        try:
            if target_path.is_file():
                target_path.unlink()
            elif target_path.is_dir():
                import shutil
                shutil.rmtree(target_path)
            else:
                return {"error": {"code": -32602, "message": "Path not found"}}
            
            return {"result": {"success": True}}
        except Exception as e:
            return {"error": {"code": -32603, "message": str(e)}}

async def main():
    """MCP サーバー メイン"""
    project_root = os.environ.get("PROJECT_ROOT", "/Users/dd/Desktop/1_dev/coding-rule2")
    server = FileSystemMCPServer(project_root)
    
    logger.info(f"Filesystem MCP Server starting with root: {project_root}")
    
    # MCP プロトコル実装
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
            
            request = json.loads(line.strip())
            response = await server.handle_request(request)
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError:
            continue
        except KeyboardInterrupt:
            break
        except Exception as e:
            logger.error(f"Server error: {e}")
            break

if __name__ == "__main__":
    asyncio.run(main())