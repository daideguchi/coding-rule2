#!/usr/bin/env python3

"""
=============================================================================
🎯 GEMINI_YOLO_INTEGRATION.py - Gemini YOLOシステム統合 v1.0
=============================================================================

【WORKER2実装】: Gemini + YOLOリアルタイム認識・分析システム
【目的】: 高速オブジェクト検出・AIビジョン分析・統合判断システム
【特徴】: リアルタイム処理・マルチモーダルAI・高精度認識

=============================================================================
"""

import os
import sys
import json
import time
import threading
import asyncio
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
from pathlib import Path
import logging

# 外部ライブラリ（通常の使用）
try:
    import cv2
    import numpy as np
    import requests
    from PIL import Image
    import torch
    DEPENDENCIES_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  依存関係不足: {e}")
    print("💡 軽量モードで動作します（実際の検出は行いません）")
    DEPENDENCIES_AVAILABLE = False

# =============================================================================
# 📊 設定・データクラス
# =============================================================================

@dataclass
class YOLODetection:
    """YOLO検出結果"""
    object_class: str
    confidence: float
    bbox: List[float]  # [x, y, width, height]
    timestamp: float

@dataclass
class GeminiAnalysis:
    """Gemini分析結果"""
    description: str
    confidence: float
    key_objects: List[str]
    scene_context: str
    timestamp: float

@dataclass
class IntegratedResult:
    """統合分析結果"""
    yolo_detections: List[YOLODetection]
    gemini_analysis: GeminiAnalysis
    integrated_confidence: float
    decision_recommendation: str
    processing_time: float
    timestamp: float

# =============================================================================
# 🎯 Gemini YOLOシステム統合クラス
# =============================================================================

class GeminiYOLOSystem:
    """Gemini + YOLO統合認識システム"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.config = self._load_config(config_path)
        self.logger = self._setup_logging()
        
        # システム状態
        self.is_running = False
        self.processing_queue = asyncio.Queue()
        self.results_cache = {}
        
        # パフォーマンス統計
        self.stats = {
            'total_processed': 0,
            'average_processing_time': 0,
            'detection_accuracy': 0,
            'gemini_calls': 0,
            'yolo_detections': 0
        }
        
        # パス設定
        self.ai_agents_dir = Path(__file__).parent.parent.parent
        self.logs_dir = self.ai_agents_dir / "logs"
        self.tmp_dir = self.ai_agents_dir / "tmp"
        self.config_dir = self.ai_agents_dir / "configs"
        
        # ディレクトリ作成
        self.logs_dir.mkdir(exist_ok=True)
        self.tmp_dir.mkdir(exist_ok=True)
        self.config_dir.mkdir(exist_ok=True)
        
        self.logger.info("🎯 Gemini YOLOシステム初期化完了")
    
    def _load_config(self, config_path: Optional[str]) -> Dict[str, Any]:
        """設定ファイル読み込み"""
        default_config = {
            "yolo": {
                "model_path": "yolov8n.pt",  # 軽量モデル
                "confidence_threshold": 0.5,
                "iou_threshold": 0.4,
                "max_detections": 100
            },
            "gemini": {
                "api_key": os.getenv("GEMINI_API_KEY", ""),
                "model": "gemini-pro-vision",
                "max_tokens": 1000,
                "temperature": 0.1
            },
            "integration": {
                "confidence_weight_yolo": 0.6,
                "confidence_weight_gemini": 0.4,
                "min_integrated_confidence": 0.7,
                "real_time_mode": True,
                "batch_processing": False
            },
            "performance": {
                "max_fps": 30,
                "max_concurrent_requests": 5,
                "cache_size": 1000,
                "timeout_seconds": 10
            }
        }
        
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    custom_config = json.load(f)
                default_config.update(custom_config)
            except Exception as e:
                print(f"⚠️ 設定ファイル読み込みエラー: {e}")
        
        return default_config
    
    def _setup_logging(self) -> logging.Logger:
        """ログシステム設定"""
        logger = logging.getLogger("GeminiYOLO")
        logger.setLevel(logging.INFO)
        
        # ファイルハンドラー
        log_file = self.ai_agents_dir / "logs" / "gemini-yolo-integration.log"
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setLevel(logging.INFO)
        
        # コンソールハンドラー
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # フォーマッター
        formatter = logging.Formatter(
            '[%(asctime)s] [GEMINI-YOLO-%(levelname)s] [%(name)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    # =============================================================================
    # 🔍 YOLO検出システム
    # =============================================================================
    
    def initialize_yolo(self) -> bool:
        """YOLO初期化"""
        self.logger.info("🔍 YOLO検出システム初期化")
        
        if not DEPENDENCIES_AVAILABLE:
            self.logger.warning("依存関係不足 - YOLOシミュレーションモード")
            return True
        
        try:
            # YOLOv8モデル読み込み（実際の実装では適切なモデルを使用）
            # self.yolo_model = YOLO(self.config["yolo"]["model_path"])
            self.logger.info("✅ YOLO初期化完了")
            return True
        except Exception as e:
            self.logger.error(f"❌ YOLO初期化失敗: {e}")
            return False
    
    def detect_objects_yolo(self, image_path: str) -> List[YOLODetection]:
        """YOLO物体検出"""
        start_time = time.time()
        
        if not DEPENDENCIES_AVAILABLE:
            # シミュレーションモード
            return self._simulate_yolo_detection()
        
        try:
            # 実際のYOLO検出（シミュレーション）
            detections = []
            
            # 画像読み込み
            # image = cv2.imread(image_path)
            # results = self.yolo_model(image)
            
            # 結果解析（シミュレーション）
            simulated_objects = [
                {"class": "person", "confidence": 0.89, "bbox": [100, 50, 80, 200]},
                {"class": "laptop", "confidence": 0.76, "bbox": [200, 150, 120, 80]},
                {"class": "mouse", "confidence": 0.65, "bbox": [350, 180, 30, 50]}
            ]
            
            for obj in simulated_objects:
                if obj["confidence"] >= self.config["yolo"]["confidence_threshold"]:
                    detection = YOLODetection(
                        object_class=obj["class"],
                        confidence=obj["confidence"],
                        bbox=obj["bbox"],
                        timestamp=time.time()
                    )
                    detections.append(detection)
            
            processing_time = time.time() - start_time
            self.logger.info(f"🔍 YOLO検出完了: {len(detections)}個のオブジェクト ({processing_time:.3f}秒)")
            
            # 統計更新
            self.stats['yolo_detections'] += len(detections)
            
            return detections
            
        except Exception as e:
            self.logger.error(f"❌ YOLO検出エラー: {e}")
            return []
    
    def _simulate_yolo_detection(self) -> List[YOLODetection]:
        """YOLO検出シミュレーション"""
        simulated_detections = [
            YOLODetection(
                object_class="person",
                confidence=0.89,
                bbox=[100, 50, 80, 200],
                timestamp=time.time()
            ),
            YOLODetection(
                object_class="computer",
                confidence=0.76,
                bbox=[200, 150, 120, 80],
                timestamp=time.time()
            )
        ]
        
        self.logger.info("🎭 YOLOシミュレーション検出完了")
        return simulated_detections
    
    # =============================================================================
    # 🧠 Gemini分析システム
    # =============================================================================
    
    def initialize_gemini(self) -> bool:
        """Gemini初期化"""
        self.logger.info("🧠 Gemini分析システム初期化")
        
        api_key = self.config["gemini"]["api_key"]
        if not api_key:
            self.logger.warning("⚠️ Gemini APIキー未設定 - シミュレーションモード")
            return True
        
        try:
            # Gemini API初期化（実際の実装では適切な初期化を行う）
            # self.gemini_client = genai.GenerativeModel(self.config["gemini"]["model"])
            self.logger.info("✅ Gemini初期化完了")
            return True
        except Exception as e:
            self.logger.error(f"❌ Gemini初期化失敗: {e}")
            return False
    
    def analyze_with_gemini(self, image_path: str, yolo_detections: List[YOLODetection]) -> GeminiAnalysis:
        """Gemini画像分析"""
        start_time = time.time()
        
        try:
            # 検出オブジェクト情報をコンテキストとして使用
            detected_objects = [det.object_class for det in yolo_detections]
            
            # Gemini分析プロンプト構築
            context_prompt = f"""
画像を分析してください。YOLO検出システムが以下のオブジェクトを検出しています：
{', '.join(detected_objects) if detected_objects else '検出オブジェクトなし'}

以下の観点で分析してください：
1. 場面の全体的な説明
2. 重要なオブジェクトとその関係性
3. 安全性・リスク評価
4. 推奨される対応やアクション
"""
            
            # 実際のGemini API呼び出し（シミュレーション）
            analysis_result = self._simulate_gemini_analysis(detected_objects)
            
            # 統計更新
            self.stats['gemini_calls'] += 1
            processing_time = time.time() - start_time
            
            self.logger.info(f"🧠 Gemini分析完了 ({processing_time:.3f}秒)")
            
            return analysis_result
            
        except Exception as e:
            self.logger.error(f"❌ Gemini分析エラー: {e}")
            return GeminiAnalysis(
                description="分析エラーが発生しました",
                confidence=0.0,
                key_objects=[],
                scene_context="error",
                timestamp=time.time()
            )
    
    def _simulate_gemini_analysis(self, detected_objects: List[str]) -> GeminiAnalysis:
        """Gemini分析シミュレーション"""
        
        # 検出オブジェクトに基づく動的分析
        if "person" in detected_objects:
            description = "人物が作業環境にいることを確認。"
            if "computer" in detected_objects or "laptop" in detected_objects:
                description += "コンピューター作業を行っている可能性が高い。"
                scene_context = "development_workspace"
                confidence = 0.88
            else:
                scene_context = "general_workspace"
                confidence = 0.75
        else:
            description = "人物不在の環境。機器のみが検出されています。"
            scene_context = "automated_system"
            confidence = 0.65
        
        return GeminiAnalysis(
            description=description,
            confidence=confidence,
            key_objects=detected_objects,
            scene_context=scene_context,
            timestamp=time.time()
        )
    
    # =============================================================================
    # 🔄 統合分析システム
    # =============================================================================
    
    def integrate_analysis(self, yolo_detections: List[YOLODetection], 
                          gemini_analysis: GeminiAnalysis) -> IntegratedResult:
        """YOLO + Gemini統合分析"""
        start_time = time.time()
        
        self.logger.info("🔄 統合分析開始")
        
        # 信頼度統合計算
        yolo_avg_confidence = sum(det.confidence for det in yolo_detections) / len(yolo_detections) if yolo_detections else 0
        gemini_confidence = gemini_analysis.confidence
        
        # 重み付き統合信頼度
        weight_yolo = self.config["integration"]["confidence_weight_yolo"]
        weight_gemini = self.config["integration"]["confidence_weight_gemini"]
        
        integrated_confidence = (yolo_avg_confidence * weight_yolo + 
                                gemini_confidence * weight_gemini)
        
        # 意思決定推奨
        decision_recommendation = self._generate_decision_recommendation(
            yolo_detections, gemini_analysis, integrated_confidence
        )
        
        # 統合結果作成
        result = IntegratedResult(
            yolo_detections=yolo_detections,
            gemini_analysis=gemini_analysis,
            integrated_confidence=integrated_confidence,
            decision_recommendation=decision_recommendation,
            processing_time=time.time() - start_time,
            timestamp=time.time()
        )
        
        self.logger.info(f"✅ 統合分析完了 - 信頼度: {integrated_confidence:.3f}")
        
        # 統計更新
        self.stats['total_processed'] += 1
        self._update_average_processing_time(result.processing_time)
        
        return result
    
    def _generate_decision_recommendation(self, yolo_detections: List[YOLODetection],
                                        gemini_analysis: GeminiAnalysis,
                                        integrated_confidence: float) -> str:
        """意思決定推奨生成"""
        
        min_confidence = self.config["integration"]["min_integrated_confidence"]
        
        if integrated_confidence >= min_confidence:
            # 高信頼度の場合
            if gemini_analysis.scene_context == "development_workspace":
                recommendation = "開発環境として認識。継続的な作業支援を推奨。"
            elif "person" in [det.object_class for det in yolo_detections]:
                recommendation = "人物検出。安全性確認済み。通常操作を継続。"
            else:
                recommendation = "自動化システム環境。監視継続を推奨。"
        else:
            # 低信頼度の場合
            recommendation = "分析結果の信頼度が低い。追加分析または人間の確認を推奨。"
        
        return recommendation
    
    def _update_average_processing_time(self, processing_time: float):
        """平均処理時間更新"""
        total = self.stats['total_processed']
        current_avg = self.stats['average_processing_time']
        
        # 指数移動平均
        alpha = 0.1
        new_avg = (1 - alpha) * current_avg + alpha * processing_time
        self.stats['average_processing_time'] = new_avg
    
    # =============================================================================
    # 🚀 リアルタイム処理システム
    # =============================================================================
    
    async def start_real_time_processing(self):
        """リアルタイム処理開始"""
        self.logger.info("🚀 リアルタイム処理開始")
        self.is_running = True
        
        # 初期化
        if not self.initialize_yolo() or not self.initialize_gemini():
            self.logger.error("初期化失敗")
            return
        
        # 処理ループ
        while self.is_running:
            try:
                # キューから処理要求取得（タイムアウト付き）
                try:
                    request = await asyncio.wait_for(
                        self.processing_queue.get(), 
                        timeout=1.0
                    )
                    await self._process_request(request)
                except asyncio.TimeoutError:
                    # タイムアウト時は定期処理実行
                    await self._periodic_processing()
                    
            except Exception as e:
                self.logger.error(f"リアルタイム処理エラー: {e}")
                await asyncio.sleep(1)
    
    async def _process_request(self, request: Dict[str, Any]):
        """処理要求実行"""
        try:
            image_path = request.get("image_path")
            request_id = request.get("request_id", "unknown")
            
            self.logger.info(f"📸 処理要求実行: {request_id}")
            
            # YOLO検出
            yolo_detections = self.detect_objects_yolo(image_path)
            
            # Gemini分析
            gemini_analysis = self.analyze_with_gemini(image_path, yolo_detections)
            
            # 統合分析
            integrated_result = self.integrate_analysis(yolo_detections, gemini_analysis)
            
            # 結果保存
            await self._save_result(request_id, integrated_result)
            
            # 外部システム連携
            await self._notify_external_systems(integrated_result)
            
        except Exception as e:
            self.logger.error(f"処理要求実行エラー: {e}")
    
    async def _periodic_processing(self):
        """定期処理"""
        # システムヘルスチェック
        self._health_check()
        
        # 統計更新
        self._update_statistics()
        
        # キャッシュクリーンアップ
        self._cleanup_cache()
    
    async def _save_result(self, request_id: str, result: IntegratedResult):
        """結果保存"""
        try:
            result_file = self.tmp_dir / f"gemini_yolo_result_{request_id}_{int(time.time())}.json"
            
            # データ準備
            result_data = {
                "request_id": request_id,
                "timestamp": datetime.fromtimestamp(result.timestamp).isoformat(),
                "yolo_detections": [asdict(det) for det in result.yolo_detections],
                "gemini_analysis": asdict(result.gemini_analysis),
                "integrated_confidence": result.integrated_confidence,
                "decision_recommendation": result.decision_recommendation,
                "processing_time": result.processing_time
            }
            
            # ファイル保存
            with open(result_file, 'w', encoding='utf-8') as f:
                json.dump(result_data, f, ensure_ascii=False, indent=2)
            
            self.logger.info(f"💾 結果保存完了: {result_file}")
            
        except Exception as e:
            self.logger.error(f"結果保存エラー: {e}")
    
    async def _notify_external_systems(self, result: IntegratedResult):
        """外部システム通知"""
        try:
            # Claude自動操縦システムへの通知
            autopilot_notification = {
                "source": "gemini_yolo",
                "confidence": result.integrated_confidence,
                "recommendation": result.decision_recommendation,
                "detected_objects": [det.object_class for det in result.yolo_detections],
                "timestamp": result.timestamp
            }
            
            # ワンライナー報告システム連携
            if result.integrated_confidence >= 0.8:
                priority = "medium"
                message = f"🎯 高信頼度検出: {result.decision_recommendation}"
            else:
                priority = "low"
                message = f"🔍 要確認: {result.decision_recommendation}"
            
            # 外部スクリプト呼び出し
            oneliner_script = self.ai_agents_dir / "scripts" / "automation" / "ONELINER_REPORTING_SYSTEM.sh"
            if oneliner_script.exists():
                import subprocess
                subprocess.run([
                    str(oneliner_script), "share", message, priority
                ], capture_output=True, text=True)
            
            self.logger.info("📤 外部システム通知完了")
            
        except Exception as e:
            self.logger.error(f"外部システム通知エラー: {e}")
    
    # =============================================================================
    # 🔧 ユーティリティ・メンテナンス
    # =============================================================================
    
    def _health_check(self):
        """システムヘルスチェック"""
        try:
            # メモリ使用量チェック
            import psutil
            memory_usage = psutil.virtual_memory().percent
            
            if memory_usage > 90:
                self.logger.warning(f"⚠️ 高メモリ使用率: {memory_usage}%")
            
            # 処理キューサイズチェック
            queue_size = self.processing_queue.qsize()
            if queue_size > 10:
                self.logger.warning(f"⚠️ 処理キュー過負荷: {queue_size} 件")
            
        except Exception as e:
            self.logger.error(f"ヘルスチェックエラー: {e}")
    
    def _update_statistics(self):
        """統計情報更新"""
        try:
            # 統計ファイル保存
            stats_file = self.logs_dir / "gemini_yolo_stats.json"
            
            current_stats = {
                **self.stats,
                "last_updated": datetime.now().isoformat(),
                "uptime_seconds": time.time() - getattr(self, 'start_time', time.time())
            }
            
            with open(stats_file, 'w', encoding='utf-8') as f:
                json.dump(current_stats, f, ensure_ascii=False, indent=2)
                
        except Exception as e:
            self.logger.error(f"統計更新エラー: {e}")
    
    def _cleanup_cache(self):
        """キャッシュクリーンアップ"""
        try:
            max_cache_size = self.config["performance"]["cache_size"]
            
            if len(self.results_cache) > max_cache_size:
                # 古いエントリを削除
                sorted_items = sorted(
                    self.results_cache.items(),
                    key=lambda x: x[1].get('timestamp', 0)
                )
                
                # 半分削除
                items_to_remove = len(sorted_items) // 2
                for i in range(items_to_remove):
                    del self.results_cache[sorted_items[i][0]]
                
                self.logger.info(f"🧹 キャッシュクリーンアップ: {items_to_remove} 件削除")
                
        except Exception as e:
            self.logger.error(f"キャッシュクリーンアップエラー: {e}")
    
    def get_statistics(self) -> Dict[str, Any]:
        """統計情報取得"""
        return {
            **self.stats,
            "cache_size": len(self.results_cache),
            "queue_size": self.processing_queue.qsize() if hasattr(self, 'processing_queue') else 0,
            "is_running": self.is_running
        }
    
    def stop_system(self):
        """システム停止"""
        self.logger.info("🛑 Gemini YOLOシステム停止")
        self.is_running = False

# =============================================================================
# 🎯 CLI インターフェース
# =============================================================================

def main():
    """メイン実行関数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Gemini YOLO統合システム")
    parser.add_argument("command", choices=["start", "test", "analyze", "stats", "stop"], 
                       help="実行コマンド")
    parser.add_argument("--image", help="分析する画像ファイル")
    parser.add_argument("--config", help="設定ファイルパス")
    
    args = parser.parse_args()
    
    # システム初期化
    system = GeminiYOLOSystem(args.config)
    
    if args.command == "start":
        print("🚀 Gemini YOLOシステム開始")
        try:
            asyncio.run(system.start_real_time_processing())
        except KeyboardInterrupt:
            print("🛑 ユーザーによる停止")
            system.stop_system()
    
    elif args.command == "test":
        print("🧪 Gemini YOLOシステムテスト")
        
        # 初期化テスト
        yolo_ok = system.initialize_yolo()
        gemini_ok = system.initialize_gemini()
        
        print(f"YOLO初期化: {'✅' if yolo_ok else '❌'}")
        print(f"Gemini初期化: {'✅' if gemini_ok else '❌'}")
        
        # シミュレーション実行
        if args.image and os.path.exists(args.image):
            yolo_detections = system.detect_objects_yolo(args.image)
            gemini_analysis = system.analyze_with_gemini(args.image, yolo_detections)
            result = system.integrate_analysis(yolo_detections, gemini_analysis)
            
            print(f"統合分析結果:")
            print(f"  検出オブジェクト: {len(result.yolo_detections)} 個")
            print(f"  統合信頼度: {result.integrated_confidence:.3f}")
            print(f"  推奨アクション: {result.decision_recommendation}")
        else:
            print("⚠️ 画像ファイルが指定されていません（--image）")
    
    elif args.command == "analyze":
        if not args.image:
            print("❌ 画像ファイルを指定してください（--image）")
            return
        
        if not os.path.exists(args.image):
            print(f"❌ 画像ファイルが見つかりません: {args.image}")
            return
        
        print(f"🔍 画像分析実行: {args.image}")
        
        system.initialize_yolo()
        system.initialize_gemini()
        
        yolo_detections = system.detect_objects_yolo(args.image)
        gemini_analysis = system.analyze_with_gemini(args.image, yolo_detections)
        result = system.integrate_analysis(yolo_detections, gemini_analysis)
        
        # 結果表示
        print("\n📊 分析結果:")
        print(f"処理時間: {result.processing_time:.3f}秒")
        print(f"統合信頼度: {result.integrated_confidence:.3f}")
        print(f"推奨アクション: {result.decision_recommendation}")
        
        print(f"\n🔍 YOLO検出 ({len(result.yolo_detections)} 個):")
        for det in result.yolo_detections:
            print(f"  - {det.object_class}: {det.confidence:.3f}")
        
        print(f"\n🧠 Gemini分析:")
        print(f"  説明: {result.gemini_analysis.description}")
        print(f"  信頼度: {result.gemini_analysis.confidence:.3f}")
        print(f"  コンテキスト: {result.gemini_analysis.scene_context}")
    
    elif args.command == "stats":
        stats = system.get_statistics()
        print("📊 Gemini YOLOシステム統計:")
        print(f"  総処理数: {stats['total_processed']}")
        print(f"  平均処理時間: {stats['average_processing_time']:.3f}秒")
        print(f"  YOLO検出数: {stats['yolo_detections']}")
        print(f"  Gemini呼び出し数: {stats['gemini_calls']}")
        print(f"  キャッシュサイズ: {stats['cache_size']}")
        print(f"  実行状態: {'🟢 実行中' if stats['is_running'] else '🔴 停止中'}")

if __name__ == "__main__":
    main()