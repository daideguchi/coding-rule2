# 最強ファイル配置ルール v2.0

## 🎯 基本理念
**プロジェクト全体の統一性と効率性を最大化するファイル配置システム**

### 設計原則
1. **機能別分離**: 関連する機能は同じディレクトリに配置
2. **アクセス頻度重視**: よく使用するファイルは浅い階層に配置
3. **拡張性確保**: 将来的な機能追加に対応できる構造
4. **責任範囲明確化**: 各ディレクトリの役割を明確に定義

## 📁 標準ディレクトリ構造 v2.0

```
project-root/
├── README.md                     # プロジェクト概要（必須）
├── cspell.json                   # 統一スペルチェック設定
├── .gitignore                    # Git除外設定
├── .env*                         # 環境設定ファイル
├── package*.json                 # 依存関係管理（必要時）
├── tsconfig.json                 # TypeScript設定（必要時）
│
├── ai-agents/                    # AI組織システム（コア）
│   ├── instructions/             # AI指示書・ルール
│   │   ├── boss.md              # BOSS指示書
│   │   ├── president.md         # PRESIDENT指示書
│   │   └── worker.md            # WORKER指示書
│   ├── configs/                  # 設定管理
│   │   ├── env/                 # 環境別設定
│   │   ├── mcp/                 # MCP設定
│   │   └── sessions/            # セッション管理
│   ├── scripts/                  # 自動化スクリプト
│   │   ├── automation/          # 自動実行スクリプト
│   │   ├── core/                # コアシステム
│   │   └── utilities/           # ユーティリティ
│   ├── monitoring/               # 監視・品質管理
│   │   ├── quality/             # 品質チェック
│   │   ├── performance/         # パフォーマンス監視
│   │   └── security/            # セキュリティ監視
│   └── logs/                     # AI活動ログ
│       ├── system/              # システムログ
│       ├── president/           # PRESIDENT記録
│       └── workers/             # ワーカー記録
│
├── docs/                         # ドキュメント管理
│   ├── getting-started/          # 初心者向けガイド
│   │   ├── README.md            # 開始ガイド
│   │   ├── installation.md      # インストール手順
│   │   └── first-steps.md       # 最初のステップ
│   ├── user-guides/              # ユーザーガイド
│   │   ├── user-guide.md        # 基本的な使い方
│   │   ├── best-practices.md    # ベストプラクティス
│   │   ├── troubleshooting.md   # トラブルシューティング
│   │   └── faq.md               # よくある質問
│   ├── standards/                # 標準・規則
│   │   ├── FILE_PLACEMENT_RULES.md
│   │   ├── NAMING_CONVENTIONS.md
│   │   └── CODING_STANDARDS.md
│   ├── technical/                # 技術仕様
│   │   ├── architecture.md      # システム構成
│   │   ├── api-reference.md     # API仕様
│   │   └── database-schema.md   # データベース設計
│   ├── design/                   # デザイン仕様
│   │   ├── ui-guidelines.md     # UI/UXガイドライン
│   │   └── style-guide.md       # スタイルガイド
│   ├── management/               # プロジェクト管理
│   │   ├── project-rules.md     # プロジェクトルール
│   │   └── workflow.md          # ワークフロー
│   └── assets/                   # ドキュメント用アセット
│       ├── images/              # 画像ファイル
│       └── diagrams/            # 図表ファイル
│
├── scripts/                      # プロジェクト管理スクリプト
│   ├── setup/                    # セットアップスクリプト
│   ├── build/                    # ビルドスクリプト
│   ├── deployment/               # デプロイメントスクリプト
│   └── maintenance/              # メンテナンススクリプト
│
├── tests/                        # テスト関連
│   ├── unit/                     # ユニットテスト
│   ├── integration/              # 統合テスト
│   ├── e2e/                      # End-to-Endテスト
│   └── fixtures/                 # テストデータ
│
├── logs/                         # システムログ
│   ├── application/              # アプリケーションログ
│   ├── error/                    # エラーログ
│   ├── access/                   # アクセスログ
│   └── performance/              # パフォーマンスログ
│
├── tmp/                          # 一時ファイル
│   ├── cache/                    # キャッシュファイル
│   ├── uploads/                  # アップロードファイル
│   └── processing/               # 処理中ファイル
│
├── archive/                      # アーカイブ
│   ├── old-versions/             # 旧バージョン
│   ├── deprecated/               # 非推奨ファイル
│   └── backups/                  # バックアップ
│
└── reports/                      # レポート・分析結果
    ├── analysis/                 # 分析レポート
    ├── improvements/             # 改善レポート
    └── performance/              # パフォーマンスレポート
```

## 🚨 配置ルール詳細

### ✅ ルートディレクトリ配置許可ファイル
- **README.md** - プロジェクト概要（必須）
- **package.json, package-lock.json** - Node.js依存関係
- **tsconfig.json** - TypeScript設定
- **cspell.json** - スペルチェック設定
- **.gitignore** - Git除外設定
- **.env, .env.local, .env.production** - 環境設定
- **LICENSE** - ライセンスファイル
- **CHANGELOG.md** - 変更履歴（必要時）

### ❌ ルートディレクトリ配置禁止ファイル
- **作業報告書** → `logs/ai-agents/workers/`
- **一時ファイル** → `tmp/`
- **テストファイル** → `tests/`
- **ドキュメント** → `docs/`
- **スクリプト** → `scripts/` または `ai-agents/scripts/`
- **ログファイル** → `logs/`
- **アーカイブファイル** → `archive/`

## 📋 ファイル分類基準

### 1. 機能別分類
- **AI組織関連** → `ai-agents/`
- **ドキュメント** → `docs/`
- **テスト** → `tests/`
- **スクリプト** → `scripts/` または `ai-agents/scripts/`

### 2. 頻度別分類
- **高頻度アクセス** → 浅い階層（1-2階層）
- **中頻度アクセス** → 中間階層（2-3階層）
- **低頻度アクセス** → 深い階層（3階層以上）

### 3. 役割別分類
- **設定ファイル** → `configs/`
- **ログファイル** → `logs/`
- **一時ファイル** → `tmp/`
- **アーカイブ** → `archive/`

## 🔄 ファイル移動・整理ルール

### 即座移動が必要なファイル
1. **ルート直下の作業ファイル** → 適切なディレクトリ
2. **重複設定ファイル** → 統一後削除
3. **古いバージョンファイル** → `archive/`
4. **一時ファイル** → `tmp/`

### 定期整理スケジュール
- **日次**: ルートディレクトリチェック
- **週次**: `tmp/`ディレクトリクリーンアップ
- **月次**: `logs/`アーカイブ、`archive/`整理

## ⚡ 品質管理システム

### 自動チェック項目
- [ ] ルートディレクトリファイル数監視
- [ ] 禁止ファイル検出
- [ ] ディレクトリ構造検証
- [ ] ファイル命名規則チェック

### 品質指標
- **ルートファイル数**: 10個以下
- **階層深度**: 5階層以下
- **ディレクトリ構造一致率**: 95%以上
- **命名規則遵守率**: 100%

## 🚨 違反対応プロセス

### 発見時の対応フロー
1. **即座停止**: 作業を一時停止
2. **ファイル移動**: 適切な場所に移動
3. **原因分析**: 違反理由の特定
4. **再発防止**: システム改善実施
5. **報告書作成**: `logs/ai-agents/workers/`に記録

### 責任分担
- **PRESIDENT**: ルール策定・監督
- **BOSS1**: 実行管理・品質確認
- **WORKER3**: 品質保証・監視
- **全ワーカー**: ルール遵守・改善提案

## 📊 効果測定

### KPI指標
- **ファイル配置精度**: 99%以上
- **検索効率**: 平均3クリック以内
- **新規メンバー学習時間**: 1時間以内
- **ルール違反件数**: 週0件

---

**策定日**: 2025-07-01  
**バージョン**: v2.0  
**策定者**: WORKER3 (品質保証・ドキュメント担当)  
**承認者**: BOSS1