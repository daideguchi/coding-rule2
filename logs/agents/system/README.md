# 📊 統合ログ管理システム

## ログディレクトリ構成

```
logs/
├── README.md              # このファイル
├── claude-code/           # Claude Code関連ログ
│   ├── sessions/          # セッションログ
│   ├── sync/              # 同期ログ
│   └── errors/            # エラーログ
├── cursor/                # Cursor関連ログ
│   ├── rules/             # ルール適用ログ
│   ├── ai-assist/         # AI支援ログ
│   └── errors/            # エラーログ
├── ai-agents/             # AI組織システムログ
│   ├── president/         # プレジデントログ
│   ├── boss/              # ボスログ
│   ├── workers/           # ワーカーログ
│   └── communication/     # エージェント間通信ログ
└── system/                # システム全体ログ
    ├── setup/             # セットアップログ
    ├── status/            # 状況確認ログ
    └── errors/            # システムエラーログ
```

## ログファイル命名規則

- **日付形式**: `YYYY-MM-DD_HH-MM-SS.log`
- **セッション形式**: `session_YYYYMMDD_HHMMSS.log`
- **エラー形式**: `error_YYYYMMDD_component.log`

## ログ確認コマンド

```bash
# 最新ログ確認
tail -f logs/system/current.log

# Claude Codeログ確認
tail -f logs/claude-code/sessions/current.log

# AI組織システムログ確認
tail -f logs/ai-agents/communication/current.log

# エラーログ確認
ls -la logs/*/errors/
```

## ログクリーンアップ

```bash
# 7日以上古いログを削除
find logs/ -name "*.log" -mtime +7 -delete

# 特定コンポーネントのログクリア
rm -f logs/ai-agents/*/*.log
```

## 自動ログローテーション

- **日次**: 毎日新しいログファイル作成
- **週次**: 古いログファイルの圧縮
- **月次**: 1 ヶ月以上古いログの自動削除
