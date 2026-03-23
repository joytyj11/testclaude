#!/bin/bash
# notify-all-channels.sh - 发送通知到所有配置的外部聊天频道
# 集成 task-status-monitor 和 channel-notify 功能

set -euo pipefail

TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
CHANNEL_NOTIFY="$TEAM_DIR/scripts/channel-notify.sh"
TASK_MONITOR="$TEAM_DIR/scripts/task-status-monitor.sh"

# Load environment
if [ -f "$TEAM_DIR/.env" ]; then
  source "$TEAM_DIR/.env"
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }

# Function to send build status
send_build_status() {
  local status="$1"
  local project="$2"
  local branch="$3"
  local duration="${4:-}"
  
  local title="Build: $project/$branch"
  local message="Build $status"
  
  if [ -n "$duration" ]; then
    message="$message in $duration"
  fi
  
  if [ "$status" = "passed" ] || [ "$status" = "success" ]; then
    "$CHANNEL_NOTIFY" all "$message" --title "✅ $title" 2>/dev/null || true
  elif [ "$status" = "failed" ]; then
    "$CHANNEL_NOTIFY" all "$message" --title "❌ $title" 2>/dev/null || true
  else
    "$CHANNEL_NOTIFY" all "$message" --title "🔄 $title" 2>/dev/null || true
  fi
}

# Function to send PR status
send_pr_status() {
  local repo="$1"
  local pr_number="$2"
  local action="$3"
  local author="${4:-}"
  
  local title="PR #$pr_number: $action"
  local message="Repository: $repo"
  
  if [ -n "$author" ]; then
    message="$message\nAuthor: $author"
  fi
  
  message="$message\nLink: https://github.com/$repo/pull/$pr_number"
  
  case "$action" in
    opened|created)
      "$CHANNEL_NOTIFY" all "$message" --title "🔀 New PR: $title" 2>/dev/null || true
      ;;
    closed)
      "$CHANNEL_NOTIFY" all "$message" --title "🔒 PR Closed: $title" 2>/dev/null || true
      ;;
    merged)
      "$CHANNEL_NOTIFY" all "$message" --title "🔀✅ PR Merged: $title" 2>/dev/null || true
      ;;
    review_requested)
      "$CHANNEL_NOTIFY" all "$message" --title "👀 Review Requested: $title" 2>/dev/null || true
      ;;
    *)
      "$CHANNEL_NOTIFY" all "$message" --title "📝 PR Update: $title" 2>/dev/null || true
      ;;
  esac
}

# Function to send CI status
send_ci_status() {
  local repo="$1"
  local pr_number="$2"
  local status="$3"
  local checks="${4:-}"
  
  local title="CI: $repo PR #$pr_number"
  local message="Status: $status"
  
  if [ -n "$checks" ]; then
    message="$message\nChecks: $checks"
  fi
  
  case "$status" in
    passed|success)
      "$CHANNEL_NOTIFY" all "$message" --title "✅ CI Passed: $title" 2>/dev/null || true
      ;;
    failed|error)
      "$CHANNEL_NOTIFY" all "$message" --title "❌ CI Failed: $title" 2>/dev/null || true
      ;;
    running|in_progress)
      "$CHANNEL_NOTIFY" all "$message" --title "🔄 CI Running: $title" 2>/dev/null || true
      ;;
    *)
      "$CHANNEL_NOTIFY" all "$message" --title "⏳ CI Status: $title" 2>/dev/null || true
      ;;
  esac
}

# Function to send deployment status
send_deployment_status() {
  local environment="$1"
  local version="$2"
  local status="$3"
  local duration="${4:-}"
  
  local title="Deploy to $environment"
  local message="Version: $version\nStatus: $status"
  
  if [ -n "$duration" ]; then
    message="$message\nDuration: $duration"
  fi
  
  case "$status" in
    success|completed)
      "$CHANNEL_NOTIFY" all "$message" --title "🚀 Deploy Success: $title" 2>/dev/null || true
      ;;
    failed|error)
      "$CHANNEL_NOTIFY" all "$message" --title "💥 Deploy Failed: $title" 2>/dev/null || true
      ;;
    in_progress|running)
      "$CHANNEL_NOTIFY" all "$message" --title "🔄 Deploying: $title" 2>/dev/null || true
      ;;
    *)
      "$CHANNEL_NOTIFY" all "$message" --title "📦 Deployment: $title" 2>/dev/null || true
      ;;
  esac
}

# Function to send daily summary
send_daily_summary() {
  log_info "Sending daily summary..."
  
  # Get task statistics
  local registry="$TEAM_DIR/swarm/active-tasks.json"
  if [ -f "$registry" ]; then
    local total=$(jq -r '.tasks | length' "$registry" 2>/dev/null || echo "0")
    local completed=$(jq -r '.tasks[] | select(.status == "completed") | .id' "$registry" 2>/dev/null | wc -l)
    local failed=$(jq -r '.tasks[] | select(.status == "failed") | .id' "$registry" 2>/dev/null | wc -l)
    
    local summary="📊 **Daily Report**\n\n"
    summary="${summary}Date: $(date '+%Y-%m-%d')\n"
    summary="${summary}Tasks: $total total, $completed completed, $failed failed\n"
    
    if [ "$total" -gt 0 ]; then
      local rate=$(( completed * 100 / total ))
      summary="${summary}Success Rate: $rate%\n"
    fi
    
    "$CHANNEL_NOTIFY" all "$summary" --title "📈 Daily Summary" 2>/dev/null || true
  else
    log_warning "No registry found"
  fi
  
  # Run task monitor summary
  "$TASK_MONITOR" summary daily 2>/dev/null || true
}

# Function to send alert
send_alert() {
  local severity="$1"
  local message="$2"
  local details="${3:-}"
  
  local title="🚨 Alert: $severity"
  local full_message="$message"
  
  if [ -n "$details" ]; then
    full_message="$full_message\n\nDetails: $details"
  fi
  
  case "$severity" in
    critical)
      "$CHANNEL_NOTIFY" all "$full_message" --title "🔥 CRITICAL: $title" 2>/dev/null || true
      ;;
    high)
      "$CHANNEL_NOTIFY" all "$full_message" --title "⚠️ HIGH: $title" 2>/dev/null || true
      ;;
    medium|normal)
      "$CHANNEL_NOTIFY" all "$full_message" --title "📢 Alert: $title" 2>/dev/null || true
      ;;
    low|info)
      "$CHANNEL_NOTIFY" all "$full_message" --title "ℹ️ Info: $title" 2>/dev/null || true
      ;;
    *)
      "$CHANNEL_NOTIFY" all "$full_message" --title "🔔 Notification: $title" 2>/dev/null || true
      ;;
  esac
}

# --- Main ---
ACTION="${1:-}"
shift 2>/dev/null || true

case "$ACTION" in
  build)
    send_build_status "$@"
    ;;
  pr)
    send_pr_status "$@"
    ;;
  ci)
    send_ci_status "$@"
    ;;
  deploy)
    send_deployment_status "$@"
    ;;
  summary)
    send_daily_summary
    ;;
  alert)
    send_alert "$@"
    ;;
  help|--help|-h)
    echo "Usage: $0 <action> [args]"
    echo ""
    echo "Actions:"
    echo "  build <status> <project> <branch> [duration]"
    echo "  pr <repo> <pr-number> <action> [author]"
    echo "  ci <repo> <pr-number> <status> [checks]"
    echo "  deploy <environment> <version> <status> [duration]"
    echo "  summary"
    echo "  alert <severity> <message> [details]"
    echo ""
    echo "Examples:"
    echo "  $0 build passed myapp main '2m 30s'"
    echo "  $0 pr owner/repo 123 opened alice"
    echo "  $0 ci owner/repo 123 passed '3/3 checks'"
    echo "  $0 deploy production v1.2.3 success '5m'"
    echo "  $0 summary"
    echo "  $0 alert critical 'Database connection failed' 'Error: timeout'"
    exit 0
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Run '$0 help' for usage"
    exit 1
    ;;
esac

echo "Notification sent"
