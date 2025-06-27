# セキュリティガイドライン

## 🚨 セキュリティ問題の発見と対策

### 発見されたリスク

1. **Claude認証情報の不適切な管理**
   - APIキーがプロンプトで表示される可能性
   - 環境変数の漏洩リスク

2. **危険なコマンドの自動実行**
   - `--dangerously-skip-permissions`の多用
   - セキュリティ確認の自動バイパス

3. **tmuxセッションでの機密情報露出**
   - セッション内容の意図しないキャプチャ
   - プロセス間での情報漏洩

### セキュリティ対策

#### 1. 認証情報の保護
```bash
# 環境変数の設定（推奨）
export ANTHROPIC_API_KEY="your-key-here"

# 設定ファイルは.gitignoreで除外
echo ".claude-auth-method" >> .gitignore
echo ".env" >> .gitignore
```

#### 2. セキュリティ確認の強化
- `--dangerously-skip-permissions`の使用を最小限に制限
- 自動バイパス設定の無効化
- ユーザー明示的確認の追加

#### 3. ログファイルの安全な管理
```bash
# 機密情報を含む可能性のあるログファイル
/tmp/ai-agents-*.log
nohup.out

# これらのファイルは.gitignoreに追加済み
```

### 推奨セキュリティ設定

#### setup.shの修正版設定
```json
{
  "tools": {
    "enabled": true,
    "auto_bypass_permissions": false,  // falseに変更
    "dangerous_commands": false,
    "require_user_confirmation": true  // 追加
  }
}
```

### セキュリティチェックリスト

- [ ] APIキーが環境変数として適切に設定されている
- [ ] `.claude-auth-method`が.gitignoreに含まれている
- [ ] 自動バイパス設定が無効化されている
- [ ] ログファイルから機密情報が除外されている
- [ ] tmuxセッションのアクセス制御が適切に設定されている

### 緊急時の対応手順

1. **APIキー漏洩の疑いがある場合**
   ```bash
   # 即座にAPIキーを無効化
   unset ANTHROPIC_API_KEY
   # 新しいAPIキーを生成・設定
   ```

2. **セッション情報の漏洩の疑いがある場合**
   ```bash
   # tmuxセッションを全削除
   ./ai-agents/manage.sh clean
   # ログファイルを削除
   rm -f /tmp/ai-agents-*.log
   ```

## 連絡先

セキュリティに関する問題を発見した場合は、すぐに報告してください。