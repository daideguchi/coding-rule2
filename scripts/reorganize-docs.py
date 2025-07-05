#!/usr/bin/env python3
"""
docs/ディレクトリを3カテゴリに再編するスクリプト
O3+Gemini分析に基づくエンタープライズ構造への変換
"""

import os
import shutil
from pathlib import Path
from typing import Dict, List, Tuple
import json

class DocsReorganizer:
    """docs/ディレクトリの3カテゴリ再編"""
    
    def __init__(self, docs_path: str = "docs"):
        self.docs_path = Path(docs_path)
        self.backup_path = Path("docs-backup-" + str(int(__import__('time').time())))
        
        # 3カテゴリ定義
        self.categories = {
            "enduser": {
                "description": "エンドユーザー向けドキュメント",
                "patterns": [
                    "README*", "GUIDE*", "MANUAL*", "TUTORIAL*", 
                    "instructions/", "procedures/", "user*"
                ]
            },
            "developer": {
                "description": "開発者向け技術ドキュメント",
                "patterns": [
                    "architecture/", "specs/", "TECH*", "API*", 
                    "rules/", "DESIGN*", "IMPLEMENTATION*"
                ]
            },
            "operator": {
                "description": "運用・メンテナンス向けドキュメント",
                "patterns": [
                    "reports/", "memory/", "analysis/", "monitoring/",
                    "REPORT*", "ANALYSIS*", "FAILURE*", "INTEGRITY*"
                ]
            }
        }
        
        self.migration_plan = []
        
    def analyze_current_structure(self) -> Dict:
        """現在の構造を分析"""
        current_files = []
        
        for item in self.docs_path.rglob("*"):
            if item.is_file():
                relative_path = item.relative_to(self.docs_path)
                current_files.append(str(relative_path))
        
        return {
            "total_files": len(current_files),
            "files": current_files,
            "directories": len([d for d in self.docs_path.rglob("*") if d.is_dir()])
        }
    
    def categorize_file(self, file_path: str) -> str:
        """ファイルを適切なカテゴリに分類"""
        file_path_lower = file_path.lower()
        
        # パターンマッチング
        for category, config in self.categories.items():
            for pattern in config["patterns"]:
                pattern_lower = pattern.lower().replace("*", "")
                if pattern_lower in file_path_lower:
                    return category
        
        # 特殊ルール
        if "legacy/" in file_path:
            return "operator"  # レガシーは運用者が管理
        
        if "agentweaver/" in file_path:
            return "developer"  # 技術仕様
        
        if "systems/" in file_path:
            return "developer"  # システム設計
        
        # デフォルトは開発者向け
        return "developer"
    
    def create_migration_plan(self) -> List[Dict]:
        """移行計画を作成"""
        analysis = self.analyze_current_structure()
        migration_plan = []
        
        for file_path in analysis["files"]:
            category = self.categorize_file(file_path)
            
            # 新しいパス計算
            source_path = self.docs_path / file_path
            target_path = self.docs_path / category / file_path
            
            migration_plan.append({
                "source": str(source_path),
                "target": str(target_path),
                "category": category,
                "file_name": Path(file_path).name,
                "original_path": file_path
            })
        
        return migration_plan
    
    def create_backup(self):
        """現在のdocs/をバックアップ"""
        print(f"📦 バックアップ作成: {self.backup_path}")
        shutil.copytree(self.docs_path, self.backup_path)
    
    def create_category_structure(self):
        """3カテゴリのディレクトリ構造作成"""
        for category, config in self.categories.items():
            category_path = self.docs_path / category
            category_path.mkdir(exist_ok=True)
            
            # カテゴリREADME作成
            readme_path = category_path / "README.md"
            readme_content = f"""# {category.title()} Documentation

{config['description']}

## このカテゴリについて

このディレクトリには{config['description']}が格納されています。

## 対象読者

- **enduser**: システムを利用するエンドユーザー
- **developer**: システムを開発・拡張する開発者  
- **operator**: システムを運用・保守するオペレーター

## ファイル構成

各サブディレクトリは機能別に整理されています。
詳細は各ディレクトリのREADME.mdを参照してください。

## 更新履歴

- 2025-07-05: 3カテゴリ再編により作成
"""
            
            with open(readme_path, 'w', encoding='utf-8') as f:
                f.write(readme_content)
            
            print(f"✅ カテゴリ作成: {category_path}")
    
    def execute_migration(self):
        """移行を実行"""
        migration_plan = self.create_migration_plan()
        
        print(f"🔄 移行開始: {len(migration_plan)}ファイル")
        
        moved_files = {"enduser": 0, "developer": 0, "operator": 0}
        errors = []
        
        for item in migration_plan:
            try:
                source = Path(item["source"])
                target = Path(item["target"])
                
                # ディレクトリ作成
                target.parent.mkdir(parents=True, exist_ok=True)
                
                # ファイル移動
                if source.exists():
                    shutil.move(str(source), str(target))
                    moved_files[item["category"]] += 1
                    print(f"📁 {item['category']}: {item['file_name']}")
                
            except Exception as e:
                errors.append(f"❌ {item['original_path']}: {e}")
        
        # 結果レポート
        print("\n📊 移行結果:")
        for category, count in moved_files.items():
            print(f"  {category}: {count}ファイル")
        
        if errors:
            print(f"\n⚠️ エラー: {len(errors)}件")
            for error in errors[:5]:  # 最初の5件のみ表示
                print(f"  {error}")
        
        return moved_files, errors
    
    def cleanup_empty_directories(self):
        """空のディレクトリをクリーンアップ"""
        removed_dirs = []
        
        # トップレベルのカテゴリディレクトリ以外を対象
        for item in self.docs_path.rglob("*"):
            if item.is_dir() and item.name not in self.categories:
                try:
                    if not any(item.iterdir()):  # 空ディレクトリ
                        item.rmdir()
                        removed_dirs.append(str(item))
                except:
                    pass  # 削除できない場合はスキップ
        
        print(f"🗑️ 空ディレクトリ削除: {len(removed_dirs)}個")
        return removed_dirs
    
    def generate_migration_report(self, moved_files: Dict, errors: List):
        """移行レポート生成"""
        report = {
            "migration_date": __import__('datetime').datetime.now().isoformat(),
            "total_files_moved": sum(moved_files.values()),
            "files_by_category": moved_files,
            "errors": errors,
            "backup_location": str(self.backup_path),
            "categories": self.categories
        }
        
        report_path = self.docs_path / "MIGRATION_REPORT.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"📋 移行レポート保存: {report_path}")
        return report

def main():
    """メイン実行"""
    reorganizer = DocsReorganizer()
    
    print("📂 docs/ディレクトリ3カテゴリ再編開始")
    print("=" * 50)
    
    # 現在の構造分析
    analysis = reorganizer.analyze_current_structure()
    print(f"📊 現在: {analysis['total_files']}ファイル, {analysis['directories']}ディレクトリ")
    
    # バックアップ作成
    reorganizer.create_backup()
    
    # カテゴリ構造作成
    reorganizer.create_category_structure()
    
    # 移行実行
    moved_files, errors = reorganizer.execute_migration()
    
    # クリーンアップ
    reorganizer.cleanup_empty_directories()
    
    # レポート生成
    report = reorganizer.generate_migration_report(moved_files, errors)
    
    print("\n✅ docs/ディレクトリ再編完了")
    print(f"📦 バックアップ: {reorganizer.backup_path}")
    print(f"📂 新構造: enduser/ developer/ operator/")

if __name__ == "__main__":
    main()