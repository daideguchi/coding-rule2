# 最強命名規則ガイドライン v2.0

## 🎯 基本理念
**一貫性・可読性・検索性を最大化する統一命名システム**

### 設計原則
1. **意味の明確性**: ファイル名から内容が即座に理解できる
2. **検索効率**: キーワード検索で確実に発見できる
3. **並び順最適化**: アルファベット順・時系列で適切に整列
4. **拡張性確保**: 将来的な機能追加に対応

## 📁 ディレクトリ命名規則

### 基本フォーマット
```
{機能カテゴリ}-{詳細分類}/
```

### 標準ディレクトリ名
| カテゴリ | 命名例 | 説明 |
|----------|--------|------|
| **AI組織** | `ai-agents/` | AI組織システム |
| **ドキュメント** | `docs/` | 文書管理 |
| **スクリプト** | `scripts/` | 実行スクリプト |
| **ログ** | `logs/` | ログファイル |
| **テスト** | `tests/` | テスト関連 |
| **設定** | `configs/` | 設定ファイル |
| **一時** | `tmp/` | 一時ファイル |
| **アーカイブ** | `archive/` | 過去ファイル |

### サブディレクトリ命名
```
{親機能}-{子機能}/
```

**例**:
- `ai-agents/instructions/` - AI指示書
- `ai-agents/monitoring/` - AI監視システム
- `docs/getting-started/` - 初心者ガイド
- `logs/ai-agents/` - AI組織ログ

## 📄 ファイル命名規則

### 1. ドキュメントファイル

#### Markdownファイル (.md)
```
{機能}_{詳細}_{バージョン}.md
```

**例**:
- `FILE_PLACEMENT_RULES.md` - ファイル配置ルール
- `NAMING_CONVENTIONS.md` - 命名規則
- `API_REFERENCE_v2.md` - API仕様書 v2
- `USER_GUIDE_ADVANCED.md` - 上級者ガイド

#### 特殊ドキュメント
- `README.md` - プロジェクト概要（各ディレクトリ）
- `CHANGELOG.md` - 変更履歴
- `LICENSE.md` - ライセンス
- `CONTRIBUTING.md` - 貢献ガイド

### 2. スクリプトファイル

#### Bashスクリプト (.sh)
```
{機能}-{操作}-{対象}.sh
```

**例**:
- `auto-startup-system.sh` - 自動起動システム
- `quality-check-monitor.sh` - 品質チェック監視
- `log-cleanup-daily.sh` - 日次ログクリーンアップ
- `backup-create-full.sh` - 完全バックアップ作成

#### Pythonスクリプト (.py)
```
{機能}_{処理内容}.py
```

**例**:
- `mcp_server_handler.py` - MCPサーバーハンドラー
- `log_analyzer_advanced.py` - 高度ログ解析
- `data_processor_core.py` - コアデータ処理

### 3. 設定ファイル

#### JSON設定 (.json)
```
{システム}_config_{環境}.json
```

**例**:
- `mcp_config_production.json` - MCP本番設定
- `session_config_default.json` - デフォルトセッション設定
- `ai_agents_config_local.json` - AI組織ローカル設定

#### 環境設定
```
.env.{環境名}
```

**例**:
- `.env.local` - ローカル環境
- `.env.production` - 本番環境
- `.env.testing` - テスト環境

### 4. ログファイル

#### システムログ
```
{システム}_{日付}_{時刻}.log
```

**例**:
- `ai_agents_20250701_143022.log` - AI組織ログ
- `quality_check_20250701_090000.log` - 品質チェックログ
- `error_system_20250701_120000.log` - システムエラーログ

#### 作業報告書
```
{WORKER名}_{作業内容}_{日付}.md
```

**例**:
- `WORKER1_quality_analysis_20250701.md` - WORKER1品質分析
- `WORKER3_documentation_20250701.md` - WORKER3文書作成
- `BOSS1_project_review_20250701.md` - BOSS1プロジェクトレビュー

### 5. テストファイル

#### ユニットテスト
```
{テスト対象}_test.{拡張子}
```

**例**:
- `file_manager_test.py` - ファイルマネージャーテスト
- `api_handler_test.js` - APIハンドラーテスト
- `data_validator_test.py` - データバリデーターテスト

#### 統合テスト
```
{機能群}_integration_test.{拡張子}
```

**例**:
- `ai_agents_integration_test.py` - AI組織統合テスト
- `workflow_integration_test.sh` - ワークフロー統合テスト

## 🔤 文字種・記号ルール

### 推奨文字種
- **英数字**: A-Z, a-z, 0-9
- **記号**: `_` (アンダースコア), `-` (ハイフン), `.` (ドット)

### 使用禁止文字
- **スペース**: ` ` → `_` または `-` で代替
- **日本語**: 全角文字 → 英語で表現
- **特殊記号**: `!@#$%^&*()+=[]{}|;:'"<>?/\` → 使用禁止

### 大文字・小文字ルール
- **ディレクトリ**: 全て小文字 + ハイフン
- **ドキュメント**: 大文字 + アンダースコア
- **スクリプト**: 小文字 + ハイフン
- **設定ファイル**: 小文字 + アンダースコア

## 📅 日付・時刻フォーマット

### 標準フォーマット
```
YYYYMMDD_HHMMSS
```

**例**:
- `20250701_143022` - 2025年7月1日 14時30分22秒
- `20250701` - 2025年7月1日（日付のみ）

### ログファイル用
```
YYYY-MM-DD_HH-MM-SS
```

**例**:
- `2025-07-01_14-30-22.log`
- `2025-07-01_error.log`

## 🔍 検索効率化ルール

### キーワード配置
1. **最重要キーワード**: ファイル名の先頭
2. **カテゴリ**: 2番目のキーワード
3. **詳細**: 3番目以降のキーワード

### 例
- `AI_AGENTS_STARTUP_GUIDE.md` - AI組織起動ガイド
- `QUALITY_CHECK_AUTOMATION.sh` - 品質チェック自動化
- `ERROR_HANDLING_SYSTEM.py` - エラーハンドリングシステム

## 🚨 品質管理・チェックリスト

### 命名前チェック項目
- [ ] 意味が明確か？
- [ ] 検索しやすいか？
- [ ] 規則に準拠しているか？
- [ ] 重複していないか？
- [ ] 適切な長さか？（推奨：50文字以内）

### 自動チェック項目
- [ ] 禁止文字使用チェック
- [ ] 命名規則準拠チェック
- [ ] 重複名検出
- [ ] 長さ制限チェック

## 📊 命名例一覧

### ディレクトリ例
```
ai-agents/
├── instructions/
├── configs/
├── scripts/
│   ├── automation/
│   ├── monitoring/
│   └── utilities/
├── logs/
│   ├── system/
│   ├── workers/
│   └── errors/
└── tmp/
    ├── cache/
    └── processing/
```

### ファイル例
```
docs/standards/
├── FILE_PLACEMENT_RULES.md
├── NAMING_CONVENTIONS.md
├── CODING_STANDARDS.md
└── QUALITY_GUIDELINES.md

ai-agents/scripts/
├── auto-startup-system.sh
├── quality-check-monitor.sh
├── log-cleanup-daily.sh
└── backup-create-full.sh

logs/ai-agents/workers/
├── WORKER1_quality_analysis_20250701.md
├── WORKER2_development_20250701.md
└── WORKER3_documentation_20250701.md
```

## 🔄 継続改善システム

### 定期レビュー
- **週次**: 新規ファイル命名チェック
- **月次**: 命名規則見直し
- **四半期**: 全ファイル命名監査

### 改善プロセス
1. **問題発見**: 命名規則違反・不便発見
2. **原因分析**: 違反理由・改善点特定
3. **ルール更新**: 命名規則改訂
4. **全体適用**: 既存ファイル名修正

## ⚡ 効果測定指標

### KPI指標
- **命名規則遵守率**: 100%
- **ファイル検索時間**: 平均10秒以内
- **新規メンバー理解時間**: 30分以内
- **命名エラー件数**: 週0件

---

**策定日**: 2025-07-01  
**バージョン**: v2.0  
**策定者**: WORKER3 (品質保証・ドキュメント担当)  
**承認者**: BOSS1