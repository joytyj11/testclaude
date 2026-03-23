#!/bin/bash
# github-webhook-listener.sh - Listen to GitHub webhook events and trigger actions
# Usage: ./github-webhook-listener.sh [--port 8080] [--secret your-webhook-secret]

set -euo pipefail

# --- Configuration ---
PORT="${1:-8080}"
WEBHOOK_SECRET="${GITHUB_WEBHOOK_SECRET:-}"
SWARM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude/swarm"
SCRIPTS_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude/scripts"
NOTIFY_SCRIPT="$SCRIPTS_DIR/notify.sh"
LOG_DIR="$SWARM_DIR/logs"
LOG_FILE="$LOG_DIR/webhook-$(date +%Y%m%d).log"

# --- Logging ---
mkdir -p "$LOG_DIR"
log() { echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
      PORT="$2"
      shift 2
      ;;
    --secret)
      WEBHOOK_SECRET="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--port PORT] [--secret WEBHOOK_SECRET]"
      echo "  --port       Port to listen on (default: 8080)"
      echo "  --secret     GitHub webhook secret for verification"
      echo ""
      echo "Environment variables:"
      echo "  GITHUB_WEBHOOK_SECRET - Alternative to --secret"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Verify webhook secret ---
if [ -z "$WEBHOOK_SECRET" ]; then
  log "WARNING: No webhook secret configured. Skipping signature verification."
fi

# --- Check if netcat is available ---
if ! command -v nc &> /dev/null; then
  log "ERROR: netcat (nc) is required but not installed."
  exit 1
fi

# --- Webhook handler function ---
handle_webhook() {
  local request="$1"
  
  # Extract headers and body
  local event_type=$(echo "$request" | grep -i "^x-github-event:" | awk '{print $2}' | tr -d '\r')
  local delivery_id=$(echo "$request" | grep -i "^x-github-delivery:" | awk '{print $2}' | tr -d '\r')
  local signature=$(echo "$request" | grep -i "^x-hub-signature-256:" | awk '{print $2}' | tr -d '\r')
  
  # Extract body (after empty line)
  local body=$(echo "$request" | awk 'BEGIN{RS="\r\n\r\n"; FS="\r\n"} NR==2')
  
  log "Received webhook: event=$event_type, delivery=$delivery_id"
  
  # Verify signature if secret is set
  if [ -n "$WEBHOOK_SECRET" ] && [ -n "$signature" ]; then
    local expected_signature=$(echo -n "$body" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | awk '{print "sha256="$2}')
    if [ "$signature" != "$expected_signature" ]; then
      log "ERROR: Invalid signature"
      echo "HTTP/1.1 401 Unauthorized\r\nContent-Type: text/plain\r\n\r\nInvalid signature"
      return
    fi
    log "Signature verified"
  fi
  
  # Process based on event type
  case "$event_type" in
    push)
      handle_push_event "$body"
      ;;
    pull_request)
      handle_pr_event "$body"
      ;;
    check_suite|check_run)
      handle_ci_event "$body"
      ;;
    status)
      handle_status_event "$body"
      ;;
    *)
      log "Ignoring event type: $event_type"
      ;;
  esac
  
  # Acknowledge
  echo "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK"
}

# --- Event handlers ---
handle_push_event() {
  local body="$1"
  local repo=$(echo "$body" | jq -r '.repository.full_name' 2>/dev/null)
  local branch=$(echo "$body" | jq -r '.ref' | sed 's|refs/heads/||')
  local commits=$(echo "$body" | jq -r '.commits | length')
  
  log "Push event: $repo/$branch ($commits commits)"
  
  # Notify about push
  if [ -f "$NOTIFY_SCRIPT" ]; then
    "$NOTIFY_SCRIPT" "push" "$repo" "$branch" "$commits commits pushed"
  fi
}

handle_pr_event() {
  local body="$1"
  local action=$(echo "$body" | jq -r '.action')
  local pr_number=$(echo "$body" | jq -r '.pull_request.number')
  local pr_title=$(echo "$body" | jq -r '.pull_request.title')
  local pr_url=$(echo "$body" | jq -r '.pull_request.html_url')
  local repo=$(echo "$body" | jq -r '.repository.full_name')
  local branch=$(echo "$body" | jq -r '.pull_request.head.ref')
  
  log "PR event: $repo#$pr_number ($action) - $pr_title"
  
  # Track PR in registry
  local registry="$SWARM_DIR/active-tasks.json"
  if [ -f "$registry" ]; then
    # Find task for this branch
    local task_id=$(jq -r ".tasks[] | select(.branch == \"$branch\") | .id" "$registry" 2>/dev/null | head -1)
    
    if [ -n "$task_id" ]; then
      # Update task with PR info
      jq ".tasks |= map(if .id == \"$task_id\" then .pr = {number: $pr_number, url: \"$pr_url\", status: \"$action\"} else . end)" "$registry" > "$registry.tmp"
      mv "$registry.tmp" "$registry"
      log "Updated task $task_id with PR #$pr_number"
      
      # If PR is opened or ready for review, trigger CI check
      if [ "$action" = "opened" ] || [ "$action" = "ready_for_review" ]; then
        log "PR ready for CI - waiting for checks..."
        # Spawn CI wait job
        if [ -f "$SCRIPTS_DIR/wait-for-ci.sh" ]; then
          "$SCRIPTS_DIR/wait-for-ci.sh" "$repo" "$pr_number" "$task_id" &
        fi
      fi
      
      # If PR is merged or closed, cleanup
      if [ "$action" = "closed" ]; then
        local merged=$(echo "$body" | jq -r '.pull_request.merged')
        if [ "$merged" = "true" ]; then
          log "PR #$pr_number merged - triggering cleanup"
          "$SCRIPTS_DIR/cleanup-agents.sh" "$task_id" &
        fi
      fi
    fi
  fi
  
  # Send notification
  if [ -f "$NOTIFY_SCRIPT" ]; then
    "$NOTIFY_SCRIPT" "pr" "$repo" "$pr_number" "$action: $pr_title"
  fi
}

handle_ci_event() {
  local body="$1"
  local action=$(echo "$body" | jq -r '.action')
  local check_name=$(echo "$body" | jq -r '.check_run.name')
  local conclusion=$(echo "$body" | jq -r '.check_run.conclusion')
  local status=$(echo "$body" | jq -r '.check_run.status')
  local pr_numbers=$(echo "$body" | jq -r '.check_run.pull_requests[].number')
  local repo=$(echo "$body" | jq -r '.repository.full_name')
  
  log "CI event: $check_name ($status/$conclusion) for PR #$pr_numbers"
  
  # Check if all CI checks passed
  if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
    log "CI passed for $repo#$pr_numbers"
    
    # Find task and update status
    local registry="$SWARM_DIR/active-tasks.json"
    if [ -f "$registry" ]; then
      local task_id=$(jq -r ".tasks[] | select(.pr.number == $pr_numbers) | .id" "$registry" 2>/dev/null | head -1)
      
      if [ -n "$task_id" ]; then
        jq ".tasks |= map(if .id == \"$task_id\" then .ci_status = \"passed\" else . end)" "$registry" > "$registry.tmp"
        mv "$registry.tmp" "$registry"
        log "Updated CI status for task $task_id"
        
        # Notify user about CI passing
        if [ -f "$NOTIFY_SCRIPT" ]; then
          "$NOTIFY_SCRIPT" "ci-pass" "$repo" "$pr_numbers" "CI checks passed! Ready for review."
        fi
        
        # Optionally, auto-request review
        if [ -f "$SCRIPTS_DIR/review-pr.sh" ]; then
          "$SCRIPTS_DIR/review-pr.sh" "$repo" "$pr_numbers" --auto &
        fi
      fi
    fi
  elif [ "$status" = "completed" ] && [ "$conclusion" != "success" ]; then
    log "CI failed for $repo#$pr_numbers: $conclusion"
    
    # Notify about CI failure
    if [ -f "$NOTIFY_SCRIPT" ]; then
      "$NOTIFY_SCRIPT" "ci-failed" "$repo" "$pr_numbers" "CI failed: $conclusion"
    fi
    
    # Trigger auto-respawn with failure context
    if [ -f "$SCRIPTS_DIR/respawn-agent.sh" ]; then
      local task_id=$(jq -r ".tasks[] | select(.pr.number == $pr_numbers) | .id" "$registry" 2>/dev/null | head -1)
      if [ -n "$task_id" ]; then
        log "CI failed for task $task_id, triggering respawn with failure context"
        "$SCRIPTS_DIR/respawn-agent.sh" "$task_id" --ci-failure &
      fi
    fi
  fi
}

handle_status_event() {
  local body="$1"
  local state=$(echo "$body" | jq -r '.state')
  local branches=$(echo "$body" | jq -r '.branches[].name')
  local repo=$(echo "$body" | jq -r '.repository.full_name')
  
  log "Status event: $repo/$branches = $state"
  
  # This can be extended to handle commit status updates
  if [ "$state" = "success" ]; then
    log "Commit status success for $repo/$branches"
  elif [ "$state" = "failure" ]; then
    log "Commit status failure for $repo/$branches"
  fi
}

# --- Main server loop ---
log "Starting GitHub webhook listener on port $PORT"
log "Press Ctrl+C to stop"

# Create a FIFO for the server
FIFO="/tmp/webhook-$$.fifo"
mkfifo "$FIFO"
trap "rm -f $FIFO; exit" INT TERM EXIT

# Start netcat listener
while true; do
  # Listen for one request at a time
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nListening..." | nc -l -p "$PORT" -q 1 | while read -r line; do
    # Accumulate request
    REQUEST="$REQUEST$line\n"
    if [ -z "$line" ]; then
      # Empty line means headers are done, process request
      handle_webhook "$REQUEST"
      REQUEST=""
    fi
  done
done

log "Server stopped"
