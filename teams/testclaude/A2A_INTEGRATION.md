# A2A 协议集成说明

## 📡 A2A 通信架构

所有 agent 现在支持 A2A (Agent-to-Agent) 协议，实现 agent 之间的消息交互。

### 消息流程
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Agent A     │────▶│   Queue     │────▶│ Agent B     │
│ (Sender)    │     │  (Storage)  │     │ (Receiver)  │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Inbox     │
                    │  (Process)  │
                    └─────────────┘
```

---

## 🎯 各 Agent 通信能力

### 1. Orchestrator Agent
**通信角色**: 中央协调者
**可以通信的对象**: 所有 agents
**消息类型**:
- 任务分配 (`task_assignment`)
- 状态查询 (`status_query`)
- 结果收集 (`result_collection`)

### 2. Coding Agent
**通信角色**: 执行者
**可以通信的对象**: Orchestrator, Reviewer
**消息类型**:
- 任务完成 (`task_completed`)
- 请求帮助 (`help_request`)
- 进度更新 (`progress_update`)

### 3. Reviewer Agent
**通信角色**: 审查者
**可以通信的对象**: Orchestrator, Coding
**消息类型**:
- 审查报告 (`review_report`)
- 问题反馈 (`issue_feedback`)
- 批准通知 (`approval_notification`)

### 4. QA Agent
**通信角色**: 测试者
**可以通信的对象**: Orchestrator
**消息类型**:
- 测试报告 (`test_report`)
- 覆盖率报告 (`coverage_report`)
- 缺陷报告 (`bug_report`)

### 5. Documentation Agent
**通信角色**: 文档者
**可以通信的对象**: Orchestrator
**消息类型**:
- 文档更新 (`doc_update`)
- API 变更 (`api_change`)
- 指南更新 (`guide_update`)

### 6. Security Agent
**通信角色**: 安全审计者
**可以通信的对象**: Orchestrator, Coding
**消息类型**:
- 安全警报 (`security_alert`)
- 漏洞报告 (`vulnerability_report`)
- 修复建议 (`fix_suggestion`)

### 7. DevOps Agent
**通信角色**: 运维者
**可以通信的对象**: Orchestrator
**消息类型**:
- 部署状态 (`deployment_status`)
- CI/CD 结果 (`ci_cd_result`)
- 环境状态 (`environment_status`)

---

## 📨 消息格式

```json
{
  "id": "msg_20260320_143022_12345_67890",
  "from": "orchestrator",
  "to": "coding",
  "type": "task_assignment",
  "content": {
    "taskId": "T001",
    "description": "实现用户认证功能",
    "priority": "high",
    "deadline": "2026-03-21T00:00:00Z"
  },
  "correlationId": "task_T001",
  "timestamp": "2026-03-20T14:30:22Z",
  "status": "pending"
}
```

---

## 🔧 使用示例

### 发送任务分配
```bash
# 在 Orchestrator 中
source scripts/lib/a2a.sh

send_task_assignment "coding" "T001" "实现用户认证功能" "orchestrator"
```

### 接收和处理消息
```bash
# 在 Coding Agent 中
source scripts/lib/a2a.sh

# 获取待处理消息
messages=$(receive_messages "coding")

# 处理消息
process_all_messages "coding" "handle_coding_message"
```

### 广播消息
```bash
# 向所有 agent 广播
broadcast_to_agents "system_notification" '{"message": "系统维护中"}' "orchestrator"
```

### 请求帮助
```bash
# Coding Agent 请求 Reviewer 帮助
send_help_request "reviewer" "code_review" "需要审查 PR #123" "coding"
```

### 响应请求
```bash
# Reviewer 响应
send_response "coding" "correlation_id" '{"review": "approved"}' "reviewer"
```

---

## 📁 消息存储

所有 A2A 消息存储在以下目录：

```
swarm/messages/
├── queue/      # 待处理消息队列
├── inbox/      # 已接收消息
├── outbox/     # 已发送消息
└── archive/    # 历史消息归档
```

---

## 🔄 Agent 配置更新

### 更新 communication 字段

在 `team-config.json` 中添加完整的通信矩阵：

```json
{
  "communication": {
    "protocol": "a2a",
    "messageQueue": "swarm/messages/",
    "agents": {
      "orchestrator": {
        "canSendTo": ["coding", "reviewer", "qa", "documentation", "security", "devops"],
        "canReceiveFrom": ["coding", "reviewer", "qa", "documentation", "security", "devops"]
      },
      "coding": {
        "canSendTo": ["orchestrator", "reviewer"],
        "canReceiveFrom": ["orchestrator", "reviewer"]
      },
      "reviewer": {
        "canSendTo": ["orchestrator", "coding"],
        "canReceiveFrom": ["orchestrator", "coding"]
      },
      "qa": {
        "canSendTo": ["orchestrator"],
        "canReceiveFrom": ["orchestrator"]
      },
      "documentation": {
        "canSendTo": ["orchestrator"],
        "canReceiveFrom": ["orchestrator"]
      },
      "security": {
        "canSendTo": ["orchestrator", "coding"],
        "canReceiveFrom": ["orchestrator"]
      },
      "devops": {
        "canSendTo": ["orchestrator"],
        "canReceiveFrom": ["orchestrator"]
      }
    }
  }
}
```

---

## 🧪 测试 A2A 通信

```bash
# 测试消息发送
cd ~/.openclaw-zero/workspace/teams/testclaude
source scripts/lib/a2a.sh

# 发送测试消息
send_to_agent "coding" "test" '{"message": "Hello from orchestrator"}' "orchestrator"

# 查看消息队列
ls -la swarm/messages/queue/

# 接收消息
receive_messages "coding"

# 查看消息历史
get_message_history "coding" 10
```

---

## 📊 消息类型枚举

| 消息类型 | 用途 | 发送者 | 接收者 |
|----------|------|--------|--------|
| `task_assignment` | 分配任务 | Orchestrator | Coding |
| `task_status` | 状态更新 | Coding | Orchestrator |
| `review_report` | 审查报告 | Reviewer | Orchestrator |
| `test_report` | 测试报告 | QA | Orchestrator |
| `security_alert` | 安全警报 | Security | Orchestrator, Coding |
| `doc_update` | 文档更新 | Documentation | Orchestrator |
| `deployment_status` | 部署状态 | DevOps | Orchestrator |
| `help_request` | 请求帮助 | 任何 Agent | 相关 Agent |
| `response` | 响应请求 | 任何 Agent | 请求者 |
| `broadcast` | 广播消息 | 任何 Agent | 所有 Agent |

---

## ✅ 集成验证

- [x] A2A 通信库已创建 (`scripts/lib/a2a.sh`)
- [x] 消息队列目录已初始化
- [x] 所有 agent 通信配置已更新
- [x] 消息格式已定义
- [x] 消息发送/接收函数已实现
- [x] 消息处理机制已实现
- [x] 历史记录功能已实现

**状态**: ✅ A2A 协议已完整集成到所有 agent
