#!/bin/bash
# task-status-monitor.sh - 监控任务状态并推送通知
# 集成到 check-agents.sh 和 workflow 中，自动推送状态变化

set -euo pipefail

# --- Configuration ---
TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
REGISTRY="$TEAM_DIR/swarm/active-tasks.json"
STATE_DIR="$TEAM_DIR/swarm/state"
STATUS_HISTORY="$STATE_DIR/task-status-history.json"
LOG_DIR="$TEAM_DIR/swarm/logs"
LOG_FILE="$LOG_DIR/task-monitor-$(date +%Y%m%d).log"

# Load environment
if [ -f "$TEAM_DIR/.env" ]; then
  source "$TEAM_DIR/.env"
fi

# --- Functions ---
log() { echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

# Initialize state directory
mkdir -p "$STATE_DIR" "$LOG_DIR"

# Initialize status history if not exists
if [ ! -f "$STATUS_HISTORY" ]; then
  echo '{"tasks": {}, "last_check": null}' > "$STATUS_HISTORY"
fi

# Function to send notification via channel-notify.sh
send_notification() {
  local task_id="$1"
  local status="$2"
  local message="$3"
  local repo="${4:-}"
  local pr="${5:-}"
  
  if [ -f "$TEAM_DIR/scripts/channel-notify.sh" ]; then
    "$TEAM_DIR/scripts/channel-notify.sh" task-status "$message" \
      --task-id "$task_id" \
      --status "$status" \
      --repo "$repo" \
      --pr "$pr" 2>/dev/null || true
  else
    # Fallback to old notify.sh
    "$TEAM_DIR/scripts/notify.sh" "$status" "$repo" "$pr" "$message" 2>/dev/null || true
  fi
}

# Function to check for status changes
check_status_changes() {
  if [ ! -f "$REGISTRY" ]; then
    log "Registry not found"
    return 0
  fi
  
  local current_statuses=$(jq -r '.tasks[] | "\(.id):\(.status)"' "$REGISTRY" 2>/dev/null || echo "")
  local previous_statuses=$(jq -r '.tasks | to_entries[] | "\(.key):\(.value.status)"' "$STATUS_HISTORY" 2>/dev/null || echo "")
  
  # Track changes
  while IFS=: read -r task_id current_status; do
    if [ -z "$task_id" ]; then continue; fi
    
    # Get previous status
    previous_status=$(echo "$previous_statuses" | grep "^$task_id:" | cut -d: -f2 || echo "")
    
    # If status changed
    if [ -n "$previous_status" ] && [ "$current_status" != "$previous_status" ]; then
      log "Status changed for $task_id: $previous_status → $current_status"
      
      # Get task details
      task_details=$(jq -r ".tasks[] | select(.id == \"$task_id\")" "$REGISTRY" 2>/dev/null)
      repo=$(echo "$task_details" | jq -r '.repo // ""')
      pr=$(echo "$task_details" | jq -r '.pr.number // ""')
      description=$(echo "$task_details" | jq -r '.description // ""')
      
      # Prepare message based on status
      case "$current_status" in
        started|in_progress)
          message="Task started: $description"
          send_notification "$task_id" "started" "$message" "$repo" "$pr"
          ;;
        completed|success|pr_created)
          message="Task completed successfully: $description"
          send_notification "$task_id" "completed" "$message" "$repo" "$pr"
          ;;
        failed|error)
          error_msg=$(echo "$task_details" | jq -r '.error // "Unknown error"')
          message="Task failed: $description\nError: $error_msg"
          send_notification "$task_id" "failed" "$message" "$repo" "$pr"
          ;;
        ci_pass|ci-pass)
          message="CI checks passed for $repo PR #$pr"
          send_notification "$task_id" "ci-pass" "$message" "$repo" "$pr"
          ;;
        ci_failed|ci-failed)
          message="CI checks failed for $repo PR #$pr"
          send_notification "$task_id" "ci-failed" "$message" "$repo" "$pr"
          ;;
        ready_for_review)
          message="PR ready for review: $description"
          send_notification "$task_id" "review-requested" "$message" "$repo" "$pr"
          ;;
        pr_merged)
          message="PR merged: $description"
          send_notification "$task_id" "pr-merged" "$message" "$repo" "$pr"
          ;;
        *)
          # Generic status change
          message="Task status: $current_status - $description"
          send_notification "$task_id" "$current_status" "$message" "$repo" "$pr"
          ;;
      esac
    fi
  done <<< "$current_statuses"
  
  # Update status history
  local new_history='{"tasks": {}, "last_check": "'$(date -Iseconds)'"}'
  while IFS=: read -r task_id status; do
    if [ -n "$task_id" ]; then
      new_history=$(echo "$new_history" | jq --arg id "$task_id" --arg status "$status" '.tasks[$id] = {status: $status, last_updated: (now | todateiso8601)}')
    fi
  done <<< "$current_statuses"
  
  echo "$new_history" > "$STATUS_HISTORY"
}

# Function to send summary of all tasks
send_summary() {
  local summary_type="${1:-daily}"
  
  if [ ! -f "$REGISTRY" ]; then
    return 0
  fi
  
  local total_tasks=$(jq -r '.tasks | length' "$REGISTRY" 2>/dev/null || echo "0")
  local completed=$(jq -r '.tasks[] | select(.status == "completed" or .status == "success") | .id' "$REGISTRY" 2>/dev/null | wc -l)
  local failed=$(jq -r '.tasks[] | select(.status == "failed" or .status == "error") | .id' "$REGISTRY" 2>/dev/null | wc -l)
  local in_progress=$(jq -r '.tasks[] | select(.status == "in_progress" or .status == "started") | .id' "$REGISTRY" 2>/dev/null | wc -l)
  
  local summary="📊 **Task Summary ($summary_type)**\n\n"
  summary="${summary}- Total Tasks: $total_tasks\n"
  summary="${summary}- ✅ Completed: $completed\n"
  summary="${summary}- ❌ Failed: $failed\n"
  summary="${summary}- 🔄 In Progress: $in_progress\n"
  
  if [ "$total_tasks" -gt 0 ]; then
    local success_rate=$(( completed * 100 / total_tasks ))
    summary="${summary}- 📈 Success Rate: $success_rate%\n"
  fi
  
  # Get recent tasks
  recent_tasks=$(jq -r '.tasks[] | select(.status != "completed" and .status != "success") | "- \(.id): \(.status) - \(.description)"' "$REGISTRY" 2>/dev/null | head -5)
  if [ -n "$recent_tasks" ]; then
    summary="${summary}\n**Active Tasks:**\n$recent_tasks"
  fi
  
  # Send summary
  if [ -f "$TEAM_DIR/scripts/channel-notify.sh" ]; then
    "$TEAM_DIR/scripts/channel-notify.sh" all "$summary" --title "Task Summary ($summary_type)" 2>/dev/null || true
  else
    "$TEAM_DIR/scripts/notify.sh" summary "" "" "$summary" 2>/dev/null || true
  fi
  
  log "Summary sent: total=$total_tasks, completed=$completed, failed=$failed"
}

# Function to send alert for stuck tasks
check_stuck_tasks() {
  local stuck_threshold="${STUCK_THRESHOLD:-3600}" # 1 hour default
  local now=$(date +%s)
  
  if [ ! -f "$REGISTRY" ]; then
    return 0
  fi
  
  jq -r '.tasks[] | select(.status == "in_progress" or .status == "started") | "\(.id):\(.startTime)"' "$REGISTRY" 2>/dev/null | while IFS=: read -r task_id start_time; do
    if [ -z "$task_id" ]; then continue; fi
    
    start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
    elapsed=$((now - start_epoch))
    
    if [ "$elapsed" -gt "$stuck_threshold" ]; then
      log "Task $task_id stuck for $elapsed seconds"
      
      # Get task details
      description=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .description" "$REGISTRY" 2>/dev/null)
      
      message="⚠️ Task stuck for $(($elapsed / 60)) minutes: $description"
      
      if [ -f "$TEAM_DIR/scripts/channel-notify.sh" ]; then
        "$TEAM_DIR/scripts/channel-notify.sh" task-status "$message" \
          --task-id "$task_id" \
          --status "stuck" 2>/dev/null || true
      fi
    fi
  done
}

# --- Main execution ---
log "=== Task Status Monitor Started ==="

ACTION="${1:-check}"

case "$ACTION" in
  check)
    check_status_changes
    check_stuck_tasks
    ;;
  summary)
    send_summary "${2:-daily}"
    ;;
  watch)
    # Continuous monitoring mode
    log "Entering watch mode (press Ctrl+C to stop)"
    while true; do
      check_status_changes
      check_stuck_tasks
      sleep 60
    done
    ;;
  *)
    echo "Usage: $0 {check|summary|watch}"
    echo "  check   - Check and send status changes"
    echo "  summary - Send daily summary"
    echo "  watch   - Continuous monitoring mode"
    exit 1
    ;;
esac

log "Monitor finished"
exit 0
