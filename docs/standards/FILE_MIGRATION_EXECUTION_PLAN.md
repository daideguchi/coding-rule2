# ファイル移動実行計画書 v1.0

## 🎯 実行計画概要
**目的**: ルートディレクトリの標準化によるプロジェクト品質向上  
**実行者**: WORKER3（品質保証・ドキュメント担当）  
**承認者**: BOSS1  
**実行予定日**: 2025-07-01  

## 📊 現状分析結果

### ルートディレクトリ現状
```
ルートファイル総数: 12個 → 目標: 10個以下
移動対象ファイル: 2個
移動不要ファイル: 10個
```

### 移動対象ファイル特定
| ファイル名 | 現在の場所 | 移動先 | 理由 |
|-----------|-----------|-------|------|
| **ai-team.sh** | `/root/` | `scripts/` | プロジェクト管理スクリプト |
| **nohup.out** | `/root/` | `logs/` | ログファイル |

### ルート保持ファイル（移動不要）
| ファイル名 | 理由 |
|-----------|------|
| **README.md** | プロジェクト概要（必須） |
| **cspell.json** | スペルチェック設定（統一済み） |
| **.mcp.json** | MCP設定（必須） |
| **.gitignore** | Git除外設定（必須） |
| **.env** | 環境設定（必須） |
| **.env.example** | 環境設定例（必須） |
| **.claude-project** | Claude設定（必須） |
| **.cursorindexingignore** | Cursor設定（必須） |
| **.ai-org-configured** | AI組織設定フラグ（必須） |
| **ディレクトリ群** | 各機能ディレクトリ（移動対象外） |

## 🔍 依存関係・参照パス分析

### ai-team.sh の依存関係
#### 内部参照パス
- **相対パス使用**: `./` で始まる自己参照のみ
- **外部参照**: 他ファイルからの直接参照なし
- **実行パス**: ルートディレクトリから実行想定

#### 影響範囲
- **ドキュメント参照**: なし（自己完結型スクリプト）
- **他スクリプト連携**: なし
- **設定ファイル依存**: `.env`, `.mcp.json` への相対パス依存

### nohup.out の依存関係
#### 参照状況
- **読み込み参照**: なし（出力専用ファイル）
- **書き込み参照**: nohup コマンドによる自動生成
- **削除可能性**: 100%（一時ログファイル）

## 📋 移動実行順序・手順

### Phase 1: 事前準備（5分）
```bash
# 1. バックアップ作成
echo "=== Phase 1: 事前準備 ==="
BACKUP_DIR="archive/migration-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 2. 移動対象ファイルバックアップ
cp ai-team.sh "$BACKUP_DIR/"
cp nohup.out "$BACKUP_DIR/" 2>/dev/null || echo "nohup.out not found"

# 3. 移動先ディレクトリ確認・作成
mkdir -p scripts/
mkdir -p logs/

echo "✅ 事前準備完了"
```

### Phase 2: ファイル移動実行（2分）
```bash
echo "=== Phase 2: ファイル移動実行 ==="

# 1. ai-team.sh の移動
echo "🔄 ai-team.sh を scripts/ に移動中..."
mv ai-team.sh scripts/ai-team.sh

# 2. nohup.out の移動（存在する場合）
echo "🔄 nohup.out を logs/ に移動中..."
if [ -f nohup.out ]; then
    mv nohup.out logs/nohup-$(date +%Y%m%d_%H%M%S).out
    echo "✅ nohup.out 移動完了"
else
    echo "ℹ️  nohup.out が存在しません"
fi

echo "✅ ファイル移動完了"
```

### Phase 3: パス参照更新（3分）
```bash
echo "=== Phase 3: パス参照更新 ==="

# 1. scripts/ai-team.sh の実行権限確認
chmod +x scripts/ai-team.sh

# 2. 新しい実行パスでのテスト実行
echo "🧪 移動後のスクリプトテスト..."
cd scripts/ && ./ai-team.sh --version 2>/dev/null || echo "バージョン確認スキップ"
cd ..

# 3. シンボリックリンク作成（互換性維持）
echo "🔗 互換性のためのシンボリックリンク作成..."
ln -sf scripts/ai-team.sh ai-team
echo "✅ ./ai-team でアクセス可能"

echo "✅ パス参照更新完了"
```

### Phase 4: 機能検証（5分）
```bash
echo "=== Phase 4: 機能検証 ==="

# 1. ルートディレクトリファイル数確認
echo "📊 ルートファイル数確認..."
ROOT_FILES=$(ls -la | grep -v '^d' | wc -l)
echo "ルートファイル数: $ROOT_FILES"

# 2. スクリプト動作確認
echo "🧪 スクリプト動作確認..."
./scripts/ai-team.sh --help > /dev/null 2>&1 && echo "✅ scripts/ai-team.sh 正常動作" || echo "⚠️  要確認"
./ai-team --help > /dev/null 2>&1 && echo "✅ シンボリックリンク正常動作" || echo "⚠️  要確認"

# 3. 設定ファイル整合性確認
echo "⚙️  設定ファイル整合性確認..."
[ -f .mcp.json ] && echo "✅ .mcp.json 存在確認" || echo "❌ .mcp.json 不存在"
[ -f .env ] && echo "✅ .env 存在確認" || echo "❌ .env 不存在"

echo "✅ 機能検証完了"
```

## 🧪 機能テスト手順詳細

### テストカテゴリ1: ファイル配置テスト
```bash
#!/bin/bash
# test-file-placement.sh

echo "=== ファイル配置テスト ==="

# T1-1: ルートディレクトリファイル数テスト
test_root_file_count() {
    local count=$(ls -la | grep -v '^d' | wc -l)
    if [ $count -le 10 ]; then
        echo "✅ T1-1: ルートファイル数 ($count) - PASS"
        return 0
    else
        echo "❌ T1-1: ルートファイル数 ($count) 超過 - FAIL"
        return 1
    fi
}

# T1-2: 必須ファイル存在テスト
test_required_files() {
    local required_files=("README.md" "cspell.json" ".mcp.json" ".gitignore")
    local failed=0
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ T1-2: $file 存在確認 - PASS"
        else
            echo "❌ T1-2: $file 不存在 - FAIL"
            failed=1
        fi
    done
    
    return $failed
}

# T1-3: 移動ファイル不存在テスト
test_moved_files_absent() {
    local moved_files=("ai-team.sh")
    local failed=0
    
    for file in "${moved_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "✅ T1-3: $file ルートから削除確認 - PASS"
        else
            echo "❌ T1-3: $file まだルートに存在 - FAIL"
            failed=1
        fi
    done
    
    return $failed
}

# テスト実行
test_root_file_count
test_required_files  
test_moved_files_absent
```

### テストカテゴリ2: スクリプト機能テスト
```bash
#!/bin/bash
# test-script-functionality.sh

echo "=== スクリプト機能テスト ==="

# T2-1: 移動後スクリプト実行テスト
test_script_execution() {
    echo "🧪 T2-1: スクリプト実行テスト"
    
    # ヘルプ表示テスト
    if ./scripts/ai-team.sh --help > /dev/null 2>&1; then
        echo "✅ T2-1a: scripts/ai-team.sh --help - PASS"
    else
        echo "❌ T2-1a: scripts/ai-team.sh --help - FAIL"
    fi
    
    # シンボリックリンクテスト
    if ./ai-team --help > /dev/null 2>&1; then
        echo "✅ T2-1b: シンボリックリンク ./ai-team - PASS"
    else
        echo "❌ T2-1b: シンボリックリンク ./ai-team - FAIL"
    fi
}

# T2-2: 設定ファイルアクセステスト
test_config_access() {
    echo "🧪 T2-2: 設定ファイルアクセステスト"
    
    # .mcp.json 読み込みテスト
    if [ -r .mcp.json ]; then
        echo "✅ T2-2a: .mcp.json 読み込み可能 - PASS"
    else
        echo "❌ T2-2a: .mcp.json 読み込み不可 - FAIL"
    fi
    
    # .env ファイルアクセステスト
    if [ -r .env ]; then
        echo "✅ T2-2b: .env 読み込み可能 - PASS"
    else
        echo "❌ T2-2b: .env 読み込み不可 - FAIL"
    fi
}

# T2-3: 相対パス動作テスト
test_relative_paths() {
    echo "🧪 T2-3: 相対パス動作テスト"
    
    # スクリプトディレクトリから実行
    cd scripts/
    if ./ai-team.sh --version > /dev/null 2>&1; then
        echo "✅ T2-3a: scripts/内からの実行 - PASS"
    else
        echo "❌ T2-3a: scripts/内からの実行 - FAIL"
    fi
    cd ..
    
    # ルートディレクトリから実行
    if ./scripts/ai-team.sh --version > /dev/null 2>&1; then
        echo "✅ T2-3b: ルートからの実行 - PASS"
    else
        echo "❌ T2-3b: ルートからの実行 - FAIL"
    fi
}

# テスト実行
test_script_execution
test_config_access
test_relative_paths
```

### テストカテゴリ3: 統合テスト
```bash
#!/bin/bash
# test-integration.sh

echo "=== 統合テスト ==="

# T3-1: プロジェクト品質スコアテスト
test_quality_score() {
    echo "🧪 T3-1: プロジェクト品質スコア"
    
    local score=0
    
    # ファイル配置点数 (30点)
    local root_files=$(ls -la | grep -v '^d' | wc -l)
    if [ $root_files -le 10 ]; then
        score=$((score + 30))
        echo "✅ ファイル配置: 30/30点"
    else
        local partial=$((30 - (root_files - 10) * 3))
        score=$((score + partial))
        echo "⚠️  ファイル配置: $partial/30点"
    fi
    
    # 機能動作点数 (40点)
    if ./scripts/ai-team.sh --help > /dev/null 2>&1; then
        score=$((score + 40))
        echo "✅ 機能動作: 40/40点"
    else
        echo "❌ 機能動作: 0/40点"
    fi
    
    # 構造最適化点数 (30点)
    if [ -d scripts/ ] && [ -d logs/ ] && [ -d docs/ ]; then
        score=$((score + 30))
        echo "✅ 構造最適化: 30/30点"
    else
        echo "❌ 構造最適化: 0/30点"
    fi
    
    echo "🎯 総合品質スコア: $score/100点"
    
    if [ $score -ge 90 ]; then
        echo "🏆 優秀 - 移動成功"
        return 0
    elif [ $score -ge 70 ]; then
        echo "⚠️  改善必要 - 部分的成功"
        return 1
    else
        echo "❌ 失敗 - ロールバック推奨"
        return 2
    fi
}

# テスト実行
test_quality_score
```

## 🚨 リスク管理・ロールバック計画

### 想定リスク
| リスク | 発生確率 | 影響度 | 対策 |
|--------|----------|--------|------|
| **スクリプト実行エラー** | 低 | 中 | バックアップからの復旧 |
| **パス参照エラー** | 低 | 低 | シンボリックリンク作成 |
| **権限エラー** | 中 | 低 | chmod +x で解決 |
| **設定ファイル参照エラー** | 低 | 中 | 相対パス修正 |

### ロールバック手順
```bash
#!/bin/bash
# rollback-migration.sh

echo "=== 緊急ロールバック実行 ==="

# 1. バックアップディレクトリ特定
BACKUP_DIR=$(ls -1d archive/migration-backup-* | tail -1)
if [ -z "$BACKUP_DIR" ]; then
    echo "❌ バックアップが見つかりません"
    exit 1
fi

echo "📁 バックアップディレクトリ: $BACKUP_DIR"

# 2. ファイル復元
echo "🔄 ファイル復元中..."
cp "$BACKUP_DIR/ai-team.sh" ./ 2>/dev/null && echo "✅ ai-team.sh 復元完了"
cp "$BACKUP_DIR/nohup.out" ./ 2>/dev/null && echo "✅ nohup.out 復元完了"

# 3. 移動先ファイル削除
echo "🗑️  移動先ファイル削除中..."
rm -f scripts/ai-team.sh logs/nohup-*.out
rm -f ai-team  # シンボリックリンク削除

# 4. 権限復元
chmod +x ai-team.sh

echo "✅ ロールバック完了"
echo "⚠️  移動前の状態に復元されました"
```

## 📊 実行チェックリスト

### 実行前チェック
- [ ] バックアップディレクトリ作成確認
- [ ] 移動先ディレクトリ存在確認
- [ ] 実行権限確認
- [ ] 依存ファイル存在確認

### 実行中チェック
- [ ] Phase 1: 事前準備完了
- [ ] Phase 2: ファイル移動完了
- [ ] Phase 3: パス参照更新完了
- [ ] Phase 4: 機能検証完了

### 実行後チェック
- [ ] ルートファイル数 ≤ 10個
- [ ] スクリプト正常動作確認
- [ ] シンボリックリンク動作確認
- [ ] 設定ファイルアクセス確認
- [ ] 品質スコア ≥ 90点

## ⏱️ 実行スケジュール

### 推奨実行時間
- **所要時間**: 15分
- **最適実行時間**: システム負荷の低い時間帯
- **緊急停止**: いつでも可能（ロールバック5分）

### 実行手順サマリー
```bash
# 1行実行版（推奨）
./docs/standards/scripts/execute-migration.sh

# 段階実行版（詳細確認用）
./docs/standards/scripts/phase1-preparation.sh
./docs/standards/scripts/phase2-migration.sh  
./docs/standards/scripts/phase3-path-update.sh
./docs/standards/scripts/phase4-verification.sh
```

## 📋 承認・実行権限

### 必要承認
- **計画承認**: BOSS1 ✅
- **実行承認**: BOSS1 ⏳
- **品質確認**: WORKER3（実行後）

### 実行権限者
- **主実行者**: WORKER3
- **緊急停止権限**: BOSS1, PRESIDENT
- **ロールバック権限**: WORKER3, BOSS1

---

**策定日**: 2025-07-01  
**策定者**: WORKER3 (品質保証・ドキュメント担当)  
**承認待ち**: BOSS1  
**実行予定**: 承認後即座実行可能