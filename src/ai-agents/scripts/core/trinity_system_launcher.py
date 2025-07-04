#!/usr/bin/env python3
"""
🚀 三位一体開発システム統合ランチャー
既存システムとの連携強化により、AI組織の統合運用を実現

機能:
- 全コンポーネントの統合起動
- 既存システムとの連携強化
- リアルタイム監視・制御
- 自動復旧システム

Author: 🚀Gemini YOLO統合エンジニア
Version: 1.0.0
"""

import asyncio
import json
import logging
import os
import sys
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional, Any
import signal
import traceback

# 設定とログ
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TrinitySystemLauncher:
    """🚀 三位一体システム統合ランチャー"""
    
    def __init__(self, config_path: str = None):
        """初期化"""
        self.config_path = config_path or "ai-agents/configs/trinity_system_config.json"
        self.config = self._load_config()
        self.processes = {}
        self.running = False
        self.health_check_task = None
        
        # シグナルハンドラー設定
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        logger.info("🚀 三位一体システムランチャー初期化完了")

    def _load_config(self) -> Dict:
        """設定ファイル読み込み"""
        try:
            config_file = Path(self.config_path)
            if not config_file.exists():
                logger.error(f"❌ 設定ファイルが見つかりません: {self.config_path}")
                sys.exit(1)
            
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            logger.info(f"📋 設定ファイル読み込み完了: {self.config_path}")
            return config
            
        except Exception as e:
            logger.error(f"❌ 設定ファイル読み込みエラー: {e}")
            sys.exit(1)

    def _signal_handler(self, signum, frame):
        """シグナルハンドラー"""
        logger.info(f"🛑 シグナル受信: {signum}")
        asyncio.create_task(self.shutdown())

    async def start_component(self, component_name: str, component_config: Dict) -> bool:
        """コンポーネント起動"""
        try:
            if not component_config.get('enabled', False):
                logger.info(f"⏭️ {component_name} は無効化されています")
                return False
            
            module_path = component_config['module']
            config = component_config.get('config', {})
            
            # モジュールパスの存在確認
            if not Path(module_path).exists():
                logger.warning(f"⚠️ モジュールが見つかりません: {module_path}")
                return False
            
            # 既存システムとの連携強化
            if component_name == "gemini_yolo":
                cmd = [sys.executable, module_path, "--server", "--config", self.config_path]
            elif component_name == "claude_mcp_bridge":
                cmd = [sys.executable, module_path, "--mode", "bridge"]
            elif component_name == "memory_optimization":
                cmd = [sys.executable, module_path, "--daemon"]
            elif component_name == "realtime_sync":
                cmd = [sys.executable, module_path, "--sync-mode", "continuous"]
            elif component_name == "smart_monitoring":
                cmd = ["node", module_path, "--monitor"]
            else:
                cmd = [sys.executable, module_path]
            
            # プロセス起動
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=os.getcwd()
            )
            
            self.processes[component_name] = {
                'process': process,
                'config': component_config,
                'start_time': time.time(),
                'restart_count': 0
            }
            
            logger.info(f"✅ {component_name} 起動完了 (PID: {process.pid})")
            return True
            
        except Exception as e:
            logger.error(f"❌ {component_name} 起動エラー: {e}")
            return False

    async def start_all_components(self):
        """全コンポーネント起動"""
        logger.info("🚀 全コンポーネント起動開始")
        
        # 起動順序に従って起動
        startup_sequence = self.config['trinity_system']['workflow']['startup_sequence']
        components = self.config['trinity_system']['components']
        
        for component_name in startup_sequence:
            if component_name in components:
                success = await self.start_component(component_name, components[component_name])
                if success:
                    # 起動間隔を設ける
                    await asyncio.sleep(2)
                else:
                    logger.warning(f"⚠️ {component_name} の起動に失敗しました")
        
        logger.info("✅ 全コンポーネント起動完了")

    async def health_check(self):
        """ヘルスチェック"""
        check_interval = self.config['trinity_system']['workflow']['health_check']['interval']
        
        while self.running:
            try:
                for component_name, component_info in self.processes.items():
                    process = component_info['process']
                    
                    # プロセス状態確認
                    if process.returncode is not None:
                        logger.warning(f"⚠️ {component_name} プロセスが終了しています")
                        await self.restart_component(component_name)
                    
                await asyncio.sleep(check_interval)
                
            except Exception as e:
                logger.error(f"❌ ヘルスチェックエラー: {e}")
                await asyncio.sleep(check_interval)

    async def restart_component(self, component_name: str):
        """コンポーネント再起動"""
        try:
            if component_name not in self.processes:
                logger.warning(f"⚠️ {component_name} は起動していません")
                return
            
            component_info = self.processes[component_name]
            max_attempts = self.config['trinity_system']['workflow']['auto_recovery']['max_attempts']
            
            if component_info['restart_count'] >= max_attempts:
                logger.error(f"❌ {component_name} の再起動回数が上限に達しました")
                return
            
            logger.info(f"🔄 {component_name} 再起動中...")
            
            # 既存プロセス終了
            try:
                component_info['process'].terminate()
                await asyncio.sleep(2)
                if component_info['process'].returncode is None:
                    component_info['process'].kill()
            except Exception as e:
                logger.warning(f"⚠️ プロセス終了エラー: {e}")
            
            # 再起動
            component_config = component_info['config']
            success = await self.start_component(component_name, component_config)
            
            if success:
                self.processes[component_name]['restart_count'] += 1
                logger.info(f"✅ {component_name} 再起動完了")
            else:
                logger.error(f"❌ {component_name} 再起動失敗")
                
        except Exception as e:
            logger.error(f"❌ {component_name} 再起動エラー: {e}")

    async def get_system_status(self) -> Dict:
        """システム状態取得"""
        status = {
            'system': {
                'name': self.config['trinity_system']['name'],
                'version': self.config['trinity_system']['version'],
                'running': self.running,
                'uptime': time.time() - getattr(self, 'start_time', time.time())
            },
            'components': {}
        }
        
        for component_name, component_info in self.processes.items():
            process = component_info['process']
            status['components'][component_name] = {
                'pid': process.pid,
                'running': process.returncode is None,
                'uptime': time.time() - component_info['start_time'],
                'restart_count': component_info['restart_count']
            }
        
        return status

    async def shutdown(self):
        """システム終了"""
        logger.info("🛑 システム終了開始")
        self.running = False
        
        # ヘルスチェック停止
        if self.health_check_task:
            self.health_check_task.cancel()
        
        # 全プロセス終了
        for component_name, component_info in self.processes.items():
            try:
                process = component_info['process']
                logger.info(f"🛑 {component_name} 終了中...")
                
                process.terminate()
                await asyncio.sleep(2)
                
                if process.returncode is None:
                    process.kill()
                    await asyncio.sleep(1)
                
                logger.info(f"✅ {component_name} 終了完了")
                
            except Exception as e:
                logger.error(f"❌ {component_name} 終了エラー: {e}")
        
        logger.info("✅ システム終了完了")

    async def run(self):
        """メイン実行"""
        try:
            logger.info("🚀 三位一体開発システム起動開始")
            self.running = True
            self.start_time = time.time()
            
            # 全コンポーネント起動
            await self.start_all_components()
            
            # ヘルスチェック開始
            self.health_check_task = asyncio.create_task(self.health_check())
            
            # 状態監視ループ
            while self.running:
                status = await self.get_system_status()
                running_components = sum(1 for comp in status['components'].values() if comp['running'])
                total_components = len(status['components'])
                
                if running_components < total_components:
                    logger.warning(f"⚠️ 一部コンポーネントが停止: {running_components}/{total_components}")
                
                await asyncio.sleep(30)
            
        except KeyboardInterrupt:
            logger.info("🛑 キーボード割り込み受信")
        except Exception as e:
            logger.error(f"❌ システム実行エラー: {e}")
            logger.error(traceback.format_exc())
        finally:
            await self.shutdown()

    def show_help(self):
        """ヘルプ表示"""
        help_text = """
🚀 三位一体開発システム統合ランチャー

使用方法:
  python trinity_system_launcher.py [オプション]

オプション:
  --config FILE     設定ファイルパス (デフォルト: ai-agents/configs/trinity_system_config.json)
  --status          システム状態表示
  --help            このヘルプを表示

機能:
  ✅ Gemini YOLO統合エンジン
  ✅ Claude MCP ブリッジシステム
  ✅ メモリ最適化エンジン
  ✅ リアルタイム同期デーモン
  ✅ スマート監視システム

統合機能:
  🔄 自動復旧システム
  📊 リアルタイム監視
  🔗 既存システム連携
  ⚡ 最適化された起動順序
        """
        print(help_text)

# CLI実行部分
async def main():
    """メイン実行関数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='🚀 三位一体開発システム統合ランチャー')
    parser.add_argument('--config', type=str, help='設定ファイルパス')
    parser.add_argument('--status', action='store_true', help='システム状態表示')
    parser.add_argument('--help', action='store_true', help='ヘルプ表示')
    
    args = parser.parse_args()
    
    launcher = TrinitySystemLauncher(args.config)
    
    if args.help:
        launcher.show_help()
        return
    
    if args.status:
        status = await launcher.get_system_status()
        print(json.dumps(status, indent=2, ensure_ascii=False))
        return
    
    # メイン実行
    await launcher.run()

if __name__ == "__main__":
    asyncio.run(main())