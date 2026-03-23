# Agent 工具库能力清单

## 📚 lib 目录结构

```
scripts/lib/
├── common.sh          # 公共基础函数库
├── github.sh          # GitHub API 操作库
├── notify.sh          # 多平台通知库
└── agent-tools.sh     # Agent 专用工具库
```

---

## 🔧 公共函数库 (common.sh)

### 日志函数
| 函数 | 说明 |
|------|------|
| `log_info` | 信息日志 (蓝色) |
| `log_success` | 成功日志 (绿色) |
| `log_warning` | 警告日志 (黄色) |
| `log_error` | 错误日志 (红色) |
| `log_debug` | 调试日志 (黄色，需 DEBUG=1) |

### 配置管理
| 函数 | 说明 |
|------|------|
| `load_config` | 加载 .env 配置 |

### 任务注册表操作
| 函数 | 说明 |
|------|------|
| `get_task_registry` | 获取任务注册表路径 |
| `add_task` | 添加新任务 |
| `update_task_status` | 更新任务状态 |
| `get_task` | 获取任务详情 |

### Git 操作
| 函数 | 说明 |
|------|------|
| `get_repo_info` | 获取仓库信息 |
| `create_branch` | 创建分支 |

### 通知
| 函数 | 说明 |
|------|------|
| `send_notification` | 发送通知 |

### 工具函数
| 函数 | 说明 |
|------|------|
| `get_timestamp` | 获取时间戳 |
| `get_elapsed` | 计算耗时 |
| `ensure_dir` | 确保目录存在 |
| `write_file` | 写入文件 |
| `read_file` | 读取文件 |
| `validate_url` | 验证 URL |
| `validate_repo` | 验证仓库名 |
| `wait_for_condition` | 等待条件满足 |

---

## 🐙 GitHub 操作库 (github.sh)

### 认证检查
| 函数 | 说明 |
|------|------|
| `check_gh` | 检查 gh CLI 和认证 |

### PR 操作
| 函数 | 说明 |
|------|------|
| `get_pr_info` | 获取 PR 信息 |
| `get_pr_status` | 获取 PR 状态 |
| `create_pr` | 创建 PR |
| `add_pr_comment` | 添加 PR 评论 |
| `review_pr` | 审查 PR (APPROVE/REQUEST_CHANGES/COMMENT) |
| `merge_pr` | 合并 PR |
| `get_prs` | 列出 PR |

### CI 操作
| 函数 | 说明 |
|------|------|
| `get_ci_status` | 获取 CI 状态 |

### 仓库操作
| 函数 | 说明 |
|------|------|
| `get_repo_details` | 获取仓库详情 |
| `get_latest_commit` | 获取最新 commit |

---

## 📢 通知库 (notify.sh)

### 平台支持
| 函数 | 平台 | 配置变量 |
|------|------|----------|
| `send_discord` | Discord | DISCORD_WEBHOOK_URL |
| `send_slack` | Slack | SLACK_WEBHOOK_URL |
| `send_telegram` | Telegram | TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID |
| `send_wechat` | 企业微信 | WECHAT_WEBHOOK_URL |
| `send_dingtalk` | 钉钉 | DINGTALK_WEBHOOK_URL |
| `send_feishu` | 飞书 | FEISHU_WEBHOOK_URL |

### 综合函数
| 函数 | 说明 |
|------|------|
| `send_to_all` | 发送到所有配置的渠道 |
| `send_task_notification` | 发送任务状态通知 |

---

## 🤖 Agent 专用工具库 (agent-tools.sh)

### Orchestrator Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `decompose_task` | 分解任务 | 任务规划阶段 |
| `assign_task_to_agent` | 分配任务给 agent | 任务调度 |
| `monitor_agents` | 监控所有 agent | 状态检查 |

### Reviewer Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `generate_review_report` | 生成审查报告 | 代码审查完成 |
| `add_review_comment` | 添加审查评论 | PR 评论 |

### QA Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `run_tests` | 运行测试 | 测试执行 |
| `generate_test_report` | 生成测试报告 | 测试完成 |

### Security Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `run_security_scan` | 运行安全扫描 | 安全审计 |

### Documentation Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `generate_readme` | 生成 README | 文档创建 |

### DevOps Agent 工具
| 函数 | 说明 | 使用场景 |
|------|------|----------|
| `generate_github_workflow` | 生成 GitHub Actions | CI/CD 配置 |
| `generate_dockerfile` | 生成 Dockerfile | 容器化 |

---

## 🎯 在 Agent 配置中使用

### 为 Orchestrator Agent 添加工具

在 `orchestrator-config.json` 中：

```json
{
  "tools": [
    "spawn-agent",
    "check-agents",
    "decompose_task",
    "assign_task_to_agent",
    "monitor_agents"
  ],
  "toolConfig": {
    "decompose_task": {
      "description": "将复杂任务分解为子任务",
      "usage": "decompose_task <task-description> [output-file]"
    },
    "assign_task_to_agent": {
      "description": "分配任务给指定的 agent",
      "usage": "assign_task_to_agent <agent-type> <task-id> <description>"
    }
  }
}
```

### 为 Reviewer Agent 添加工具

```json
{
  "tools": [
    "generate_review_report",
    "add_review_comment",
    "get_pr_info",
    "review_pr"
  ],
  "toolConfig": {
    "generate_review_report": {
      "description": "生成代码审查报告",
      "usage": "generate_review_report <repo> <pr-number> [output-file]"
    }
  }
}
```

### 为 QA Agent 添加工具

```json
{
  "tools": [
    "run_tests",
    "generate_test_report"
  ],
  "toolConfig": {
    "run_tests": {
      "description": "运行测试套件",
      "usage": "run_tests <project-dir> [test-type]"
    }
  }
}
```

---

## 📦 使用示例

### 在脚本中加载库

```bash
#!/bin/bash

# 加载公共库
source "$(dirname "$0")/lib/common.sh"

# 加载 GitHub 库
source "$(dirname "$0")/lib/github.sh"

# 加载通知库
source "$(dirname "$0")/lib/notify.sh"

# 加载 Agent 工具
source "$(dirname "$0")/lib/agent-tools.sh"

# 使用函数
load_config
log_info "Starting task..."

# 创建 PR
create_pr "owner/repo" "Feature" "Description" "feature-branch"

# 发送通知
send_notification "discord" "Task completed" --title "Success"
```

### 在 Agent 中使用

```bash
# Orchestrator 分解任务
decompose_task "Implement user authentication" tasks.json

# 分配任务
assign_task_to_agent "coding" "T001" "Implement login API"

# 监控进度
monitor_agents

# Reviewer 生成报告
generate_review_report "owner/repo" "123" review.md

# QA 运行测试
run_tests "/path/to/project" "unit"

# Security 扫描
run_security_scan "/path/to/project" "all"

# DevOps 生成配置
generate_github_workflow "CI" .github/workflows/ci.yml
generate_dockerfile Dockerfile
```

---

## ✅ 能力分配总结

| Agent | 新增工具 | 来源库 |
|-------|----------|--------|
| **Orchestrator** | decompose_task, assign_task_to_agent, monitor_agents | agent-tools.sh |
| **Coding Agent** | create_branch, get_repo_info | common.sh, github.sh |
| **Reviewer Agent** | generate_review_report, add_review_comment, review_pr | agent-tools.sh, github.sh |
| **QA Agent** | run_tests, generate_test_report | agent-tools.sh |
| **Documentation Agent** | generate_readme | agent-tools.sh |
| **Security Agent** | run_security_scan | agent-tools.sh |
| **DevOps Agent** | generate_github_workflow, generate_dockerfile | agent-tools.sh |
| **所有 Agent** | log_*, send_notification, get_task, update_task_status | common.sh, notify.sh |

---

**状态**: ✅ 所有库已创建并可用  
**位置**: `~/.openclaw-zero/workspace/teams/testclaude/scripts/lib/`  
**下一步**: 在各 agent 配置中添加对应的工具声明
