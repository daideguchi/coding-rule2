#!/usr/bin/env node

/**
 * 統合オーケストレーター - Anthropic多エージェントシステム設計に基づく
 * 
 * 機能:
 * - 単一の調整システムとして動作
 * - 複数ワーカーの並列処理管理
 * - 構造化メッセージ制御
 * - 動的タスク分散
 * - 性能測定と品質管理
 */

const EventEmitter = require('events');
const WebSocket = require('ws');
const fs = require('fs').promises;
const path = require('path');

class UnifiedOrchestrator extends EventEmitter {
    constructor(config = {}) {
        super();
        this.config = {
            maxWorkers: 4,
            messageBusPort: 8080,
            monitoringInterval: 30000,
            qualityThreshold: 0.8,
            ...config
        };
        
        this.workers = new Map();
        this.taskQueue = [];
        this.activeJobs = new Map();
        this.performance = {
            completedTasks: 0,
            averageTime: 0,
            successRate: 0
        };
        
        this.messageBus = null;
        this.isRunning = false;
        
        this.setupMessageBus();
        this.setupMonitoring();
    }
    
    /**
     * メッセージバスの初期化
     */
    setupMessageBus() {
        this.messageBus = new WebSocket.Server({ 
            port: this.config.messageBusPort,
            perMessageDeflate: false
        });
        
        this.messageBus.on('connection', (ws, req) => {
            const workerId = this.extractWorkerId(req);
            this.registerWorker(workerId, ws);
            
            ws.on('message', (data) => {
                this.handleWorkerMessage(workerId, JSON.parse(data));
            });
            
            ws.on('close', () => {
                this.unregisterWorker(workerId);
            });
        });
        
        console.log(`🚀 統合オーケストレーター開始 - ポート ${this.config.messageBusPort}`);
    }
    
    /**
     * ワーカー登録
     */
    registerWorker(workerId, websocket) {
        this.workers.set(workerId, {
            id: workerId,
            ws: websocket,
            status: 'idle',
            currentTask: null,
            performance: {
                tasksCompleted: 0,
                averageTime: 0,
                lastActivity: Date.now()
            }
        });
        
        this.emit('workerRegistered', workerId);
        console.log(`✅ ワーカー登録: ${workerId}`);
    }
    
    /**
     * ワーカー登録解除
     */
    unregisterWorker(workerId) {
        if (this.workers.has(workerId)) {
            this.workers.delete(workerId);
            this.emit('workerUnregistered', workerId);
            console.log(`❌ ワーカー登録解除: ${workerId}`);
        }
    }
    
    /**
     * ワーカーメッセージハンドラ
     */
    handleWorkerMessage(workerId, message) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        switch (message.type) {
            case 'taskCompleted':
                this.handleTaskCompletion(workerId, message);
                break;
            case 'taskFailed':
                this.handleTaskFailure(workerId, message);
                break;
            case 'statusUpdate':
                this.handleStatusUpdate(workerId, message);
                break;
            case 'performanceMetrics':
                this.handlePerformanceMetrics(workerId, message);
                break;
            case 'healthStatus':
                this.handleHealthStatus(workerId, message);
                break;
        }
    }
    
    /**
     * ステータス更新の処理
     */
    handleStatusUpdate(workerId, message) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        worker.status = message.status;
        worker.performance.lastActivity = Date.now();
        
        if (message.capabilities) {
            worker.capabilities = message.capabilities;
        }
        
        console.log(`📊 ワーカー ${workerId} ステータス更新: ${message.status}`);
    }
    
    /**
     * 性能メトリクスの処理
     */
    handlePerformanceMetrics(workerId, message) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        worker.performance = { ...worker.performance, ...message.metrics };
        console.log(`📈 ワーカー ${workerId} 性能メトリクス更新`);
    }
    
    /**
     * ヘルス状態の処理
     */
    handleHealthStatus(workerId, message) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        worker.status = message.status;
        worker.performance = { ...worker.performance, ...message.performance };
        
        console.log(`💚 ワーカー ${workerId} ヘルスチェック: ${message.status}`);
    }
    
    /**
     * タスク完了処理
     */
    handleTaskCompletion(workerId, message) {
        const worker = this.workers.get(workerId);
        const job = this.activeJobs.get(message.jobId);
        
        if (job) {
            job.status = 'completed';
            job.result = message.result;
            job.completedAt = Date.now();
            
            // 性能統計更新
            this.updatePerformanceMetrics(workerId, job);
            
            // 次のタスクを割り当て
            this.assignNextTask(workerId);
            
            this.emit('taskCompleted', job);
            console.log(`✅ タスク完了: ${job.id} by ${workerId}`);
        }
    }
    
    /**
     * タスク失敗処理
     */
    handleTaskFailure(workerId, message) {
        const job = this.activeJobs.get(message.jobId);
        
        if (job) {
            job.status = 'failed';
            job.error = message.error;
            job.failedAt = Date.now();
            
            // 再試行ロジック
            if (job.retryCount < 3) {
                job.retryCount++;
                this.taskQueue.unshift(job); // 優先して再試行
                console.log(`🔄 タスク再試行: ${job.id} (${job.retryCount}/3)`);
            } else {
                this.emit('taskFailed', job);
                console.log(`❌ タスク失敗: ${job.id} - ${message.error}`);
            }
            
            this.assignNextTask(workerId);
        }
    }
    
    /**
     * タスクの追加
     */
    addTask(task) {
        const job = {
            id: `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            task,
            status: 'queued',
            createdAt: Date.now(),
            retryCount: 0,
            priority: task.priority || 'medium'
        };
        
        // 優先度に基づいてキューに挿入
        if (job.priority === 'high') {
            this.taskQueue.unshift(job);
        } else {
            this.taskQueue.push(job);
        }
        
        this.emit('taskQueued', job);
        
        // アイドル状態のワーカーに即座に割り当て
        this.assignTasksToIdleWorkers();
        
        return job.id;
    }
    
    /**
     * アイドルワーカーへのタスク割り当て
     */
    assignTasksToIdleWorkers() {
        const idleWorkers = Array.from(this.workers.values())
            .filter(worker => worker.status === 'idle')
            .sort((a, b) => a.performance.tasksCompleted - b.performance.tasksCompleted);
        
        for (const worker of idleWorkers) {
            if (this.taskQueue.length === 0) break;
            this.assignNextTask(worker.id);
        }
    }
    
    /**
     * 次のタスクを割り当て
     */
    assignNextTask(workerId) {
        const worker = this.workers.get(workerId);
        if (!worker || this.taskQueue.length === 0) {
            if (worker) worker.status = 'idle';
            return;
        }
        
        const job = this.taskQueue.shift();
        job.status = 'running';
        job.assignedTo = workerId;
        job.startedAt = Date.now();
        
        worker.status = 'busy';
        worker.currentTask = job.id;
        
        this.activeJobs.set(job.id, job);
        
        // タスクをワーカーに送信
        this.sendMessageToWorker(workerId, {
            type: 'executeTask',
            jobId: job.id,
            task: job.task
        });
        
        console.log(`📋 タスク割り当て: ${job.id} → ${workerId}`);
    }
    
    /**
     * ワーカーへのメッセージ送信
     */
    sendMessageToWorker(workerId, message) {
        const worker = this.workers.get(workerId);
        if (worker && worker.ws.readyState === WebSocket.OPEN) {
            worker.ws.send(JSON.stringify(message));
        }
    }
    
    /**
     * 全ワーカーへのブロードキャスト
     */
    broadcastToWorkers(message) {
        for (const [workerId, worker] of this.workers) {
            if (worker.ws.readyState === WebSocket.OPEN) {
                worker.ws.send(JSON.stringify(message));
            }
        }
    }
    
    /**
     * 性能統計の更新
     */
    updatePerformanceMetrics(workerId, job) {
        const worker = this.workers.get(workerId);
        if (!worker) return;
        
        const duration = job.completedAt - job.startedAt;
        worker.performance.tasksCompleted++;
        worker.performance.averageTime = 
            (worker.performance.averageTime * (worker.performance.tasksCompleted - 1) + duration) / 
            worker.performance.tasksCompleted;
        worker.performance.lastActivity = Date.now();
        
        // 全体統計の更新
        this.performance.completedTasks++;
        this.performance.averageTime = 
            (this.performance.averageTime * (this.performance.completedTasks - 1) + duration) / 
            this.performance.completedTasks;
    }
    
    /**
     * 監視システムの初期化
     */
    setupMonitoring() {
        setInterval(() => {
            this.performHealthCheck();
            this.optimizeWorkload();
            this.logPerformanceMetrics();
        }, this.config.monitoringInterval);
    }
    
    /**
     * ヘルスチェック
     */
    performHealthCheck() {
        const now = Date.now();
        const unhealthyWorkers = [];
        
        for (const [workerId, worker] of this.workers) {
            if (now - worker.performance.lastActivity > 60000) { // 1分間非アクティブ
                unhealthyWorkers.push(workerId);
            }
        }
        
        if (unhealthyWorkers.length > 0) {
            console.log(`⚠️ 非アクティブワーカー検出: ${unhealthyWorkers.join(', ')}`);
            this.emit('unhealthyWorkers', unhealthyWorkers);
        }
    }
    
    /**
     * ワークロード最適化
     */
    optimizeWorkload() {
        // 負荷分散の最適化
        const busyWorkers = Array.from(this.workers.values())
            .filter(worker => worker.status === 'busy');
        
        if (busyWorkers.length > 0 && this.taskQueue.length > 0) {
            console.log(`🔄 ワークロード最適化中: ${busyWorkers.length} busy workers, ${this.taskQueue.length} queued tasks`);
        }
    }
    
    /**
     * 性能ログ出力
     */
    logPerformanceMetrics() {
        const activeWorkers = this.workers.size;
        const queuedTasks = this.taskQueue.length;
        const activeTasks = this.activeJobs.size;
        
        console.log(`📊 性能統計: Workers: ${activeWorkers}, Queued: ${queuedTasks}, Active: ${activeTasks}, Completed: ${this.performance.completedTasks}`);
    }
    
    /**
     * システム開始
     */
    start() {
        this.isRunning = true;
        this.emit('started');
        console.log('🚀 統合オーケストレーターシステム開始');
    }
    
    /**
     * システム停止
     */
    async stop() {
        this.isRunning = false;
        
        // 全ワーカーに停止通知
        this.broadcastToWorkers({ type: 'shutdown' });
        
        // WebSocketサーバーを閉じる
        if (this.messageBus) {
            this.messageBus.close();
        }
        
        this.emit('stopped');
        console.log('🛑 統合オーケストレーターシステム停止');
    }
    
    /**
     * ワーカーIDの抽出
     */
    extractWorkerId(req) {
        const url = new URL(req.url, 'http://localhost');
        return url.searchParams.get('workerId') || `worker_${Date.now()}`;
    }
    
    /**
     * システム状態の取得
     */
    getStatus() {
        return {
            isRunning: this.isRunning,
            workers: Array.from(this.workers.values()).map(w => ({
                id: w.id,
                status: w.status,
                currentTask: w.currentTask,
                performance: w.performance
            })),
            queuedTasks: this.taskQueue.length,
            activeTasks: this.activeJobs.size,
            performance: this.performance
        };
    }
}

module.exports = UnifiedOrchestrator;

// 直接実行時
if (require.main === module) {
    const orchestrator = new UnifiedOrchestrator();
    
    // サンプルタスクを追加
    orchestrator.addTask({
        type: 'analysis',
        data: { input: 'sample data' },
        priority: 'high'
    });
    
    orchestrator.start();
    
    // 終了処理
    process.on('SIGINT', async () => {
        await orchestrator.stop();
        process.exit(0);
    });
}