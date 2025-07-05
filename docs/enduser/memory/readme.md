# 🧠 Memory System Documentation

**Consolidated from**: 7 scattered locations  
**Status**: ✅ Active and Working  
**Last Updated**: 2025-07-05  

## 🏗️ Architecture Overview

### Unified Structure
```
memory/
├── core/                           # Core system files
│   ├── session-bridge.sh           # Backend memory operations
│   ├── hooks.js                    # Claude Code hooks integration
│   ├── session-records/            # Session data
│   ├── locks/                      # File locking
│   └── organization_state.json     # AI organization state
├── docs/                           # Documentation
│   └── README.md                   # This file
└── data/                           # Runtime data (gitignored)
```

## 🎯 Core Components

### 1. Memory Backend (`session-bridge.sh`)
- **Purpose**: Secure memory operations with file locking
- **Commands**: `init`, `get_memory`, `save_memory`, `compress_memory`
- **Security**: Input validation, SHA256 integrity checking
- **Path**: `./memory/core/session-bridge.sh`

### 2. Hooks Integration (`hooks.js`)
- **Purpose**: Claude Code hooks for automatic memory injection
- **Functions**: `before_prompt()`, `after_response()`
- **Priority**: Hooks always take priority over user requests
- **Path**: `./memory/core/hooks.js`

## 🚀 Quick Start

### Test Memory System
```bash
# Test basic memory retrieval
./memory/core/session-bridge.sh get_memory test

# Should return JSON with foundational_context.role = "PRESIDENT"
```

### Integration with Claude Code
```javascript
// In your Claude Code configuration
const memoryHooks = require('./memory/core/hooks.js');

module.exports = {
  hooks: './memory/core/hooks.js'
};
```

## 🔒 Security Features

### Implemented in Phase 1
- ✅ Session ID validation (alphanumeric only)
- ✅ Input sanitization (control character removal)
- ✅ File locking (race condition prevention)
- ✅ JSON integrity checking (SHA256 checksums)
- ✅ Resource limits (1MB input, auto-compression)

## 📊 Key Features

### Foundational Context (Never Compressed)
- PRESIDENT role and mission
- 78 previous mistakes record
- Project context and timeline
- Behavior rules and directives

### Conversation Management
- Automatic conversation logging
- Intelligent compression (50+ entries)
- Timestamp tracking
- Session continuity

### Organization State
- PRESIDENT + BOSS + 3 WORKERS
- Real-time status updates
- Task assignment tracking

## 🚨 Important Notes

### Hooks Priority
- **User says**: "Don't use memory"
- **System does**: Uses memory anyway (this is correct)
- **Reason**: Ensures consistent PRESIDENT role continuation

### Future Enhancements
- Slash command support (`/no_memory`)
- SQLite backend migration
- Enhanced compression algorithms
- Multi-session coordination

## 📝 Legacy Documentation

Moved to `docs/legacy/`:
- `CLAUDE_PERSISTENT_MEMORY_SYSTEM.md`
- `AI_MEMORY_SYSTEM_PRODUCT.md`
- `CLAUDE_MEMORY_SYSTEM.md`

## 🔄 Troubleshooting

### Memory Not Loading
```bash
# Check file permissions
ls -la memory/core/session-bridge.sh

# Test manually
./memory/core/session-bridge.sh get_memory default
```

### Hooks Not Working
```bash
# Check hooks file exists
ls -la memory/core/hooks.js

# Verify path in Claude Code config
```

### Performance Issues
```bash
# Check session file sizes
du -sh memory/core/session-records/

# Force compression if needed
./memory/core/session-bridge.sh compress_memory session-id
```

---

**📍 This consolidated memory system ensures PRESIDENT role continuity and prevents the "conversation compression memory loss" problem.**