#!/bin/bash
# Pre-prompt Critical File Validation System
# Prevents confirmation errors by validating required files before any AI response

set -euo pipefail

echo "🔍 Pre-prompt critical file validation..."

# Required files for system integrity
REQUIRED_FILES=(
  ".cursor/rules/globals.mdc"
  "docs/instructions/CLAUDE.md"
  "src/ai/memory/core/session-bridge.sh"
  "src/ai/memory/core/hooks.js"
)

VALIDATION_RESULT="validation_result.json"
CONFIDENCE_SCORE=0.0
FOUND_FILES=()
MISSING_FILES=()

# Function to perform robust file search
robust_file_search() {
  local pattern="$1"
  local found=false
  
  # 1. Direct path check
  if [[ -f "$pattern" ]]; then
    echo "✅ Direct hit: $pattern"
    found=true
    return 0
  fi
  
  # 2. Glob pattern search
  local glob_results
  if glob_results=$(find . -name "*$(basename "$pattern")*" -type f 2>/dev/null); then
    if [[ -n "$glob_results" ]]; then
      echo "🔍 Glob found: $glob_results"
      found=true
      return 0
    fi
  fi
  
  # 3. Content-based search for config files
  if [[ "$pattern" == *"cursor"* || "$pattern" == *"rule"* ]]; then
    local grep_results
    if grep_results=$(grep -r "cursor\|rule" . --include="*.mdc" --include="*.md" -l 2>/dev/null | head -5); then
      if [[ -n "$grep_results" ]]; then
        echo "📄 Content search found: $grep_results"
        found=true
        return 0
      fi
    fi
  fi
  
  return 1
}

# Validate each required file
for file in "${REQUIRED_FILES[@]}"; do
  echo -n "Checking $file... "
  
  if robust_file_search "$file"; then
    FOUND_FILES+=("$file")
    CONFIDENCE_SCORE=$(echo "$CONFIDENCE_SCORE + 0.25" | bc -l)
  else
    echo "❌ NOT FOUND"
    MISSING_FILES+=("$file")
  fi
done

# Calculate final confidence score
CONFIDENCE_PERCENTAGE=$(echo "$CONFIDENCE_SCORE * 100" | bc -l | cut -d. -f1)

# Generate validation report
cat > "$VALIDATION_RESULT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_files": ${#REQUIRED_FILES[@]},
  "found_files": ${#FOUND_FILES[@]},
  "missing_files": ${#MISSING_FILES[@]},
  "confidence_score": $CONFIDENCE_SCORE,
  "confidence_percentage": $CONFIDENCE_PERCENTAGE,
  "status": "$([[ ${#MISSING_FILES[@]} -eq 0 ]] && echo "PASS" || echo "PARTIAL")",
  "found": [$(IFS=,; echo "\"${FOUND_FILES[*]// /\",\"}")"],
  "missing": [$(IFS=,; echo "\"${MISSING_FILES[*]// /\",\"}")"]
}
EOF

# Display results
echo ""
echo "📊 Validation Results:"
echo "├── Found: ${#FOUND_FILES[@]}/${#REQUIRED_FILES[@]} files"
echo "├── Confidence: ${CONFIDENCE_PERCENTAGE}%"
echo "└── Status: $([[ ${#MISSING_FILES[@]} -eq 0 ]] && echo "✅ PASS" || echo "⚠️  PARTIAL")"

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  echo ""
  echo "❌ Missing critical files:"
  for missing in "${MISSING_FILES[@]}"; do
    echo "  - $missing"
  done
  echo ""
  echo "⚠️  AI responses will use humble expressions (推定では/おそらく)"
fi

# Exit with appropriate code
if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
  echo "✅ All critical files validated. High confidence responses enabled."
  exit 0
else
  echo "⚠️  Partial validation. Humble response mode activated."
  exit 1
fi