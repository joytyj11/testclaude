# 飞书群聊 Agent 协作配置指南

## ✅ 当前状态

- ✅ 飞书 App ID 已配置
- ✅ 飞书 App Secret 已配置  
- ✅ Token 获取成功
- ✅ API 连接正常

## 🔧 完整配置步骤

### 1. 获取飞书应用权限

在飞书开放平台为应用添加以下权限：

```
- im:chat:readonly        # 读取群聊信息
- im:chat:write           # 发送群聊消息  
- im:message:send         # 发送消息
- im:message:readonly     # 读取消息
- contact:user:readonly   # 读取用户信息（可选）
```

### 2. 创建群聊或获取群聊 ID

```bash
cd ~/.openclaw-zero/workspace/teams/testclaude
source .env

# 获取应用可访问的群聊列表
curl -X GET "https://open.feishu.cn/open-apis/chat/v4/list?page_size=10" \
  -H "Authorization: Bearer $FEISHU_ACCESS_TOKEN" | jq '.data.groups[] | {chat_id, name}'

# 或创建新群聊
curl -X POST "https://open.feishu.cn/open-apis/chat/v4/create" \
  -H "Authorization: Bearer $FEISHU_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "TestClaude Agent Chat",
    "description": "Agent 协作群聊"
  }' | jq '.data.chat_id'
```

### 3. 将群聊 ID 添加到配置

```bash
# 编辑 .env
nano ~/.openclaw-zero/workspace/teams/testclaude/.env

# 添加群聊 ID
FEISHU_GROUP_ID=your_group_id_here
```

### 4. 测试发送消息

```bash
# 测试发送普通消息
./scripts/feishu-chat.sh send "Hello from TestClaude!" "System"

# 测试 Agent 消息
./scripts/feishu-chat.sh agent orchestrator coding task_assignment \
  '{"task":"T001","description":"实现用户认证"}'

# 测试广播
./scripts/feishu-chat.sh broadcast orchestrator system_notification \
  "系统已启动"

# 测试任务状态
./scripts/feishu-chat.sh task T001 started "开始开发" "orchestrator"
```

## 📋 常用命令速查

### 发送消息
```bash
# 普通消息
./scripts/feishu-chat.sh send "消息内容" "发送者名称"

# Agent 间消息
./scripts/feishu-chat.sh agent <from> <to> <type> <content>

# 广播到所有 agent
./scripts/feishu-chat.sh broadcast <from> <type> <content>

# 任务状态更新
./scripts/feishu-chat.sh task <task-id> <status> <message> <agent>
```

### 消息类型
| 类型 | 说明 | 示例 |
|------|------|------|
| task_assignment | 任务分配 | `./scripts/feishu-chat.sh agent orchestrator coding task_assignment '{"task":"T001"}'` |
| task_completed | 任务完成 | `./scripts/feishu-chat.sh agent coding orchestrator task_completed "功能已实现"` |
| help_request | 请求帮助 | `./scripts/feishu-chat.sh agent coding reviewer help_request "需要审查PR"` |
| review_report | 审查报告 | `./scripts/feishu-chat.sh agent reviewer orchestrator review_report "代码质量良好"` |
| test_report | 测试报告 | `./scripts/feishu-chat.sh agent qa orchestrator test_report "测试通过率100%"` |
| security_alert | 安全警报 | `./scripts/feishu-chat.sh agent security all security_alert "发现漏洞"` |

## 🔄 集成到 Agent 工作流

### 在 A2A 通信中添加飞书通知

编辑 `scripts/lib/a2a.sh`，在 `send_to_agent` 函数中添加：

```bash
send_to_agent() {
    # ... 原有代码 ...
    
    # 发送到飞书群聊
    if [ -f "$TEAM_DIR/scripts/feishu-chat.sh" ]; then
        "$TEAM_DIR/scripts/feishu-chat.sh" agent \
            "$from_agent" "$to_agent" "$message_type" "$content" &
    fi
}
```

### 在 Agent 配置中添加飞书工具

```json
{
  "tools": [
    "send_feishu_message",
    "broadcast_feishu"
  ],
  "toolConfig": {
    "send_feishu_message": {
      "script": "scripts/feishu-chat.sh",
      "function": "send_agent_message",
      "description": "发送消息到飞书群聊"
    }
  }
}
```

## 🎯 完整协作示例

```bash
# 1. Orchestrator 分配任务
./scripts/feishu-chat.sh agent orchestrator coding task_assignment \
  '{"task":"T001","description":"实现登录API","priority":"high"}'

# 2. Coding Agent 开始开发
./scripts/feishu-chat.sh task T001 started "开始开发登录API" "coding"

# 3. Coding Agent 完成并请求审查
./scripts/feishu-chat.sh task T001 completed "登录API已实现" "coding"
./scripts/feishu-chat.sh agent coding reviewer help_request \
  "请审查登录API实现"

# 4. Reviewer 审查
./scripts/feishu-chat.sh agent reviewer orchestrator review_report \
  "代码质量良好，建议合并。发现2个minor问题已注释。"

# 5. QA 测试
./scripts/feishu-chat.sh agent qa orchestrator test_report \
  "测试通过率100%，覆盖率85%"

# 6. Security 扫描
./scripts/feishu-chat.sh agent security all security_alert \
  "依赖扫描: 0个漏洞"

# 7. DevOps 部署
./scripts/feishu-chat.sh agent devops orchestrator deployment_status \
  "已部署到staging环境"
```

## 🐛 故障排除

### Token 获取失败
```bash
# 检查 App ID 和 Secret 是否正确
cat .env | grep FEISHU_APP

# 检查应用是否启用
# 登录飞书开放平台确认应用状态
```

### 发送消息失败
```bash
# 检查群聊 ID 是否正确
# 确保应用已添加到群聊
# 检查应用是否有发送消息权限
```

### 权限不足
```bash
# 在飞书开放平台添加以下权限：
# - im:chat:write
# - im:message:send
# - im:message:readonly

# 添加后需要重新授权
```

## 📊 监控群聊消息

```bash
# 启动消息监听机器人
./scripts/feishu-chat.sh bot

# 当有人 @orchestrator 时自动触发任务
```

## ✅ 验证清单

- [ ] 飞书 App ID 和 Secret 已配置
- [ ] 应用已添加必要权限
- [ ] Token 获取成功
- [ ] 群聊已创建或已获取群聊 ID
- [ ] 测试消息发送成功
- [ ] Agent 消息格式正确
- [ ] 广播功能正常
- [ ] 任务状态更新正常

---

**当前状态**: ✅ API 连接成功，等待群聊配置后即可发送消息
