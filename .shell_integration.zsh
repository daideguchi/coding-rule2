# Auto-status display for this project
# Add to ~/.zshrc: source /path/to/project/.shell_integration.zsh

# Function to check if we're in the project directory
function _in_project_dir() {
    local current_dir="$PWD"
    local project_root=""
    
    # Find project root by looking for STATUS.md
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/STATUS.md" ]]; then
            project_root="$current_dir"
            break
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    [[ -n "$project_root" ]]
}

# Enhanced cd function
function cd() {
    builtin cd "$@"
    
    if _in_project_dir; then
        # Update status first
        if [[ -f "scripts/auto-status-display.py" ]]; then
            python3 scripts/auto-status-display.py > /dev/null 2>&1 || true
        fi
        
        # Show brief status
        if [[ -f ".task_status" ]]; then
            echo ""
            echo "$(cat .task_status)"
            echo ""
        fi
    fi
}

# Alias for quick status check
alias status='python3 scripts/auto-status-display.py --brief'
alias tasks='cat STATUS.md'
alias quicktask='cat .task_status'
