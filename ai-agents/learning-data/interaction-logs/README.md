# Interaction Logs

自律成長システムのインタラクションログ管理ディレクトリ

## ファイル構造

- `commands_YYYYMMDD.log` - コマンド実行履歴
- `errors_YYYYMMDD.log` - エラー発生履歴  
- `performance_YYYYMMDD.log` - パフォーマンス記録

## ログローテーション

- 日次ローテーション
- 30日間保持
- 自動圧縮機能

## プライバシー

- 個人情報は記録しない
- ハッシュ化された識別子のみ使用