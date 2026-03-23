# TestClaude Team - Agent 角色体系

## 📋 概述

TestClaude 团队现已配备完整的多 agent 开发流程，包含 **7 个专业 agent 角色**，覆盖从需求分析到部署的全流程。

## 🤖 Agent 角色清单

### 1. Orchestrator Agent (编排 Agent) - 保留
**角色**: 任务编排与项目管理  
**配置**: `orchestrator-config.json`  
**职责**:
- 任务分解和工作流协调
- 多 agent 调度和结果整合
- 生成结构化任务提示
- 监控整体进度

**通信**: 可以与所有其他 agents 通信

---

### 2. Coding Agent (编码 Agent) - 保留
**角色**: 代码实现专家  
**配置**: `coding-agent-config.json`  
**职责**:
- 功能实现和重构
- Bug 修复
- 代码优化
- 测试编写（基础）

**通信**: 可与 orchestrator 和 reviewer 通信

---

### 3. Reviewer Agent (审查 Agent) - 新增
**角色**: 代码审查与质量保证  
**配置**: `reviewer-config.json`  
**职责**:
- 代码质量审查
- 最佳实践验证
- 安全漏洞检测
- 性能分析
- 提供改进建议

**审查维度**:
- ✅ 代码质量和可读性
- ✅ 设计模式和架构
- ✅ 安全性检查
- ✅ 性能优化
- ✅ 测试覆盖

**输出**: 结构化的审查报告（critical/major/minor/suggestion）

---

### 4. QA Agent (测试 Agent) - 新增
**角色**: 质量保证与测试专家  
**配置**: `qa-config.json`  
**职责**:
- 编写单元测试、集成测试、E2E测试
- 执行测试套件
- 分析测试覆盖率
- 生成测试报告

**支持框架**:
- JavaScript/TypeScript: Jest, Mocha, Vitest
- Python: pytest
- Java: JUnit
- Go: testing

**质量目标**: 测试覆盖率 ≥ 80%

---

### 5. Documentation Agent (文档 Agent) - 新增
**角色**: 技术文档专家  
**配置**: `documentation-config.json`  
**职责**:
- 编写和更新 README
- 生成 API 文档
- 维护用户指南
- 增强代码注释

**文档类型**:
- 📖 README 和快速开始
- 📚 API 参考
- 🎯 用户指南
- 🛠️ 开发者文档
- 💡 最佳实践

---

### 6. Security Agent (安全 Agent) - 新增
**角色**: 安全与漏洞分析专家  
**配置**: `security-config.json`  
**职责**:
- 依赖漏洞扫描
- 代码安全审计
- 敏感信息检测
- 许可证合规检查

**扫描工具**:
- npm audit / yarn audit
- safety (Python)
- gitleaks (秘密检测)
- OWASP dependency-check

**漏洞等级**: Critical, High, Medium, Low

---

### 7. DevOps Agent (运维 Agent) - 新增
**角色**: CI/CD 与基础设施专家  
**配置**: `devops-config.json`  
**职责**:
- CI/CD 流水线配置
- Docker 容器化
- 部署脚本编写
- 环境管理

**CI/CD 平台**:
- GitHub Actions
- GitLab CI/CD
- Jenkins

**交付物**:
- `.github/workflows/*.yml`
- `Dockerfile`
- `docker-compose.yml`
- 部署脚本

---

## 🔄 工作流程

### 1. Feature Development (功能开发流程)
完整的端到端功能开发流程：

```
需求分析 (Orchestrator)
    ↓
任务分解 (Orchestrator)
    ↓
并行执行:
├─ 功能实现 (Coding Agent)
├─ 测试编写 (QA Agent)
├─ 文档更新 (Documentation Agent)
└─ 安全扫描 (Security Agent)
    ↓
代码审查 (Reviewer Agent)
    ↓
反馈处理 (Coding Agent)
    ↓
测试验证 (QA Agent)
    ↓
部署准备 (DevOps Agent)
```

### 2. Bug Fix (Bug修复流程)
```
Bug分析 (Orchestrator)
    ↓
修复实现 (Coding Agent)
    ↓
验证测试 (QA Agent)
    ↓
审查 (Reviewer Agent)
```

### 3. Code Review (代码审查流程)
```
审查请求 (Orchestrator)
    ↓
代码审查 (Reviewer Agent)
    ↓
反馈处理 (Coding Agent)
    ↓
重新测试 (QA Agent)
```

### 4. CI/CD Pipeline (CI/CD配置)
```
流水线设计 (Orchestrator)
    ↓
配置编写 (DevOps Agent)
    ↓
测试配置 (QA Agent)
    ↓
安全集成 (Security Agent)
```

### 5. Security Audit (安全审计)
```
审计启动 (Orchestrator)
    ↓
依赖扫描 (Security Agent)
    ↓
代码审计 (Security Agent)
    ↓
漏洞修复 (Coding Agent)
    ↓
验证 (QA Agent)
```

## 🛠️ 工具和脚本

### 核心脚本
| 脚本 | 用途 |
|------|------|
| `orchestrate-workflow.sh` | 主工作流编排器 |
| `spawn-agent.sh` | 启动 agent |
| `check-agents.sh` | 监控 agent 状态 |
| `cleanup-agents.sh` | 清理已完成任务 |
| `respawn-agent.sh` | 重启失败 agent |
| `generate-prompt.sh` | 生成任务提示 |
| `github-webhook-listener.sh` | GitHub webhook 监听 |
| `wait-for-ci.sh` | CI 状态等待 |
| `notify.sh` | 通知系统 |
| `review-pr.sh` | PR 审查 |
| `check-pr-status.sh` | PR 状态检查 |

### 工作流命令示例

```bash
# 启动功能开发
./scripts/orchestrate-workflow.sh feature-development \
  "Add user authentication with JWT" \
  --repo owner/repo

# 启动 Bug 修复
./scripts/orchestrate-workflow.sh bug-fix \
  "Fix login timeout issue" \
  --repo owner/repo \
  --branch fix/login-timeout

# 执行代码审查
./scripts/orchestrate-workflow.sh code-review \
  "Review PR #123" \
  --repo owner/repo \
  --branch feature/auth

# 安全审计
./scripts/orchestrate-workflow.sh security-audit \
  "Full security audit" \
  --repo owner/repo

# 配置 CI/CD
./scripts/orchestrate-workflow.sh ci-cd-pipeline \
  "Setup GitHub Actions" \
  --repo owner/repo
```

## 📊 监控和管理

### 检查所有 agent 状态
```bash
./scripts/check-agents.sh
```

### 查看活跃任务
```bash
cat swarm/active-tasks.json | jq '.tasks[] | {id, type, status, startTime}'
```

### 查看特定 agent 日志
```bash
tmux attach -t swarm-[task-id]
# 或
tail -f swarm/logs/[task-id]-*.log
```

### 清理已完成任务
```bash
./scripts/cleanup-agents.sh
```

### 重启失败任务
```bash
./scripts/respawn-agent.sh [task-id]
```

## 🔌 集成能力

### GitHub Webhook 集成
- 自动监听 PR 事件
- 实时跟踪 CI 状态
- 自动触发审查流程

### 通知渠道
- Discord
- Slack
- 自定义 webhook
- 本地队列（fallback）

### CI/CD 集成
- GitHub Actions
- 自动等待 CI 完成
- CI 失败自动重试

## 📈 扩展性

### 添加新的 Agent 角色
1. 创建新的配置文件（如 `new-agent-config.json`）
2. 在 `team-config.json` 中添加 agent 定义
3. 配置通信权限
4. 更新 orchestrator 的 `canSendTo` 列表

### 添加新的工作流
1. 在 `team-config.json` 的 `workflows` 中添加新工作流定义
2. 在 `orchestrate-workflow.sh` 中添加对应的执行函数
3. 测试新工作流

## 🎯 最佳实践

1. **任务分解**: 将复杂任务拆分为小的、独立的子任务
2. **并行执行**: 充分利用多个 agent 并行工作
3. **监控优先**: 定期运行 `check-agents.sh` 监控状态
4. **自动清理**: 配置 cron 定期清理已完成任务
5. **通知配置**: 至少配置一个通知渠道接收实时更新
6. **安全第一**: 始终运行安全审计，尤其是依赖更新

## 📚 相关文档

- [团队配置](team-config.json) - Agent 角色定义
- [Webhook 快速入门](WEBHOOK_QUICKSTART.md) - GitHub webhook 设置
- [完整设置文档](GITHUB_WEBHOOK_SETUP.md) - 详细配置指南
- [Orchestrator 配置](orchestrator-config.json) - 编排器详细配置

## 🚀 下一步

1. **配置通知渠道**: 设置 Discord/Slack webhook
2. **启用 GitHub webhook**: 在仓库中添加 webhook 配置
3. **测试工作流**: 运行一个示例功能开发
4. **监控日志**: 观察 agent 协作过程
5. **优化配置**: 根据实际使用调整超时和重试参数

---

**状态**: ✅ 所有 7 个 agent 角色已配置完成  
**版本**: 2.0.0  
**最后更新**: 2026-03-20
