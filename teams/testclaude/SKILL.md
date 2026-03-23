---
name: testclaude-feishu-chat
description: |
  testclaude 团队的飞书群聊管理能力。当用户需要为 testclaude 团队创建飞书群聊、绑定 agent 到群聊、管理群成员时使用。
  触发词：testclaude 飞书、创建群聊、绑定 agent、添加群成员。
---

# testclaude 团队 - 飞书群聊集成

## 概述

为 testclaude 团队提供飞书群聊管理能力，让团队编排 agent 和编码 agent 可以通过飞书群聊接收任务、汇报结果。

## 核心组件

### 1. 飞书群聊管理脚本

位置: `scripts/feishu_chat_manager.py`

```bash
# 创建群聊
python3 scripts/feishu_chat_manager.py \
  --create-chat "testclaude 任务群" \
  --app-id <your_app_id> \
  --app-secret <your_app_secret> \
  --user-open-ids ou_xxx ou_yyy

# 绑定 agent 到群聊
python3 scripts/feishu_chat_manager.py \
  --bind orchestrator-agent oc_xxxxxx

# 列出所有 binding
python3 scripts/feishu_chat_manager.py --list

# 添加成员
python3 scripts/feishu_chat_manager.py \
  --add-member oc_xxxxxx ou_zzzzz \
  --app-id <app_id> --app-secret <app_secret>
```

### 2. 飞书群聊绑定配置

绑定后，群聊消息会自动路由到对应的 agent：

```json
{
  "bindings": [
    {
      "agentId": "orchestrator-agent",
      "match": {
        "channel": "feishu",
        "accountId": "default",
        "peer": {
          "kind": "group",
          "id": "oc_xxxxxx"
        }
      }
    }
  ]
}
```

## 工作流程集成

### 原工作流（纯本地）
```
用户 → 编排agent → 任务分解 → 启动编码agent → 收集结果
```

### 增加飞书后
```
飞书群聊消息 → 编排agent → 任务分解 → 启动编码agent → 结果汇报回群聊
```

## 使用场景

### 场景 1: 团队接入飞书群聊

```bash
# 1. 创建飞书群聊
python3 scripts/feishu_chat_manager.py \
  --create-chat "testclaude 开发团队" \
  --app-id cli_xxx --app-secret xxx \
  --user-open-ids ou_abc ou_def

# 2. 绑定编排 agent
python3 scripts/feishu_chat_manager.py \
  --bind orchestrator-agent oc_xxxxxx

# 3. 重启 gateway
openclaw gateway restart
```

### 场景 2: 飞书接收编码结果

编排 agent 收到飞书消息后，会自动：
1. 分解任务
2. 启动编码 agent
3. 等待结果
4. 将结果发回飞书群聊

### 场景 3: 多群聊隔离

不同团队可以有不同群聊，绑定不同 agent：

```bash
# 开发团队群 → 编排 agent
python3 scripts/feishu_chat_manager.py --bind orchestrator-agent oc_dev

# 代码审查群 → 编码 agent 直接接收
python3 scripts/feishu_chat_manager.py --bind coder-agent oc_review
```

## 配置要求

### 飞书应用权限

需要开通以下权限：
- `im:chat:create` - 创建群聊
- `im:chat:update` - 修改群信息
- `im:chat.members:write_only` - 管理成员

### OpenClaw 配置

确保 `openclaw.json` 中已配置飞书账号：

```json
{
  "channels": {
    "feishu": {
      "accounts": {
        "default": {
          "appId": "cli_xxx",
          "appSecret": "xxx"
        }
      }
    }
  }
}
```

## 故障排查

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| 创建群聊失败 | app_id/app_secret 错误 | 检查飞书应用凭证 |
| 绑定后无响应 | binding 未生效 | 重启 gateway: `openclaw gateway restart` |
| 群聊收不到消息 | groups 配置缺失 | 运行 `--bind` 自动添加 |
| 成员添加失败 | open_id 格式错误 | 确认 open_id 以 `ou_` 开头 |

## 相关资源

- 飞书群聊管理 skill: `~/openclaw-zero-token/skills/feishu-chat/SKILL.md`
- 跨 agent 通信: `~/openclaw-zero-token/skills/agent-comm/SKILL.md`
- 完整飞书多 Agent 示例: `~/feishu-multi-agent/`
