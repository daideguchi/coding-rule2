# 📁 Folder Organization Rules - Enterprise Grade

**Version**: 1.0  
**Last Updated**: 2025-07-05  
**Status**: 🔴 ENFORCED BY HOOKS  
**Purpose**: Maintain enterprise-grade structure automatically  

## 🎯 Core Principles

### 1. Source vs Runtime Separation
```
✅ CORRECT: src/ = source code, runtime/ = generated files
❌ WRONG: logs/, tmp/, data/ at root level
```

### 2. Function-Based Grouping
```
✅ CORRECT: src/ai/{agents,memory,models}
❌ WRONG: ai-agents/, memory/, models/ at root
```

### 3. 6-8 Root Directory Rule
```
✅ TARGET: 6-8 persistent directories at root
❌ VIOLATION: >12 directories at root level
```

## 📋 Mandatory Structure

### Root Directory (MAX 8 items)
```
project-root/
├── src/                    # Source code only
├── tests/                  # All test files
├── docs/                   # All documentation
├── ops/                    # Infrastructure/operations
├── config/                 # Configuration files
├── scripts/                # Utility scripts
├── runtime/               # Generated files (gitignored)
├── pyproject.toml         # Project metadata
├── README.md              # Project overview
└── .gitignore             # Git rules
```

### Source Code Structure (`src/`)
```
src/
├── app/                   # Application entry points
├── ai/                    # AI-related components
│   ├── agents/           # AI agents (was ai-agents/)
│   ├── memory/           # Memory system (was memory/)
│   ├── models/           # ML models (was models/)
│   └── prompts/          # Prompt templates
├── services/             # Business logic
├── integrations/         # External service integrations
└── utils/                # Shared utilities
```

### Documentation Structure (`docs/`)
```
docs/
├── architecture/         # System design documents
├── memory/              # Memory system documentation
├── reports/             # All standalone reports
├── instructions/        # User instructions
├── legacy/              # Deprecated documentation
└── ADR-XXXX.md         # Architecture Decision Records
```

### Operations Structure (`ops/`)
```
ops/
├── terraform/           # Infrastructure as Code
├── k8s/                # Kubernetes manifests
├── monitoring/         # Monitoring/alerting config
└── scripts/            # Operational scripts
```

### Runtime Structure (`runtime/` - Gitignored)
```
runtime/
├── logs/               # All log files
├── cache/              # Temporary cache
├── data/               # Generated data
└── tmp/                # Temporary files
```

## 🚨 Enforcement Rules

### Automatic Violation Detection
```bash
# Too many root directories
if [ $(ls -1 | wc -l) -gt 12 ]; then
    echo "❌ ROOT VIOLATION: >12 items at root"
    exit 1
fi

# Prohibited patterns at root
PROHIBITED=("logs" "tmp" "data" "ai-agents" "memory" "models")
for dir in "${PROHIBITED[@]}"; do
    if [ -d "$dir" ]; then
        echo "❌ STRUCTURE VIOLATION: $dir must be moved"
        exit 1
    fi
done
```

### File Type Placement Rules
```
.md reports     → docs/reports/
.sh scripts     → scripts/ (if project-wide) or src/*/scripts/
logs/*          → runtime/logs/
tmp/*           → runtime/tmp/
backup-*        → archive/ (outside repo preferred)
```

### Import Path Rules
```python
# CORRECT
from src.ai.memory import MemorySystem
from src.services.auth import AuthService

# WRONG
from memory.core import session_bridge
from ai_agents.president import President
```

## 🔄 Maintenance Routines

### Daily Checks (Automated)
1. **Root directory count** ≤ 12 items
2. **Prohibited patterns** detection
3. **Large file** scanning (>10MB)
4. **Gitignore compliance** check

### Weekly Reviews (AI + Human)
1. **Structure assessment** by o3/Gemini
2. **Performance impact** analysis
3. **New pattern** identification
4. **Rule updates** if needed

### Monthly Audits (Deep Analysis)
1. **Dependency analysis** (import paths)
2. **Dead code** identification
3. **Architecture debt** review
4. **Cleanup recommendations**

## 🎯 Migration Patterns

### When Adding New Components
```bash
# CORRECT procedure
mkdir -p src/new_component/{core,utils,tests}
echo "from src.new_component.core import ..." >> example.py

# WRONG procedure
mkdir new_component/  # at root
```

### When Refactoring
```bash
# 1. Create target structure
mkdir -p src/ai/new_module

# 2. Move files with git mv (preserves history)
git mv old_module/* src/ai/new_module/

# 3. Update import paths
find . -name "*.py" -exec sed -i 's/old_module/src.ai.new_module/g' {} \;

# 4. Run tests
pytest tests/

# 5. Update documentation
vim docs/architecture/migration-YYYYMMDD.md
```

## 🧪 Validation Scripts

### Structure Validation (`scripts/validate-structure.sh`)
```bash
#!/bin/bash
# Auto-generated validation script

echo "🔍 Validating project structure..."

# Check root directory count
ROOT_COUNT=$(ls -1 | grep -v '\.' | wc -l)
if [ $ROOT_COUNT -gt 12 ]; then
    echo "❌ Too many root directories: $ROOT_COUNT (max: 12)"
    exit 1
fi

# Check for prohibited patterns
VIOLATIONS=()
for item in logs tmp data ai-agents memory models; do
    if [ -e "$item" ]; then
        VIOLATIONS+=("$item")
    fi
done

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "❌ Structure violations found:"
    printf '  - %s\n' "${VIOLATIONS[@]}"
    exit 1
fi

echo "✅ Structure validation passed"
```

### Import Path Validation (`scripts/validate-imports.py`)
```python
#!/usr/bin/env python3
"""Validate import paths follow organization rules."""

import ast
import os
import sys
from pathlib import Path

def check_imports(file_path):
    """Check if imports follow organization rules."""
    with open(file_path, 'r') as f:
        try:
            tree = ast.parse(f.read())
        except SyntaxError:
            return []
    
    violations = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.startswith(('ai_agents', 'memory.core')):
                    violations.append(f"Deprecated import: {alias.name}")
        elif isinstance(node, ast.ImportFrom):
            if node.module and node.module.startswith(('ai_agents', 'memory.core')):
                violations.append(f"Deprecated import: from {node.module}")
    
    return violations

def main():
    """Main validation function."""
    violations = []
    for py_file in Path('.').rglob('*.py'):
        file_violations = check_imports(py_file)
        for violation in file_violations:
            violations.append(f"{py_file}: {violation}")
    
    if violations:
        print("❌ Import path violations found:")
        for violation in violations:
            print(f"  - {violation}")
        sys.exit(1)
    
    print("✅ Import path validation passed")

if __name__ == "__main__":
    main()
```

## 🔮 Future Automation (Hooks Integration)

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: structure-validation
        name: Validate project structure
        entry: scripts/validate-structure.sh
        language: system
        pass_filenames: false
        
      - id: import-validation
        name: Validate import paths
        entry: scripts/validate-imports.py
        language: python
        files: \.py$
```

### CI/CD Integration
```yaml
# .github/workflows/structure-check.yml
name: Structure Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate Structure
        run: |
          bash scripts/validate-structure.sh
          python scripts/validate-imports.py
```

## 📊 Success Metrics

### Target KPIs
- **Root directories**: ≤ 8 (current: 12)
- **Structure violations**: 0
- **Import path compliance**: 100%
- **File organization score**: >95%

### Monitoring
- **Daily automated checks**: Structure, imports, file sizes
- **Weekly AI reviews**: o3/Gemini architectural feedback
- **Monthly reports**: Compliance trends, improvement areas

## 🎯 Next Phase Enhancements

### Phase 1 (Current)
- ✅ Basic structure rules
- ✅ Validation scripts
- ✅ Documentation

### Phase 2 (Next Week)
- [ ] Pre-commit hooks
- [ ] CI/CD integration
- [ ] Automated refactoring tools

### Phase 3 (Next Month)
- [ ] AI-powered structure optimization
- [ ] Real-time violation detection
- [ ] Self-healing organization system

---

**📍 This document serves as the single source of truth for project organization. All structural decisions should reference and update these rules.**