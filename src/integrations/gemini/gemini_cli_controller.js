#!/usr/bin/env node

/**
 * Gemini CLI自動制御システム
 * 
 * 機能:
 * - Gemini CLIプロセスを検出
 * - 対話モードのGeminiに自動でメッセージ送信
 * - プロセス間通信でタスクを実行
 */

const { spawn, exec } = require('child_process');
const fs = require('fs');
const path = require('path');

class GeminiCliController {
    constructor() {
        this.geminiProcesses = [];
        this.logFile = path.resolve(__dirname, 'coordination/gemini_controller.log');
    }

    // ログ出力
    log(message, level = 'INFO') {
        const timestamp = new Date().toISOString();
        const logMessage = `[${timestamp}] ${level}: ${message}`;
        console.log(logMessage);
        fs.appendFileSync(this.logFile, logMessage + '\n');
    }

    // Geminiプロセスを検出
    async findGeminiProcesses() {
        return new Promise((resolve, reject) => {
            exec('ps aux | grep -E "gemini.*--yolo" | grep -v grep', (error, stdout, stderr) => {
                if (error) {
                    this.log('Geminiプロセス検出エラー: ' + error.message, 'ERROR');
                    resolve([]);
                    return;
                }

                const processes = stdout.trim().split('\n')
                    .filter(line => line.length > 0)
                    .map(line => {
                        const parts = line.trim().split(/\s+/);
                        return {
                            pid: parseInt(parts[1]),
                            terminal: parts[6],
                            command: parts.slice(10).join(' ')
                        };
                    });

                this.log(`Geminiプロセス検出: ${processes.length}個`);
                processes.forEach(p => {
                    this.log(`  PID: ${p.pid}, Terminal: ${p.terminal}`);
                });

                resolve(processes);
            });
        });
    }

    // Geminiプロセスにメッセージを送信
    async sendMessageToGemini(message, targetPid = null) {
        const processes = await this.findGeminiProcesses();
        
        if (processes.length === 0) {
            this.log('実行中のGeminiプロセスが見つかりません', 'ERROR');
            return false;
        }

        // 対象プロセスを決定
        const targetProcess = targetPid 
            ? processes.find(p => p.pid === targetPid)
            : processes[0]; // 最初に見つけたプロセス

        if (!targetProcess) {
            this.log(`対象プロセス(PID: ${targetPid})が見つかりません`, 'ERROR');
            return false;
        }

        this.log(`メッセージ送信開始 - PID: ${targetProcess.pid}, TTY: ${targetProcess.terminal}`);
        this.log(`送信内容: ${message.substring(0, 100)}...`);

        try {
            // TTYに直接メッセージを送信
            const ttyDevice = `/dev/tty${targetProcess.terminal}`;
            const command = `echo "${message.replace(/"/g, '\\"')}" > ${ttyDevice}`;
            
            return new Promise((resolve, reject) => {
                exec(command, (error, stdout, stderr) => {
                    if (error) {
                        this.log(`TTY送信エラー: ${error.message}`, 'ERROR');
                        resolve(false);
                    } else {
                        this.log(`メッセージ送信完了 - TTY: ${ttyDevice}`);
                        resolve(true);
                    }
                });
            });

        } catch (error) {
            this.log(`メッセージ送信エラー: ${error.message}`, 'ERROR');
            return false;
        }
    }

    // AppleScript生成
    buildAppleScript(process, message) {
        // メッセージをエスケープ
        const escapedMessage = message
            .replace(/\\/g, '\\\\')
            .replace(/"/g, '\\"')
            .replace(/'/g, "\\'");

        // AppleScriptでCursorにフォーカスしてメッセージ送信
        return `tell application "Cursor"
    activate
end tell
delay 0.5
tell application "System Events"
    tell process "Cursor"
        -- メッセージを直接入力
        keystroke "${escapedMessage}"
        key code 36 -- Enter key
        return "success"
    end tell
end tell`;
    }

    // タスクファイルからメッセージを処理
    async processTaskFile(taskFilePath) {
        try {
            const taskData = JSON.parse(fs.readFileSync(taskFilePath, 'utf8'));
            
            this.log(`タスク処理開始: ${taskData.id}`);
            
            // タスク内容からプロンプトを構築
            const prompt = this.buildPromptFromTask(taskData);
            
            // Geminiに送信
            const success = await this.sendMessageToGemini(prompt);
            
            if (success) {
                this.log(`タスク送信成功: ${taskData.id}`);
                
                // 処理済みマーク
                const processedPath = taskFilePath.replace('.json', '_sent.json');
                fs.renameSync(taskFilePath, processedPath);
                
                return true;
            } else {
                this.log(`タスク送信失敗: ${taskData.id}`, 'ERROR');
                return false;
            }
            
        } catch (error) {
            this.log(`タスクファイル処理エラー: ${error.message}`, 'ERROR');
            return false;
        }
    }

    // タスクからプロンプト構築
    buildPromptFromTask(taskData) {
        let prompt = `🤖 AI間連携システムからのタスク\n\n`;
        prompt += `📋 タスクID: ${taskData.id}\n`;
        prompt += `📅 受信時刻: ${new Date().toLocaleString('ja-JP')}\n`;
        prompt += `🎯 タスクタイプ: ${taskData.type}\n`;
        prompt += `⭐ 優先度: ${taskData.priority}\n\n`;
        
        if (taskData.content) {
            prompt += `📝 タスク内容:\n`;
            if (typeof taskData.content === 'string') {
                prompt += taskData.content;
            } else {
                Object.entries(taskData.content).forEach(([key, value]) => {
                    prompt += `- ${key}: ${value}\n`;
                });
            }
        }
        
        prompt += `\n✅ このタスクを実行して、結果をMarkdown形式で出力してください。`;
        
        return prompt;
    }

    // 監視モード開始
    async startWatching(watchDir) {
        this.log('Gemini CLI制御システム起動');
        this.log(`監視ディレクトリ: ${watchDir}`);
        
        const chokidar = require('chokidar');
        
        // ファイル監視
        const watcher = chokidar.watch(path.join(watchDir, '*.json'), {
            persistent: true,
            ignoreInitial: false
        });
        
        watcher.on('add', async (filePath) => {
            if (filePath.endsWith('_sent.json')) return; // 処理済みファイルは無視
            
            this.log(`新規タスクファイル検出: ${filePath}`);
            
            // 少し待ってからファイル処理（書き込み完了を待つ）
            setTimeout(async () => {
                await this.processTaskFile(filePath);
            }, 1000);
        });

        this.log('ファイル監視開始 - Gemini CLI制御システム稼働中');
        
        // プロセス終了処理
        process.on('SIGINT', () => {
            this.log('Gemini CLI制御システム終了');
            watcher.close();
            process.exit(0);
        });
    }
}

// 直接実行時の処理
if (require.main === module) {
    const controller = new GeminiCliController();
    
    // コマンドライン引数処理
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('使用法:');
        console.log('  node gemini_cli_controller.js watch [ディレクトリ]  # 監視モード');
        console.log('  node gemini_cli_controller.js send "メッセージ"     # 単発送信');
        console.log('  node gemini_cli_controller.js test                  # テストモード');
        process.exit(1);
    }
    
    const command = args[0];
    
    switch (command) {
        case 'watch':
            const watchDir = args[1] || path.resolve(__dirname, 'inbox/gemini_tasks');
            controller.startWatching(watchDir);
            break;
            
        case 'send':
            const message = args[1];
            if (!message) {
                console.log('エラー: メッセージが指定されていません');
                process.exit(1);
            }
            controller.sendMessageToGemini(message);
            break;
            
        case 'test':
            controller.sendMessageToGemini('🧪 テストメッセージ: システム連携テストです。簡単な挨拶をお願いします。');
            break;
            
        default:
            console.log('エラー: 不明なコマンド:', command);
            process.exit(1);
    }
}

module.exports = GeminiCliController;