#!/bin/bash
# Feishu Chat Integration for TestClaude Team
# 使用 OpenClaw 的飞书通道发送消息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAM_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="/home/administrator/.openclaw-zero/workspace"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 获取飞书群聊 ID（从配置或环境变量）
get_group_id() {
    if [ -f "$TEAM_DIR/.env" ]; then
        source "$TEAM_DIR/.env" 2>/dev/null
        if [ -n "$FEISHU_GROUP_ID" ]; then
            echo "$FEISHU_GROUP_ID"
            return
        fi
    fi
    
    # 尝试从 OpenClaw 配置获取
    GROUP_ID=$(openclaw config get channels.feishu.groupId 2>/dev/null | tr -d '"')
    if [ -n "$GROUP_ID" ]; then
        echo "$GROUP_ID"
        return
    fi
    
    echo ""
}

# 发送消息到飞书群聊
send_message() {
    local message="$1"
    local sender="${2:-TestClaude}"
    local group_id=$(get_group_id)
    
    if [ -z "$group_id" ]; then
        log_error "未配置飞书群聊 ID"
        log_info "请设置 FEISHU_GROUP_ID 环境变量或配置 channels.feishu.groupId"
        return 1
    fi
    
    # 格式化消息
    local formatted_message="[$sender] $message"
    
    # 使用 OpenClaw message 工具发送
    log_info "发送飞书消息到群聊: $group_id"
    openclaw message send feishu --to "chat:$group_id" --message "$formatted_message" 2>&1 || {
        log_error "发送失败，尝试通过 API 直接发送..."
        # fallback: 直接调用飞书 API
        send_via_api "$formatted_message" "$group_id"
    }
}

# 通过飞书 API 直接发送（备用）
send_via_api() {
    local message="$1"
    local group_id="$2"
    
    # 获取 token（需要实现）
    log_error "API 直接发送需要实现 token 获取逻辑"
}

# 发送 Agent 间消息
send_agent_message() {
    local from_agent="$1"
    local to_agent="$2"
    local msg_type="$3"
    local content="$4"
    
    local message="[${from_agent} → ${to_agent}] [${msg_type}] ${content}"
    send_message "$message" "$from_agent"
}

# 发送任务状态更新
send_task_status() {
    local task_id="$1"
    local status="$2"
    local message="$3"
    local agent="$4"
    
    local status_emoji=""
    case "$status" in
        started) status_emoji="🚀" ;;
        completed) status_emoji="✅" ;;
        failed) status_emoji="❌" ;;
        reviewing) status_emoji="👀" ;;
        testing) status_emoji="🧪" ;;
        *) status_emoji="📋" ;;
    esac
    
    local formatted="${status_emoji} [Task ${task_id}] ${status}: ${message} (by ${agent})"
    send_message "$formatted" "Agent"
}

# 广播消息到所有 agent
broadcast() {
    local from="$1"
    local msg_type="$2"
    local content="$3"
    
    local message="📢 [BROADCAST] from ${from}: [${msg_type}] ${content}"
    send_message "$message" "System"
}

# 主函数
main() {
    local action="${1:-help}"
    shift || true
    
    case "$action" in
        send)
            send_message "$1" "${2:-TestClaude}"
            ;;
        agent)
            send_agent_message "$1" "$2" "$3" "$4"
            ;;
        broadcast)
            broadcast "$1" "$2" "$3"
            ;;
        task)
            send_task_status "$1" "$2" "$3" "$4"
            ;;
        test)
            log_info "测试飞书消息发送..."
            send_message "🧪 TestClaude 团队飞书集成测试成功！时间: $(date '+%Y-%m-%d %H:%M:%S')" "TestBot"
            ;;
        config)
            log_info "当前飞书配置:"
            echo "  FEISHU_GROUP_ID: $(get_group_id)"
            ;;
        help|*)
            echo "用法: $0 {send|agent|broadcast|task|test|config}"
            echo ""
            echo "命令:"
            echo "  send <message> [sender]           - 发送普通消息"
            echo "  agent <from> <to> <type> <msg>    - 发送 Agent 间消息"
            echo "  broadcast <from> <type> <msg>     - 广播消息"
            echo "  task <id> <status> <msg> <agent>  - 发送任务状态"
            echo "  test                              - 测试飞书连接"
            echo "  config                            - 显示配置信息"
            echo ""
            echo "示例:"
            echo "  $0 send 'Hello Team' Orchestrator"
            echo "  $0 agent orchestrator coding task_assignment '实现登录功能'"
            echo "  $0 task T001 completed '功能完成' coding"
            echo "  $0 test"
            ;;
    esac
}

main "$@"
