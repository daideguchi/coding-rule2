// hooks/memory.js
// Enterprise-grade Claude Code Memory Persistence System
// Integrates with existing claude-memory/session-bridge.sh backend

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

/* ---------- Configuration ---------- */
const ROOT = path.resolve(__dirname, '../../../..');
const BRIDGE_SCRIPT = path.join(ROOT, 'src/ai/memory/core/session-bridge.sh');
const MAX_CONVERSATIONAL_TOKENS = 2500; // When to compress conversation
const ORGANIZATION_STATE_FILE = path.join(ROOT, 'src/ai/memory/core/organization_state.json');

/* ---------- Reliability & Trust System ---------- */
const REQUIRED_FILES = [
  '.cursor/rules/globals.mdc',
  'docs/instructions/CLAUDE.md',
  'src/ai/memory/core/session-bridge.sh'
];

// Confidence scoring for responses
function calculateConfidence(searchResults, validationStatus) {
  let score = 0.0;
  
  // Tier 0 (Ground Truth) verification
  if (validationStatus.groundTruthChecked) score += 0.6;
  
  // Multiple search patterns succeeded
  if (searchResults.multiplePatterns) score += 0.2;
  
  // Recent cache hit
  if (searchResults.cacheHit) score += 0.15;
  
  // File metadata validation
  if (searchResults.metadataValid) score += 0.05;
  
  return Math.min(score, 0.99); // Never 100% confident
}

// Robust file search with fallback patterns
function robustFileSearch(pattern, basePath = ROOT) {
  const searchResults = {
    found: false,
    paths: [],
    multiplePatterns: false,
    cacheHit: false,
    metadataValid: false
  };
  
  try {
    // 1. Direct path check
    const directPath = path.join(basePath, pattern);
    if (fs.existsSync(directPath)) {
      searchResults.found = true;
      searchResults.paths.push(directPath);
      searchResults.metadataValid = true;
      return searchResults;
    }
    
    // 2. Glob pattern search
    const { execSync } = require('child_process');
    try {
      const globResults = execSync(`find "${basePath}" -name "*${path.basename(pattern)}*" -type f 2>/dev/null`, 
        { encoding: 'utf8', timeout: 5000 });
      
      if (globResults.trim()) {
        searchResults.found = true;
        searchResults.paths = globResults.trim().split('\n').filter(p => p);
        searchResults.multiplePatterns = true;
        return searchResults;
      }
    } catch (globError) {
      console.warn('Glob search failed, continuing...');
    }
    
    // 3. Content-based search for config files
    if (pattern.includes('cursor') || pattern.includes('rule')) {
      try {
        const grepResults = execSync(`grep -r "cursor\\|rule" "${basePath}" --include="*.mdc" --include="*.md" -l 2>/dev/null`, 
          { encoding: 'utf8', timeout: 5000 });
        
        if (grepResults.trim()) {
          searchResults.found = true;
          searchResults.paths = grepResults.trim().split('\n').filter(p => p);
          searchResults.multiplePatterns = true;
          return searchResults;
        }
      } catch (grepError) {
        console.warn('Content search failed, continuing...');
      }
    }
    
  } catch (error) {
    console.error('Robust search error:', error.message);
  }
  
  return searchResults;
}

// Pre-prompt validation of critical files
function validateCriticalFiles() {
  const validation = {
    allValid: true,
    missing: [],
    found: [],
    confidence: 1.0
  };
  
  for (const requiredFile of REQUIRED_FILES) {
    const searchResult = robustFileSearch(requiredFile);
    
    if (searchResult.found) {
      validation.found.push({
        pattern: requiredFile,
        paths: searchResult.paths
      });
    } else {
      validation.missing.push(requiredFile);
      validation.allValid = false;
    }
  }
  
  validation.confidence = validation.found.length / REQUIRED_FILES.length;
  
  return validation;
}

// Generate humble response based on confidence
function generateHumbleResponse(message, confidence) {
  if (confidence >= 0.95) {
    return message;
  } else if (confidence >= 0.8) {
    return `推定では${message}。念のため追加確認をお勧めします。`;
  } else if (confidence >= 0.6) {
    return `おそらく${message}ですが、他の場所にある可能性もあります。`;
  } else {
    return `${message}を確認しましたが、見つかりませんでした。別の場所や異なる名前で存在する可能性があります。追加の検索パターンを試しますか？`;
  }
}

/* ---------- Memory Backend Integration ---------- */
let bridgeInitialized = false;

function ensureBridge() {
  if (bridgeInitialized) return;
  
  try {
    // Initialize memory system
    execSync(`${BRIDGE_SCRIPT} init`, { stdio: 'inherit', shell: true });
    bridgeInitialized = true;
    console.log('🧠 Memory bridge initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize memory bridge:', error.message);
    throw error;
  }
}

function loadMemory(sessionId) {
  try {
    const stdout = execSync(`${BRIDGE_SCRIPT} get_memory ${sessionId}`, { 
      encoding: 'utf8',
      timeout: 5000 
    });
    const memory = JSON.parse(stdout);
    
    // Validate memory structure
    if (!memory.foundational_context) {
      memory.foundational_context = getDefaultFoundationalContext();
    }
    
    return memory;
  } catch (error) {
    console.error(`❌ Failed to load memory for session ${sessionId}:`, error.message);
    return getDefaultMemoryStructure();
  }
}

function saveMemory(sessionId, userMessage, assistantResponse) {
  try {
    const memoryUpdate = {
      user_message: userMessage,
      assistant_response: assistantResponse,
      timestamp: new Date().toISOString(),
      session_id: sessionId
    };
    
    execSync(`${BRIDGE_SCRIPT} save_memory ${sessionId}`, {
      input: JSON.stringify(memoryUpdate),
      stdio: ['pipe', 'ignore', 'pipe'],
      encoding: 'utf8',
      timeout: 10000
    });
    
    console.log(`💾 Memory saved for session ${sessionId}`);
  } catch (error) {
    console.error(`❌ Failed to save memory for session ${sessionId}:`, error.message);
  }
}

/* ---------- Organizational State Management ---------- */
function loadOrganizationState() {
  try {
    if (fs.existsSync(ORGANIZATION_STATE_FILE)) {
      const state = JSON.parse(fs.readFileSync(ORGANIZATION_STATE_FILE, 'utf8'));
      return state;
    }
    return getDefaultOrganizationState();
  } catch (error) {
    console.error('❌ Failed to load organization state:', error.message);
    return getDefaultOrganizationState();
  }
}

function updateAgentState(agentName, newState) {
  try {
    const orgState = loadOrganizationState();
    
    if (agentName === 'president') {
      orgState.president = { ...orgState.president, ...newState };
    } else if (agentName === 'boss') {
      orgState.boss = { ...orgState.boss, ...newState };
    } else if (orgState.workers[agentName]) {
      orgState.workers[agentName] = { ...orgState.workers[agentName], ...newState };
    }
    
    orgState.last_updated = new Date().toISOString();
    
    fs.writeFileSync(ORGANIZATION_STATE_FILE, JSON.stringify(orgState, null, 2));
    console.log(`🔄 Updated ${agentName} state`);
  } catch (error) {
    console.error(`❌ Failed to update ${agentName} state:`, error.message);
  }
}

/* ---------- Default Structures ---------- */
function getDefaultFoundationalContext() {
  return {
    role: "PRESIDENT",
    mission: "AI永続化システム開発統括 - 記憶喪失問題の根本解決",
    critical_directives: [
      "🚨 78回のミス記録を継承し、79回目を防ぐ",
      "👑 PRESIDENT役割を継続維持",
      "🎯 AI Compliance Engine実装統括",
      "🤝 BOSS・WORKER組織の状態管理"
    ],
    project_context: {
      name: "AI Persistence & Memory System",
      phase: "Phase 1 MVP Implementation",
      technology_stack: "PostgreSQL + pgvector + Claude Code hooks",
      budget: "$33,000 (Phase 1)",
      timeline: "2-4 weeks"
    },
    past_mistakes_summary: "78回の重大ミス（虚偽報告、詐欺、責任逃れ等）を記録済み",
    behavior_rules: [
      "証拠なき報告は絶対禁止",
      "プロジェクト文脈を常に維持",
      "職務放棄は重大違反",
      "ユーザーとの信頼関係最優先"
    ]
  };
}

function getDefaultMemoryStructure() {
  return {
    foundational_context: getDefaultFoundationalContext(),
    conversational_summary: "",
    conversational_log: [],
    metadata: {
      session_start: new Date().toISOString(),
      total_interactions: 0,
      last_compression: null
    }
  };
}

function getDefaultOrganizationState() {
  return {
    last_updated: new Date().toISOString(),
    president: {
      status: "active",
      current_mission: "AI永続化システム実装統括",
      active_directive: "hooks-implementation"
    },
    boss: {
      status: "managing",
      current_task: "Phase 1 Implementation Coordination",
      assigned_workers: ["worker1", "worker2", "worker3"]
    },
    workers: {
      worker1: {
        role: "Frontend Engineer",
        status: "ready",
        current_task: null,
        session_id: null
      },
      worker2: {
        role: "Backend Engineer", 
        status: "ready",
        current_task: null,
        session_id: null
      },
      worker3: {
        role: "UI/UX Designer",
        status: "ready",
        current_task: null,
        session_id: null
      }
    }
  };
}

/* ---------- Conversation Compression ---------- */
function shouldCompress(conversationalLog) {
  const totalTokens = conversationalLog.reduce((sum, msg) => {
    return sum + (msg.content ? msg.content.split(/\s+/).length : 0);
  }, 0);
  
  return totalTokens > MAX_CONVERSATIONAL_TOKENS;
}

function generateCompressionPrompt(conversationalLog) {
  const logText = conversationalLog.map(msg => 
    `${msg.role}: ${msg.content}`
  ).join('\n\n');
  
  return `Analyze the following conversation log and produce a structured summary in JSON format.

Requirements:
1. "summary": Concise third-person summary of key decisions, outcomes, and user intent
2. "entities": Object with arrays for files_mentioned, commands_executed, key_decisions, open_questions
3. Preserve exact syntax of file paths and code snippets
4. Focus on project-critical information for AI永続化システム development

Conversation Log:
---
${logText}
---

Respond with valid JSON only:`;
}

/* ---------- Mistake Prevention Integration ---------- */
import { enforceMistakePrevention, getMistakeContext } from './mistake-prevention-hooks.js';

/* ---------- Core Hook Functions ---------- */
export async function before_prompt({ prompt, metadata }) {
  // 🚨 MISTAKE #79 再発防止チェック
  const preventionResult = enforceMistakePrevention(prompt, metadata);
  if (preventionResult.shouldBlock) {
    console.error('🚨 作業ブロック:', preventionResult.reason);
    return { prompt, metadata }; // 作業を停止
  }
  
  // 再発防止プロンプト注入
  if (preventionResult.injectedPrompt) {
    prompt.messages.unshift({
      role: 'system',
      content: preventionResult.injectedPrompt
    });
  }
  
  // ミス記録コンテキスト追加
  prompt.messages.unshift({
    role: 'system', 
    content: getMistakeContext()
  });
  
  ensureBridge();
  
  // 🚨 CRITICAL: Validate required files before proceeding
  const validation = validateCriticalFiles();
  if (!validation.allValid) {
    console.warn('⚠️  Missing critical files:', validation.missing);
    // Continue but mark as low confidence
  }
  
  const sessionId = metadata.session_id || 'default';
  const memory = loadMemory(sessionId);
  const orgState = loadOrganizationState();
  
  // Build context hierarchy: Foundational → Organizational → Conversational
  const contextMessages = [];
  
  // Add validation status to context
  const validationContext = `# 🔍 システム検証状況

✅ 必須ファイル確認: ${validation.found.length}/${REQUIRED_FILES.length}
⚠️  信頼度: ${Math.round(validation.confidence * 100)}%

${validation.missing.length > 0 ? `❌ 未確認ファイル: ${validation.missing.join(', ')}` : '✅ すべての必須ファイルを確認済み'}

この信頼度に基づいて、適切な表現（断定/推定/要確認）を選択してください。`;
  
  contextMessages.push({
    role: 'system',
    content: validationContext
  });
  
  // 1. Foundational context (NEVER compressed)
  if (memory.foundational_context) {
    const foundationalPrompt = `# 🧠 永続記憶継承システム

## 役割・使命
${JSON.stringify(memory.foundational_context, null, 2)}

## 組織状態
${JSON.stringify(orgState, null, 2)}

この情報を基に、PRESIDENTとして一貫した役割を維持してください。`;
    
    contextMessages.push({
      role: 'system',
      content: foundationalPrompt
    });
  }
  
  // 2. Conversational summary
  if (memory.conversational_summary) {
    contextMessages.push({
      role: 'system', 
      content: `前回までの会話要約: ${memory.conversational_summary}`
    });
  }
  
  // 3. Recent conversation log
  if (memory.conversational_log.length > 0) {
    contextMessages.push(...memory.conversational_log);
  }
  
  // Inject context at the beginning
  prompt.messages = [...contextMessages, ...prompt.messages];
  
  console.log(`🧠 Memory loaded for session ${sessionId}: ${contextMessages.length} context messages`);
  
  return { prompt, metadata };
}

export async function after_response({ response, metadata }) {
  const sessionId = metadata.session_id || 'default';
  const userMessage = metadata.user_message || metadata.prompt || '';
  const assistantResponse = response.text || response.content || response;
  
  // Save to memory backend
  saveMemory(sessionId, userMessage, assistantResponse);
  
  // Update organization state if this affects agent status
  if (userMessage.includes('PRESIDENT') || userMessage.includes('BOSS') || userMessage.includes('WORKER')) {
    updateAgentState('president', {
      last_interaction: new Date().toISOString(),
      last_user_message: userMessage.substring(0, 100) + '...'
    });
  }
  
  console.log(`💾 Memory updated for session ${sessionId}`);
  
  return { response, metadata };
}

/* ---------- Utility Functions ---------- */
export function getMemoryStatus(sessionId = 'default') {
  const memory = loadMemory(sessionId);
  const orgState = loadOrganizationState();
  
  return {
    session_id: sessionId,
    foundational_context_loaded: !!memory.foundational_context,
    conversational_items: memory.conversational_log.length,
    organization_agents: Object.keys(orgState.workers).length + 2, // +president +boss
    last_updated: orgState.last_updated
  };
}

export function forceCompress(sessionId = 'default') {
  try {
    execSync(`${BRIDGE_SCRIPT} compress_memory ${sessionId}`, { 
      stdio: 'inherit',
      timeout: 30000 
    });
    console.log(`🗜️ Forced compression completed for session ${sessionId}`);
  } catch (error) {
    console.error(`❌ Failed to compress memory:`, error.message);
  }
}

console.log('🧠 Claude Code Memory Hooks loaded successfully');