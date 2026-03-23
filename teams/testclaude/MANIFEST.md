# TestClaude Team Manifest

**统一配置 | 流程工具 | 技能调用**

---

## 🎯 核心能力

| 领域 | 工具/技能 | 调用方式 |
|------|----------|----------|
| **代码协作** | GitHub CLI | `gh` 命令 |
| **文档处理** | Feishu | `feishu_doc`, `feishu_wiki` |
| **自动化** | Browser | `browser` 工具 |
| **智能分析** | Image/PDF | `image`, `pdf` 工具 |
| **任务编排** | Subagent | `sessions_spawn` |
| **编码代理** | ACP | `sessions_spawn runtime="acp"` |

---

## 🔧 统一工具调用

### GitHub 操作
```bash
# 所有 GitHub 操作通过 gh CLI
gh issue list --repo joytyj11/testclaude
gh pr create --title "feat" --body "desc"
gh pr merge 2 --squash
```

### Feishu 操作
```yaml
# 文档读取
feishu_doc action=read doc_token=XXX

# 群聊消息
message channel=feishu message="内容"

# 知识库
feishu_wiki action=spaces
```

### 子代理调用
```yaml
# 临时任务
sessions_spawn task="描述任务" runtime="subagent" mode="run"

# 持久会话
sessions_spawn task="准备" runtime="subagent" mode="session" label="helper"

# 管理
subagents action=list
subagents action=steer target=helper message="新指令"
```

### 编码代理
```yaml
# Claude Code
sessions_spawn runtime="acp" agentId="claude-code" thread=true

# Codex
sessions_spawn runtime="acp" agentId="codex" thread=true
```

---

## 📋 标准工作流

### 1. 需求 → Issue
```bash
gh issue create --title "需求" --label enhancement
```

### 2. 开发 → PR
```bash
git checkout -b feature/xxx
# 编写代码...
git commit -m "feat: xxx"
git push origin feature/xxx
gh pr create --title "feat: xxx" --base master
```

### 3. 审查 → 合并
```bash
# 自动审查
sessions_spawn task="审查 PR #$PR" runtime="subagent"

# 手动合并
gh pr merge $PR --squash
```

### 4. 测试 → 部署
```bash
# 运行测试
sessions_spawn task="python3 -m pytest" runtime="subagent"

# 部署验证
python3 weather.py 北京
```

---

## 🧩 技能加载

### 可用技能
| 技能 | 触发条件 | 加载方式 |
|------|----------|----------|
| `github` | GitHub 操作 | 自动检测 `gh` 命令 |
| `feishu-doc` | Feishu 文档链接 | 匹配 URL 模式 |
| `coding-agent` | 编码任务 | 用户提及代码/PR |
| `weather` | 天气查询 | 城市+天气关键词 |

### 手动调用技能
```bash
# 读取技能文档
read path=~/openclaw-zero-token/skills/github/SKILL.md

# 技能会指导具体操作
```

---

## ⚙️ 配置清单

### 已完成 ✅
- [x] GitHub CLI 认证 (joytyj11)
- [x] 工作目录初始化
- [x] 基础工具配置
- [x] Agent 设计文档

### 待配置 ⏳
- [ ] `agents.allowed` 白名单
- [ ] Feishu 写入权限
- [ ] 网络搜索 API

### 快速配置
```bash
# 1. Agent 白名单
openclaw config set agents.allowed '["coding-agent", "codex"]'

# 2. ACP 默认代理
openclaw config set acp.defaultAgent "claude-code"

# 3. 验证
agents_list
```

---

## 📊 状态速查

| 能力 | 状态 | 命令 |
|------|------|------|
| GitHub | ✅ | `gh auth status` |
| Subagent | ✅ | `agents_list` |
| ACP | ⚠️ | 需配置 |
| 搜索 | ❌ | 需 API |
| TTS | ❌ | 需配置 |

---

## 🔗 快速链接

- 仓库: https://github.com/joytyj11/testclaude
- 工作区: `/home/administrator/.openclaw-zero/workspace`
- 日志: `~/openclaw-zero-token/logs/`

---

**更新**: 2026-03-23 | **版本**: v2.0 (精简合并)
