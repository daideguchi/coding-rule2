#!/usr/bin/env node

/**
 * システムランチャー - 統合多エージェントシステムの起動管理
 * 
 * 機能:
 * - オーケストレーターとワーカーの統合起動
 * - 設定ファイルの読み込み
 * - システムヘルスチェック
 * - 自動復旧機能
 */

const fs = require('fs').promises;
const path = require('path');
const { spawn } = require('child_process');
const EventEmitter = require('events');

class SystemLauncher extends EventEmitter {
    constructor(configPath = '../../configs/unified_system_config.json') {
        super();
        this.configPath = configPath;
        this.config = null;
        this.orchestrator = null;
        this.workers = new Map();
        this.isRunning = false;
        
        this.setupSignalHandlers();
    }
    
    /**
     * 設定ファイルの読み込み
     */
    async loadConfig() {
        try {
            const configFile = path.resolve(__dirname, this.configPath);
            const configData = await fs.readFile(configFile, 'utf8');
            this.config = JSON.parse(configData);
            console.log('📋 設定ファイル読み込み完了');
            return true;
        } catch (error) {
            console.error('❌ 設定ファイル読み込み失敗:', error.message);
            return false;
        }
    }
    
    /**
     * システムの起動
     */
    async start() {
        console.log('🚀 統合多エージェントシステム起動開始');
        
        // 設定ファイルの読み込み
        if (!(await this.loadConfig())) {
            process.exit(1);
        }
        
        // オーケストレーターの起動
        await this.startOrchestrator();
        
        // ワーカーの起動
        await this.startWorkers();
        
        // ヘルスチェックの開始
        this.startHealthCheck();
        
        this.isRunning = true;
        this.emit('systemStarted');
        
        console.log('✅ 統合多エージェントシステム起動完了');
        console.log(`📊 オーケストレーター: ポート ${this.config.orchestrator.port}`);
        console.log(`👥 ワーカー数: ${this.workers.size}`);
    }
    
    /**
     * オーケストレーターの起動
     */
    async startOrchestrator() {
        return new Promise((resolve, reject) => {
            const orchestratorPath = path.resolve(__dirname, '../core/UNIFIED_ORCHESTRATOR.js');
            
            this.orchestrator = spawn('node', [orchestratorPath], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: {
                    ...process.env,
                    CONFIG_PATH: this.configPath
                }
            });
            
            this.orchestrator.stdout.on('data', (data) => {
                console.log(`🎯 [ORCHESTRATOR] ${data.toString().trim()}`);
            });
            
            this.orchestrator.stderr.on('data', (data) => {
                console.error(`🎯 [ORCHESTRATOR ERROR] ${data.toString().trim()}`);
            });
            
            this.orchestrator.on('close', (code) => {
                console.log(`🎯 オーケストレーター終了: ${code}`);
                if (this.isRunning) {
                    this.handleOrchestratorFailure();
                }
            });
            
            // 起動確認のため少し待機
            setTimeout(() => {
                console.log('✅ オーケストレーター起動完了');
                resolve();
            }, 2000);
        });
    }
    
    /**
     * ワーカーの起動
     */
    async startWorkers() {
        const maxWorkers = this.config.orchestrator.maxWorkers;
        const workerPath = path.resolve(__dirname, '../core/WORKER_AGENT.js');
        
        for (let i = 1; i <= maxWorkers; i++) {
            const workerId = `WORKER${i}`;
            const orchestratorUrl = `ws://localhost:${this.config.orchestrator.port}`;
            
            const worker = spawn('node', [workerPath, workerId, orchestratorUrl], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: {
                    ...process.env,
                    WORKER_ID: workerId,
                    CONFIG_PATH: this.configPath
                }
            });
            
            worker.stdout.on('data', (data) => {
                console.log(`👤 [${workerId}] ${data.toString().trim()}`);
            });
            
            worker.stderr.on('data', (data) => {
                console.error(`👤 [${workerId} ERROR] ${data.toString().trim()}`);
            });
            
            worker.on('close', (code) => {
                console.log(`👤 ワーカー ${workerId} 終了: ${code}`);
                this.workers.delete(workerId);
                
                if (this.isRunning) {
                    this.handleWorkerFailure(workerId);
                }
            });
            
            this.workers.set(workerId, {
                process: worker,
                id: workerId,
                startTime: Date.now(),
                restarts: 0
            });
            
            // 起動間隔を空ける
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        console.log(`✅ ワーカー起動完了: ${this.workers.size} 個`);
    }
    
    /**
     * ヘルスチェックの開始
     */
    startHealthCheck() {
        setInterval(() => {
            this.performHealthCheck();
        }, this.config.monitoring.metricsInterval * 1000);
    }
    
    /**
     * ヘルスチェックの実行
     */
    performHealthCheck() {
        const now = Date.now();
        
        // オーケストレーターの状態チェック
        if (this.orchestrator && this.orchestrator.killed) {
            console.log('⚠️ オーケストレーター停止検出');
            this.handleOrchestratorFailure();
        }
        
        // ワーカーの状態チェック
        for (const [workerId, worker] of this.workers) {
            if (worker.process.killed) {
                console.log(`⚠️ ワーカー ${workerId} 停止検出`);
                this.handleWorkerFailure(workerId);
            }
        }
        
        // システム統計の出力
        this.logSystemStats();
    }
    
    /**
     * オーケストレーター失敗時の処理
     */
    async handleOrchestratorFailure() {
        console.log('🔄 オーケストレーター自動復旧中...');
        
        try {
            await this.startOrchestrator();
            console.log('✅ オーケストレーター復旧完了');
        } catch (error) {
            console.error('❌ オーケストレーター復旧失敗:', error);
            this.emit('systemFailure', 'orchestrator');
        }
    }
    
    /**
     * ワーカー失敗時の処理
     */
    async handleWorkerFailure(workerId) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        worker.restarts++;
        
        if (worker.restarts > 3) {
            console.log(`❌ ワーカー ${workerId} 復旧制限超過`);
            this.workers.delete(workerId);
            return;
        }
        
        console.log(`🔄 ワーカー ${workerId} 自動復旧中... (${worker.restarts}/3)`);
        
        try {
            const workerPath = path.resolve(__dirname, '../core/WORKER_AGENT.js');
            const orchestratorUrl = `ws://localhost:${this.config.orchestrator.port}`;
            
            const newWorker = spawn('node', [workerPath, workerId, orchestratorUrl], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: {
                    ...process.env,
                    WORKER_ID: workerId,
                    CONFIG_PATH: this.configPath
                }
            });
            
            // イベントハンドラーの設定
            newWorker.stdout.on('data', (data) => {
                console.log(`👤 [${workerId}] ${data.toString().trim()}`);
            });
            
            newWorker.stderr.on('data', (data) => {
                console.error(`👤 [${workerId} ERROR] ${data.toString().trim()}`);
            });
            
            newWorker.on('close', (code) => {
                console.log(`👤 ワーカー ${workerId} 終了: ${code}`);
                if (this.isRunning) {
                    this.handleWorkerFailure(workerId);
                }
            });
            
            // ワーカー情報の更新
            worker.process = newWorker;
            worker.startTime = Date.now();
            
            console.log(`✅ ワーカー ${workerId} 復旧完了`);
            
        } catch (error) {
            console.error(`❌ ワーカー ${workerId} 復旧失敗:`, error);
            this.workers.delete(workerId);
        }
    }
    
    /**
     * システム統計の出力
     */
    logSystemStats() {
        const runningWorkers = Array.from(this.workers.values())
            .filter(worker => !worker.process.killed).length;
        
        console.log(`📊 システム統計: オーケストレーター: ${this.orchestrator && !this.orchestrator.killed ? '稼働' : '停止'}, ワーカー: ${runningWorkers}/${this.workers.size}`);
    }
    
    /**
     * システムの停止
     */
    async stop() {
        console.log('🛑 統合多エージェントシステム停止中...');
        
        this.isRunning = false;
        
        // ワーカーの停止
        for (const [workerId, worker] of this.workers) {
            if (!worker.process.killed) {
                worker.process.kill('SIGTERM');
                console.log(`👤 ワーカー ${workerId} 停止`);
            }
        }
        
        // オーケストレーターの停止
        if (this.orchestrator && !this.orchestrator.killed) {
            this.orchestrator.kill('SIGTERM');
            console.log('🎯 オーケストレーター停止');
        }
        
        // 確実に終了するまで待機
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        this.emit('systemStopped');
        console.log('✅ 統合多エージェントシステム停止完了');
    }
    
    /**
     * シグナルハンドラーの設定
     */
    setupSignalHandlers() {
        process.on('SIGINT', async () => {
            console.log('\\n🛑 SIGINT受信 - システム停止中...');
            await this.stop();
            process.exit(0);
        });
        
        process.on('SIGTERM', async () => {
            console.log('\\n🛑 SIGTERM受信 - システム停止中...');
            await this.stop();
            process.exit(0);
        });
        
        process.on('uncaughtException', async (error) => {
            console.error('💥 未処理例外:', error);
            await this.stop();
            process.exit(1);
        });
    }
    
    /**
     * システム状態の取得
     */
    getStatus() {
        return {
            isRunning: this.isRunning,
            orchestrator: {
                running: this.orchestrator && !this.orchestrator.killed,
                pid: this.orchestrator ? this.orchestrator.pid : null
            },
            workers: Array.from(this.workers.values()).map(worker => ({
                id: worker.id,
                running: !worker.process.killed,
                pid: worker.process.pid,
                startTime: worker.startTime,
                restarts: worker.restarts
            }))
        };
    }
}

module.exports = SystemLauncher;

// 直接実行時
if (require.main === module) {
    const launcher = new SystemLauncher();
    
    launcher.on('systemStarted', () => {
        console.log('🎉 システム起動完了');
    });
    
    launcher.on('systemStopped', () => {
        console.log('🎉 システム停止完了');
    });
    
    launcher.on('systemFailure', (component) => {
        console.error(`💥 システム障害: ${component}`);
    });
    
    launcher.start().catch(error => {
        console.error('❌ システム起動失敗:', error);
        process.exit(1);
    });
}