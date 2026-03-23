# Agent 工具集成清单

## 📊 当前状态分析

### 现有工具配置

| Agent | 现有工具 | 缺失的 lib 功能 |
|-------|----------|------------------|
| **Orchestrator** | spawn-agent, check-agents, cleanup-agents, respawn-agent, generate-prompt, exec, sessions_send, sessions_spawn | decompose_task, assign_task_to_agent, monitor_agents |
| **Coding Agent** | (未配置) | create_branch, get_repo_info, create_pr, get_pr_info |
| **Reviewer Agent** | (未配置) | generate_review_report, add_review_comment, review_pr, get_pr_info |
| **QA Agent** | (未配置) | run_tests, generate_test_report |
| **Documentation Agent** | (未配置) | generate_readme |
| **Security Agent** | (未配置) | run_security_scan |
| **DevOps Agent** | (未配置) | generate_github_workflow, generate_dockerfile |

---

## 🔧 需要添加的工具

### 1. Orchestrator Agent 新增工具

在 `orchestrator-config.json` 的 `tools` 数组中添加：
```json
"decompose_task",
"assign_task_to_agent", 
"monitor_agents"
```

在 `toolConfig` 中添加：
```json
"decompose_task": {
  "script": "scripts/lib/agent-tools.sh",
  "function": "decompose_task",
  "description": "将复杂任务分解为子任务",
  "parameters": ["task-description", "output-file"],
  "usage": "decompose_task <task-description> [output-file]"
},
"assign_task_to_agent": {
  "script": "scripts/lib/agent-tools.sh",
  "function": "assign_task_to_agent",
  "description": "分配任务给指定的 agent",
  "parameters": ["agent-type", "task-id", "description"],
  "usage": "assign_task_to_agent <agent-type> <task-id> <description>"
},
"monitor_agents": {
  "script": "scripts/lib/agent-tools.sh",
  "function": "monitor_agents",
  "description": "监控所有 agent 进度",
  "parameters": [],
  "usage": "monitor_agents"
}
```

### 2. Coding Agent 新增工具

创建或更新 `coding-agent-config.json`，添加：
```json
{
  "tools": [
    "create_branch",
    "get_repo_info", 
    "create_pr",
    "get_pr_info",
    "get_latest_commit"
  ],
  "toolConfig": {
    "create_branch": {
      "script": "scripts/lib/common.sh",
      "function": "create_branch",
      "description": "创建 Git 分支",
      "usage": "create_branch <repo> <branch> [base]"
    },
    "create_pr": {
      "script": "scripts/lib/github.sh",
      "function": "create_pr",
      "description": "创建 Pull Request",
      "usage": "create_pr <repo> <title> <body> <head> [base]"
    }
  }
}
```

### 3. Reviewer Agent 新增工具

创建 `reviewer-config.json`：
```json
{
  "tools": [
    "generate_review_report",
    "add_review_comment",
    "review_pr",
    "get_pr_info",
    "get_pr_status"
  ],
  "toolConfig": {
    "generate_review_report": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "generate_review_report",
      "description": "生成代码审查报告",
      "usage": "generate_review_report <repo> <pr-number> [output-file]"
    },
    "review_pr": {
      "script": "scripts/lib/github.sh",
      "function": "review_pr",
      "description": "审查 PR",
      "usage": "review_pr <repo> <pr-number> <review-type> <body>"
    }
  }
}
```

### 4. QA Agent 新增工具

创建 `qa-config.json`：
```json
{
  "tools": [
    "run_tests",
    "generate_test_report"
  ],
  "toolConfig": {
    "run_tests": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "run_tests",
      "description": "运行测试套件",
      "usage": "run_tests <project-dir> [test-type]"
    },
    "generate_test_report": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "generate_test_report",
      "description": "生成测试报告",
      "usage": "generate_test_report <project-dir> [output-file]"
    }
  }
}
```

### 5. Documentation Agent 新增工具

创建 `documentation-config.json`：
```json
{
  "tools": [
    "generate_readme"
  ],
  "toolConfig": {
    "generate_readme": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "generate_readme",
      "description": "生成 README 文档",
      "usage": "generate_readme <project-name> <description> [output-file]"
    }
  }
}
```

### 6. Security Agent 新增工具

创建 `security-config.json`：
```json
{
  "tools": [
    "run_security_scan"
  ],
  "toolConfig": {
    "run_security_scan": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "run_security_scan",
      "description": "运行安全扫描",
      "usage": "run_security_scan <project-dir> [scan-type]"
    }
  }
}
```

### 7. DevOps Agent 新增工具

创建 `devops-config.json`：
```json
{
  "tools": [
    "generate_github_workflow",
    "generate_dockerfile"
  ],
  "toolConfig": {
    "generate_github_workflow": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "generate_github_workflow",
      "description": "生成 GitHub Actions 工作流",
      "usage": "generate_github_workflow <workflow-name> [output-file]"
    },
    "generate_dockerfile": {
      "script": "scripts/lib/agent-tools.sh",
      "function": "generate_dockerfile",
      "description": "生成 Dockerfile",
      "usage": "generate_dockerfile [output-file]"
    }
  }
}
```

---

## 📋 公共工具 (所有 Agent 共享)

### 日志函数
所有 agent 都可以使用：
- `log_info`, `log_success`, `log_warning`, `log_error`, `log_debug`

### 通知函数
所有 agent 都可以使用：
- `send_notification`, `send_task_notification`

### 任务管理
所有 agent 都可以使用：
- `get_task`, `update_task_status`

---

## 🔄 集成步骤

### Step 1: 更新 Orchestrator 配置
```bash
cd ~/.openclaw-zero/workspace/teams/testclaude

# 备份原配置
cp orchestrator-config.json orchestrator-config.json.bak

# 添加新工具到 tools 数组
jq '.tools += ["decompose_task", "assign_task_to_agent", "monitor_agents"]' orchestrator-config.json > tmp.json && mv tmp.json orchestrator-config.json

# 添加 toolConfig
jq '.toolConfig.decompose_task = {
  "script": "scripts/lib/agent-tools.sh",
  "function": "decompose_task",
  "description": "将复杂任务分解为子任务",
  "parameters": ["task-description", "output-file"],
  "usage": "decompose_task <task-description> [output-file]"
}' orchestrator-config.json > tmp.json && mv tmp.json orchestrator-config.json
```

### Step 2: 创建/更新各 Agent 配置
```bash
# Coding Agent
cat > coding-agent-config.json << 'EOF'
{
  "name": "Coding Agent",
  "tools": ["create_branch", "get_repo_info", "create_pr", "get_pr_info", "get_latest_commit"],
  "toolConfig": {
    "create_branch": {
      "script": "scripts/lib/common.sh",
      "function": "create_branch"
    },
    "create_pr": {
      "script": "scripts/lib/github.sh",
      "function": "create_pr"
    }
  }
}
EOF
```

---

## ✅ 验证清单

- [ ] Orchestrator 已添加 decompose_task, assign_task_to_agent, monitor_agents
- [ ] Coding Agent 已添加 Git 和 PR 操作工具
- [ ] Reviewer Agent 已添加审查工具
- [ ] QA Agent 已添加测试工具
- [ ] Documentation Agent 已添加文档生成工具
- [ ] Security Agent 已添加安全扫描工具
- [ ] DevOps Agent 已添加 CI/CD 配置工具

---

## 📊 能力覆盖总结

| 功能类别 | 是否具备 | 覆盖 Agent |
|----------|----------|------------|
| 任务分解 | ✅ | Orchestrator |
| 任务分配 | ✅ | Orchestrator |
| 状态监控 | ✅ | Orchestrator |
| Git 分支管理 | ✅ | Coding Agent |
| PR 创建/管理 | ✅ | Coding, Reviewer |
| 代码审查 | ✅ | Reviewer |
| 测试执行 | ✅ | QA |
| 测试报告 | ✅ | QA |
| 文档生成 | ✅ | Documentation |
| 安全扫描 | ✅ | Security |
| CI/CD 配置 | ✅ | DevOps |
| Docker 配置 | ✅ | DevOps |
| 日志系统 | ✅ | 所有 Agent |
| 通知系统 | ✅ | 所有 Agent |
| 任务管理 | ✅ | 所有 Agent |

**状态**: 所有 lib 功能已识别，待集成到各 Agent 配置中
