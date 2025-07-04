#!/usr/bin/env node

/**
 * ワーカーエージェント - Anthropic多エージェントシステム設計に基づく
 * 
 * 機能:
 * - オーケストレーターとの通信
 * - タスクの実行
 * - 性能メトリクスの報告
 * - 専門化された処理能力
 */

const WebSocket = require('ws');
const EventEmitter = require('events');

class WorkerAgent extends EventEmitter {
    constructor(workerId, orchestratorUrl = 'ws://localhost:8080') {
        super();
        this.workerId = workerId;
        this.orchestratorUrl = orchestratorUrl;
        this.ws = null;
        this.isConnected = false;
        this.currentTask = null;
        
        this.capabilities = {
            analysis: true,
            automation: true,
            monitoring: true,
            integration: true
        };
        
        this.performance = {
            tasksCompleted: 0,
            averageTime: 0,
            successRate: 1.0,
            lastActivity: Date.now()
        };
        
        this.setupConnection();
    }
    
    /**
     * オーケストレーターとの接続設定
     */
    setupConnection() {
        const url = `${this.orchestratorUrl}?workerId=${this.workerId}`;
        this.ws = new WebSocket(url);
        
        this.ws.on('open', () => {
            this.isConnected = true;
            this.emit('connected');
            console.log(`🔗 ワーカー ${this.workerId} 接続完了`);
            
            // 初期状態を送信
            this.sendMessage({
                type: 'statusUpdate',
                status: 'idle',
                capabilities: this.capabilities
            });
        });
        
        this.ws.on('message', (data) => {
            try {
                const message = JSON.parse(data);
                this.handleMessage(message);
            } catch (error) {
                console.error('メッセージ解析エラー:', error);
            }
        });
        
        this.ws.on('close', () => {
            this.isConnected = false;
            this.emit('disconnected');
            console.log(`🔌 ワーカー ${this.workerId} 接続切断`);
            
            // 再接続試行
            setTimeout(() => this.setupConnection(), 5000);
        });
        
        this.ws.on('error', (error) => {
            console.error(`ワーカー ${this.workerId} 接続エラー:`, error);
            this.emit('error', error);
        });
    }
    
    /**
     * メッセージハンドラ
     */
    handleMessage(message) {
        switch (message.type) {
            case 'executeTask':
                this.executeTask(message.jobId, message.task);
                break;
            case 'shutdown':
                this.shutdown();
                break;
            case 'healthCheck':
                this.sendHealthStatus();
                break;
            case 'updateCapabilities':
                this.updateCapabilities(message.capabilities);
                break;
        }
    }
    
    /**
     * タスクの実行
     */
    async executeTask(jobId, task) {
        this.currentTask = { jobId, task, startTime: Date.now() };
        
        try {
            console.log(`🔄 タスク実行開始: ${jobId} - ${task.type}`);
            
            // タスク実行
            const result = await this.processTask(task);
            
            // 成功時の処理
            const duration = Date.now() - this.currentTask.startTime;
            this.updatePerformanceMetrics(duration, true);
            
            this.sendMessage({
                type: 'taskCompleted',
                jobId,
                result,
                duration,
                metrics: this.performance
            });
            
            console.log(`✅ タスク実行完了: ${jobId} (${duration}ms)`);
            
        } catch (error) {
            // エラー時の処理
            const duration = Date.now() - this.currentTask.startTime;
            this.updatePerformanceMetrics(duration, false);
            
            this.sendMessage({
                type: 'taskFailed',
                jobId,
                error: error.message,
                duration,
                metrics: this.performance
            });
            
            console.error(`❌ タスク実行失敗: ${jobId} - ${error.message}`);
            
        } finally {
            this.currentTask = null;
        }
    }
    
    /**
     * タスクの処理（専門化された実装）
     */
    async processTask(task) {
        switch (task.type) {
            case 'analysis':
                return await this.performAnalysis(task.data);
            case 'automation':
                return await this.performAutomation(task.data);
            case 'monitoring':
                return await this.performMonitoring(task.data);
            case 'integration':
                return await this.performIntegration(task.data);
            default:
                throw new Error(`未知のタスクタイプ: ${task.type}`);
        }
    }
    
    /**
     * 分析タスクの実行
     */
    async performAnalysis(data) {
        // シミュレーション - 実際の分析処理
        await this.simulateWork(1000 + Math.random() * 2000);
        
        return {
            type: 'analysis',
            result: {
                status: 'completed',
                insights: ['パターンA検出', 'パターンB検出'],
                confidence: 0.85,
                timestamp: Date.now()
            }
        };
    }
    
    /**
     * 自動化タスクの実行
     */
    async performAutomation(data) {
        // シミュレーション - 実際の自動化処理
        await this.simulateWork(500 + Math.random() * 1000);
        
        return {
            type: 'automation',
            result: {
                status: 'completed',
                actions: ['アクション1実行', 'アクション2実行'],
                duration: 1234,
                timestamp: Date.now()
            }
        };
    }
    
    /**
     * 監視タスクの実行
     */
    async performMonitoring(data) {
        // シミュレーション - 実際の監視処理
        await this.simulateWork(200 + Math.random() * 500);
        
        return {
            type: 'monitoring',
            result: {
                status: 'completed',
                metrics: {
                    cpu: Math.random() * 100,
                    memory: Math.random() * 100,
                    disk: Math.random() * 100
                },
                alerts: [],
                timestamp: Date.now()
            }
        };
    }
    
    /**
     * 統合タスクの実行
     */
    async performIntegration(data) {
        // シミュレーション - 実際の統合処理
        await this.simulateWork(800 + Math.random() * 1200);
        
        return {
            type: 'integration',
            result: {
                status: 'completed',
                connections: ['システムA', 'システムB'],
                dataTransfer: 1024,
                timestamp: Date.now()
            }
        };
    }
    
    /**
     * 作業シミュレーション
     */
    async simulateWork(duration) {
        return new Promise(resolve => {
            setTimeout(resolve, duration);
        });
    }
    
    /**
     * 性能メトリクスの更新
     */
    updatePerformanceMetrics(duration, success) {
        this.performance.tasksCompleted++;
        this.performance.averageTime = 
            (this.performance.averageTime * (this.performance.tasksCompleted - 1) + duration) / 
            this.performance.tasksCompleted;
        
        if (success) {
            this.performance.successRate = 
                (this.performance.successRate * (this.performance.tasksCompleted - 1) + 1) / 
                this.performance.tasksCompleted;
        } else {
            this.performance.successRate = 
                (this.performance.successRate * (this.performance.tasksCompleted - 1) + 0) / 
                this.performance.tasksCompleted;
        }
        
        this.performance.lastActivity = Date.now();
    }
    
    /**
     * オーケストレーターへのメッセージ送信
     */
    sendMessage(message) {
        if (this.isConnected && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(message));
        }
    }
    
    /**
     * ヘルス状態の送信
     */
    sendHealthStatus() {
        this.sendMessage({
            type: 'healthStatus',
            workerId: this.workerId,
            status: this.currentTask ? 'busy' : 'idle',
            performance: this.performance,
            capabilities: this.capabilities,
            timestamp: Date.now()
        });
    }
    
    /**
     * 能力の更新
     */
    updateCapabilities(capabilities) {
        this.capabilities = { ...this.capabilities, ...capabilities };
        console.log(`🔧 能力更新: ${this.workerId}`, this.capabilities);
    }
    
    /**
     * システム停止
     */
    shutdown() {
        console.log(`🛑 ワーカー ${this.workerId} 停止中...`);
        
        if (this.ws) {
            this.ws.close();
        }
        
        this.emit('shutdown');
        process.exit(0);
    }
    
    /**
     * 状態の取得
     */
    getStatus() {
        return {
            workerId: this.workerId,
            isConnected: this.isConnected,
            currentTask: this.currentTask,
            performance: this.performance,
            capabilities: this.capabilities
        };
    }
}

module.exports = WorkerAgent;

// 直接実行時
if (require.main === module) {
    const workerId = process.argv[2] || `worker_${Date.now()}`;
    const orchestratorUrl = process.argv[3] || 'ws://localhost:8080';
    
    const worker = new WorkerAgent(workerId, orchestratorUrl);
    
    worker.on('connected', () => {
        console.log(`🚀 ワーカー ${workerId} 開始`);
    });
    
    worker.on('disconnected', () => {
        console.log(`🔌 ワーカー ${workerId} 切断`);
    });
    
    worker.on('error', (error) => {
        console.error(`❌ ワーカー ${workerId} エラー:`, error);
    });
    
    // 終了処理
    process.on('SIGINT', () => {
        worker.shutdown();
    });
}