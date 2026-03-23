#!/bin/bash
# notify.sh - 通知库
# 提供多平台通知功能

# 加载配置
load_notify_config() {
    local config_file="${1:-$HOME/.openclaw-zero/workspace/teams/testclaude/.env}"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi
}

# 发送到 Discord
send_discord() {
    local webhook_url="${DISCORD_WEBHOOK_URL:-}"
    local title="$1"
    local message="$2"
    local color="${3:-5814783}"
    
    [ -z "$webhook_url" ] && return 1
    
    local payload=$(jq -n \
        --arg title "$title" \
        --arg description "$message" \
        --argjson color "$color" \
        '{embeds: [{title: $title, description: $description, color: $color}]}')
    
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1
}

# 发送到 Slack
send_slack() {
    local webhook_url="${SLACK_WEBHOOK_URL:-}"
    local title="$1"
    local message="$2"
    local color="${3:-good}"
    
    [ -z "$webhook_url" ] && return 1
    
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        --arg color "$color" \
        '{attachments: [{title: $title, text: $message, color: $color}]}')
    
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1
}

# 发送到 Telegram
send_telegram() {
    local bot_token="${TELEGRAM_BOT_TOKEN:-}"
    local chat_id="${TELEGRAM_CHAT_ID:-}"
    local title="$1"
    local message="$2"
    
    [ -z "$bot_token" ] || [ -z "$chat_id" ] && return 1
    
    local text="*$title*\n\n$message"
    curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$text" \
        -d "parse_mode=Markdown" > /dev/null 2>&1
}

# 发送到企业微信
send_wechat() {
    local webhook_url="${WECHAT_WEBHOOK_URL:-}"
    local title="$1"
    local message="$2"
    
    [ -z "$webhook_url" ] && return 1
    
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        '{msgtype: "markdown", markdown: {content: "## \($title)\n\n\($message)"}}')
    
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1
}

# 发送到钉钉
send_dingtalk() {
    local webhook_url="${DINGTALK_WEBHOOK_URL:-}"
    local title="$1"
    local message="$2"
    
    [ -z "$webhook_url" ] && return 1
    
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        '{msgtype: "markdown", markdown: {title: $title, text: "## \($title)\n\n\($message)"}}')
    
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1
}

# 发送到飞书
send_feishu() {
    local webhook_url="${FEISHU_WEBHOOK_URL:-}"
    local title="$1"
    local message="$2"
    
    [ -z "$webhook_url" ] && return 1
    
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        '{msg_type: "text", content: {text: "[\($title)] \($message)"}}')
    
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url" > /dev/null 2>&1
}

# 发送到所有配置的渠道
send_to_all() {
    local title="$1"
    local message="$2"
    
    send_discord "$title" "$message" || true
    send_slack "$title" "$message" || true
    send_telegram "$title" "$message" || true
    send_wechat "$title" "$message" || true
    send_dingtalk "$title" "$message" || true
    send_feishu "$title" "$message" || true
}

# 发送任务状态通知
send_task_notification() {
    local task_id="$1"
    local status="$2"
    local message="$3"
    local repo="${4:-}"
    local pr="${5:-}"
    
    local emoji=""
    local color="5814783"
    
    case "$status" in
        started) emoji="🚀"; color="5814783" ;;
        completed|success) emoji="✅"; color="3066993" ;;
        failed|error) emoji="❌"; color="15158332" ;;
        ci-pass) emoji="✅"; color="3066993" ;;
        ci-failed) emoji="❌"; color="15158332" ;;
        pr-created) emoji="🔀"; color="5814783" ;;
        pr-merged) emoji="🔀✅"; color="3066993" ;;
        review-requested) emoji="👀"; color="5814783" ;;
    esac
    
    local title="$emoji Task $task_id: $status"
    local full_message="$message\n\nTime: $(date '+%Y-%m-%d %H:%M:%S')"
    
    [ -n "$repo" ] && full_message="$full_message\nRepo: $repo"
    [ -n "$pr" ] && full_message="$full_message\nPR: https://github.com/$repo/pull/$pr"
    
    send_to_all "$title" "$full_message"
}

# 导出函数
export -f load_notify_config send_discord send_slack send_telegram
export -f send_wechat send_dingtalk send_feishu send_to_all send_task_notification
