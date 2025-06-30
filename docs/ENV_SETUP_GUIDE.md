# 環境変数セットアップガイド

## 📋 .envファイル設定

### 🚀 クイックスタート

1. `.env.example`を`.env`にコピー
```bash
cp .env.example .env
```

2. 必要な値を設定
```bash
# .envファイルを編集
OPENAI_API_KEY=your_actual_api_key
GITHUB_TOKEN=your_actual_token
```

### 🔒 セキュリティベストプラクティス

- ✅ `.env`は`.gitignore`に追加済み
- ✅ `.env.example`で設定例を提供
- ✅ 機密情報はコミットされません

### 🛠️ 使用方法

```bash
# .envファイル読み込み
source .env

# スクリプトで使用
echo $OPENAI_API_KEY
```

### 📝 設定項目説明

| 変数名 | 説明 | 必須 |
|--------|------|------|
| OPENAI_API_KEY | OpenAI APIキー | ✅ |
| GITHUB_TOKEN | GitHub Personal Access Token | ✅ |
| PROJECT_NAME | プロジェクト名 | ○ |
| AI_ORGANIZATION_MODE | AI組織モード | ○ |