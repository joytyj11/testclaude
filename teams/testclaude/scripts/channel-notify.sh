#!/bin/bash
# channel-notify.sh - 多通道消息推送脚本
# 支持 Discord, Slack, Telegram, 企业微信, 钉钉, 飞书等
# Usage: ./channel-notify.sh <channel> <message> [options]

set -euo pipefail

# --- Configuration ---
TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
CONFIG_FILE="$TEAM_DIR/.env"
LOG_DIR="$TEAM_DIR/swarm/logs"
LOG_FILE="$LOG_DIR/channel-notify-$(date +%Y%m%d).log"

# Load environment variables
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
log_info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }

# --- Function: Send to Discord ---
send_discord() {
  local webhook_url="${DISCORD_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    log_warning "DISCORD_WEBHOOK_URL not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  local color="${3:-5814783}"
  local fields="${4:-}"
  
  # Build payload
  local payload=$(jq -n \
    --arg title "$title" \
    --arg description "$message" \
    --argjson color "$color" \
    '{embeds: [{title: $title, description: $description, color: $color, timestamp: (now | todateiso8601)}]}')
  
  # Add fields if provided
  if [ -n "$fields" ]; then
    payload=$(echo "$payload" | jq --argjson fields "$fields" '.embeds[0].fields = $fields')
  fi
  
  local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" 2>&1)
  if [ $? -eq 0 ]; then
    log_info "Discord notification sent: $title"
    return 0
  else
    log_error "Discord send failed: $response"
    return 1
  fi
}

# --- Function: Send to Slack ---
send_slack() {
  local webhook_url="${SLACK_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    log_warning "SLACK_WEBHOOK_URL not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  local color="${3:-good}"
  
  # Convert Discord color to Slack color
  case $color in
    "3066993") color="good" ;;
    "15158332") color="danger" ;;
    "5814783") color="warning" ;;
  esac
  
  local payload=$(jq -n \
    --arg title "$title" \
    --arg message "$message" \
    --arg color "$color" \
    '{attachments: [{title: $title, text: $message, color: $color, ts: (now | floor)}]}')
  
  local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" 2>&1)
  if [ $? -eq 0 ]; then
    log_info "Slack notification sent: $title"
    return 0
  else
    log_error "Slack send failed: $response"
    return 1
  fi
}

# --- Function: Send to Telegram ---
send_telegram() {
  local bot_token="${TELEGRAM_BOT_TOKEN:-}"
  local chat_id="${TELEGRAM_CHAT_ID:-}"
  
  if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
    log_warning "Telegram credentials not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  
  # Format message for Telegram
  local text="*$title*\n\n$message"
  
  local response=$(curl -s -X POST \
    "https://api.telegram.org/bot$bot_token/sendMessage" \
    -d "chat_id=$chat_id" \
    -d "text=$text" \
    -d "parse_mode=Markdown" 2>&1)
  
  if echo "$response" | jq -e '.ok' > /dev/null 2>&1; then
    log_info "Telegram notification sent: $title"
    return 0
  else
    log_error "Telegram send failed: $response"
    return 1
  fi
}

# --- Function: Send to WeChat Work (企业微信) ---
send_wechat() {
  local webhook_url="${WECHAT_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    log_warning "WeChat webhook not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  
  local payload=$(jq -n \
    --arg title "$title" \
    --arg message "$message" \
    '{msgtype: "markdown", markdown: {content: "## \($title)\n\n\($message)"}}')
  
  local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" 2>&1)
  if echo "$response" | jq -e '.errcode == 0' > /dev/null 2>&1; then
    log_info "WeChat notification sent: $title"
    return 0
  else
    log_error "WeChat send failed: $response"
    return 1
  fi
}

# --- Function: Send to DingTalk (钉钉) ---
send_dingtalk() {
  local webhook_url="${DINGTALK_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    log_warning "DingTalk webhook not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  
  local payload=$(jq -n \
    --arg title "$title" \
    --arg message "$message" \
    '{msgtype: "markdown", markdown: {title: $title, text: "## \($title)\n\n\($message)"}}')
  
  local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" 2>&1)
  if echo "$response" | jq -e '.errcode == 0' > /dev/null 2>&1; then
    log_info "DingTalk notification sent: $title"
    return 0
  else
    log_error "DingTalk send failed: $response"
    return 1
  fi
}

# --- Function: Send to Feishu/Lark (飞书) ---
send_feishu() {
  local webhook_url="${FEISHU_WEBHOOK_URL:-}"
  if [ -z "$webhook_url" ]; then
    log_warning "Feishu webhook not configured"
    return 1
  fi
  
  local title="$1"
  local message="$2"
  
  local payload=$(jq -n \
    --arg title "$title" \
    --arg message "$message" \
    '{msg_type: "text", content: {text: "[\($title)] \($message)"}}')
  
  local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" 2>&1)
  if echo "$response" | jq -e '.code == 0' > /dev/null 2>&1; then
    log_info "Feishu notification sent: $title"
    return 0
  else
    log_error "Feishu send failed: $response"
    return 1
  fi
}

# --- Function: Send task status notification ---
send_task_status() {
  local task_id="$1"
  local status="$2"
  local details="$3"
  local repo="${4:-}"
  local pr_number="${5:-}"
  
  # Determine color based on status
  local color="5814783"  # Default blue
  local emoji="🔔"
  
  case "$status" in
    "started")
      emoji="🚀"
      color="5814783"  # Blue
      ;;
    "completed"|"success")
      emoji="✅"
      color="3066993"  # Green
      ;;
    "failed"|"error")
      emoji="❌"
      color="15158332"  # Red
      ;;
    "ci-pass")
      emoji="✅"
      color="3066993"
      ;;
    "ci-failed")
      emoji="❌"
      color="15158332"
      ;;
    "pr-created")
      emoji="🔀"
      color="5814783"
      ;;
    "pr-merged")
      emoji="🔀✅"
      color="3066993"
      ;;
    "review-requested")
      emoji="👀"
      color="5814783"
      ;;
  esac
  
  local title="$emoji Task $task_id: $status"
  local message="**Details:** $details\n\n**Time:** $(date '+%Y-%m-%d %H:%M:%S')"
  
  if [ -n "$repo" ]; then
    message="$message\n**Repository:** $repo"
  fi
  
  if [ -n "$pr_number" ]; then
    message="$message\n**PR:** https://github.com/$repo/pull/$pr_number"
  fi
  
  # Build fields for Discord
  local fields=$(jq -n \
    --arg name "Status" \
    --arg value "$status" \
    --arg name2 "Task ID" \
    --arg value2 "$task_id" \
    '[
      {name: $name, value: $value, inline: true},
      {name: $name2, value: $value2, inline: true}
    ]')
  
  if [ -n "$repo" ]; then
    fields=$(echo "$fields" | jq --arg name "Repository" --arg value "$repo" '. += [{name: $name, value: $value, inline: true}]')
  fi
  
  # Send to all configured channels
  local any_success=false
  
  if send_discord "$title" "$message" "$color" "$fields"; then
    any_success=true
  fi
  
  if send_slack "$title" "$message" "$color"; then
    any_success=true
  fi
  
  if send_telegram "$title" "$message"; then
    any_success=true
  fi
  
  if send_wechat "$title" "$message"; then
    any_success=true
  fi
  
  if send_dingtalk "$title" "$message"; then
    any_success=true
  fi
  
  if send_feishu "$title" "$message"; then
    any_success=true
  fi
  
  if [ "$any_success" = false ]; then
    log_warning "No notification channels configured, saving to queue"
    # Save to queue for later processing
    local queue_file="$TEAM_DIR/swarm/notifications/pending.json"
    mkdir -p "$(dirname "$queue_file")"
    
    local notification=$(jq -n \
      --arg task_id "$task_id" \
      --arg status "$status" \
      --arg details "$details" \
      --arg repo "$repo" \
      --arg pr "$pr_number" \
      --arg timestamp "$(date -Iseconds)" \
      '{task_id: $task_id, status: $status, details: $details, repo: $repo, pr: $pr, timestamp: $timestamp}')
    
    if [ -f "$queue_file" ]; then
      jq ".notifications += [$notification]" "$queue_file" > "$queue_file.tmp" 2>/dev/null && mv "$queue_file.tmp" "$queue_file"
    else
      jq -n --argjson notification "$notification" '{notifications: [$notification]}' > "$queue_file"
    fi
    log_info "Notification saved to queue: $queue_file"
  fi
}

# --- Main execution ---
mkdir -p "$LOG_DIR"

# Parse command line
CHANNEL="${1:-}"
MESSAGE="${2:-}"
shift 2 2>/dev/null || true

# Parse optional arguments
TITLE=""
TASK_ID=""
STATUS=""
REPO=""
PR_NUMBER=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --title)
      TITLE="$2"
      shift 2
      ;;
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --status)
      STATUS="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --pr)
      PR_NUMBER="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 <channel> <message> [options]"
      echo ""
      echo "Channels:"
      echo "  discord     - Send to Discord"
      echo "  slack       - Send to Slack"
      echo "  telegram    - Send to Telegram"
      echo "  wechat      - Send to WeChat Work"
      echo "  dingtalk    - Send to DingTalk"
      echo "  feishu      - Send to Feishu/Lark"
      echo "  task-status - Send task status notification"
      echo "  all         - Send to all configured channels"
      echo ""
      echo "Options:"
      echo "  --title TEXT        Notification title"
      echo "  --task-id ID        Task identifier"
      echo "  --status STATUS     Task status (started/completed/failed/ci-pass/...)"
      echo "  --repo REPO         GitHub repository"
      echo "  --pr NUMBER         Pull request number"
      echo ""
      echo "Examples:"
      echo "  $0 discord 'Hello World' --title 'Test'"
      echo "  $0 task-status 'Task completed successfully' --task-id T001 --status completed --repo owner/repo"
      echo "  $0 all 'Build passed' --title 'CI Result'"
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate input
if [ -z "$CHANNEL" ] || [ -z "$MESSAGE" ]; then
  log_error "Channel and message are required"
  exit 1
fi

# Send based on channel
case "$CHANNEL" in
  discord)
    send_discord "${TITLE:-Notification}" "$MESSAGE"
    ;;
  slack)
    send_slack "${TITLE:-Notification}" "$MESSAGE"
    ;;
  telegram)
    send_telegram "${TITLE:-Notification}" "$MESSAGE"
    ;;
  wechat)
    send_wechat "${TITLE:-Notification}" "$MESSAGE"
    ;;
  dingtalk)
    send_dingtalk "${TITLE:-Notification}" "$MESSAGE"
    ;;
  feishu)
    send_feishu "${TITLE:-Notification}" "$MESSAGE"
    ;;
  task-status)
    send_task_status "$TASK_ID" "$STATUS" "$MESSAGE" "$REPO" "$PR_NUMBER"
    ;;
  all)
    log_info "Sending to all configured channels..."
    send_discord "${TITLE:-Notification}" "$MESSAGE" || true
    send_slack "${TITLE:-Notification}" "$MESSAGE" || true
    send_telegram "${TITLE:-Notification}" "$MESSAGE" || true
    send_wechat "${TITLE:-Notification}" "$MESSAGE" || true
    send_dingtalk "${TITLE:-Notification}" "$MESSAGE" || true
    send_feishu "${TITLE:-Notification}" "$MESSAGE" || true
    ;;
  *)
    log_error "Unknown channel: $CHANNEL"
    exit 1
    ;;
esac

exit 0
