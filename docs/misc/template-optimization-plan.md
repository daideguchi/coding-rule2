# 🎯 テンプレート最適化計画

## 問題分析
現在のプロジェクトは**移植不可能な状態**:
- ルートファイル: 12個以上散乱
- 設定ファイル: バラバラに配置
- ランタイムファイル: ルートに残存
- テンプレート化: 全く機能しない

## 🎯 目標構造（ポータブルテンプレート）

### **理想のルート構造（最大5個）**
```
├── README.md          # プロジェクト説明（必須）
├── .gitignore         # 基本除外設定（必須）
├── pyproject.toml     # Python設定統合（必須）
├── config/           # 全設定ファイル統合
└── [以下のディレクトリ]
```

### **必須9ディレクトリ（既存維持）**
```
├── config/           # 全設定統合
├── docs/            # ドキュメント
├── src/             # ソースコード
├── scripts/         # ユーティリティ
├── tests/           # テスト（srcから分離）
├── data/            # データ
├── models/          # MLモデル
├── ops/             # 運用
└── runtime/         # ランタイム
```

## 📋 削除・統合対象ファイル

### **即座削除（プロジェクト固有）**
```bash
# ランタイム生成ファイル
rm -f validation_result.json
rm -f STATUS.md
rm -f SETUP_AUTO_STATUS.md

# 重複設定ファイル
rm -f .mcp.json.local
rm -f .mcp.json.template
rm -f .env.example
```

### **config/に統合**
```bash
# 設定ファイル統合
mv .mcp.json config/
mv .env config/
mv Makefile config/
```

### **pyproject.tomlに統合**
```toml
[tool.project]
name = "ai-control-rules"
version = "1.0.0"
description = "AI Behavior Control Rules Template"

[tool.scripts]
setup = "scripts/setup.sh"
test = "scripts/test.sh"
deploy = "scripts/deploy.sh"

[tool.ai-control]
template_mode = true
portable = true
```

## 🔄 自動化スクリプト

### **template-cleanup.sh**
```bash
#!/bin/bash
# テンプレート最適化自動実行

echo "🧹 テンプレート最適化開始"

# 1. ランタイムファイル削除
rm -f validation_result.json STATUS.md SETUP_AUTO_STATUS.md

# 2. 設定ファイル統合
mkdir -p config/system
mv .mcp.json config/system/ 2>/dev/null || true
mv .env config/system/ 2>/dev/null || true
mv Makefile config/system/ 2>/dev/null || true

# 3. 重複削除
rm -f .mcp.json.local .mcp.json.template .env.example

# 4. 隠しファイル整理
mv .shell_integration.bash config/system/ 2>/dev/null || true

echo "✅ テンプレート最適化完了"
echo "📁 ルートファイル数: $(ls -1 | wc -l)"
```

## 📏 移植性検証チェックリスト

### **✅ 必須条件**
- [ ] ルートファイル ≤ 5個
- [ ] 設定ファイル統合済み
- [ ] プロジェクト固有ファイル削除済み
- [ ] ランタイムファイル除去済み

### **✅ テンプレート機能**
- [ ] 新プロジェクトに1コマンドでコピー可能
- [ ] 環境依存ファイルなし
- [ ] カスタマイズ容易

### **✅ 移植テスト**
```bash
# 移植性テスト
cp -r . /tmp/test-template
cd /tmp/test-template
./scripts/setup.sh
# → エラーなく動作すること
```

## 🎯 成功基準

### **定量指標**
- ルートファイル: 12個 → 5個以下
- 設定ファイル: 散在 → config/に統合
- Git未追跡: 大量 → 最小限

### **定性指標**
- **即座移植**: 5分以内で新環境に移植
- **設定統合**: 1箇所で全設定管理
- **保守容易**: テンプレート更新が簡単

---

**🚀 このプランで、真のポータブルテンプレートを実現します**