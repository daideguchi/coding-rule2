#!/usr/bin/env python3
"""
Gemini API Integration System with Claude Code Coordination
Gemini API統合システム - Claude Code連携対応
"""

import asyncio
import json
import aiohttp
import time
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import aiofiles
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('GeminiIntegration')

@dataclass
class ContentAnalysis:
    """Content analysis result"""
    quality_score: int
    word_count: int
    structure_score: int
    readability_score: int
    suggestions: List[str]
    timestamp: str

@dataclass
class BookProject:
    """Book project data structure"""
    id: str
    title: str
    target_audience: str
    chapters: List[Dict]
    status: str
    created_at: str
    updated_at: str
    
class SharedStateMonitor(FileSystemEventHandler):
    """Shared state file monitor"""
    
    def __init__(self, callback):
        self.callback = callback
        self.last_modified = 0
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        # Rate limiting to prevent excessive callbacks
        current_time = time.time()
        if current_time - self.last_modified < 1.0:  # 1秒間隔
            return
            
        self.last_modified = current_time
        asyncio.create_task(self.callback())

class GeminiIntegration:
    """Gemini API Integration with Claude Code coordination"""
    
    def __init__(self):
        self.config = {
            'api_key': os.getenv('GEMINI_API_KEY'),
            'api_endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent',
            'shared_state_path': './ai-collaboration/shared-state.json',
            'monitoring_interval': 5.0,
            'max_retries': 3,
            'timeout': 30.0
        }
        
        if not self.config['api_key']:
            raise ValueError('GEMINI_API_KEY environment variable required')
            
        self.session: Optional[aiohttp.ClientSession] = None
        self.shared_state: Dict = {}
        self.running = False
        self.file_observer: Optional[Observer] = None
        
        # 品質チェック器の初期化
        self.quality_analyzer = QualityAnalyzer()
        self.kindle_checker = KindleQualityChecker()
        
        # 統計情報
        self.statistics = {
            'api_calls': 0,
            'successful_calls': 0,
            'failed_calls': 0,
            'content_generated': 0,
            'books_completed': 0,
            'uptime_start': datetime.now().isoformat()
        }
    
    async def initialize(self) -> bool:
        """Initialize the Gemini integration system"""
        logger.info('🚀 Initializing Gemini Integration System...')
        
        try:
            # HTTPセッション作成
            self.session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.config['timeout'])
            )
            
            # API接続テスト
            await self.test_api_connection()
            
            # 共通状態ファイルの読み込み
            await self.load_shared_state()
            
            # ファイル監視開始
            await self.start_file_monitoring()
            
            # Gemini状態更新
            await self.update_gemini_status({
                'status': 'initialized',
                'current_task': 'ready_for_collaboration',
                'capabilities': [
                    'content_generation',
                    'creative_writing', 
                    'quality_analysis',
                    'real_time_collaboration'
                ]
            })
            
            self.running = True
            logger.info('✅ Gemini Integration System initialized successfully')
            return True
            
        except Exception as e:
            logger.error(f'❌ Initialization failed: {e}')
            await self.cleanup()
            raise
    
    async def test_api_connection(self) -> bool:
        """Test Gemini API connection"""
        test_prompt = 'Test connection - respond with "Connection successful"'
        
        try:
            response = await self.call_gemini_api(test_prompt)
            if 'successful' in response.lower():
                logger.info('✅ Gemini API connection verified')
                return True
            else:
                raise Exception(f'Unexpected test response: {response}')
        except Exception as e:
            logger.error(f'❌ API connection test failed: {e}')
            raise
    
    async def call_gemini_api(
        self, 
        prompt: str, 
        system_instruction: Optional[str] = None,
        max_tokens: int = 2048
    ) -> str:
        """Call Gemini API with retry logic"""
        
        request_data = {
            'contents': [{
                'parts': [{'text': prompt}]
            }],
            'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': max_tokens,
                'stopSequences': []
            }
        }
        
        if system_instruction:
            request_data['systemInstruction'] = {
                'parts': [{'text': system_instruction}]
            }
        
        headers = {
            'Content-Type': 'application/json',
            'x-goog-api-key': self.config['api_key']
        }
        
        for attempt in range(self.config['max_retries']):
            try:
                self.statistics['api_calls'] += 1
                
                async with self.session.post(
                    self.config['api_endpoint'],
                    json=request_data,
                    headers=headers
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        
                        if 'candidates' in result and result['candidates']:
                            content = result['candidates'][0]['content']['parts'][0]['text']
                            self.statistics['successful_calls'] += 1
                            return content
                        else:
                            raise Exception('No content in API response')
                    else:
                        error_text = await response.text()
                        raise Exception(f'API error {response.status}: {error_text}')
                        
            except Exception as e:
                self.statistics['failed_calls'] += 1
                logger.warning(f'API call attempt {attempt + 1} failed: {e}')
                
                if attempt < self.config['max_retries'] - 1:
                    wait_time = (2 ** attempt) * 1.0  # 指数バックオフ
                    await asyncio.sleep(wait_time)
                else:
                    raise
    
    async def load_shared_state(self) -> None:
        """Load shared state from file"""
        try:
            async with aiofiles.open(self.config['shared_state_path'], 'r', encoding='utf-8') as f:
                content = await f.read()
                self.shared_state = json.loads(content)
            logger.info('📊 Shared state loaded successfully')
        except FileNotFoundError:
            logger.warning('⚠️ Shared state file not found, creating new one')
            self.shared_state = self.create_initial_shared_state()
            await self.save_shared_state()
        except Exception as e:
            logger.error(f'❌ Failed to load shared state: {e}')
            raise
    
    def create_initial_shared_state(self) -> Dict:
        """Create initial shared state structure"""
        return {
            'system_info': {
                'version': '2.0.0',
                'last_updated': datetime.now().isoformat(),
                'active_ais': ['claude_code', 'gemini_api'],
                'status': 'initializing'
            },
            'current_projects': {
                'active_books': [],
                'queue': [],
                'completed': []
            },
            'ai_communication': {
                'claude_code': {
                    'status': 'disconnected',
                    'current_task': 'waiting_for_connection',
                    'last_activity': datetime.now().isoformat(),
                    'message_queue': [],
                    'capabilities': []
                },
                'gemini_api': {
                    'status': 'initializing',
                    'current_task': 'system_startup',
                    'last_activity': datetime.now().isoformat(),
                    'message_queue': [],
                    'capabilities': []
                }
            },
            'book_production': {
                'workflow_state': 'idle',
                'current_book': None,
                'production_metrics': {
                    'books_in_progress': 0,
                    'books_completed': 0,
                    'average_quality_score': 0,
                    'production_rate': '0 books/month'
                }
            },
            'quality_control': {
                'review_queue': [],
                'quality_standards': {
                    'minimum_score': 85,
                    'required_word_count': 20000,
                    'chapter_count': 8,
                    'revision_cycles': 3
                },
                'metrics': {
                    'total_reviews': 0,
                    'approved_content': 0,
                    'revision_requests': 0,
                    'average_score': 0
                }
            }
        }
    
    async def save_shared_state(self) -> None:
        """Save shared state to file"""
        try:
            # ディレクトリ作成
            Path(self.config['shared_state_path']).parent.mkdir(parents=True, exist_ok=True)
            
            async with aiofiles.open(self.config['shared_state_path'], 'w', encoding='utf-8') as f:
                await f.write(json.dumps(self.shared_state, indent=2, ensure_ascii=False))
        except Exception as e:
            logger.error(f'❌ Failed to save shared state: {e}')
    
    async def start_file_monitoring(self) -> None:
        """Start monitoring shared state file for changes"""
        try:
            # ファイル監視システム設定
            self.file_observer = Observer()
            event_handler = SharedStateMonitor(self.on_shared_state_change)
            
            watch_dir = Path(self.config['shared_state_path']).parent
            self.file_observer.schedule(event_handler, str(watch_dir), recursive=False)
            self.file_observer.start()
            
            logger.info('🔄 File monitoring started')
        except Exception as e:
            logger.error(f'❌ Failed to start file monitoring: {e}')
    
    async def on_shared_state_change(self) -> None:
        """Handle shared state file changes"""
        try:
            await self.load_shared_state()
            await self.process_claude_messages()
            await self.check_workflow_state()
        except Exception as e:
            logger.error(f'❌ Error processing shared state change: {e}')
    
    async def update_gemini_status(self, updates: Dict) -> None:
        """Update Gemini status in shared state"""
        try:
            await self.load_shared_state()
            
            self.shared_state['ai_communication']['gemini_api'].update({
                **updates,
                'last_activity': datetime.now().isoformat()
            })
            
            await self.save_shared_state()
            logger.debug(f'📝 Gemini status updated: {updates.get("current_task", "status update")}')
        except Exception as e:
            logger.error(f'❌ Failed to update Gemini status: {e}')
    
    async def process_claude_messages(self) -> None:
        """Process messages from Claude Code"""
        try:
            messages = self.shared_state['ai_communication']['gemini_api']['message_queue']
            
            if messages:
                logger.info(f'📨 Processing {len(messages)} messages from Claude Code')
                
                for message in messages:
                    await self.handle_claude_message(message)
                
                # メッセージキューをクリア
                await self.update_gemini_status({'message_queue': []})
        except Exception as e:
            logger.error(f'❌ Error processing Claude messages: {e}')
    
    async def handle_claude_message(self, message: Dict) -> None:
        """Handle individual message from Claude Code"""
        message_type = message.get('type')
        message_data = message.get('data', {})
        
        logger.info(f'📝 Handling Claude message: {message_type}')
        
        try:
            if message_type == 'review_result':
                await self.handle_review_result(message_data)
            elif message_type == 'quality_feedback':
                await self.handle_quality_feedback(message_data)
            elif message_type == 'content_request':
                await self.handle_content_request(message_data)
            elif message_type == 'collaboration_request':
                await self.handle_collaboration_request(message_data)
            else:
                logger.warning(f'❓ Unknown message type from Claude: {message_type}')
        except Exception as e:
            logger.error(f'❌ Error handling Claude message {message_type}: {e}')
    
    async def handle_review_result(self, review_data: Dict) -> None:
        """Handle content review result from Claude"""
        approval_status = review_data.get('approval_status')
        
        if approval_status == 'approved':
            logger.info('✅ Content approved by Claude Code')
            await self.continue_content_generation()
        elif approval_status == 'revision_required':
            logger.info('🔄 Content revision requested by Claude Code')
            await self.revise_content(review_data)
        
        await self.update_gemini_status({
            'current_task': f'processed_review_{approval_status}',
            'last_review_result': review_data
        })
    
    async def handle_quality_feedback(self, feedback_data: Dict) -> None:
        """Handle quality improvement feedback"""
        feedback_items = feedback_data.get('feedback', [])
        
        if feedback_items:
            logger.info(f'💡 Received {len(feedback_items)} quality improvement suggestions')
            
            # フィードバックを今後のコンテンツ生成に反映
            await self.apply_quality_improvements(feedback_items)
    
    async def handle_content_request(self, request_data: Dict) -> None:
        """Handle content generation request from Claude"""
        content_type = request_data.get('type', 'general')
        specifications = request_data.get('specifications', {})
        
        logger.info(f'✍️ Generating {content_type} content as requested by Claude')
        
        await self.update_gemini_status({
            'status': 'generating_content',
            'current_task': f'creating_{content_type}_content'
        })
        
        content = await self.generate_requested_content(content_type, specifications)
        await self.send_content_to_claude(content, request_data)
    
    async def generate_requested_content(self, content_type: str, specs: Dict) -> str:
        """Generate content based on Claude's request"""
        
        if content_type == 'chapter':
            return await self.generate_chapter_content(specs)
        elif content_type == 'book_outline':
            return await self.generate_book_outline(specs)
        elif content_type == 'analysis':
            return await self.generate_content_analysis(specs)
        else:
            return await self.generate_general_content(specs)
    
    async def generate_chapter_content(self, specs: Dict) -> str:
        """Generate chapter content using Gemini API"""
        
        chapter_title = specs.get('title', '無題の章')
        book_context = specs.get('book_context', '')
        target_words = specs.get('target_words', 3000)
        
        system_instruction = """
You are a professional Japanese content writer specializing in business and self-improvement books.
Write high-quality, practical content that provides real value to readers.
Include specific examples, data, and actionable advice.
"""
        
        prompt = f"""
以下の章を執筆してください：

章タイトル：{chapter_title}
本のコンテキスト：{book_context}
目標文字数：{target_words}文字以上

執筆要件：
- 具体的な数値データを3つ以上含める
- 実例や事例を2つ以上紹介する
- 読者が実際に行動できる具体的な手順を提供する
- 適切な見出しで構造化する
- ビジネス書としての品質を保つ

読者に価値を提供する内容を目指してください。
"""
        
        try:
            content = await self.call_gemini_api(prompt, system_instruction)
            
            # 品質チェック
            analysis = await self.quality_analyzer.analyze_content(content)
            
            if analysis.quality_score < 80:
                logger.info('🔄 Content quality below threshold, improving...')
                content = await self.improve_content_quality(content, analysis.suggestions)
            
            self.statistics['content_generated'] += 1
            return content
            
        except Exception as e:
            logger.error(f'❌ Chapter generation failed: {e}')
            return f'# {chapter_title}\n\nコンテンツ生成エラー: {str(e)}'
    
    async def improve_content_quality(self, content: str, suggestions: List[str]) -> str:
        """Improve content quality based on suggestions"""
        
        improvement_prompt = f"""
以下の文章を改善してください：

元の文章：
{content}

改善項目：
{"; ".join(suggestions)}

より高品質な内容に修正してください。
"""
        
        try:
            improved_content = await self.call_gemini_api(improvement_prompt)
            return improved_content
        except Exception as e:
            logger.error(f'❌ Content improvement failed: {e}')
            return content  # 元のコンテンツを返す
    
    async def send_content_to_claude(self, content: str, request_data: Dict) -> None:
        """Send generated content to Claude Code for review"""
        
        content_submission = {
            'type': 'content_submission',
            'timestamp': datetime.now().isoformat(),
            'data': {
                'content': content,
                'request_id': request_data.get('request_id'),
                'content_type': request_data.get('type'),
                'word_count': len(content.split()),
                'generation_time': datetime.now().isoformat()
            },
            'sender': 'gemini_api'
        }
        
        # Claude Codeのメッセージキューに追加
        self.shared_state['ai_communication']['claude_code']['message_queue'].append(content_submission)
        await self.save_shared_state()
        
        logger.info('📤 Content sent to Claude Code for review')
    
    async def check_workflow_state(self) -> None:
        """Check and respond to workflow state changes"""
        workflow_state = self.shared_state['book_production']['workflow_state']
        
        if workflow_state == 'idle':
            await self.propose_new_project()
        elif workflow_state == 'writing':
            await self.continue_writing_workflow()
        elif workflow_state == 'reviewing':
            await self.support_review_process()
    
    async def propose_new_project(self) -> None:
        """Propose a new book project"""
        try:
            logger.info('💡 Proposing new book project...')
            
            await self.update_gemini_status({
                'status': 'proposing_project',
                'current_task': 'generating_book_concept'
            })
            
            book_concept = await self.generate_book_concept()
            
            # 新しいプロジェクトを共通状態に追加
            self.shared_state['current_projects']['queue'].append(book_concept)
            await self.save_shared_state()
            
            # Claude Codeに提案を送信
            proposal = {
                'type': 'project_proposal',
                'timestamp': datetime.now().isoformat(),
                'data': book_concept,
                'sender': 'gemini_api'
            }
            
            self.shared_state['ai_communication']['claude_code']['message_queue'].append(proposal)
            await self.save_shared_state()
            
            logger.info(f'📚 New book proposal: "{book_concept["title"]}"')
            
        except Exception as e:
            logger.error(f'❌ Failed to propose new project: {e}')
    
    async def generate_book_concept(self) -> Dict:
        """Generate a new book concept using Gemini API"""
        
        prompt = """
新しいKindle本のアイデアを提案してください。

分野：AIビジネス、副業、マーケティング、自己啓発
条件：
- 実用的で今すぐ役立つ内容
- 初心者から中級者向け
- 8章構成
- 各章は具体的で実践的な内容

JSON形式で以下の構造で回答してください：
{
  "title": "本のタイトル",
  "target_audience": "ターゲット読者",
  "description": "本の説明",
  "chapters": [
    {"number": 1, "title": "章タイトル", "summary": "章の概要"},
    ...
  ]
}
"""
        
        try:
            response = await self.call_gemini_api(prompt)
            book_data = self.extract_json_from_response(response)
            
            # メティデータ追加
            book_data.update({
                'id': f'book_{int(time.time())}',
                'status': 'proposed',
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat(),
                'generated_by': 'gemini_api'
            })
            
            return book_data
            
        except Exception as e:
            logger.error(f'❌ Book concept generation failed: {e}')
            # フォールバックアイデア
            return self.get_fallback_book_concept()
    
    def extract_json_from_response(self, response: str) -> Dict:
        """Extract JSON from Gemini response"""
        try:
            import re
            
            # JSONブロックを探す
            json_match = re.search(r'```json\s*([\s\S]*?)\s*```', response, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(1))
            
            # 直接JSONを探す
            start = response.find('{')
            end = response.rfind('}') + 1
            if start != -1 and end != 0:
                return json.loads(response[start:end])
                
        except Exception as e:
            logger.warning(f'JSON extraction failed: {e}')
        
        return self.get_fallback_book_concept()
    
    def get_fallback_book_concept(self) -> Dict:
        """Get fallback book concept when generation fails"""
        return {
            'title': 'AI活用実践ガイド：ビジネスを変革する10の手法',
            'target_audience': 'AIをビジネスに活用したい経営者・ビジネスパーソン',
            'description': 'AIをビジネスに活用するための実践的な手法を紹介',
            'chapters': [
                {'number': 1, 'title': 'AIビジネス活用の基本', 'summary': 'AIの基本理解とビジネス応用'},
                {'number': 2, 'title': '業務自動化と効率化', 'summary': 'AIで業務を自動化する方法'},
                {'number': 3, 'title': 'データ分析と意思決定', 'summary': 'AIでデータを分析し意思決定を支援'},
                {'number': 4, 'title': '顧客サービスの高度化', 'summary': 'AIで顧客サービスを向上させる'},
                {'number': 5, 'title': 'マーケティング戦略の最適化', 'summary': 'AIでマーケティングを最適化'},
                {'number': 6, 'title': 'リスク管理とセキュリティ', 'summary': 'AI導入時のリスクと対策'},
                {'number': 7, 'title': '組織変革と人材育成', 'summary': 'AI時代の組織運営と人材育成'},
                {'number': 8, 'title': '未来戦略と持続成長', 'summary': 'AIを活用した持続成長戦略'}
            ]
        }
    
    async def run_monitoring_loop(self) -> None:
        """Main monitoring loop"""
        logger.info('🔄 Starting Gemini monitoring loop...')
        
        while self.running:
            try:
                await self.load_shared_state()
                await self.process_claude_messages()
                await self.check_workflow_state()
                await self.update_statistics()
                await asyncio.sleep(self.config['monitoring_interval'])
                
            except Exception as e:
                logger.error(f'❌ Monitoring loop error: {e}')
                await asyncio.sleep(10)  # エラー時は長めに待機
    
    async def update_statistics(self) -> None:
        """Update system statistics"""
        self.statistics.update({
            'last_update': datetime.now().isoformat(),
            'uptime_seconds': (datetime.now() - datetime.fromisoformat(self.statistics['uptime_start'])).total_seconds()
        })
        
        await self.update_gemini_status({
            'statistics': self.statistics
        })
    
    async def cleanup(self) -> None:
        """Cleanup resources"""
        logger.info('🛑 Cleaning up Gemini Integration System...')
        
        self.running = False
        
        if self.file_observer:
            self.file_observer.stop()
            self.file_observer.join()
        
        if self.session:
            await self.session.close()
        
        logger.info('✅ Cleanup completed')

class QualityAnalyzer:
    """Content quality analysis system"""
    
    async def analyze_content(self, content: str) -> ContentAnalysis:
        """Analyze content quality"""
        word_count = len(content.split())
        
        # 構造スコア
        structure_score = self.calculate_structure_score(content)
        
        # 読みやすさスコア
        readability_score = self.calculate_readability_score(content)
        
        # 総合品質スコア
        quality_score = self.calculate_overall_quality_score(
            word_count, structure_score, readability_score
        )
        
        # 改善提案
        suggestions = self.generate_improvement_suggestions(
            content, word_count, structure_score, readability_score
        )
        
        return ContentAnalysis(
            quality_score=quality_score,
            word_count=word_count,
            structure_score=structure_score,
            readability_score=readability_score,
            suggestions=suggestions,
            timestamp=datetime.now().isoformat()
        )
    
    def calculate_structure_score(self, content: str) -> int:
        """Calculate content structure score"""
        score = 60  # ベーススコア
        
        # 見出しの数
        headings = len([line for line in content.split('\n') if line.strip().startswith('#')])
        if headings >= 3:
            score += 20
        elif headings >= 1:
            score += 10
        
        # リストの数
        lists = len([line for line in content.split('\n') if line.strip().startswith(('-', '*', '+'))])
        if lists >= 5:
            score += 10
        elif lists >= 2:
            score += 5
        
        # 段落数
        paragraphs = len([p for p in content.split('\n\n') if p.strip()])
        if paragraphs >= 5:
            score += 10
        
        return min(score, 100)
    
    def calculate_readability_score(self, content: str) -> int:
        """Calculate readability score"""
        sentences = [s for s in content.split('。') if s.strip()]
        if not sentences:
            return 50
        
        words = content.split()
        avg_words_per_sentence = len(words) / len(sentences)
        
        # 適切な文長かどうか
        if 15 <= avg_words_per_sentence <= 25:
            return 90
        elif 10 <= avg_words_per_sentence <= 30:
            return 75
        else:
            return 60
    
    def calculate_overall_quality_score(self, word_count: int, structure: int, readability: int) -> int:
        """Calculate overall quality score"""
        base_score = 40
        
        # 文字数スコア
        word_score = 0
        if word_count >= 3000:
            word_score = 25
        elif word_count >= 2000:
            word_score = 15
        elif word_count >= 1000:
            word_score = 10
        
        # 重み付き平均
        overall = int(base_score + word_score + (structure * 0.2) + (readability * 0.15))
        return min(overall, 100)
    
    def generate_improvement_suggestions(self, content: str, word_count: int, structure: int, readability: int) -> List[str]:
        """Generate improvement suggestions"""
        suggestions = []
        
        if word_count < 2000:
            suggestions.append('文字数を増やしてより詳細な内容にしてください')
        
        if structure < 70:
            suggestions.append('見出しやリストを使って構造を整理してください')
        
        if readability < 70:
            suggestions.append('文長を適切に調整して読みやすさを向上させてください')
        
        # 具体的な要素のチェック
        if '例：' not in content and '具体例' not in content:
            suggestions.append('具体例や事例を追加してください')
        
        import re
        if len(re.findall(r'\d+[%円人時間]', content)) < 3:
            suggestions.append('数値データをより多く含めてください')
        
        return suggestions

class KindleQualityChecker:
    """Kindle book specific quality checker"""
    
    def check_kindle_readiness(self, book_data: Dict) -> Dict:
        """Check if book is ready for Kindle publishing"""
        
        title_score = self.check_title_optimization(book_data.get('title', ''))
        structure_score = self.check_book_structure(book_data.get('chapters', []))
        content_score = self.check_content_quality(book_data)
        
        overall_score = (title_score + structure_score + content_score) / 3
        
        return {
            'overall_score': int(overall_score),
            'title_score': title_score,
            'structure_score': structure_score,
            'content_score': content_score,
            'ready_for_publish': overall_score >= 85,
            'recommendations': self.generate_kindle_recommendations(book_data, overall_score)
        }
    
    def check_title_optimization(self, title: str) -> int:
        """Check title optimization for Kindle"""
        score = 50
        
        # キーワードの有無
        keywords = ['AI', '副業', 'ガイド', '実践', '完全', '手法', '方法']
        keyword_count = sum(1 for keyword in keywords if keyword in title)
        score += keyword_count * 10
        
        # タイトル長
        if 20 <= len(title) <= 60:
            score += 10
        
        return min(score, 100)
    
    def check_book_structure(self, chapters: List[Dict]) -> int:
        """Check book structure"""
        if not chapters:
            return 0
        
        score = 60
        
        # 章数
        if len(chapters) >= 8:
            score += 20
        elif len(chapters) >= 5:
            score += 10
        
        # 各章の内容有無
        content_chapters = sum(1 for ch in chapters if ch.get('content', '').strip())
        if content_chapters == len(chapters):
            score += 20
        
        return min(score, 100)
    
    def check_content_quality(self, book_data: Dict) -> int:
        """Check overall content quality"""
        chapters = book_data.get('chapters', [])
        if not chapters:
            return 0
        
        total_words = sum(len(ch.get('content', '').split()) for ch in chapters)
        
        score = 50
        if total_words >= 20000:
            score += 30
        elif total_words >= 15000:
            score += 20
        elif total_words >= 10000:
            score += 10
        
        return min(score, 100)
    
    def generate_kindle_recommendations(self, book_data: Dict, overall_score: float) -> List[str]:
        """Generate Kindle-specific recommendations"""
        recommendations = []
        
        if overall_score < 85:
            if overall_score < 70:
                recommendations.append('本の全体的な品質向上が必要です')
            
            title = book_data.get('title', '')
            if len(title) < 20:
                recommendations.append('タイトルをより詳細にしてSEOを向上させてください')
            
            chapters = book_data.get('chapters', [])
            if len(chapters) < 8:
                recommendations.append('章数を8章以上に増やしてください')
        
        return recommendations

# メイン実行部
async def main():
    """Main execution function"""
    
    # 環境変数チェック
    if not os.getenv('GEMINI_API_KEY'):
        logger.error('❌ GEMINI_API_KEY environment variable is required')
        print('💡 Set it with: export GEMINI_API_KEY="your-api-key"')
        return
    
    gemini_integration = None
    
    try:
        # システム初期化
        gemini_integration = GeminiIntegration()
        await gemini_integration.initialize()
        
        # 監視ループ開始
        await gemini_integration.run_monitoring_loop()
        
    except KeyboardInterrupt:
        logger.info('⚠️  Received keyboard interrupt, shutting down gracefully...')
    except Exception as e:
        logger.error(f'❌ System error: {e}')
    finally:
        if gemini_integration:
            await gemini_integration.cleanup()

if __name__ == '__main__':
    asyncio.run(main())
