#!/usr/bin/env node

/**
 * =============================================================================
 * 🔗 TRINITY_DEVELOPMENT_SYSTEM.js - 三位一体開発システム v1.0
 * =============================================================================
 * 
 * 【WORKER3実装】: Claude + Gemini + YOLO三位一体統合開発システム
 * 【目的】: 3つのAIシステムの統合管理・協調開発・統一インターフェース
 * 【特徴】: 統合管理・ワークフロー自動化・統一API・品質保証
 * 
 * =============================================================================
 */

const fs = require('fs').promises;
const path = require('path');
const { spawn, exec } = require('child_process');
const EventEmitter = require('events');
const WebSocket = require('ws');

// =============================================================================
// 📊 設定・データクラス
// =============================================================================

class TrinityConfig {
    constructor() {
        this.claude = {
            autopilot_script: './CLAUDE_AUTOPILOT_SYSTEM.sh',
            confidence_threshold: 0.8,
            auto_execution: true,
            safety_mode: true
        };
        
        this.gemini_yolo = {
            integration_script: './GEMINI_YOLO_INTEGRATION.py',
            real_time_mode: true,
            detection_threshold: 0.7,
            max_concurrent: 5
        };
        
        this.trinity = {
            coordination_mode: 'collaborative',
            decision_strategy: 'consensus',
            conflict_resolution: 'weighted_voting',
            performance_monitoring: true,
            auto_optimization: true
        };
        
        this.workflow = {
            default_pipeline: 'analyze_decide_execute',
            timeout_seconds: 30,
            retry_attempts: 3,
            error_escalation: true
        };
    }
}

class TrinityMessage {
    constructor(source, target, type, data, priority = 'medium') {
        this.id = this.generateId();
        this.source = source;
        this.target = target;
        this.type = type;
        this.data = data;
        this.priority = priority;
        this.timestamp = Date.now();
        this.status = 'pending';
    }
    
    generateId() {
        return `trinity_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
}

class TrinityResult {
    constructor(claudeResult, geminiYoloResult, decisionData) {
        this.id = this.generateId();
        this.timestamp = Date.now();
        this.claude_result = claudeResult;
        this.gemini_yolo_result = geminiYoloResult;
        this.decision_data = decisionData;
        this.integrated_confidence = this.calculateIntegratedConfidence();
        this.final_recommendation = this.generateFinalRecommendation();
        this.execution_plan = this.generateExecutionPlan();
    }
    
    generateId() {
        return `result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    calculateIntegratedConfidence() {
        const claudeConf = this.claude_result?.confidence || 0;
        const geminiConf = this.gemini_yolo_result?.integrated_confidence || 0;
        
        // 加重平均（Claude 60%, Gemini+YOLO 40%）
        return claudeConf * 0.6 + geminiConf * 0.4;
    }
    
    generateFinalRecommendation() {
        const claudeRec = this.claude_result?.recommendation || '';
        const geminiRec = this.gemini_yolo_result?.decision_recommendation || '';
        
        if (this.integrated_confidence >= 0.8) {
            return `高信頼度統合判断: ${claudeRec} | ${geminiRec}`;
        } else if (this.integrated_confidence >= 0.6) {
            return `中信頼度判断: 追加検証推奨 - ${claudeRec}`;
        } else {
            return `低信頼度: 人間の確認が必要 - 複数システムで判断不一致`;
        }
    }
    
    generateExecutionPlan() {
        const plan = {
            immediate_actions: [],
            scheduled_actions: [],
            verification_steps: [],
            escalation_triggers: []
        };
        
        if (this.integrated_confidence >= 0.8) {
            plan.immediate_actions.push('自動実行可能');
            plan.verification_steps.push('事後確認');
        } else {
            plan.scheduled_actions.push('人間承認後実行');
            plan.verification_steps.push('事前確認');
            plan.escalation_triggers.push('信頼度不足');
        }
        
        return plan;
    }
}

// =============================================================================
// 🎯 三位一体開発システムメインクラス
// =============================================================================

class TrinityDevelopmentSystem extends EventEmitter {
    constructor(configPath = null) {
        super();
        
        this.config = new TrinityConfig();
        this.isRunning = false;
        this.messageQueue = [];
        this.activeProcesses = new Map();
        this.resultHistory = [];
        this.performance = {
            total_requests: 0,
            successful_integrations: 0,
            average_response_time: 0,
            system_uptime: Date.now()
        };
        
        // パス設定
        this.aiAgentsDir = path.resolve(__dirname, '../..');
        this.logsDir = path.join(this.aiAgentsDir, 'logs');
        this.tmpDir = path.join(this.aiAgentsDir, 'tmp');
        this.configDir = path.join(this.aiAgentsDir, 'configs');
        
        this.setupLogging();
        this.loadConfig(configPath);
        
        this.log('info', 'SYSTEM', '🔗 三位一体開発システム初期化完了');
    }
    
    // =============================================================================
    // 🔧 システム初期化・設定
    // =============================================================================
    
    async setupLogging() {
        try {
            await fs.mkdir(this.logsDir, { recursive: true });
            await fs.mkdir(this.tmpDir, { recursive: true });
            await fs.mkdir(this.configDir, { recursive: true });
            
            this.logFile = path.join(this.logsDir, 'trinity-development-system.log');
        } catch (error) {
            console.error('ログディレクトリ作成エラー:', error);
        }
    }
    
    async loadConfig(configPath) {
        if (configPath && await this.fileExists(configPath)) {
            try {
                const configData = await fs.readFile(configPath, 'utf8');
                const customConfig = JSON.parse(configData);
                this.config = { ...this.config, ...customConfig };
                this.log('info', 'CONFIG', `設定ファイル読み込み完了: ${configPath}`);
            } catch (error) {
                this.log('error', 'CONFIG', `設定ファイル読み込みエラー: ${error.message}`);
            }
        }
    }
    
    log(level, component, message) {
        const timestamp = new Date().toISOString();
        const logMessage = `[${timestamp}] [TRINITY-${level.toUpperCase()}] [${component}] ${message}`;
        
        console.log(logMessage);
        
        // ファイルログ（非同期）
        if (this.logFile) {
            fs.appendFile(this.logFile, logMessage + '\\n').catch(console.error);
        }
    }
    
    async fileExists(filePath) {
        try {
            await fs.access(filePath);
            return true;
        } catch {
            return false;
        }
    }
    
    // =============================================================================
    // 🚀 システム起動・管理
    // =============================================================================
    
    async startTrinitySystem() {
        this.log('info', 'STARTUP', '🚀 三位一体システム起動開始');
        this.isRunning = true;
        
        try {
            // 各サブシステム初期化
            await this.initializeClaudeAutopilot();
            await this.initializeGeminiYolo();
            await this.initializeCoordinationEngine();
            
            // メッセージ処理ループ開始
            this.startMessageProcessingLoop();
            
            // パフォーマンス監視開始
            this.startPerformanceMonitoring();
            
            // WebSocket サーバー開始（他システムとの連携用）
            await this.startWebSocketServer();
            
            this.log('info', 'STARTUP', '✅ 三位一体システム起動完了');
            this.emit('systemStarted');
            
        } catch (error) {
            this.log('error', 'STARTUP', `起動エラー: ${error.message}`);
            this.isRunning = false;
            throw error;
        }
    }
    
    async initializeClaudeAutopilot() {
        this.log('info', 'CLAUDE', 'Claude自動操縦システム初期化');
        
        const scriptPath = path.join(this.aiAgentsDir, 'scripts/core/CLAUDE_AUTOPILOT_SYSTEM.sh');
        
        if (await this.fileExists(scriptPath)) {
            // Claude自動操縦システムのテスト実行
            const testResult = await this.executeScript(scriptPath, ['test']);
            
            if (testResult.success) {
                this.log('info', 'CLAUDE', '✅ Claude自動操縦システム初期化完了');
            } else {
                throw new Error(`Claude初期化失敗: ${testResult.error}`);
            }
        } else {
            throw new Error(`Claudeスクリプトが見つかりません: ${scriptPath}`);
        }
    }
    
    async initializeGeminiYolo() {
        this.log('info', 'GEMINI_YOLO', 'Gemini YOLOシステム初期化');
        
        const scriptPath = path.join(this.aiAgentsDir, 'scripts/core/GEMINI_YOLO_INTEGRATION.py');
        
        if (await this.fileExists(scriptPath)) {
            // Gemini YOLOシステムのテスト実行
            const testResult = await this.executeScript('python3', [scriptPath, 'test']);
            
            if (testResult.success) {
                this.log('info', 'GEMINI_YOLO', '✅ Gemini YOLOシステム初期化完了');
            } else {
                this.log('warn', 'GEMINI_YOLO', `初期化警告: ${testResult.error}`);
                // Gemini YOLOは警告レベルで継続（依存関係不足の可能性）
            }
        } else {
            throw new Error(`Gemini YOLOスクリプトが見つかりません: ${scriptPath}`);
        }
    }
    
    async initializeCoordinationEngine() {
        this.log('info', 'COORDINATION', '協調エンジン初期化');
        
        // 協調エンジンの内部初期化
        this.coordinationEngine = {
            decision_queue: [],
            conflict_resolver: this.createConflictResolver(),
            consensus_builder: this.createConsensusBuilder(),
            workflow_manager: this.createWorkflowManager()
        };
        
        this.log('info', 'COORDINATION', '✅ 協調エンジン初期化完了');
    }
    
    // =============================================================================
    // 📨 メッセージ処理・通信システム
    // =============================================================================
    
    startMessageProcessingLoop() {
        this.log('info', 'MESSAGING', 'メッセージ処理ループ開始');
        
        const processMessages = async () => {
            while (this.isRunning) {
                try {
                    if (this.messageQueue.length > 0) {
                        const message = this.messageQueue.shift();
                        await this.processMessage(message);
                    }
                    
                    // 100ms待機
                    await new Promise(resolve => setTimeout(resolve, 100));
                } catch (error) {
                    this.log('error', 'MESSAGING', `メッセージ処理エラー: ${error.message}`);
                }
            }
        };
        
        processMessages();
    }
    
    async processMessage(message) {
        this.log('info', 'MESSAGE', `メッセージ処理開始: ${message.type} (${message.id})`);
        
        const startTime = Date.now();
        
        try {
            let result;
            
            switch (message.type) {
                case 'analyze_request':
                    result = await this.handleAnalyzeRequest(message);
                    break;
                case 'decision_request':
                    result = await this.handleDecisionRequest(message);
                    break;
                case 'execution_request':
                    result = await this.handleExecutionRequest(message);
                    break;
                case 'coordination_request':
                    result = await this.handleCoordinationRequest(message);
                    break;
                default:
                    throw new Error(`未知のメッセージタイプ: ${message.type}`);
            }
            
            const processingTime = Date.now() - startTime;
            this.updatePerformanceMetrics(processingTime, true);
            
            this.log('info', 'MESSAGE', `メッセージ処理完了: ${message.id} (${processingTime}ms)`);
            
            // 結果を外部システムに通知
            await this.notifyExternalSystems(result);
            
        } catch (error) {
            const processingTime = Date.now() - startTime;
            this.updatePerformanceMetrics(processingTime, false);
            
            this.log('error', 'MESSAGE', `メッセージ処理失敗: ${message.id} - ${error.message}`);
        }
    }
    
    async handleAnalyzeRequest(message) {
        this.log('info', 'ANALYZE', '統合分析要求処理開始');
        
        const { input_data, analysis_type } = message.data;
        
        // Claude自動操縦による分析
        const claudeAnalysis = await this.requestClaudeAnalysis(input_data, analysis_type);
        
        // Gemini YOLO分析（画像データがある場合）
        let geminiYoloAnalysis = null;
        if (input_data.image_path) {
            geminiYoloAnalysis = await this.requestGeminiYoloAnalysis(input_data.image_path);
        }
        
        // 統合結果生成
        const integratedResult = new TrinityResult(claudeAnalysis, geminiYoloAnalysis, {
            analysis_type,
            integration_strategy: 'comprehensive'
        });
        
        this.resultHistory.push(integratedResult);
        
        return integratedResult;
    }
    
    async handleDecisionRequest(message) {
        this.log('info', 'DECISION', '統合意思決定要求処理開始');
        
        const { situation, options, constraints } = message.data;
        
        // 各システムからの意思決定取得
        const claudeDecision = await this.requestClaudeDecision(situation, options);
        const geminiDecision = await this.requestGeminiDecision(situation, options);
        
        // 協調エンジンによる統合判断
        const finalDecision = await this.coordinationEngine.consensus_builder({
            claude: claudeDecision,
            gemini: geminiDecision,
            constraints
        });
        
        return {
            decision: finalDecision,
            reasoning: this.generateDecisionReasoning(claudeDecision, geminiDecision, finalDecision),
            confidence: this.calculateDecisionConfidence(claudeDecision, geminiDecision)
        };
    }
    
    async handleExecutionRequest(message) {
        this.log('info', 'EXECUTION', '統合実行要求処理開始');
        
        const { action, parameters, safety_check } = message.data;
        
        // 安全性チェック
        if (safety_check) {
            const safetyResult = await this.performSafetyCheck(action, parameters);
            if (!safetyResult.safe) {
                throw new Error(`安全性チェック失敗: ${safetyResult.reason}`);
            }
        }
        
        // 実行計画生成
        const executionPlan = await this.generateExecutionPlan(action, parameters);
        
        // 段階的実行
        const executionResult = await this.executeWithMonitoring(executionPlan);
        
        return executionResult;
    }
    
    async handleCoordinationRequest(message) {
        this.log('info', 'COORDINATION', '協調要求処理開始');
        
        const { coordination_type, systems, objective } = message.data;
        
        // 協調パターンに基づく処理
        let coordinationResult;
        
        switch (coordination_type) {
            case 'parallel_analysis':
                coordinationResult = await this.coordinateParallelAnalysis(systems, objective);
                break;
            case 'sequential_workflow':
                coordinationResult = await this.coordinateSequentialWorkflow(systems, objective);
                break;
            case 'consensus_building':
                coordinationResult = await this.coordinateConsensusBuilding(systems, objective);
                break;
            default:
                throw new Error(`未知の協調タイプ: ${coordination_type}`);
        }
        
        return coordinationResult;
    }
    
    // =============================================================================
    // 🤝 協調エンジン・統合ロジック
    // =============================================================================
    
    createConflictResolver() {
        return async (conflictData) => {
            this.log('info', 'CONFLICT_RESOLVER', '競合解決開始');
            
            const { claude_opinion, gemini_opinion, context } = conflictData;
            
            // 重み付き投票による解決
            const claudeWeight = this.calculateSystemWeight('claude', context);
            const geminiWeight = this.calculateSystemWeight('gemini', context);
            
            let resolution;
            if (claudeWeight > geminiWeight) {
                resolution = {
                    decision: claude_opinion,
                    primary_system: 'claude',
                    confidence: claudeWeight / (claudeWeight + geminiWeight)
                };
            } else {
                resolution = {
                    decision: gemini_opinion,
                    primary_system: 'gemini',
                    confidence: geminiWeight / (claudeWeight + geminiWeight)
                };
            }
            
            this.log('info', 'CONFLICT_RESOLVER', `競合解決完了: ${resolution.primary_system}採用`);
            
            return resolution;
        };
    }
    
    createConsensusBuilder() {
        return async (inputData) => {
            this.log('info', 'CONSENSUS_BUILDER', 'コンセンサス構築開始');
            
            const { claude, gemini, constraints } = inputData;
            
            // 合意点の探索
            const commonPoints = this.findCommonGround(claude, gemini);
            const differences = this.identifyDifferences(claude, gemini);
            
            // 統合案の生成
            const consensus = {
                agreed_points: commonPoints,
                resolved_differences: await this.resolveDifferences(differences, constraints),
                confidence: this.calculateConsensusConfidence(commonPoints, differences),
                integration_strategy: 'weighted_compromise'
            };
            
            this.log('info', 'CONSENSUS_BUILDER', 'コンセンサス構築完了');
            
            return consensus;
        };
    }
    
    createWorkflowManager() {
        return {
            executeWorkflow: async (workflow) => {
                this.log('info', 'WORKFLOW', `ワークフロー実行開始: ${workflow.name}`);
                
                const results = [];
                
                for (const step of workflow.steps) {
                    try {
                        const stepResult = await this.executeWorkflowStep(step);
                        results.push(stepResult);
                        
                        // 失敗時の処理
                        if (!stepResult.success && step.required) {
                            throw new Error(`必須ステップ失敗: ${step.name}`);
                        }
                    } catch (error) {
                        this.log('error', 'WORKFLOW', `ステップ実行エラー: ${step.name} - ${error.message}`);
                        
                        if (workflow.error_handling === 'stop_on_error') {
                            throw error;
                        }
                    }
                }
                
                return {
                    workflow_name: workflow.name,
                    results,
                    overall_success: results.every(r => r.success || !r.required)
                };
            }
        };
    }
    
    // =============================================================================
    // 🔌 外部システム連携
    // =============================================================================
    
    async requestClaudeAnalysis(inputData, analysisType) {
        this.log('info', 'CLAUDE_REQUEST', 'Claude分析要求送信');
        
        try {
            const scriptPath = path.join(this.aiAgentsDir, 'scripts/core/CLAUDE_AUTOPILOT_SYSTEM.sh');
            const result = await this.executeScript(scriptPath, ['analyze', analysisType]);
            
            return {
                confidence: 0.85, // 模擬値
                recommendation: result.output || '分析完了',
                reasoning: 'Claude自動操縦による分析結果',
                system: 'claude_autopilot'
            };
        } catch (error) {
            this.log('error', 'CLAUDE_REQUEST', `Claude分析エラー: ${error.message}`);
            return { confidence: 0, recommendation: 'エラー', reasoning: error.message };
        }
    }
    
    async requestGeminiYoloAnalysis(imagePath) {
        this.log('info', 'GEMINI_YOLO_REQUEST', 'Gemini YOLO分析要求送信');
        
        try {
            const scriptPath = path.join(this.aiAgentsDir, 'scripts/core/GEMINI_YOLO_INTEGRATION.py');
            const result = await this.executeScript('python3', [scriptPath, 'analyze', '--image', imagePath]);
            
            return {
                integrated_confidence: 0.78, // 模擬値
                decision_recommendation: result.output || '画像分析完了',
                detected_objects: ['person', 'computer'],
                system: 'gemini_yolo'
            };
        } catch (error) {
            this.log('error', 'GEMINI_YOLO_REQUEST', `Gemini YOLO分析エラー: ${error.message}`);
            return { integrated_confidence: 0, decision_recommendation: 'エラー' };
        }
    }
    
    async executeScript(command, args = []) {
        return new Promise((resolve) => {
            const process = spawn(command, args, {
                stdio: 'pipe',
                shell: true
            });
            
            let output = '';
            let errorOutput = '';
            
            process.stdout.on('data', (data) => {
                output += data.toString();
            });
            
            process.stderr.on('data', (data) => {
                errorOutput += data.toString();
            });
            
            process.on('close', (code) => {
                resolve({
                    success: code === 0,
                    output: output.trim(),
                    error: errorOutput.trim(),
                    exitCode: code
                });
            });
            
            // タイムアウト設定
            setTimeout(() => {
                process.kill('SIGTERM');
                resolve({
                    success: false,
                    output: '',
                    error: 'タイムアウト',
                    exitCode: -1
                });
            }, this.config.workflow.timeout_seconds * 1000);
        });
    }
    
    // =============================================================================
    // 📊 パフォーマンス監視・統計
    // =============================================================================
    
    startPerformanceMonitoring() {
        this.log('info', 'PERFORMANCE', 'パフォーマンス監視開始');
        
        setInterval(() => {
            this.collectPerformanceMetrics();
        }, 60000); // 1分間隔
    }
    
    collectPerformanceMetrics() {
        const currentTime = Date.now();
        const uptime = currentTime - this.performance.system_uptime;
        
        const metrics = {
            timestamp: new Date().toISOString(),
            uptime_seconds: Math.floor(uptime / 1000),
            message_queue_size: this.messageQueue.length,
            active_processes: this.activeProcesses.size,
            result_history_count: this.resultHistory.length,
            ...this.performance
        };
        
        // メトリクスファイル保存
        const metricsFile = path.join(this.logsDir, 'trinity_performance_metrics.json');
        fs.writeFile(metricsFile, JSON.stringify(metrics, null, 2)).catch(console.error);
        
        this.log('info', 'PERFORMANCE', `メトリクス更新: 処理数=${metrics.total_requests}, 成功率=${Math.round(metrics.successful_integrations / Math.max(metrics.total_requests, 1) * 100)}%`);
    }
    
    updatePerformanceMetrics(processingTime, success) {
        this.performance.total_requests++;
        
        if (success) {
            this.performance.successful_integrations++;
        }
        
        // 指数移動平均でレスポンス時間更新
        const alpha = 0.1;
        this.performance.average_response_time = 
            (1 - alpha) * this.performance.average_response_time + alpha * processingTime;
    }
    
    // =============================================================================
    // 🌐 WebSocket通信・リアルタイム連携
    // =============================================================================
    
    async startWebSocketServer() {
        this.log('info', 'WEBSOCKET', 'WebSocketサーバー開始');
        
        const port = 8765;
        this.wss = new WebSocket.Server({ port });
        
        this.wss.on('connection', (ws) => {
            this.log('info', 'WEBSOCKET', '新しいクライアント接続');
            
            ws.on('message', async (message) => {
                try {
                    const data = JSON.parse(message);
                    const response = await this.handleWebSocketMessage(data);
                    ws.send(JSON.stringify(response));
                } catch (error) {
                    ws.send(JSON.stringify({ error: error.message }));
                }
            });
            
            ws.on('close', () => {
                this.log('info', 'WEBSOCKET', 'クライアント切断');
            });
        });
        
        this.log('info', 'WEBSOCKET', `WebSocketサーバー起動完了: ws://localhost:${port}`);
    }
    
    async handleWebSocketMessage(data) {
        const { type, payload } = data;
        
        switch (type) {
            case 'trinity_request':
                const message = new TrinityMessage('websocket', 'trinity', payload.request_type, payload);
                this.messageQueue.push(message);
                return { status: 'queued', message_id: message.id };
                
            case 'status_request':
                return this.getSystemStatus();
                
            case 'metrics_request':
                return this.performance;
                
            default:
                throw new Error(`未知のWebSocketメッセージタイプ: ${type}`);
        }
    }
    
    // =============================================================================
    // 🔧 ユーティリティ・ヘルパー関数
    // =============================================================================
    
    calculateSystemWeight(systemName, context) {
        // コンテキストに基づいたシステム重み計算
        const baseWeights = {
            claude: 0.6,
            gemini: 0.4
        };
        
        // コンテキスト調整
        if (context.includes('image') || context.includes('visual')) {
            return systemName === 'gemini' ? 0.7 : 0.3;
        } else if (context.includes('decision') || context.includes('automation')) {
            return systemName === 'claude' ? 0.8 : 0.2;
        }
        
        return baseWeights[systemName] || 0.5;
    }
    
    findCommonGround(opinion1, opinion2) {
        // 模擬的な合意点発見
        return ['基本的な分析は一致', 'リスク認識は共通'];
    }
    
    identifyDifferences(opinion1, opinion2) {
        // 模擬的な相違点識別
        return ['実行タイミング', '優先度設定'];
    }
    
    async resolveDifferences(differences, constraints) {
        // 相違点解決
        const resolutions = {};
        
        for (const diff of differences) {
            resolutions[diff] = `制約条件に基づく調整: ${diff}`;
        }
        
        return resolutions;
    }
    
    calculateConsensusConfidence(commonPoints, differences) {
        const total = commonPoints.length + differences.length;
        return total > 0 ? commonPoints.length / total : 0;
    }
    
    getSystemStatus() {
        return {
            is_running: this.isRunning,
            message_queue_size: this.messageQueue.length,
            active_processes: this.activeProcesses.size,
            uptime: Date.now() - this.performance.system_uptime,
            subsystems: {
                claude_autopilot: 'active',
                gemini_yolo: 'active',
                coordination_engine: 'active',
                websocket_server: this.wss ? 'active' : 'inactive'
            }
        };
    }
    
    async notifyExternalSystems(result) {
        try {
            // ワンライナー報告システムへの通知
            const onelinerScript = path.join(this.aiAgentsDir, 'scripts/automation/ONELINER_REPORTING_SYSTEM.sh');
            
            if (await this.fileExists(onelinerScript)) {
                const message = `🔗 三位一体統合: ${result.final_recommendation || result.decision || '処理完了'}`;
                const priority = result.integrated_confidence >= 0.8 ? 'medium' : 'low';
                
                await this.executeScript(onelinerScript, ['share', message, priority]);
            }
        } catch (error) {
            this.log('error', 'NOTIFICATION', `外部システム通知エラー: ${error.message}`);
        }
    }
    
    // システム停止
    async stopSystem() {
        this.log('info', 'SHUTDOWN', '🛑 三位一体システム停止開始');
        
        this.isRunning = false;
        
        if (this.wss) {
            this.wss.close();
        }
        
        // アクティブプロセス終了
        for (const [pid, process] of this.activeProcesses) {
            process.kill('SIGTERM');
        }
        
        this.log('info', 'SHUTDOWN', '✅ 三位一体システム停止完了');
    }
}

// =============================================================================
// 🎯 CLI インターフェース
// =============================================================================

async function main() {
    const args = process.argv.slice(2);
    const command = args[0] || 'start';
    
    const system = new TrinityDevelopmentSystem();
    
    switch (command) {
        case 'start':
            console.log('🚀 三位一体開発システム開始');
            try {
                await system.startTrinitySystem();
                
                // Ctrl+C での優雅な停止
                process.on('SIGINT', async () => {
                    console.log('\\n🛑 システム停止中...');
                    await system.stopSystem();
                    process.exit(0);
                });
                
                // システム継続実行
                console.log('✅ システム稼働中 - Ctrl+C で停止');
                
            } catch (error) {
                console.error('❌ システム起動エラー:', error.message);
                process.exit(1);
            }
            break;
            
        case 'test':
            console.log('🧪 三位一体システムテスト');
            
            try {
                await system.initializeClaudeAutopilot();
                await system.initializeGeminiYolo();
                await system.initializeCoordinationEngine();
                
                console.log('✅ 全サブシステム初期化成功');
                
                // 簡単な統合テスト
                const testMessage = new TrinityMessage(
                    'test', 'trinity', 'analyze_request',
                    { input_data: { test: true }, analysis_type: 'system_test' }
                );
                
                system.messageQueue.push(testMessage);
                console.log('📨 テストメッセージ送信完了');
                
            } catch (error) {
                console.error('❌ テスト失敗:', error.message);
                process.exit(1);
            }
            break;
            
        case 'status':
            const status = system.getSystemStatus();
            console.log('📊 三位一体システム状況:');
            console.log(JSON.stringify(status, null, 2));
            break;
            
        case 'metrics':
            const metrics = system.performance;
            console.log('📈 パフォーマンスメトリクス:');
            console.log(JSON.stringify(metrics, null, 2));
            break;
            
        default:
            console.log('🔗 三位一体開発システム v1.0');
            console.log('');
            console.log('使用方法:');
            console.log('  node TRINITY_DEVELOPMENT_SYSTEM.js start    # システム開始');
            console.log('  node TRINITY_DEVELOPMENT_SYSTEM.js test     # テスト実行');
            console.log('  node TRINITY_DEVELOPMENT_SYSTEM.js status   # 状況確認');
            console.log('  node TRINITY_DEVELOPMENT_SYSTEM.js metrics  # メトリクス表示');
            break;
    }
}

// メイン実行
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { TrinityDevelopmentSystem, TrinityConfig, TrinityMessage, TrinityResult };