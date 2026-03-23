#!/bin/bash
# a2a.sh - Agent-to-Agent 通信协议库
# 提供 agent 之间的消息交互能力

# 加载基础库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================
# A2A 配置
# ============================================

A2A_MESSAGE_DIR="${SWARM_DIR:-$HOME/.openclaw-zero/workspace/teams/testclaude/swarm}/messages"
A2A_QUEUE_DIR="$A2A_MESSAGE_DIR/queue"
A2A_INBOX_DIR="$A2A_MESSAGE_DIR/inbox"
A2A_OUTBOX_DIR="$A2A_MESSAGE_DIR/outbox"
A2A_ARCHIVE_DIR="$A2A_MESSAGE_DIR/archive"

# 初始化 A2A 目录
init_a2a() {
    ensure_dir "$A2A_MESSAGE_DIR"
    ensure_dir "$A2A_QUEUE_DIR"
    ensure_dir "$A2A_INBOX_DIR"
    ensure_dir "$A2A_OUTBOX_DIR"
    ensure_dir "$A2A_ARCHIVE_DIR"
    log_debug "A2A directories initialized"
}

# ============================================
# 消息格式定义
# ============================================

# 生成消息 ID
generate_message_id() {
    echo "msg_$(date +%Y%m%d_%H%M%S)_$$_$RANDOM"
}

# 创建 A2A 消息
create_message() {
    local from="$1"
    local to="$2"
    local type="$3"
    local content="$4"
    local correlation_id="${5:-}"
    
    local message_id=$(generate_message_id)
    local timestamp=$(date -Iseconds)
    
    cat << EOF
{
  "id": "$message_id",
  "from": "$from",
  "to": "$to",
  "type": "$type",
  "content": $content,
  "correlationId": "$correlation_id",
  "timestamp": "$timestamp",
  "status": "pending"
}
EOF
}

# ============================================
# 消息发送
# ============================================

# 发送消息到指定 agent
send_to_agent() {
    local to_agent="$1"
    local message_type="$2"
    local content="$3"
    local from_agent="${4:-$(whoami)}"
    local correlation_id="${5:-}"
    
    init_a2a
    
    local message=$(create_message "$from_agent" "$to_agent" "$message_type" "$content" "$correlation_id")
    local message_file="$A2A_QUEUE_DIR/$(generate_message_id).json"
    
    echo "$message" > "$message_file"
    log_info "Message sent from $from_agent to $to_agent: $message_type"
    
    echo "$message_file"
}

# 广播消息到所有 agent
broadcast_to_agents() {
    local message_type="$1"
    local content="$2"
    local from_agent="${3:-$(whoami)}"
    
    local agents=("orchestrator" "coding" "reviewer" "qa" "documentation" "security" "devops")
    
    for agent in "${agents[@]}"; do
        if [ "$agent" != "$from_agent" ]; then
            send_to_agent "$agent" "$message_type" "$content" "$from_agent"
        fi
    done
    
    log_info "Broadcast sent to all agents from $from_agent"
}

# ============================================
# 消息接收
# ============================================

# 接收消息
receive_messages() {
    local agent_name="$1"
    local limit="${2:-10}"
    
    init_a2a
    
    local messages=()
    local count=0
    
    for msg_file in "$A2A_QUEUE_DIR"/msg_*.json; do
        [ -f "$msg_file" ] || continue
        
        local to=$(jq -r '.to' "$msg_file" 2>/dev/null)
        
        if [ "$to" = "$agent_name" ] || [ "$to" = "all" ]; then
            messages+=("$msg_file")
            count=$((count + 1))
            [ $count -ge $limit ] && break
        fi
    done
    
    for msg_file in "${messages[@]}"; do
        cat "$msg_file"
        # 移动到 inbox
        mv "$msg_file" "$A2A_INBOX_DIR/"
    done
}

# 获取待处理消息数量
get_pending_message_count() {
    local agent_name="$1"
    local count=0
    
    for msg_file in "$A2A_QUEUE_DIR"/msg_*.json; do
        [ -f "$msg_file" ] || continue
        
        local to=$(jq -r '.to' "$msg_file" 2>/dev/null)
        if [ "$to" = "$agent_name" ] || [ "$to" = "all" ]; then
            count=$((count + 1))
        fi
    done
    
    echo "$count"
}

# ============================================
# 消息处理
# ============================================

# 处理消息
process_message() {
    local message_file="$1"
    local handler="${2:-}"
    
    if [ ! -f "$message_file" ]; then
        log_error "Message file not found: $message_file"
        return 1
    fi
    
    local message=$(cat "$message_file")
    local message_id=$(echo "$message" | jq -r '.id')
    local from=$(echo "$message" | jq -r '.from')
    local type=$(echo "$message" | jq -r '.type')
    local content=$(echo "$message" | jq -r '.content')
    local correlation_id=$(echo "$message" | jq -r '.correlationId')
    
    log_info "Processing message $message_id from $from, type: $type"
    
    # 更新状态
    local updated_message=$(echo "$message" | jq '.status = "processing"')
    echo "$updated_message" > "$message_file"
    
    # 如果有自定义处理器，调用它
    if [ -n "$handler" ] && command -v "$handler" &> /dev/null; then
        "$handler" "$from" "$type" "$content" "$correlation_id"
        local result=$?
        
        if [ $result -eq 0 ]; then
            updated_message=$(echo "$updated_message" | jq '.status = "processed"')
            echo "$updated_message" > "$message_file"
            mv "$message_file" "$A2A_ARCHIVE_DIR/"
        else
            updated_message=$(echo "$updated_message" | jq '.status = "failed"')
            echo "$updated_message" > "$message_file"
        fi
    fi
    
    return 0
}

# 处理所有待处理消息
process_all_messages() {
    local agent_name="$1"
    local handler="${2:-}"
    
    local messages=$(receive_messages "$agent_name" 100)
    
    while IFS= read -r msg_file; do
        [ -f "$msg_file" ] && process_message "$msg_file" "$handler"
    done <<< "$messages"
}

# ============================================
# 消息类型定义
# ============================================

# 任务分配消息
send_task_assignment() {
    local to_agent="$1"
    local task_id="$2"
    local task_description="$3"
    local from_agent="${4:-orchestrator}"
    
    local content=$(jq -n \
        --arg task_id "$task_id" \
        --arg description "$task_description" \
        '{taskId: $task_id, description: $description, status: "assigned"}')
    
    send_to_agent "$to_agent" "task_assignment" "$content" "$from_agent" "$task_id"
}

# 任务状态更新
send_task_status() {
    local to_agent="$1"
    local task_id="$2"
    local status="$3"
    local message="$4"
    local from_agent="${5:-}"
    
    local content=$(jq -n \
        --arg task_id "$task_id" \
        --arg status "$status" \
        --arg message "$message" \
        '{taskId: $task_id, status: $status, message: $message}')
    
    send_to_agent "$to_agent" "task_status" "$content" "$from_agent" "$task_id"
}

# 请求协助
send_help_request() {
    local to_agent="$1"
    local request_type="$2"
    local details="$3"
    local from_agent="${4:-}"
    
    local content=$(jq -n \
        --arg type "$request_type" \
        --arg details "$details" \
        '{requestType: $type, details: $details}')
    
    send_to_agent "$to_agent" "help_request" "$content" "$from_agent"
}

# 响应请求
send_response() {
    local to_agent="$1"
    local correlation_id="$2"
    local response="$3"
    local from_agent="${4:-}"
    
    local content=$(jq -n \
        --arg response "$response" \
        '{response: $response}')
    
    send_to_agent "$to_agent" "response" "$content" "$from_agent" "$correlation_id"
}

# ============================================
# 消息监控
# ============================================

# 监控消息队列
monitor_message_queue() {
    local agent_name="$1"
    local interval="${2:-5}"
    
    while true; do
        local count=$(get_pending_message_count "$agent_name")
        if [ "$count" -gt 0 ]; then
            log_info "$agent_name has $count pending messages"
            process_all_messages "$agent_name"
        fi
        sleep "$interval"
    done
}

# 获取消息历史
get_message_history() {
    local agent_name="$1"
    local limit="${2:-50}"
    
    local history="[]"
    
    for msg_file in "$A2A_ARCHIVE_DIR"/msg_*.json; do
        [ -f "$msg_file" ] || continue
        
        local to=$(jq -r '.to' "$msg_file" 2>/dev/null)
        local from=$(jq -r '.from' "$msg_file" 2>/dev/null)
        
        if [ "$to" = "$agent_name" ] || [ "$from" = "$agent_name" ]; then
            local msg=$(cat "$msg_file")
            history=$(echo "$history" | jq ". + [$msg]")
        fi
    done
    
    echo "$history" | jq ".[-$limit:]"
}

# ============================================
# 导出函数
# ============================================

export -f init_a2a generate_message_id create_message
export -f send_to_agent broadcast_to_agents
export -f receive_messages get_pending_message_count
export -f process_message process_all_messages
export -f send_task_assignment send_task_status
export -f send_help_request send_response
export -f monitor_message_queue get_message_history
