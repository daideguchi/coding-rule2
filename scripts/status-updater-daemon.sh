#!/bin/bash
# Background status updater daemon

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$PROJECT_ROOT/runtime/status-updater.lock"
PID_FILE="$PROJECT_ROOT/runtime/status-updater.pid"

# Check if already running
if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "Status updater already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

# Create lock and PID files
echo $$ > "$PID_FILE"
touch "$LOCK_FILE"

# Cleanup on exit
cleanup() {
    rm -f "$LOCK_FILE" "$PID_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

echo "🔄 Status updater daemon started (PID: $$)"

cd "$PROJECT_ROOT"

# Update every 5 minutes while files are being modified
while true; do
    if [[ -f "scripts/auto-status-display.py" ]]; then
        # Check if any relevant files changed in last 5 minutes
        if find runtime/ scripts/ docs/ src/ -name "*.json" -o -name "*.py" -o -name "*.md" -newer "$LOCK_FILE" -print -quit | grep -q .; then
            python3 scripts/auto-status-display.py > /dev/null 2>&1 || true
            touch "$LOCK_FILE"
        fi
    fi
    
    sleep 300  # 5 minutes
done
