#!/bin/bash
# common.sh - 公共函数库
# 提供所有 agent 共享的基础功能

# --- 颜色定义 ---
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# --- 日志函数 ---
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_debug() { [ "${DEBUG:-0}" = "1" ] && echo -e "${YELLOW}[DEBUG]${NC} $*"; }

# --- 配置加载 ---
load_config() {
    local config_file="${1:-$HOME/.openclaw-zero/workspace/teams/testclaude/.env}"
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_debug "Loaded config from $config_file"
    fi
}

# --- 任务注册表操作 ---
get_task_registry() {
    local registry="${SWARM_DIR:-$HOME/.openclaw-zero/workspace/teams/testclaude/swarm}/active-tasks.json"
    echo "$registry"
}

add_task() {
    local task_id="$1"
    local task_type="$2"
    local description="$3"
    local repo="${4:-}"
    local branch="${5:-}"
    
    local registry=$(get_task_registry)
    local timestamp=$(date -Iseconds)
    
    jq ".tasks += [{
        id: \"$task_id\",
        type: \"$task_type\",
        description: \"$description\",
        repo: \"$repo\",
        branch: \"$branch\",
        status: \"started\",
        startTime: \"$timestamp\",
        attempts: 1
    }]" "$registry" > "$registry.tmp" 2>/dev/null && mv "$registry.tmp" "$registry"
    
    log_debug "Task added: $task_id"
}

update_task_status() {
    local task_id="$1"
    local status="$2"
    local registry=$(get_task_registry)
    
    jq ".tasks |= map(if .id == \"$task_id\" then .status = \"$status\" else . end)" \
        "$registry" > "$registry.tmp" 2>/dev/null && mv "$registry.tmp" "$registry"
    
    log_debug "Task $task_id status updated to $status"
}

get_task() {
    local task_id="$1"
    local registry=$(get_task_registry)
    jq -r ".tasks[] | select(.id == \"$task_id\")" "$registry" 2>/dev/null
}

# --- Git 操作 ---
get_repo_info() {
    local repo="$1"
    local branch="${2:-main}"
    
    # 使用 gh CLI 获取仓库信息
    if command -v gh &> /dev/null; then
        local owner=$(echo "$repo" | cut -d/ -f1)
        local name=$(echo "$repo" | cut -d/ -f2)
        gh api "repos/$repo" --jq '{name: .name, owner: .owner.login, default_branch: .default_branch, description: .description}' 2>/dev/null
    else
        echo "{\"name\":\"$name\",\"owner\":\"$owner\",\"default_branch\":\"$branch\"}"
    fi
}

create_branch() {
    local repo="$1"
    local branch="$2"
    local base="${3:-main}"
    
    cd "$WORKSPACE/projects/$repo" 2>/dev/null || return 1
    git checkout -b "$branch" "$base" 2>/dev/null
    git push origin "$branch" 2>/dev/null
    log_debug "Branch created: $branch"
}

# --- 通知发送 ---
send_notification() {
    local channel="$1"
    local message="$2"
    local title="${3:-Notification}"
    
    local notify_script="$HOME/.openclaw-zero/workspace/teams/testclaude/scripts/channel-notify.sh"
    if [ -f "$notify_script" ]; then
        "$notify_script" "$channel" "$message" --title "$title" 2>/dev/null || true
    fi
}

# --- 时间工具 ---
get_timestamp() {
    date -Iseconds
}

get_elapsed() {
    local start="$1"
    local now=$(date +%s)
    local start_epoch=$(date -d "$start" +%s 2>/dev/null || echo "0")
    echo $((now - start_epoch))
}

# --- 文件操作 ---
ensure_dir() {
    local dir="$1"
    mkdir -p "$dir"
}

write_file() {
    local file="$1"
    local content="$2"
    echo "$content" > "$file"
}

read_file() {
    local file="$1"
    [ -f "$file" ] && cat "$file"
}

# --- 验证函数 ---
validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

validate_repo() {
    local repo="$1"
    if [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- 等待函数 ---
wait_for_condition() {
    local condition="$1"
    local timeout="${2:-60}"
    local interval="${3:-2}"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if eval "$condition"; then
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    return 1
}

# --- 导出函数 ---
export -f log_info log_success log_warning log_error log_debug
export -f load_config get_task_registry add_task update_task_status get_task
export -f get_repo_info create_branch send_notification
export -f get_timestamp get_elapsed ensure_dir write_file read_file
export -f validate_url validate_repo wait_for_condition
