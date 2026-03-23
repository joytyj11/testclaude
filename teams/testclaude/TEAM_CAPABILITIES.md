# TestClaude 团队能力全景图

**版本**: v3.0 | **更新**: 2026-03-23

---

## 📊 能力总览

| 类别 | 能力项 | 工具/脚本 | 状态 |
|------|--------|----------|------|
| **代码协作** | GitHub 集成 | `gh` CLI | ✅ |
| | Issue 管理 | `gh issue` | ✅ |
| | PR 管理 | `gh pr` | ✅ |
| | CI/CD | GitHub Actions | ✅ |
| **文档处理** | Feishu 文档 | `feishu_doc` | ⚠️ 只读 |
| | Feishu 知识库 | `feishu_wiki` | ✅ |
| | 本地文档 | Markdown | ✅ |
| **自动化** | 浏览器控制 | `browser` | ✅ |
| | 命令执行 | `exec` | ✅ |
| | 进程管理 | `process` | ✅ |
| | 定时任务 | HEARTBEAT.md | ⚠️ 待配置 |
| **智能分析** | 图像识别 | `image` | ✅ |
| | PDF 分析 | `pdf` | ✅ |
| | 网页抓取 | `web_fetch` | ✅ |
| | 网络搜索 | `web_search` | ❌ 需 API |
| **Agent 编排** | 子代理启动 | `sessions_spawn` | ✅ |
| | 任务分配 | `subagents` | ✅ |
| | 编码代理 | ACP (Claude Code) | ⚠️ 需配置 |
| | 跨会话通信 | `sessions_send` | ✅ |
| **脚本库** | 任务分发 | `dispatch.sh` | ✅ |
| | PR 管理 | 5+ 脚本 | ✅ |
| | 测试执行 | 8+ 脚本 | ✅ |
| | 通知监控 | 6+ 脚本 | ✅ |
| | Agent 管理 | 5+ 脚本 | ✅ |
| | 扫描分析 | 5+ 脚本 | ✅ |
| **技能库** | GitHub 审查 | `github-review` | ✅ |
| | Feishu 通知 | `feishu-notify` | ✅ |
| | 自动测试 | `auto-test` | ✅ |

---

## 📁 Scripts 详细能力 (47个)

### 1. 任务编排 (5个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `dispatch.sh` | 任务分发器 | `./dispatch.sh --task "审查 PR"` |
| `queue-task.sh` | 任务入队 | `./queue-task.sh --add "测试"` |
| `list-queue.sh` | 查看队列 | `./list-queue.sh` |
| `cancel-task.sh` | 取消任务 | `./cancel-task.sh --id 123` |
| `orchestrate-workflow.sh` | 工作流编排 | `./orchestrate-workflow.sh` |

### 2. PR 管理 (6个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `create-pr.sh` | 创建 PR | `./create-pr.sh --title "feat"` |
| `review-pr.sh` | 审查 PR | `./review-pr.sh --pr 2` |
| `check-pr-status.sh` | 查看状态 | `./check-pr-status.sh --pr 2` |
| `check-all-prs.sh` | 批量查看 | `./check-all-prs.sh` |
| `merge-pr.sh` | 合并 PR | `./merge-pr.sh --pr 2` |
| `wait-for-ci.sh` | 等待 CI | `./wait-for-ci.sh` |

### 3. 测试执行 (8个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `test-all-fixes.sh` | 全量测试 | `./test-all-fixes.sh` |
| `test-monitor.sh` | 监控测试 | `./test-monitor.sh` |
| `test-spawn-dryrun.sh` | 试运行 | `./test-spawn-dryrun.sh` |
| `test-scanners.sh` | 扫描器测试 | `./test-scanners.sh` |
| `test-prod.sh` | 生产测试 | `./test-prod.sh` |
| `test-fixes.sh` | 修复测试 | `./test-fixes.sh` |
| `test-registry-integration.sh` | 集成测试 | `./test-registry-integration.sh` |
| `test-screenshot-workflow.sh` | 截图测试 | `./test-screenshot-workflow.sh` |

### 4. 通知与监控 (6个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `notify.sh` | 发送通知 | `./notify.sh --message "完成"` |
| `channel-notify.sh` | 多渠道通知 | `./channel-notify.sh --channel all` |
| `notify-all-channels.sh` | 全渠道通知 | `./notify-all-channels.sh` |
| `feishu-chat.sh` | Feishu 聊天 | `./feishu-chat.sh --send "消息"` |
| `feishu_chat_manager.py` | Feishu 管理 | `python3 feishu_chat_manager.py` |
| `task-status-monitor.sh` | 任务监控 | `./task-status-monitor.sh` |

### 5. Agent 管理 (5个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `spawn-agent.sh` | 启动 Agent | `./spawn-agent.sh --agent coding` |
| `spawn-agent-openclaw.sh` | OpenClaw Agent | `./spawn-agent-openclaw.sh` |
| `respawn-agent.sh` | 重启 Agent | `./respawn-agent.sh --id 123` |
| `cleanup-agents.sh` | 清理 Agent | `./cleanup-agents.sh` |
| `check-agents.sh` | 检查状态 | `./check-agents.sh` |

### 6. 扫描与分析 (5个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `scan-all.sh` | 全量扫描 | `./scan-all.sh` |
| `scan-deps.sh` | 依赖扫描 | `./scan-deps.sh` |
| `scan-issues.sh` | Issue 扫描 | `./scan-issues.sh` |
| `scan-repos.sh` | 仓库扫描 | `./scan-repos.sh` |
| `scan-todos.sh` | TODO 扫描 | `./scan-todos.sh` |

### 7. 其他工具 (12个)
| 脚本 | 功能 | 示例 |
|------|------|------|
| `monitor.sh` | 系统监控 | `./monitor.sh` |
| `swarm-status.sh` | Swarm 状态 | `./swarm-status.sh` |
| `generate-prompt.sh` | 生成提示词 | `./generate-prompt.sh` |
| `generate-prompt-interactive.sh` | 交互式提示 | `./generate-prompt-interactive.sh` |
| `github-webhook-listener.sh` | Webhook 监听 | `./github-webhook-listener.sh` |
| `github-webhook.service` | systemd 服务 | `systemctl start github-webhook` |
| `test-feishu.sh` | Feishu 测试 | `./test-feishu.sh` |
| `test_integration.py` | 集成测试 | `python3 test_integration.py` |
| `test_feishu_api.py` | API 测试 | `python3 test_feishu_api.py` |

---

## 🧩 Skills 详细能力 (3个)

### 1. github-review
**位置**: `skills/github-review/`

| 能力 | 触发条件 | 输出 |
|------|----------|------|
| 代码规范检查 | PR 创建 | 格式问题列表 |
| 测试覆盖率 | PR 更新 | 覆盖率报告 |
| 安全扫描 | 自动 | 漏洞清单 |
| 性能影响分析 | 可选 | 性能评估 |

**调用方式**:
```yaml
# 自动触发
# 或手动
sessions_spawn task="审查 PR #2" runtime="subagent"
```

### 2. feishu-notify
**位置**: `skills/feishu-notify/`

| 能力 | 触发条件 | 输出 |
|------|----------|------|
| 文本消息 | 测试完成 | Feishu 消息 |
| 富文本卡片 | PR 合并 | 卡片消息 |
| @提及 | 紧急事件 | @指定成员 |
| 批量通知 | 定时任务 | 汇总报告 |

**调用方式**:
```bash
./scripts/notify.sh --message "测试通过 ✅"
```

### 3. auto-test
**位置**: `skills/auto-test/`

| 能力 | 触发条件 | 输出 |
|------|----------|------|
| 单元测试 | 代码提交 | 测试结果 |
| 集成测试 | PR 创建 | 集成报告 |
| 覆盖率收集 | 测试后 | coverage.xml |
| 结果分析 | 测试完成 | 失败分析 |

**调用方式**:
```bash
./scripts/test-all-fixes.sh --type unit
```

---

## 🔧 OpenClaw 原生工具能力

| 类别 | 工具 | 功能 |
|------|------|------|
| 文件 | `read`/`write`/`edit` | 文件操作 |
| 命令 | `exec`/`process` | 命令执行 |
| 通信 | `message` | 消息发送 |
| 浏览器 | `browser` | 自动化 |
| 智能 | `image`/`pdf` | 分析 |
| 代理 | `sessions_spawn`/`subagents` | Agent 编排 |
| 记忆 | `memory_search`/`memory_get` | 记忆系统 |
| Feishu | `feishu_doc`/`feishu_wiki`/`feishu_chat` | 飞书集成 |

---

## 📊 能力成熟度

| 类别 | 完成度 | 说明 |
|------|--------|------|
| 代码协作 | 95% | GitHub 全功能，缺 Webhook 自动响应 |
| 文档处理 | 60% | 只读为主，缺写入权限 |
| 自动化 | 85% | 浏览器/命令完善，缺定时任务 |
| 智能分析 | 90% | 图像/PDF 完善，缺网络搜索 |
| Agent 编排 | 75% | subagent 可用，缺 ACP 配置 |
| 脚本库 | 100% | 47 个脚本覆盖全场景 |
| 技能库 | 80% | 3 个核心技能，可扩展 |
| **总体** | **85%** | 核心能力完整 |

---

## 🎯 快速调用索引

| 需求 | 调用方式 |
|------|----------|
| 创建 Issue | `gh issue create` |
| 创建 PR | `./scripts/create-pr.sh` |
| 审查 PR | `./scripts/review-pr.sh` |
| 运行测试 | `./scripts/test-all-fixes.sh` |
| 发送通知 | `./scripts/notify.sh` |
| 启动 Agent | `./scripts/spawn-agent.sh` |
| 查看状态 | `./scripts/swarm-status.sh` |
| Feishu 消息 | `message channel=feishu` |
| 浏览器自动化 | `browser action=open` |
| 图像分析 | `image prompt="描述"` |

---

**文档位置**: `teams/testclaude/TEAM_CAPABILITIES.md`
