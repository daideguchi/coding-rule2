#!/bin/bash
# Project Structure Validation Script
# Auto-enforces enterprise-grade organization rules

echo "🔍 Validating project structure..."

# Check root directory count
ROOT_COUNT=$(ls -1 | grep -v '^\.' | wc -l)
MAX_ROOT=12

echo "📊 Root directories: $ROOT_COUNT (max: $MAX_ROOT)"

if [ $ROOT_COUNT -gt $MAX_ROOT ]; then
    echo "❌ VIOLATION: Too many root directories"
    echo "Current items:"
    ls -1 | grep -v '^\.' | nl
    exit 1
fi

# Check for prohibited patterns at root level
PROHIBITED=("logs" "tmp" "data" "ai-agents" "memory" "models" "monitoring" "kubernetes" "infrastructure")
VIOLATIONS=()

for item in "${PROHIBITED[@]}"; do
    if [ -e "$item" ]; then
        VIOLATIONS+=("$item")
    fi
done

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "❌ STRUCTURE VIOLATIONS: Prohibited items at root level"
    printf '  - %s (should be moved)\n' "${VIOLATIONS[@]}"
    echo ""
    echo "Correct locations:"
    echo "  logs → runtime/logs/"
    echo "  tmp → runtime/tmp/"
    echo "  data → runtime/data/"
    echo "  ai-agents → src/ai/agents/"
    echo "  memory → src/ai/memory/"
    echo "  models → src/ai/models/"
    echo "  monitoring → ops/monitoring/"
    echo "  kubernetes → ops/k8s/"
    echo "  infrastructure → ops/terraform/"
    exit 1
fi

# Check required directories exist
REQUIRED=("src" "docs" "tests")
MISSING=()

for dir in "${REQUIRED[@]}"; do
    if [ ! -d "$dir" ]; then
        MISSING+=("$dir")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ MISSING REQUIRED DIRECTORIES:"
    printf '  - %s\n' "${MISSING[@]}"
    exit 1
fi

# Check for large files in wrong locations
echo "🔍 Checking for large files..."
LARGE_FILES=$(find . -type f -size +10M -not -path './runtime/*' -not -path './.git/*' -not -path './archive/*' 2>/dev/null)

if [ ! -z "$LARGE_FILES" ]; then
    echo "⚠️  WARNING: Large files outside runtime/:"
    echo "$LARGE_FILES"
    echo "Consider moving to runtime/ or archive/"
fi

# Check src/ structure
if [ -d "src" ]; then
    echo "🔍 Validating src/ structure..."
    
    # Check for proper AI component organization
    if [ -d "src/ai" ]; then
        echo "✅ AI components properly organized under src/ai/"
    else
        if [ -d "src/agents" ] || [ -d "src/memory" ] || [ -d "src/models" ]; then
            echo "⚠️  WARNING: AI components should be under src/ai/"
        fi
    fi
fi

# Check runtime/ is gitignored
if [ -d "runtime" ]; then
    if grep -q "runtime/" .gitignore 2>/dev/null; then
        echo "✅ runtime/ is properly gitignored"
    else
        echo "⚠️  WARNING: runtime/ should be added to .gitignore"
    fi
fi

echo "✅ Structure validation completed successfully"
echo ""
echo "📋 Current structure summary:"
echo "├── Root directories: $ROOT_COUNT/$MAX_ROOT"
echo "├── Structure violations: ${#VIOLATIONS[@]}"
echo "├── Missing required: ${#MISSING[@]}"
echo "└── Organization score: $(( (MAX_ROOT - ROOT_COUNT + MAX_ROOT - ${#VIOLATIONS[@]} + 3 - ${#MISSING[@]}) * 100 / (MAX_ROOT + MAX_ROOT + 3) ))%"