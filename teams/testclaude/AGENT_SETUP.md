# TestClaude Agent 配置指南

## 快速配置

### 1. 配置 OpenClaw Agent 白名单

编辑 `~/.config/openclaw/config.yaml` 或运行:

```bash
openclaw config set agents.allowed '["coding-agent", "codex", "claude-code"]'
```

### 2. 配置 ACP 运行时

```bash
openclaw config set acp.defaultAgent "claude-code"
openclaw config set acp.allowedAgents '["claude-code", "codex"]'
```

### 3. 验证配置

```bash
# 查看可用 Agent
agents_list

# 应该看到配置的 Agent 列表
```

---

## 测试 Subagent

### 启动简单任务

```typescript
sessions_spawn({
  task: "列出当前目录所有 Markdown 文件",
  runtime: "subagent",
  mode: "run"
})
```

### 启动持久会话

```typescript
sessions_spawn({
  task: "准备就绪，等待指令",
  runtime: "subagent",
  mode: "session",
  label: "test-helper"
})
```

### 管理 Subagent

```typescript
// 查看运行中的
subagents({ action: "list" })

// 发送指令
subagents({ 
  action: "steer", 
  target: "test-helper", 
  message: "运行测试套件" 
})

// 终止
subagents({ action: "kill", target: "test-helper" })
```

---

## 测试 ACP Agent

### 启动 Claude Code

```typescript
sessions_spawn({
  task: "分析当前代码结构",
  runtime: "acp",
  agentId: "claude-code",
  mode: "session",
  thread: true
})
```

### 查看 ACP 会话

```typescript
sessions_list({ kinds: ["acp"] })
```

---

## 集成测试

### 完整测试流程

```bash
# 1. 创建测试任务
git checkout -b test/agent-flow

# 2. 启动 Subagent 自动测试
sessions_spawn task="
  python3 -m pytest --collect-only
  如果找到测试，运行并生成报告
" runtime="subagent"

# 3. 启动 ACP Agent 修复问题
sessions_spawn task="
  修复测试失败的问题
  确保所有测试通过
" runtime="acp" agentId="claude-code"

# 4. 提交结果
git add .
git commit -m "test: agent flow"
git push
```

---

## 故障排查

### Subagent 不启动

```bash
# 检查配置
openclaw config get agents.allowed

# 查看日志
tail -f /home/administrator/.openclaw-zero/logs/openclaw.log
```

### ACP Agent 连接失败

```bash
# 检查 Claude Code 是否安装
which claude

# 测试 Claude Code
claude --version
```

### 权限问题

```bash
# 确保工作目录可写
chmod -R 755 /home/administrator/.openclaw-zero/workspace
```

---

## 下一步

1. ✅ 完成配置
2. ⬜ 测试 Subagent 启动
3. ⬜ 测试 ACP Agent 启动
4. ⬜ 集成到 GitHub Actions
5. ⬜ 创建自定义 Skill

**需要帮助?** 运行 `openclaw help` 或查阅文档
