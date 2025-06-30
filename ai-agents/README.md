# 🗂️ AI組織整理システム

## 📁 ディレクトリ構造

```
organized/
├── scripts/           # 実行可能スクリプト
│   ├── core/         # 核心システム（5個）
│   │   ├── AUTO_EXECUTE_MONITOR_SYSTEM.sh
│   │   ├── PARALLEL_PROCESSING_SYSTEM.sh
│   │   ├── ULTIMATE_PROCESS.sh
│   │   └── ...
│   ├── automation/   # 自動化・監視系
│   ├── management/   # 管理・制御系
│   └── utilities/    # 補助ツール
│       ├── PATH_MANAGEMENT_SYSTEM.sh
│       ├── o3-integration-helper.sh
│       └── ...
├── docs/             # ドキュメント
│   ├── systems/      # システム仕様
│   │   ├── CONTINUOUS_IMPROVEMENT_SYSTEM.md
│   │   ├── O3_COLLABORATION_SYSTEM.md
│   │   ├── SYSTEM_CONSOLIDATION_PLAN.md
│   │   ├── president.md
│   │   └── ...
│   ├── guides/       # 使用ガイド
│   ├── records/      # 作業記録
│   └── references/   # 参考資料
├── configs/          # 設定ファイル
│   ├── mcp/         # MCP設定
│   ├── env/         # 環境設定
│   │   └── env-setup.sh
│   └── sessions/    # セッション設定
└── temp/            # 一時ファイル
```

## 🔧 整理原則

### ✅ 安全な整理
- **既存ファイル保持**: 元ファイルは削除せず保持
- **機能継続**: 既存プロセス・機能を破壊しない
- **段階的移行**: コピー→検証→段階的移行

### 📋 分類基準
- **scripts/core**: 必須システム（5個以下）
- **scripts/utilities**: 補助・支援ツール
- **docs/systems**: システム仕様・設計書
- **configs**: 設定・環境ファイル

## 🎯 使用方法

### 新しいファイルアクセス
```bash
# 核心スクリプト実行
./organized/scripts/core/AUTO_EXECUTE_MONITOR_SYSTEM.sh

# 設定スクリプト実行
source ./organized/configs/env/env-setup.sh

# ドキュメント参照
cat ./organized/docs/systems/president.md
```

### 従来ファイルアクセス（継続可能）
```bash
# 従来通りアクセス可能（既存プロセス保護）
./AUTO_EXECUTE_MONITOR_SYSTEM.sh
cat instructions/president.md
```

## 🚨 重要注意事項

**既存プロセス保護**: 
- 元ファイルの削除・移動は行わない
- 既存の参照パス・スクリプトは動作継続
- AI組織システム稼働に影響なし

**段階的移行**:
- organized/で新構造テスト
- 問題なしを確認後、順次移行検討
- 絶対に破壊的変更は行わない

---

## 🚨 散乱防止ルール（永続遵守）

### 📋 ファイル作成時の絶対ルール

#### ✅ 新規ファイル作成前チェック
1. **配置場所確認**: どのディレクトリに属するか明確化
2. **既存統合検討**: 既存ファイルへの追記・統合可能か確認
3. **命名規則遵守**: `category-purpose-version.ext` 形式
4. **目的明確化**: 明確な目的・機能を持つか確認

#### 📁 配置ルール（絶対遵守）
```
scripts/core/        → 核心システム（5個以下維持）
scripts/automation/  → 自動化・監視系スクリプト
scripts/management/  → 管理・制御系スクリプト  
scripts/utilities/   → 補助ツール・ヘルパー

docs/systems/        → システム仕様・設計書
docs/guides/         → 使用ガイド・マニュアル
docs/records/        → 作業記録・履歴
docs/references/     → 参考資料・テンプレート

configs/mcp/         → MCP関連設定
configs/env/         → 環境・パス設定  
configs/sessions/    → tmuxセッション設定

temp/               → 一時ファイル（定期削除対象）
legacy/             → 旧ファイル保管（参照用）
```

#### ❌ 禁止行為
1. **ルートディレクトリ散乱**: ai-agents/直下への無分類ファイル配置禁止
2. **重複ファイル**: 既存機能と重複するファイル作成禁止
3. **無分類配置**: どのカテゴリにも属さないファイル作成禁止
4. **一時ファイル放置**: temp/以外での一時ファイル作成・放置禁止

### 🔄 定期メンテナンスルール

#### 📅 日次（毎作業終了時）
- [ ] temp/フォルダクリーンアップ
- [ ] 新規作成ファイルの適切配置確認
- [ ] README.md更新（新機能追加時）

#### 📅 週次（日曜日）
- [ ] 各ディレクトリ構造確認
- [ ] 重複・不要ファイル確認
- [ ] 統合可能ファイル検討

#### 📅 月次（月末）
- [ ] 全体構造見直し
- [ ] legacy/フォルダ整理
- [ ] アクセス頻度分析・最適化

### 🚫 散乱発生時の緊急対応

#### 即座実行事項
1. **散乱検知**: 5個以上の無分類ファイル発見時
2. **緊急整理**: 24時間以内の強制整理実行
3. **原因分析**: 散乱原因の特定・対策立案
4. **ルール更新**: 再発防止のルール追加

#### エスカレーション
- 散乱が2回連続発生 → ルール全面見直し
- 散乱により作業効率低下 → システム再設計検討

### 💪 PRESIDENT責任事項

1. **ルール遵守監視**: 全作業でのルール適用確認
2. **散乱予防**: 事前チェック・配置ガイダンス
3. **改善提案**: より効率的な構造への進化提案
4. **教育**: チーム全体でのルール共有・徹底

**このルールにより、二度と散乱を発生させず、常に整理された状態を維持します。**