#!/bin/bash
# wait-for-ci.sh - Wait for GitHub Actions CI to complete
# Usage: ./wait-for-ci.sh <repo> <pr-number> [task-id] [--timeout 3600]

set -euo pipefail

# --- Configuration ---
REPO="${1:-}"
PR_NUMBER="${2:-}"
TASK_ID="${3:-}"
TIMEOUT="${4:-3600}"  # Default 1 hour timeout
POLL_INTERVAL="30"     # Check every 30 seconds

SWARM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude/swarm"
SCRIPTS_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude/scripts"
NOTIFY_SCRIPT="$SCRIPTS_DIR/notify.sh"
LOG_DIR="$SWARM_DIR/logs"
LOG_FILE="$LOG_DIR/ci-wait-${TASK_ID:-$PR_NUMBER}-$(date +%Y%m%d-%H%M%S).log"

# Parse optional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 <repo> <pr-number> [task-id] [--timeout SECONDS]"
      echo "  repo        GitHub repository (owner/repo)"
      echo "  pr-number   Pull request number"
      echo "  task-id     Optional task ID for tracking"
      echo "  --timeout   Maximum wait time in seconds (default: 3600)"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# --- Validation ---
if [ -z "$REPO" ] || [ -z "$PR_NUMBER" ]; then
  echo "ERROR: Repository and PR number are required"
  exit 1
fi

# --- Logging ---
mkdir -p "$LOG_DIR"
log() { echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

# --- Check if gh CLI is available ---
if ! command -v gh &> /dev/null; then
  log "ERROR: GitHub CLI (gh) is required but not installed."
  exit 1
fi

# --- Check if authenticated ---
if ! gh auth status &> /dev/null; then
  log "ERROR: Not authenticated with GitHub. Run 'gh auth login' first."
  exit 1
fi

# --- Function to get CI status ---
get_ci_status() {
  local repo="$1"
  local pr="$2"
  
  # Get all check runs for the latest commit in PR
  local head_sha=$(gh pr view "$pr" --repo "$repo" --json headRefOid -q '.headRefOid' 2>/dev/null)
  
  if [ -z "$head_sha" ]; then
    echo "unknown"
    return
  fi
  
  # Get check runs
  local checks=$(gh api "repos/$repo/commits/$head_sha/check-runs" --jq '.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}' 2>/dev/null)
  
  if [ -z "$checks" ]; then
    echo "no-checks"
    return
  fi
  
  # Check if all checks completed successfully
  local all_success=true
  local any_failed=false
  local any_pending=false
  local any_in_progress=false
  
  while IFS= read -r check; do
    local status=$(echo "$check" | jq -r '.status')
    local conclusion=$(echo "$check" | jq -r '.conclusion')
    
    if [ "$status" = "completed" ]; then
      if [ "$conclusion" != "success" ] && [ "$conclusion" != "skipped" ] && [ "$conclusion" != "neutral" ]; then
        any_failed=true
        all_success=false
      fi
    else
      any_pending=true
      all_success=false
      if [ "$status" = "in_progress" ]; then
        any_in_progress=true
      fi
    fi
  done <<< "$checks"
  
  if [ "$any_failed" = true ]; then
    echo "failed"
  elif [ "$all_success" = true ]; then
    echo "success"
  elif [ "$any_in_progress" = true ]; then
    echo "in_progress"
  elif [ "$any_pending" = true ]; then
    echo "pending"
  else
    echo "unknown"
  fi
}

# --- Function to check PR merge status ---
is_pr_merged() {
  local repo="$1"
  local pr="$2"
  
  local merged=$(gh pr view "$pr" --repo "$repo" --json merged -q '.merged' 2>/dev/null)
  [ "$merged" = "true" ] && return 0 || return 1
}

# --- Function to get check runs details ---
get_check_details() {
  local repo="$1"
  local pr="$2"
  
  local head_sha=$(gh pr view "$pr" --repo "$repo" --json headRefOid -q '.headRefOid' 2>/dev/null)
  
  if [ -z "$head_sha" ]; then
    echo "Unable to get commit SHA"
    return
  fi
  
  echo "Check runs for commit $head_sha:"
  gh api "repos/$repo/commits/$head_sha/check-runs" --jq '.check_runs[] | "  \(.name): \(.status)/\(.conclusion // "N/A")"' 2>/dev/null || echo "  No check runs found"
}

# --- Main wait loop ---
log "Waiting for CI to complete on $REPO PR #$PR_NUMBER"
log "Timeout: ${TIMEOUT}s, Poll interval: ${POLL_INTERVAL}s"

START_TIME=$(date +%s)
WAIT_COUNT=0

while true; do
  # Check timeout
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED -gt $TIMEOUT ]; then
    log "ERROR: Timeout after ${TIMEOUT}s"
    
    # Send timeout notification
    if [ -f "$NOTIFY_SCRIPT" ]; then
      "$NOTIFY_SCRIPT" "ci-timeout" "$REPO" "$PR_NUMBER" "CI wait timed out after ${TIMEOUT}s"
    fi
    
    exit 1
  fi
  
  # Check if PR is merged (CI no longer matters)
  if is_pr_merged "$REPO" "$PR_NUMBER"; then
    log "PR #$PR_NUMBER has been merged - stopping wait"
    
    # Notify about merge
    if [ -f "$NOTIFY_SCRIPT" ]; then
      "$NOTIFY_SCRIPT" "pr-merged" "$REPO" "$PR_NUMBER" "PR merged before CI completed"
    fi
    
    exit 0
  fi
  
  # Get current CI status
  CI_STATUS=$(get_ci_status "$REPO" "$PR_NUMBER")
  
  log "CI status: $CI_STATUS (elapsed: ${ELAPSED}s)"
  
  case "$CI_STATUS" in
    success)
      log "✅ CI passed successfully!"
      
      # Update task registry
      if [ -n "$TASK_ID" ]; then
        local registry="$SWARM_DIR/active-tasks.json"
        if [ -f "$registry" ]; then
          jq ".tasks |= map(if .id == \"$TASK_ID\" then .ci_status = \"passed\" else . end)" "$registry" > "$registry.tmp"
          mv "$registry.tmp" "$registry"
          log "Updated task $TASK_ID with CI passed"
        fi
      fi
      
      # Send success notification
      if [ -f "$NOTIFY_SCRIPT" ]; then
        "$NOTIFY_SCRIPT" "ci-pass" "$REPO" "$PR_NUMBER" "CI checks passed! Ready for review."
      fi
      
      # Optionally, request review automatically
      if [ -f "$SCRIPTS_DIR/review-pr.sh" ]; then
        log "Auto-requesting review..."
        "$SCRIPTS_DIR/review-pr.sh" "$REPO" "$PR_NUMBER" --auto &
      fi
      
      exit 0
      ;;
    failed)
      log "❌ CI failed"
      
      # Get failure details
      log "Failure details:"
      get_check_details "$REPO" "$PR_NUMBER" | tee -a "$LOG_FILE"
      
      # Update registry
      if [ -n "$TASK_ID" ]; then
        local registry="$SWARM_DIR/active-tasks.json"
        if [ -f "$registry" ]; then
          jq ".tasks |= map(if .id == \"$TASK_ID\" then .ci_status = \"failed\" else . end)" "$registry" > "$registry.tmp"
          mv "$registry.tmp" "$registry"
        fi
      fi
      
      # Send failure notification
      if [ -f "$NOTIFY_SCRIPT" ]; then
        "$NOTIFY_SCRIPT" "ci-failed" "$REPO" "$PR_NUMBER" "CI checks failed"
      fi
      
      # Trigger respawn with failure context
      if [ -n "$TASK_ID" ] && [ -f "$SCRIPTS_DIR/respawn-agent.sh" ]; then
        log "CI failed - triggering respawn with failure context"
        "$SCRIPTS_DIR/respawn-agent.sh" "$TASK_ID" --ci-failure
      fi
      
      exit 1
      ;;
    in_progress|pending)
      # Still waiting
      WAIT_COUNT=$((WAIT_COUNT + 1))
      
      # Log progress every 5 checks
      if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
        log "Still waiting for CI (${ELAPSED}s elapsed)..."
        get_check_details "$REPO" "$PR_NUMBER" | head -5 | tee -a "$LOG_FILE"
      fi
      
      sleep $POLL_INTERVAL
      ;;
    no-checks)
      log "No CI checks found yet, waiting..."
      sleep $POLL_INTERVAL
      ;;
    unknown)
      log "Unable to determine CI status, waiting..."
      sleep $POLL_INTERVAL
      ;;
    *)
      log "Unknown status: $CI_STATUS"
      sleep $POLL_INTERVAL
      ;;
  esac
done

log "Wait loop ended"
