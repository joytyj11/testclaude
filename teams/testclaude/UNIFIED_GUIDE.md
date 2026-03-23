# TestClaude 统一操作指南

**精简版 | 一页搞定所有操作**

---

## 🚀 快速命令

### GitHub 操作
```bash
# Issue
gh issue create --repo joytyj11/testclaude --title "标题" --body "内容"
gh issue list --repo joytyj11/testclaude

# PR
git checkout -b feature/xxx
gh pr create --title "feat: xxx" --body "描述" --base master
gh pr view 2 --repo joytyj11/testclaude
gh pr merge 2 --squash
```

### Feishu 操作
```yaml
# 发送消息
message channel=feishu message="Hello"

# 读取文档
feishu_doc action=read doc_token=XXX

# 知识库
feishu_wiki action=spaces
```

### Agent 调用
```yaml
# 启动子代理
sessions_spawn task="运行测试" runtime="subagent" mode="run"

# 启动编码代理
sessions_spawn runtime="acp" agentId="claude-code" thread=true

# 管理子代理
subagents action=list
subagents action=steer target=xxx message="停止"
```

### 智能分析
```yaml
# 图像分析
image prompt="描述图片" image="/path/to/image.jpg"

# PDF 分析
pdf prompt="提取关键信息" pdf="/path/to/doc.pdf"

# 浏览器
browser action=open profile=openclaw url=https://example.com
browser action=snapshot profile=openclaw
```

---

## 📋 标准流程

### 代码审查流程
```bash
# 1. 创建 PR
gh pr create --title "feat: xxx" --body "描述"

# 2. 自动审查
sessions_spawn task="审查最新 PR" runtime="subagent"

# 3. 手动审查
gh pr view 2

# 4. 合并
gh pr merge 2 --squash
```

### 测试自动化流程
```bash
# 1. 运行测试
sessions_spawn task="python3 -m pytest tests/" runtime="subagent"

# 2. 生成报告
python3 -m pytest --html=report.html

# 3. 通知结果
message channel=feishu message="测试通过 ✅"
```

### 文档生成流程
```bash
# 1. 从代码生成文档
sessions_spawn task="为 weather.py 生成文档" runtime="subagent"

# 2. 写入 Feishu
feishu_doc action=write doc_token=XXX content="文档内容"
```

---

## 🧩 技能速查

| 技能 | 触发词 | 命令 |
|------|--------|------|
| GitHub | PR, issue, commit | `gh` |
| 天气 | 天气, temperature | `python3 weather.py 北京` |
| 文档 | 文档, doc | `feishu_doc` |
| 图像 | 图片, 识别 | `image` |
| PDF | PDF, 提取 | `pdf` |

---

## ⚙️ 一键配置

```bash
# 配置 Agent 白名单
openclaw config set agents.allowed '["coding-agent", "codex"]'

# 验证
agents_list

# 测试子代理
sessions_spawn task="echo 'Hello Agent'" runtime="subagent"
```

---

## 🔧 故障排查

| 问题 | 解决 |
|------|------|
| `gh auth` 失败 | `gh auth login` |
| Subagent 不启动 | 检查 `agents.allowed` |
| Feishu 无权限 | 申请 `docx:document:write` |
| 浏览器连不上 | `browser start profile=openclaw` |

---

## 📚 核心文件

- `MANIFEST.md` - 完整能力清单
- `UNIFIED_GUIDE.md` - 本文件 (快速操作)
- `skills/` - 自定义技能目录
- `scripts/` - 自动化脚本

---

**版本**: v2.1 | **更新**: 2026-03-23
