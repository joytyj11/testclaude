#!/bin/bash
# notify.sh — Enhanced notification sender with Discord/Slack/Webhook support
# Usage: notify.sh <type> <repo> <pr-number> <message> [--dry-run]

set -euo pipefail

# --- Configuration ---
SWARM_DIR="${SWARMHOME:-$HOME/.openclaw-zero/workspace/teams/testclaude}/swarm"
NOTIFICATIONS_DIR="$SWARM_DIR/notifications"
PENDING_FILE="$NOTIFICATIONS_DIR/pending.json"
SENT_DIR="$NOTIFICATIONS_DIR/sent"
LOG_FILE="$SWARM_DIR/logs/notify-$(date +%Y%m%d-%H%M%S).log"

# Load environment variables if .env exists
if [ -f "$HOME/.openclaw-zero/workspace/teams/testclaude/.env" ]; then
  source "$HOME/.openclaw-zero/workspace/teams/testclaude/.env"
fi

# Notification types and their emojis
declare -A NOTIFICATION_EMOJIS=(
  ["push"]="📦"
  ["pr"]="🔀"
  ["ci-pass"]="✅"
  ["ci-failed"]="❌"
  ["ci-timeout"]="⏰"
  ["pr-merged"]="🔀✅"
  ["review-requested"]="👀"
  ["task-completed"]="🎉"
  ["task-failed"]="💥"
)

# Dry-run mode
DRY_RUN=false
if [[ "${*}" == *"--dry-run"* ]]; then
  DRY_RUN=true
  echo "DRY RUN MODE - No actual actions will be taken"
  # Remove --dry-run from args
  set -- ${@/--dry-run/}
fi

# Parse arguments
NOTIFY_TYPE="${1:-}"
REPO="${2:-}"
PR_NUMBER="${3:-}"
MESSAGE="${4:-}"

# --- Logging ---
mkdir -p "$(dirname "$LOG_FILE")" "$SENT_DIR" "$NOTIFICATIONS_DIR"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

log() { echo "[$(date +%H:%M:%S)] $*"; }

# --- Function to send notification to Discord ---
send_discord() {
  local webhook_url="${DISCORD_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    return 1
  fi
  
  local emoji="${NOTIFICATION_EMOJIS[$NOTIFY_TYPE]:-🔔}"
  local title="$emoji $NOTIFY_TYPE"
  local description="$MESSAGE"
  local color=5814783  # Default blue
  
  if [ "$NOTIFY_TYPE" = "ci-pass" ]; then
    color=3066993  # Green
  elif [ "$NOTIFY_TYPE" = "ci-failed" ] || [ "$NOTIFY_TYPE" = "ci-timeout" ]; then
    color=15158332  # Red
  fi
  
  if [ -n "$REPO" ] && [ -n "$PR_NUMBER" ]; then
    title="$emoji $REPO PR #$PR_NUMBER"
    description="**$MESSAGE**\n\n🔗 [View PR](https://github.com/$REPO/pull/$PR_NUMBER)"
  fi
  
  local payload=$(jq -n \
    --arg title "$title" \
    --arg description "$description" \
    --argjson color "$color" \
    '{embeds: [{title: $title, description: $description, color: $color}]}')
  
  if [ "$DRY_RUN" = false ]; then
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1 || true
  fi
  log "Sent Discord notification: $title"
  return 0
}

# --- Function to send notification to Slack ---
send_slack() {
  local webhook_url="${SLACK_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    return 1
  fi
  
  local emoji="${NOTIFICATION_EMOJIS[$NOTIFY_TYPE]:-🔔}"
  local text="$emoji *$NOTIFY_TYPE*: $MESSAGE"
  
  if [ -n "$REPO" ] && [ -n "$PR_NUMBER" ]; then
    text="$emoji *$REPO PR #$PR_NUMBER*\n$MESSAGE\n<https://github.com/$REPO/pull/$PR_NUMBER|View PR>"
  fi
  
  local payload=$(jq -n --arg text "$text" '{text: $text}')
  
  if [ "$DRY_RUN" = false ]; then
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1 || true
  fi
  log "Sent Slack notification"
  return 0
}

# --- Function to send notification via custom webhook ---
send_webhook() {
  local webhook_url="${CUSTOM_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    return 1
  fi
  
  local payload=$(jq -n \
    --arg type "$NOTIFY_TYPE" \
    --arg repo "$REPO" \
    --arg pr "$PR_NUMBER" \
    --arg message "$MESSAGE" \
    --arg timestamp "$(date -Iseconds)" \
    '{type: $type, repo: $repo, pr: $pr, message: $message, timestamp: $timestamp}')
  
  if [ "$DRY_RUN" = false ]; then
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1 || true
  fi
  log "Sent custom webhook notification"
  return 0
}

# --- Main execution ---
log "=== Notification Sender Started ==="

# If called with arguments, send notification directly
if [ -n "$NOTIFY_TYPE" ]; then
  log "Direct notification: type=$NOTIFY_TYPE, repo=$REPO, pr=$PR_NUMBER"
  log "Message: $MESSAGE"
  
  # Try to send through available channels
  local sent=false
  if send_discord; then
    sent=true
  elif send_slack; then
    sent=true
  elif send_webhook; then
    sent=true
  fi
  
  if [ "$sent" = false ]; then
    log "No notification channels configured, saving to pending file"
    
    # Save to pending file
    local notification=$(jq -n \
      --arg type "$NOTIFY_TYPE" \
      --arg repo "$REPO" \
      --arg pr "$PR_NUMBER" \
      --arg message "$MESSAGE" \
      --arg timestamp "$(date -Iseconds)" \
      '{type: $type, repo: $repo, pr: $pr, message: $message, timestamp: $timestamp}')
    
    if [ -f "$PENDING_FILE" ]; then
      jq ".notifications += [$notification]" "$PENDING_FILE" > "$PENDING_FILE.tmp" 2>/dev/null && mv "$PENDING_FILE.tmp" "$PENDING_FILE"
    else
      jq -n --argjson notification "$notification" '{notifications: [$notification]}' > "$PENDING_FILE"
    fi
    log "Saved to $PENDING_FILE"
  fi
  exit 0
fi

# Otherwise, process pending notifications
if [ ! -f "$PENDING_FILE" ]; then
  log "No pending notifications found"
  exit 0
fi

# Parse and send pending notifications
NOTIFICATION_COUNT=$(jq -r '.notifications | length' "$PENDING_FILE" 2>/dev/null || echo "0")

if [ "$NOTIFICATION_COUNT" = "0" ]; then
  log "Pending file has no notifications"
  exit 0
fi

log "Processing $NOTIFICATION_COUNT pending notification(s)"

# Archive pending file
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mv "$PENDING_FILE" "$SENT_DIR/pending-${TIMESTAMP}.json"
log "Moved pending notifications to sent/"

exit 0
