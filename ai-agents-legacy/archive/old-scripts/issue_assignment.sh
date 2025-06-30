#!/bin/bash
# Issue自動割り当てシステム

assign_issue() {
    local issue_title=$1
    local issue_labels=$2
    
    # ラベルに基づいて担当者決定
    if [[ $issue_labels == *"documentation"* ]]; then
        assignee="WORKER1_DOCUMENTATION"
    elif [[ $issue_labels == *"bug"* ]] || [[ $issue_labels == *"feature"* ]]; then
        assignee="WORKER2_DEVELOPMENT"
    elif [[ $issue_labels == *"ui"* ]] || [[ $issue_labels == *"ux"* ]]; then
        assignee="WORKER3_UIUX"
    else
        assignee="WORKER0_MANAGEMENT"
    fi
    
    echo "Issue [$issue_title] → $assignee"
}
