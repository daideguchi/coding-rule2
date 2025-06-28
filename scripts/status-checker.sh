#!/bin/bash

# 🔍 TeamAI 設定状況チェッカー v1.0
# 現在の設定状況を確認し、STATUS.mdを更新

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# 設定状況を検出
detect_pattern() {
    local pattern="未検出"
    local install_date="不明"
    
    if [ -d "ai-agents" ] && [ -f ".claude-project" ] && [ -d ".cursor" ]; then
        pattern="パターン 3: 完全設定"
    elif [ -f ".claude-project" ] && [ -d ".cursor" ]; then
        pattern="パターン 2: 開発環境設定"
    elif [ -d ".cursor" ]; then
        pattern="パターン 1: 基本設定"
    fi
    
    # インストール日時を取得（.cursorディレクトリの作成日時）
    if [ -d ".cursor" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" .cursor 2>/dev/null || echo "不明")
        else
            install_date=$(stat -c "%y" .cursor 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "不明")
        fi
    fi
    
    echo "$pattern|$install_date"
}

# ファイル存在確認
check_files() {
    local files_status=""
    
    files_status+="📁 設定ファイル確認結果:\n"
    
    # 基本設定ファイル
    if [ -d ".cursor" ]; then
        files_status+="✅ .cursor/ - Cursor設定ディレクトリ\n"
        if [ -f ".cursor/rules.md" ]; then
            files_status+="  ✅ .cursor/rules.md - メイン設定ファイル\n"
        else
            files_status+="  ❌ .cursor/rules.md - 見つかりません\n"
        fi
        if [ -d ".cursor/rules" ]; then
            files_status+="  ✅ .cursor/rules/ - ルール集ディレクトリ\n"
        else
            files_status+="  ❌ .cursor/rules/ - 見つかりません\n"
        fi
    else
        files_status+="❌ .cursor/ - Cursor設定が見つかりません\n"
    fi
    
    # Claude Code設定
    if [ -f ".claude-project" ]; then
        files_status+="✅ .claude-project - Claude Code設定ファイル\n"
    else
        files_status+="⚪ .claude-project - 未インストール\n"
    fi
    
    if [ -f "claude-cursor-sync.sh" ]; then
        files_status+="✅ claude-cursor-sync.sh - 同期スクリプト\n"
    else
        files_status+="⚪ claude-cursor-sync.sh - 未インストール\n"
    fi
    
    # AI組織システム
    if [ -d "ai-agents" ]; then
        files_status+="✅ ai-agents/ - AI組織システム\n"
        if [ -f "ai-agents/manage.sh" ]; then
            files_status+="  ✅ ai-agents/manage.sh - 管理スクリプト\n"
        fi
        if [ -d "ai-agents/instructions" ]; then
            files_status+="  ✅ ai-agents/instructions/ - 指示書ディレクトリ\n"
        fi
        if [ -d "ai-agents/logs" ]; then
            files_status+="  ✅ ai-agents/logs/ - ログディレクトリ\n"
        fi
    else
        files_status+="⚪ ai-agents/ - 未インストール\n"
    fi
    
    echo -e "$files_status"
}

# 権限確認
check_permissions() {
    local perm_status=""
    
    perm_status+="⚙️ 実行権限確認結果:\n"
    
    if [ -x "setup.sh" ]; then
        perm_status+="✅ setup.sh - 実行可能\n"
    else
        perm_status+="❌ setup.sh - 実行権限なし\n"
    fi
    
    if [ -f "claude-cursor-sync.sh" ]; then
        if [ -x "claude-cursor-sync.sh" ]; then
            perm_status+="✅ claude-cursor-sync.sh - 実行可能\n"
        else
            perm_status+="❌ claude-cursor-sync.sh - 実行権限なし\n"
        fi
    fi
    
    if [ -f "ai-agents/manage.sh" ]; then
        if [ -x "ai-agents/manage.sh" ]; then
            perm_status+="✅ ai-agents/manage.sh - 実行可能\n"
        else
            perm_status+="❌ ai-agents/manage.sh - 実行権限なし\n"
        fi
    fi
    

    
    echo -e "$perm_status"
}

# ヘルスチェック
health_check() {
    local health_status=""
    
    # Cursor連携確認
    if [ -f ".cursor/rules.md" ] && [ -d ".cursor/rules" ]; then
        health_status+="- **Cursor 連携**: ✅ 正常\n"
    else
        health_status+="- **Cursor 連携**: ❌ 設定不完全\n"
    fi
    
    # Claude Code連携確認
    if [ -f ".claude-project" ] && [ -f "claude-cursor-sync.sh" ]; then
        health_status+="- **Claude Code 連携**: ✅ 正常\n"
    elif [ -f ".claude-project" ] || [ -f "claude-cursor-sync.sh" ]; then
        health_status+="- **Claude Code 連携**: ⚠️  設定不完全\n"
    else
        health_status+="- **Claude Code 連携**: ⚪ 未設定\n"
    fi
    
    # AI組織システム確認
    if [ -d "ai-agents" ] && [ -f "ai-agents/manage.sh" ] && [ -d "ai-agents/instructions" ]; then
        health_status+="- **AI 組織システム**: ✅ 正常\n"
    elif [ -d "ai-agents" ]; then
        health_status+="- **AI 組織システム**: ⚠️  設定不完全\n"
    else
        health_status+="- **AI 組織システム**: ⚪ 未設定\n"
    fi
    
    # 設定状況管理システム確認
    if [ -f "status-checker.sh" ] && [ -x "status-checker.sh" ]; then
        health_status+="- **設定状況管理システム**: ✅ 正常\n"
    else
        health_status+="- **設定状況管理システム**: ❌ 設定不完全\n"
    fi
    
    echo -e "$health_status"
}

# STATUS.mdを更新
update_status_file() {
    local pattern_info=$(detect_pattern)
    local pattern=$(echo "$pattern_info" | cut -d'|' -f1)
    local install_date=$(echo "$pattern_info" | cut -d'|' -f2)
    local current_time=$(date +'%Y-%m-%d %H:%M:%S')
    
    # 基本機能の状態
    local basic_status="❌ 未インストール"
    local basic_cursor_rules="❌"
    local basic_config_file="❌"
    local basic_rules_dir="❌"
    local basic_state="未設定"
    
    if [ -d ".cursor" ]; then
        basic_status="✅ インストール済み"
        basic_state="正常動作"
        
        if [ -f ".cursor/rules.md" ]; then
            basic_cursor_rules="✅"
            basic_config_file="✅"
        fi
        
        if [ -d ".cursor/rules" ]; then
            basic_rules_dir="✅"
        fi
    fi
    
    # Claude Code機能の状態
    local claude_status="❌ 未インストール"
    local claude_config="❌"
    local claude_sync="❌"
    local claude_project="❌"
    local claude_state="未設定"
    
    if [ -f ".claude-project" ] || [ -f "claude-cursor-sync.sh" ]; then
        if [ -f ".claude-project" ] && [ -f "claude-cursor-sync.sh" ]; then
            claude_status="✅ インストール済み"
            claude_state="正常動作"
            claude_config="✅"
            claude_sync="✅"
            claude_project="✅"
        else
            claude_status="⚠️  部分インストール"
            claude_state="設定不完全"
            if [ -f ".claude-project" ]; then
                claude_project="✅"
            fi
            if [ -f "claude-cursor-sync.sh" ]; then
                claude_sync="✅"
            fi
        fi
    fi
    
    # AI組織システムの状態
    local ai_status="❌ 未インストール"
    local ai_system="❌"
    local ai_manage="❌"
    local ai_instructions="❌"
    local ai_logs="❌"
    local ai_state="未設定"
    
    if [ -d "ai-agents" ]; then
        ai_system="✅"
        if [ -f "ai-agents/manage.sh" ] && [ -d "ai-agents/instructions" ] && [ -d "ai-agents/logs" ]; then
            ai_status="✅ インストール済み"
            ai_state="正常動作"
            ai_manage="✅"
            ai_instructions="✅"
            ai_logs="✅"
        else
            ai_status="⚠️  部分インストール"
            ai_state="設定不完全"
            if [ -f "ai-agents/manage.sh" ]; then
                ai_manage="✅"
            fi
            if [ -d "ai-agents/instructions" ]; then
                ai_instructions="✅"
            fi
            if [ -d "ai-agents/logs" ]; then
                ai_logs="✅"
            fi
        fi
    fi
    
    # STATUS.mdを生成
    cat > STATUS.md << EOF
# 🔍 CodingRule2 設定状況

## 📊 現在のセットアップ状況

### 🎯 インストール済みパターン
- **パターン**: $pattern
- **インストール日時**: $install_date
- **最終更新**: $current_time

---

## 📦 インストール済み機能

### 🟢 基本機能（Cursor Rules）
- $basic_cursor_rules **Cursor Rules**: $basic_status
- $basic_config_file **設定ファイル**: \`.cursor/rules.md\`
- $basic_rules_dir **ルール集**: \`.cursor/rules/\`
- ✅ **状態**: $basic_state

### 🟡 開発環境機能（Claude Code 連携）
- $claude_config **Claude Code 設定**: $claude_status
- $claude_sync **同期スクリプト**: \`claude-cursor-sync.sh\`
- $claude_project **プロジェクト設定**: \`.claude-project\`
- ⚪ **状態**: $claude_state

### 🔴 完全機能（AI 組織システム）
- $ai_system **AI 組織システム**: $ai_status
- $ai_manage **管理スクリプト**: \`ai-agents/manage.sh\`
- $ai_instructions **指示書**: \`ai-agents/instructions/\`
- $ai_logs **ログ管理**: \`ai-agents/logs/\`
- ⚪ **状態**: $ai_state

---

## 🔧 システム詳細

### 📁 設定ファイル状況
\`\`\`
$(check_files)
\`\`\`

### ⚙️ 権限状況
\`\`\`
$(check_permissions)
\`\`\`

### 📈 ヘルスチェック
$(health_check)

---

## 🚀 推奨アクション

### 📋 今すぐできること
- [ ] Cursor を再起動して Rules を反映
- [ ] Claude Code 連携をテスト: \`./claude-cursor-sync.sh record\`
- [ ] AI 組織システムを起動: \`./ai-agents/manage.sh status\`
 - [ ] 設定状況を再確認: \`./status-checker.sh check\`
 
 ### 🔄 メンテナンス推奨
 - [ ] 設定ファイルのバックアップ: \`cp -r cursor-rules/ backup/\`
 - [ ] ログファイルのクリーンアップ: \`rm -f ai-agents/logs/*.log\`
 - [ ] 設定状況の定期確認: \`./status-checker.sh check\`

---

## 📞 トラブル時の確認項目

### ❌ 問題が発生した場合
1. **権限確認**: \`chmod +x *.sh\`
2. **設定確認**: \`cat .cursor/rules.md\`
3. **ログ確認**: \`tail -f ai-agents/logs/system.log\`
4. **完全リセット**: \`./setup.sh reset\`

---

## 📝 更新履歴

- **$current_time**: 設定状況を自動更新

---

*このファイルは自動生成されます。手動編集は推奨されません。*  
*最終更新: $current_time*
EOF

    log_success "STATUS.md を更新しました"
}

# メイン処理
main() {
    case "${1:-check}" in
        "check"|"status")
            log_info "🔍 設定状況をチェック中..."
            update_status_file
            log_success "✅ 設定状況確認完了"
            echo ""
            echo "📋 結果を確認: cat STATUS.md"
            echo "🌐 ブラウザで確認: open STATUS.md"
            ;;
        "show")
            if [ -f "STATUS.md" ]; then
                cat STATUS.md
            else
                log_warn "STATUS.md が見つかりません。まず './status-checker.sh check' を実行してください"
            fi
            ;;
        "help")
            echo "🔍 CodingRule2 設定状況チェッカー"
            echo ""
            echo "使用方法:"
            echo "  ./status-checker.sh [コマンド]"
            echo ""
            echo "コマンド:"
            echo "  check    設定状況をチェックし、STATUS.mdを更新 (デフォルト)"
            echo "  status   設定状況をチェックし、STATUS.mdを更新 (checkと同じ)"
            echo "  show     現在のSTATUS.mdの内容を表示"
            echo "  help     このヘルプを表示"
            ;;
        *)
            log_warn "不明なコマンド: $1"
            echo "使用方法: ./status-checker.sh {check|status|show|help}"
            ;;
    esac
}

# スクリプト実行
main "$@" 