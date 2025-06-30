# 🗂️ AI-Agents スクリプト完全ガイド

## 🚨 PRESIDENT必須スクリプト（最重要）

### 1. **president-declaration-system.sh** - 宣言忘れ防止
- **目的**: 作業開始前の必須宣言実行
- **使用タイミング**: 全作業開始前（絶対必須）
- **コマンド**: `./president-declaration-system.sh declare`

### 2. **president-auto-command.sh** - 自動指示送信
- **目的**: Enter忘れ防止の自動指示送信システム
- **使用タイミング**: ワーカーへの指示送信時
- **コマンド**: `./president-auto-command.sh boss "指示内容"`

### 3. **auto-enter-system.sh** - Enter自動実行
- **目的**: C-m 2回実行でワーカー停止防止
- **使用タイミング**: 手動指示送信時
- **コマンド**: `./auto-enter-system.sh boss "指示"`

## 🔍 監視・状況確認システム

### 4. **lightweight-monitor.sh** - 軽量監視
- **目的**: 30秒間隔の軽量バックグラウンド監視
- **使用タイミング**: システム起動後の継続監視
- **コマンド**: `./lightweight-monitor.sh start`

### 5. **auto-monitoring-system.sh** - 自動監視
- **目的**: 5秒間隔での詳細監視と自動修正
- **使用タイミング**: 重要作業中の集中監視
- **コマンド**: `./auto-monitoring-system.sh start`

### 6. **auto-status-updater.sh** - ステータス表示
- **目的**: 🟡待機中 👔チームリーダー形式の表示
- **使用タイミング**: 起動時・表示修正時
- **コマンド**: `./auto-status-updater.sh update`

## 🚀 起動・初期化システム

### 7. **smart-startup.sh** - スマート起動
- **目的**: AI組織の効率的起動
- **使用タイミング**: システム起動時
- **コマンド**: `./smart-startup.sh`

### 8. **president-startup-memory.sh** - 起動時思い出し
- **目的**: 立ち上がり時の自動ミス確認
- **使用タイミング**: PRESIDENT起動時
- **コマンド**: `./president-startup-memory.sh`

### 9. **startup-check.sh** - 起動確認
- **目的**: システム状態確認
- **使用タイミング**: 起動後の状況確認
- **コマンド**: `./startup-check.sh`

## 🛠️ ユーティリティ（utils/フォルダ）

### 重要ユーティリティ
- **governance-helper.sh** - ガバナンス支援
- **smart-status.sh** - 詳細ステータス確認
- **team-coordination.sh** - チーム協調
- **claude-auto-bypass.sh** - Bypassing Permissions自動突破

## 📋 実行優先順位（推奨フロー）

### 🚨 最優先（必須）
1. `president-declaration-system.sh declare`
2. `auto-status-updater.sh update`
3. `lightweight-monitor.sh start`

### 🔧 作業時（推奨）
1. `president-auto-command.sh boss "指示"`
2. `auto-monitoring-system.sh check`

### 🚀 起動時（推奨）
1. `smart-startup.sh`
2. `president-startup-memory.sh`
3. `startup-check.sh`

## ⚠️ 注意事項

### 🚫 非推奨・重複スクリプト
- **autonomous-monitoring.sh** → lightweight-monitor.sh使用推奨
- **simple-enter.sh** → auto-enter-system.sh使用推奨
- **backup/フォルダ内** → 過去版のため使用禁止

### 🔥 絶対ルール
1. **必ず宣言してから作業開始**
2. **Enter忘れ防止システム必須使用**
3. **軽量監視システム常時起動**
4. **推測報告禁止、確認済み事実のみ**

## 📊 使用頻度別分類

### 📈 毎回使用（必須）
- president-declaration-system.sh
- president-auto-command.sh
- lightweight-monitor.sh

### 📊 定期使用（推奨）
- auto-status-updater.sh
- auto-monitoring-system.sh
- smart-startup.sh

### 📉 必要時使用（オプション）
- utils/内の各種ツール
- 緊急修正系スクリプト