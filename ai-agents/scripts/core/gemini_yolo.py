#!/usr/bin/env python3
"""
🚀 Gemini YOLO統合エンジン
三位一体開発システム - 画像認識とAI統合の中核コンポーネント

機能:
- YOLOv8リアルタイム物体検出
- Gemini API統合による高度な画像解析
- AI組織システム統合
- WebSocket通信による実行時連携
- 統合ダッシュボードへの結果送信

Author: 🚀Gemini YOLO統合エンジニア
Version: 1.0.0
"""

import asyncio
import json
import logging
import os
import sys
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import traceback

# 外部ライブラリ（requirements.txtで管理）
try:
    import cv2
    import numpy as np
    from ultralytics import YOLO
    import google.generativeai as genai
    import websockets
    import aiohttp
    import aiofiles
except ImportError as e:
    print(f"❌ 依存関係エラー: {e}")
    print("📋 requirements.txtからライブラリをインストールしてください")
    sys.exit(1)

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class DetectionResult:
    """YOLO検出結果データクラス"""
    class_name: str
    confidence: float
    bbox: Tuple[int, int, int, int]  # x1, y1, x2, y2
    timestamp: float

@dataclass
class GeminiAnalysis:
    """Gemini解析結果データクラス"""
    description: str
    insights: List[str]
    suggestions: List[str]
    timestamp: float

@dataclass
class IntegratedResult:
    """統合結果データクラス"""
    yolo_detections: List[DetectionResult]
    gemini_analysis: GeminiAnalysis
    session_id: str
    total_objects: int
    processing_time: float

class GeminiYOLOEngine:
    """🚀 Gemini YOLO統合エンジン メインクラス"""
    
    def __init__(self, config_path: Optional[str] = None):
        """初期化"""
        self.config = self._load_config(config_path)
        self.yolo_model = None
        self.gemini_client = None
        self.websocket_clients = set()
        self.session_id = f"session_{int(time.time())}"
        
        # 出力ディレクトリ設定
        self.output_dir = Path(self.config.get('output_dir', './outputs'))
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"🚀 Gemini YOLO統合エンジン初期化完了 - セッション: {self.session_id}")

    def _load_config(self, config_path: Optional[str]) -> Dict:
        """設定ファイル読み込み"""
        default_config = {
            'yolo_model': 'yolov8n.pt',
            'gemini_api_key': os.getenv('GEMINI_API_KEY'),
            'confidence_threshold': 0.5,
            'websocket_port': 8765,
            'output_dir': './outputs',
            'max_detections': 100,
            'gemini_model': 'gemini-1.5-flash'
        }
        
        if config_path and Path(config_path).exists():
            try:
                with open(config_path, 'r') as f:
                    user_config = json.load(f)
                default_config.update(user_config)
                logger.info(f"📋 設定ファイル読み込み完了: {config_path}")
            except Exception as e:
                logger.warning(f"⚠️ 設定ファイル読み込みエラー: {e}")
        
        return default_config

    async def initialize_models(self):
        """モデル初期化"""
        try:
            # YOLO初期化
            logger.info("🔥 YOLOモデル初期化中...")
            self.yolo_model = YOLO(self.config['yolo_model'])
            logger.info("✅ YOLOモデル初期化完了")
            
            # Gemini初期化
            if self.config['gemini_api_key']:
                logger.info("🔥 Gemini API初期化中...")
                genai.configure(api_key=self.config['gemini_api_key'])
                self.gemini_client = genai.GenerativeModel(self.config['gemini_model'])
                logger.info("✅ Gemini API初期化完了")
            else:
                logger.warning("⚠️ Gemini APIキーが設定されていません")
                
        except Exception as e:
            logger.error(f"❌ モデル初期化エラー: {e}")
            raise

    async def detect_objects(self, image_path: str) -> List[DetectionResult]:
        """YOLO物体検出"""
        try:
            if not self.yolo_model:
                raise ValueError("YOLOモデルが初期化されていません")
            
            # 画像読み込み
            image = cv2.imread(image_path)
            if image is None:
                raise ValueError(f"画像読み込みエラー: {image_path}")
            
            # YOLO推論
            results = self.yolo_model(image)
            detections = []
            
            for result in results:
                for box in result.boxes:
                    if box.conf[0] >= self.config['confidence_threshold']:
                        detection = DetectionResult(
                            class_name=result.names[int(box.cls[0])],
                            confidence=float(box.conf[0]),
                            bbox=tuple(map(int, box.xyxy[0].tolist())),
                            timestamp=time.time()
                        )
                        detections.append(detection)
            
            logger.info(f"🎯 検出完了: {len(detections)}個のオブジェクト")
            return detections
            
        except Exception as e:
            logger.error(f"❌ 物体検出エラー: {e}")
            return []

    async def analyze_with_gemini(self, image_path: str, detections: List[DetectionResult]) -> GeminiAnalysis:
        """Gemini画像解析"""
        try:
            if not self.gemini_client:
                logger.warning("⚠️ Gemini クライアントが利用できません")
                return GeminiAnalysis("", [], [], time.time())
            
            # 画像読み込み
            async with aiofiles.open(image_path, 'rb') as f:
                image_data = await f.read()
            
            # 検出結果サマリー作成
            detection_summary = f"検出されたオブジェクト: {len(detections)}個\n"
            for det in detections:
                detection_summary += f"- {det.class_name} (信頼度: {det.confidence:.2f})\n"
            
            # Gemini プロンプト
            prompt = f"""
            この画像を詳細に分析してください。

            YOLO検出結果:
            {detection_summary}

            以下の観点で分析をお願いします:
            1. 画像全体の状況説明
            2. 検出されたオブジェクトの関係性
            3. 改善提案やインサイト
            4. 注意すべき点

            JSON形式で回答してください:
            {{
                "description": "画像の詳細な説明",
                "insights": ["インサイト1", "インサイト2"],
                "suggestions": ["提案1", "提案2"]
            }}
            """
            
            # Gemini API呼び出し
            response = await self._call_gemini_api(prompt, image_data)
            
            # レスポンス解析
            try:
                result_data = json.loads(response)
                analysis = GeminiAnalysis(
                    description=result_data.get('description', ''),
                    insights=result_data.get('insights', []),
                    suggestions=result_data.get('suggestions', []),
                    timestamp=time.time()
                )
                logger.info("✅ Gemini解析完了")
                return analysis
            except json.JSONDecodeError:
                # フォールバック: テキストのまま返す
                return GeminiAnalysis(
                    description=response,
                    insights=[],
                    suggestions=[],
                    timestamp=time.time()
                )
                
        except Exception as e:
            logger.error(f"❌ Gemini解析エラー: {e}")
            return GeminiAnalysis("", [], [], time.time())

    async def _call_gemini_api(self, prompt: str, image_data: bytes) -> str:
        """Gemini API呼び出し"""
        try:
            # 画像データをGemini形式に変換
            image_part = {
                "mime_type": "image/jpeg",
                "data": image_data
            }
            
            response = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: self.gemini_client.generate_content([prompt, image_part])
            )
            
            return response.text
            
        except Exception as e:
            logger.error(f"❌ Gemini API呼び出しエラー: {e}")
            return "API呼び出しエラー"

    async def process_image(self, image_path: str) -> IntegratedResult:
        """画像統合処理"""
        start_time = time.time()
        
        try:
            logger.info(f"🚀 画像処理開始: {image_path}")
            
            # YOLO検出
            detections = await self.detect_objects(image_path)
            
            # Gemini解析
            gemini_analysis = await self.analyze_with_gemini(image_path, detections)
            
            # 統合結果作成
            processing_time = time.time() - start_time
            result = IntegratedResult(
                yolo_detections=detections,
                gemini_analysis=gemini_analysis,
                session_id=self.session_id,
                total_objects=len(detections),
                processing_time=processing_time
            )
            
            # 結果保存
            await self._save_result(result, image_path)
            
            # WebSocket通知
            await self._broadcast_result(result)
            
            logger.info(f"✅ 画像処理完了 - 処理時間: {processing_time:.2f}秒")
            return result
            
        except Exception as e:
            logger.error(f"❌ 画像処理エラー: {e}")
            logger.error(traceback.format_exc())
            raise

    async def _save_result(self, result: IntegratedResult, image_path: str):
        """結果保存"""
        try:
            # JSON結果保存
            result_file = self.output_dir / f"result_{int(time.time())}.json"
            async with aiofiles.open(result_file, 'w') as f:
                await f.write(json.dumps(asdict(result), indent=2, ensure_ascii=False))
            
            # 画像コピー保存
            image_copy = self.output_dir / f"processed_{Path(image_path).name}"
            async with aiofiles.open(image_path, 'rb') as src, \
                       aiofiles.open(image_copy, 'wb') as dst:
                await dst.write(await src.read())
            
            logger.info(f"💾 結果保存完了: {result_file}")
            
        except Exception as e:
            logger.error(f"❌ 結果保存エラー: {e}")

    async def _broadcast_result(self, result: IntegratedResult):
        """WebSocket結果配信"""
        if self.websocket_clients:
            message = json.dumps(asdict(result), ensure_ascii=False)
            disconnected = set()
            
            for client in self.websocket_clients:
                try:
                    await client.send(message)
                except websockets.exceptions.ConnectionClosed:
                    disconnected.add(client)
                except Exception as e:
                    logger.warning(f"⚠️ WebSocket送信エラー: {e}")
                    disconnected.add(client)
            
            # 切断されたクライアントを削除
            self.websocket_clients -= disconnected

    async def start_websocket_server(self):
        """WebSocketサーバー開始"""
        async def handle_client(websocket, path):
            self.websocket_clients.add(websocket)
            logger.info(f"🔗 WebSocketクライアント接続: {len(self.websocket_clients)}台")
            
            try:
                await websocket.wait_closed()
            finally:
                self.websocket_clients.discard(websocket)
                logger.info(f"🔗 WebSocketクライアント切断: {len(self.websocket_clients)}台")
        
        server = await websockets.serve(
            handle_client,
            "localhost",
            self.config['websocket_port']
        )
        
        logger.info(f"🌐 WebSocketサーバー開始: port {self.config['websocket_port']}")
        return server

    async def run_batch_processing(self, image_directory: str):
        """バッチ処理実行"""
        try:
            image_dir = Path(image_directory)
            if not image_dir.exists():
                raise ValueError(f"ディレクトリが存在しません: {image_directory}")
            
            # 対応画像形式
            image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
            image_files = []
            
            for ext in image_extensions:
                image_files.extend(image_dir.glob(f"*{ext}"))
                image_files.extend(image_dir.glob(f"*{ext.upper()}"))
            
            if not image_files:
                logger.warning("⚠️ 処理可能な画像ファイルが見つかりません")
                return
            
            logger.info(f"🚀 バッチ処理開始: {len(image_files)}ファイル")
            
            results = []
            for i, image_file in enumerate(image_files, 1):
                logger.info(f"📷 処理中 ({i}/{len(image_files)}): {image_file.name}")
                result = await self.process_image(str(image_file))
                results.append(result)
            
            # バッチ結果統計
            total_objects = sum(r.total_objects for r in results)
            total_time = sum(r.processing_time for r in results)
            
            logger.info(f"✅ バッチ処理完了")
            logger.info(f"📊 統計: {len(results)}画像, {total_objects}オブジェクト, {total_time:.2f}秒")
            
            return results
            
        except Exception as e:
            logger.error(f"❌ バッチ処理エラー: {e}")
            raise

# CLI実行部分
async def main():
    """メイン実行関数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='🚀 Gemini YOLO統合エンジン')
    parser.add_argument('--config', type=str, help='設定ファイルパス')
    parser.add_argument('--image', type=str, help='単一画像処理')
    parser.add_argument('--batch', type=str, help='バッチ処理ディレクトリ')
    parser.add_argument('--server', action='store_true', help='WebSocketサーバー起動')
    
    args = parser.parse_args()
    
    try:
        # エンジン初期化
        engine = GeminiYOLOEngine(args.config)
        await engine.initialize_models()
        
        # WebSocketサーバー起動
        if args.server:
            server = await engine.start_websocket_server()
        
        # 単一画像処理
        if args.image:
            result = await engine.process_image(args.image)
            print(f"✅ 処理完了: {result.total_objects}オブジェクト検出")
        
        # バッチ処理
        if args.batch:
            results = await engine.run_batch_processing(args.batch)
            print(f"✅ バッチ処理完了: {len(results)}画像処理")
        
        # サーバーモードの場合は待機
        if args.server:
            print("🌐 WebSocketサーバー稼働中 (Ctrl+Cで停止)")
            await server.wait_closed()
            
    except KeyboardInterrupt:
        logger.info("🛑 ユーザーによる停止")
    except Exception as e:
        logger.error(f"❌ 実行エラー: {e}")
        logger.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())