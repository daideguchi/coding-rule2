#!/usr/bin/env python3
"""
Gemini YOLO System for Kindle Book Production
実際に動作するKindle本量産システム - Gemini担当部分
"""

import json
import time
import os
import asyncio
import logging
from datetime import datetime
from pathlib import Path
import google.generativeai as genai
from typing import Dict, List, Optional

class GeminiYolo:
    def __init__(self):
        self.shared_state_path = Path('../ai-collaboration/shared-state.json')
        self.project_root = Path.cwd()
        self.current_book = None
        self.writing_standards = {
            'chapter_word_count': 3000,
            'min_examples': 2,
            'min_numbers': 3,
            'creativity_level': 'maximum'
        }
        
        # ログ設定
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger('GeminiYolo')
        
        # Gemini API設定
        self.setup_gemini()

    def setup_gemini(self):
        """Gemini API設定"""
        try:
            # 環境変数からAPIキー取得
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                raise ValueError("GEMINI_API_KEY not found in environment variables")
            
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-pro')
            self.logger.info("✅ Gemini API configured successfully")
        except Exception as e:
            self.logger.error(f"❌ Gemini API setup failed: {e}")
            raise

    async def initialize(self):
        """システム初期化"""
        self.logger.info("🚀 Gemini YOLO System initializing...")
        
        # 共通状態ファイル読み込み
        await self.load_shared_state()
        
        # Gemini接続確認
        await self.verify_gemini()
        
        # 監視ループ開始
        await self.start_monitoring_loop()
        
        self.logger.info("✅ Gemini YOLO System ready for creative production")

    async def load_shared_state(self):
        """共通状態ファイル読み込み"""
        try:
            with open(self.shared_state_path, 'r', encoding='utf-8') as f:
                self.shared_state = json.load(f)
            self.logger.info("📊 Shared state loaded successfully")
        except Exception as e:
            self.logger.error(f"❌ Failed to load shared state: {e}")
            raise

    async def update_shared_state(self, updates: Dict):
        """共通状態ファイル更新"""
        try:
            # 現在の状態を読み込み
            await self.load_shared_state()
            
            # Geminiの状態を更新
            self.shared_state['ai_communication']['gemini_yolo'].update({
                **updates,
                'last_activity': datetime.now().isoformat()
            })
            
            # ファイルに書き込み
            with open(self.shared_state_path, 'w', encoding='utf-8') as f:
                json.dump(self.shared_state, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"📝 Shared state updated: {updates.get('current_task', 'status update')}")
        except Exception as e:
            self.logger.error(f"❌ Failed to update shared state: {e}")

    async def verify_gemini(self):
        """Gemini接続確認"""
        try:
            # テスト生成
            response = self.model.generate_content("Test connection")
            if response.text:
                await self.update_shared_state({
                    'status': 'authenticated',
                    'current_task': 'ready_for_creative_writing'
                })
                self.logger.info("✅ Gemini connection verified")
            else:
                raise Exception("No response from Gemini")
        except Exception as e:
            self.logger.error(f"❌ Gemini verification failed: {e}")
            await self.update_shared_state({
                'status': 'error',
                'current_task': 'authentication_failed'
            })

    async def start_monitoring_loop(self):
        """監視ループ開始"""
        self.logger.info("🔄 Starting monitoring loop...")
        
        while True:
            try:
                await self.load_shared_state()
                await self.process_message_queue()
                await self.check_for_writing_assignments()
                await self.continue_active_writing()
                await asyncio.sleep(10)  # 10秒間隔
            except Exception as e:
                self.logger.error(f"❌ Monitoring loop error: {e}")
                await asyncio.sleep(30)

    async def process_message_queue(self):
        """メッセージキュー処理"""
        messages = self.shared_state['ai_communication']['gemini_yolo']['message_queue']
        
        if messages:
            self.logger.info(f"📨 Processing {len(messages)} messages...")
            
            for message in messages:
                await self.handle_message(message)
            
            # メッセージキューをクリア
            await self.update_shared_state({'message_queue': []})

    async def handle_message(self, message: Dict):
        """メッセージ処理"""
        self.logger.info(f"📝 Handling message: {message['type']}")
        
        message_type = message['type']
        if message_type == 'start_new_book':
            await self.start_new_book(message['data'])
        elif message_type == 'write_chapter':
            await self.write_chapter(message['data'])
        elif message_type == 'review_feedback':
            await self.process_review_feedback(message['data'])
        elif message_type == 'revise_content':
            await self.revise_content(message['data'])
        else:
            self.logger.warning(f"❓ Unknown message type: {message_type}")

    async def check_for_writing_assignments(self):
        """執筆課題確認"""
        workflow_state = self.shared_state['book_production']['workflow_state']
        
        if workflow_state == 'idle':
            # 新しい本の執筆を開始
            await self.propose_new_book()

    async def propose_new_book(self):
        """新しい本の提案"""
        self.logger.info("💡 Proposing new book idea...")
        
        await self.update_shared_state({
            'current_task': 'generating_book_idea',
            'status': 'busy'
        })

        # 新しい本のアイデア生成
        book_idea = await self.generate_book_idea()
        
        # 共通状態に新しい本を追加
        self.shared_state['current_projects']['active_books'].append(book_idea)
        self.shared_state['book_production']['workflow_state'] = 'writing'
        self.shared_state['book_production']['current_book'] = book_idea['id']
        
        with open(self.shared_state_path, 'w', encoding='utf-8') as f:
            json.dump(self.shared_state, f, indent=2, ensure_ascii=False)
        
        await self.update_shared_state({
            'current_task': 'book_idea_proposed',
            'status': 'writing'
        })
        
        self.logger.info(f"📚 New book proposed: {book_idea['title']}")

    async def generate_book_idea(self) -> Dict:
        """本のアイデア生成"""
        prompt = """
        AIビジネス、副業、自己啓発、マーケティングの分野で、
        Kindle本として人気が出そうな実用的なテーマを1つ提案してください。

        以下の要素を含めてください：
        - 具体的なタイトル
        - ターゲット読者
        - 8章構成の詳細な目次
        - 各章で扱う具体的な内容
        - 実際の数字や事例を含む実用性

        JSON形式で回答してください。
        """
        
        try:
            response = self.model.generate_content(prompt)
            # JSONの抽出と解析
            book_data = self.extract_json_from_response(response.text)
            
            # IDと基本情報を追加
            book_data.update({
                'id': f"book_{int(time.time())}",
                'creation_date': datetime.now().isoformat(),
                'status': 'planning',
                'chapters_completed': 0,
                'total_chapters': 8,
                'current_chapter': 1,
                'word_count': 0
            })
            
            return book_data
        except Exception as e:
            self.logger.error(f"❌ Book idea generation failed: {e}")
            # フォールバック用のデフォルト本
            return self.get_default_book_idea()

    def extract_json_from_response(self, text: str) -> Dict:
        """レスポンスからJSON抽出"""
        try:
            # ```json と ``` で囲まれた部分を抽出
            import re
            json_match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(1))
            else:
                # JSON部分を直接探す
                start = text.find('{')
                end = text.rfind('}') + 1
                if start != -1 and end != 0:
                    return json.loads(text[start:end])
        except Exception as e:
            self.logger.warning(f"JSON extraction failed: {e}")
        
        return self.get_default_book_idea()

    def get_default_book_idea(self) -> Dict:
        """デフォルト本アイデア"""
        return {
            "title": "AI時代の副業完全ガイド：月10万円を稼ぐ実践方法",
            "target_audience": "副業を始めたいサラリーマン・主婦",
            "chapters": [
                {"number": 1, "title": "AI副業の基礎知識", "content": ""},
                {"number": 2, "title": "ChatGPTを活用した文章作成副業", "content": ""},
                {"number": 3, "title": "画像生成AIを使ったデザイン副業", "content": ""},
                {"number": 4, "title": "AIプログラミング副業の始め方", "content": ""},
                {"number": 5, "title": "AI×動画編集で稼ぐ方法", "content": ""},
                {"number": 6, "title": "AIコンサルティング副業", "content": ""},
                {"number": 7, "title": "AI教育・研修事業の立ち上げ", "content": ""},
                {"number": 8, "title": "継続的収入を得るAIビジネス戦略", "content": ""}
            ]
        }

    async def continue_active_writing(self):
        """進行中の執筆を継続"""
        current_book_id = self.shared_state['book_production']['current_book']
        
        if current_book_id:
            # 現在の本を取得
            active_books = self.shared_state['current_projects']['active_books']
            current_book = next((book for book in active_books if book['id'] == current_book_id), None)
            
            if current_book and current_book['chapters_completed'] < current_book['total_chapters']:
                await self.write_next_chapter(current_book)

    async def write_next_chapter(self, book: Dict):
        """次の章を執筆"""
        next_chapter_num = book['current_chapter']
        
        if next_chapter_num <= book['total_chapters']:
            self.logger.info(f"✍️ Writing chapter {next_chapter_num}: {book['title']}")
            
            await self.update_shared_state({
                'current_task': f'writing_chapter_{next_chapter_num}',
                'status': 'writing'
            })
            
            chapter_content = await self.generate_chapter_content(book, next_chapter_num)
            
            # 章をClaudeのレビューキューに追加
            await self.submit_for_review(book, next_chapter_num, chapter_content)

    async def generate_chapter_content(self, book: Dict, chapter_num: int) -> str:
        """章の内容生成"""
        chapter_info = book['chapters'][chapter_num - 1]
        
        prompt = f"""
        書籍「{book['title']}」の第{chapter_num}章「{chapter_info['title']}」を執筆してください。

        要件：
        - 3000文字以上の本格的な内容
        - 具体的な数字を3つ以上含める
        - 実体験や具体的事例を2つ以上含める
        - 読者が実際に行動できる具体的な手順を含める
        - 見出しを使って読みやすく構成する

        ターゲット読者：{book['target_audience']}

        実用的で価値のある内容にしてください。
        """
        
        try:
            response = self.model.generate_content(prompt)
            content = response.text
            
            self.logger.info(f"📝 Chapter {chapter_num} completed: {len(content)} characters")
            return content
        except Exception as e:
            self.logger.error(f"❌ Chapter generation failed: {e}")
            return f"# 第{chapter_num}章 {chapter_info['title']}\n\n執筆エラーが発生しました。再試行が必要です。"

    async def submit_for_review(self, book: Dict, chapter_num: int, content: str):
        """レビュー提出"""
        review_item = {
            'book_id': book['id'],
            'book_title': book['title'],
            'chapter_number': chapter_num,
            'chapter_title': book['chapters'][chapter_num - 1]['title'],
            'content': content,
            'word_count': len(content.split()),
            'submission_time': datetime.now().isoformat(),
            'status': 'pending_review'
        }
        
        # Claude Codeのメッセージキューに追加
        self.shared_state['ai_communication']['claude_code']['message_queue'].append({
            'type': 'review_request',
            'timestamp': datetime.now().isoformat(),
            'data': review_item,
            'sender': 'gemini_yolo'
        })
        
        # レビューキューにも追加
        self.shared_state['quality_control']['review_queue'].append(review_item)
        
        with open(self.shared_state_path, 'w', encoding='utf-8') as f:
            json.dump(self.shared_state, f, indent=2, ensure_ascii=False)
        
        await self.update_shared_state({
            'current_task': f'chapter_{chapter_num}_submitted_for_review',
            'status': 'waiting_for_review'
        })
        
        self.logger.info(f"📤 Chapter {chapter_num} submitted for Claude review")

    async def process_review_feedback(self, review_data: Dict):
        """レビューフィードバック処理"""
        self.logger.info(f"📨 Processing review feedback: {review_data['quality_score']}/100")
        
        if review_data['approval_status'] == 'approved':
            await self.handle_chapter_approval(review_data)
        else:
            await self.handle_revision_request(review_data)

    async def handle_chapter_approval(self, review_data: Dict):
        """章承認処理"""
        self.logger.info("✅ Chapter approved by Claude")
        
        # 本の情報を更新
        await self.update_book_progress(review_data, approved=True)
        
        await self.update_shared_state({
            'current_task': 'chapter_approved_continuing_writing',
            'status': 'writing'
        })

    async def handle_revision_request(self, review_data: Dict):
        """修正要求処理"""
        self.logger.info("🔄 Chapter revision requested by Claude")
        
        feedback = review_data.get('feedback', [])
        
        await self.update_shared_state({
            'current_task': 'revising_chapter_based_on_feedback',
            'status': 'revising'
        })
        
        # フィードバックに基づいて修正
        revised_content = await self.revise_chapter_content(review_data, feedback)
        
        # 修正版を再提出
        await self.resubmit_revised_chapter(review_data, revised_content)

    async def revise_chapter_content(self, review_data: Dict, feedback: List[str]) -> str:
        """章内容修正"""
        original_content = review_data.get('content', '')
        
        feedback_text = '\n'.join(feedback)
        
        prompt = f"""
        以下の章の内容を、レビューフィードバックに基づいて修正してください。

        【元の内容】
        {original_content}

        【修正指示】
        {feedback_text}

        【修正要件】
        - 指摘された問題をすべて解決する
        - 3000文字以上を維持
        - より具体的で実用的な内容にする
        - 読者にとって価値のある情報を追加する

        修正版を出力してください。
        """
        
        try:
            response = self.model.generate_content(prompt)
            revised_content = response.text
            
            self.logger.info(f"🔧 Chapter revised: {len(revised_content)} characters")
            return revised_content
        except Exception as e:
            self.logger.error(f"❌ Chapter revision failed: {e}")
            return original_content

    async def resubmit_revised_chapter(self, review_data: Dict, revised_content: str):
        """修正版章再提出"""
        review_item = {
            **review_data,
            'content': revised_content,
            'word_count': len(revised_content.split()),
            'revision_submission_time': datetime.now().isoformat(),
            'status': 'revised_pending_review',
            'revision_count': review_data.get('revision_count', 0) + 1
        }
        
        # Claude Codeのメッセージキューに追加
        self.shared_state['ai_communication']['claude_code']['message_queue'].append({
            'type': 'review_request',
            'timestamp': datetime.now().isoformat(),
            'data': review_item,
            'sender': 'gemini_yolo'
        })
        
        with open(self.shared_state_path, 'w', encoding='utf-8') as f:
            json.dump(self.shared_state, f, indent=2, ensure_ascii=False)
        
        self.logger.info("📤 Revised chapter resubmitted for review")

    async def update_book_progress(self, review_data: Dict, approved: bool = True):
        """本の進捗更新"""
        book_id = review_data['book_id']
        
        # アクティブな本を取得
        active_books = self.shared_state['current_projects']['active_books']
        book = next((b for b in active_books if b['id'] == book_id), None)
        
        if book and approved:
            book['chapters_completed'] += 1
            book['current_chapter'] += 1
            book['word_count'] += review_data['word_count']
            
            # 章内容を保存
            chapter_num = review_data['chapter_number']
            book['chapters'][chapter_num - 1]['content'] = review_data['content']
            
            # 全章完了チェック
            if book['chapters_completed'] >= book['total_chapters']:
                await self.complete_book(book)
            
            with open(self.shared_state_path, 'w', encoding='utf-8') as f:
                json.dump(self.shared_state, f, indent=2, ensure_ascii=False)

    async def complete_book(self, book: Dict):
        """本完成処理"""
        self.logger.info(f"🎉 Book completed: {book['title']}")
        
        book['status'] = 'completed'
        book['completion_date'] = datetime.now().isoformat()
        
        # Claude Codeに最終承認を要求
        self.shared_state['ai_communication']['claude_code']['message_queue'].append({
            'type': 'final_approval',
            'timestamp': datetime.now().isoformat(),
            'data': book,
            'sender': 'gemini_yolo'
        })
        
        await self.update_shared_state({
            'current_task': 'book_completed_awaiting_final_approval',
            'status': 'completed'
        })
        
        with open(self.shared_state_path, 'w', encoding='utf-8') as f:
            json.dump(self.shared_state, f, indent=2, ensure_ascii=False)

# システム起動
async def main():
    gemini = GeminiYolo()
    await gemini.initialize()

if __name__ == "__main__":
    asyncio.run(main())