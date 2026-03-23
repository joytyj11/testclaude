# testclaude 团队脚本

## feishu_chat_manager.py

飞书群聊管理工具，为 testclaude 团队提供：
- 创建群聊
- 管理成员
- 配置 binding

### 快速使用

```bash
# 给脚本添加执行权限
chmod +x scripts/feishu_chat_manager.py

# 查看帮助
python3 scripts/feishu_chat_manager.py -h

# 列出当前 binding
python3 scripts/feishu_chat_manager.py --list

# 绑定 agent 到群聊
python3 scripts/feishu_chat_manager.py --bind orchestrator-agent oc_xxxxxx

# 创建新群聊并绑定
python3 scripts/feishu_chat_manager.py \
  --create-chat "testclaude 开发群" \
  --app-id cli_xxx \
  --app-secret xxx \
  --user-open-ids ou_abc
```

### 典型工作流

1. **创建飞书群聊**
2. **绑定编排 agent**
3. **重启 gateway**
4. **在群聊中发送任务**

编排 agent 会自动接收飞书消息，分解任务并启动编码 agent。

## 原有脚本（团队协作）

以下脚本由 swarm 框架提供，用于任务管理：

- `generate-prompt.sh` - 生成编码任务提示
- `spawn-agent.sh` - 启动编码 agent
- `check-agents.sh` - 监控 agent 状态
- `cleanup-agents.sh` - 清理已完成任务
- `respawn-agent.sh` - 重启失败任务

这些脚本的完整路径：
```
/home/administrator/openclaw-zero-token/.openclaw-upstream-state/swarm/scripts/
```

## 集成说明

飞书群聊管理脚本独立于原有任务管理脚本，两者可以配合使用：

1. 飞书脚本负责通信渠道
2. 原有脚本负责任务编排
3. 编排 agent 连接两者

编排 agent 需要：
- 监听飞书消息（通过 binding）
- 调用 spawn-agent.sh 启动编码 agent
- 将结果发回飞书群聊
