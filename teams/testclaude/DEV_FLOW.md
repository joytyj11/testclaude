# TestClaude 统一开发流程

**Scripts + Skills 整合 | 标准化调用**

---

## 📁 目录结构

```
teams/testclaude/
├── MANIFEST.md          # 核心能力清单
├── UNIFIED_GUIDE.md     # 快速操作指南
├── DEV_FLOW.md          # 本文件 - 开发流程
├── scripts/             # 自动化脚本 (Shell/Python)
│   ├── dispatch.sh      # 任务分发器
│   ├── review-pr.sh     # PR 审查
│   ├── notify.sh        # 通知
│   └── ...
├── skills/              # OpenClaw 技能
│   ├── github-review/   # PR 审查技能
│   ├── feishu-notify/   # Feishu 通知技能
│   └── auto-test/       # 自动化测试技能
└── swarm/               # 多代理协作
```

---

## 🔧 脚本调用统一方式

### 1. 任务分发 (dispatch.sh)
```bash
# 分发任务给多个 Agent
./scripts/dispatch.sh --task "审查所有 PR" --agents "reviewer,qa"
```

### 2. PR 审查 (review-pr.sh)
```bash
# 审查指定 PR
./scripts/review-pr.sh --pr 2 --repo joytyj11/testclaude

# 输出审查报告
./scripts/review-pr.sh --pr 2 --output report.md
```

### 3. 通知 (notify.sh)
```bash
# 发送通知到 Feishu
./scripts/notify.sh --channel feishu --message "测试通过 ✅"

# 发送卡片消息
./scripts/notify.sh --channel feishu --card card.json
```

### 4. 测试执行 (test-all-fixes.sh)
```bash
# 运行所有测试
./scripts/test-all-fixes.sh

# 指定测试类型
./scripts/test-all-fixes.sh --type unit
```

---

## 🧩 技能调用统一方式

### 技能列表

| 技能 | 位置 | 触发方式 |
|------|------|----------|
| github-review | `skills/github-review/` | 提及 PR 或 "review" |
| feishu-notify | `skills/feishu-notify/` | 需要发送通知时 |
| auto-test | `skills/auto-test/` | 代码提交后 |

### 自动触发
技能会在以下场景自动激活：
- PR 创建/更新 → `github-review`
- 测试完成 → `feishu-notify`
- 代码提交 → `auto-test`

### 手动调用
```bash
# 通过 OpenClaw 工具调用
sessions_spawn task="激活 github-review 技能审查 PR #2" runtime="subagent"
```

---

## 📋 标准开发流程

### 阶段 1: 需求 → Issue
```bash
# 创建 Issue
gh issue create --title "功能需求" --body "详细描述"

# 或通过脚本
./scripts/dispatch.sh --action create-issue --title "功能需求"
```

### 阶段 2: 开发 → PR
```bash
# 1. 创建分支
git checkout -b feature/xxx

# 2. 开发代码...

# 3. 运行测试
./scripts/test-all-fixes.sh --type unit

# 4. 提交代码
git commit -m "feat: xxx"
git push origin feature/xxx

# 5. 创建 PR
./scripts/create-pr.sh --title "feat: xxx" --body "描述"
```

### 阶段 3: 审查 → 合并
```bash
# 1. 自动审查 (技能激活)
sessions_spawn task="审查 PR #2" runtime="subagent"

# 2. 手动审查
./scripts/review-pr.sh --pr 2

# 3. 合并
./scripts/merge-pr.sh --pr 2 --strategy squash
```

### 阶段 4: 测试 → 部署
```bash
# 1. 运行集成测试
./scripts/test-all-fixes.sh --type integration

# 2. 发送通知
./scripts/notify.sh --message "部署完成 ✅"

# 3. 更新文档
./scripts/update-docs.sh
```

---

## 🚀 快速命令速查

| 操作 | 命令 |
|------|------|
| 创建 Issue | `gh issue create --title "标题"` |
| 创建 PR | `./scripts/create-pr.sh --title "标题"` |
| 审查 PR | `./scripts/review-pr.sh --pr 2` |
| 运行测试 | `./scripts/test-all-fixes.sh` |
| 发送通知 | `./scripts/notify.sh --message "内容"` |
| 分发任务 | `./scripts/dispatch.sh --task "任务"` |
| 查看状态 | `./scripts/swarm-status.sh` |

---

## 🧪 技能开发模板

创建新技能时，使用以下模板：

```markdown
# skills/new-skill/SKILL.md

---
name: new-skill
description: 技能描述
---

# New Skill

## 触发条件
- 场景1
- 场景2

## 执行步骤
1. 步骤1
2. 步骤2

## 输出
- 输出内容
```

---

## 🔗 与 OpenClaw 工具集成

所有脚本和技能最终都映射到 OpenClaw 原生工具：

| 功能 | 脚本 | OpenClaw 工具 |
|------|------|---------------|
| 执行命令 | `./scripts/xxx.sh` | `exec` |
| 文件操作 | `./scripts/xxx.sh` | `read`/`write`/`edit` |
| GitHub 操作 | `./scripts/create-pr.sh` | `gh` 命令 |
| Feishu 通知 | `./scripts/notify.sh` | `message` 工具 |
| Agent 任务 | `./scripts/dispatch.sh` | `sessions_spawn` |

---

## 📊 状态监控

```bash
# 查看 Agent 状态
./scripts/swarm-status.sh

# 查看任务队列
./scripts/list-queue.sh

# 清理僵尸 Agent
./scripts/cleanup-agents.sh
```

---

**版本**: v1.0 | **更新**: 2026-03-23
