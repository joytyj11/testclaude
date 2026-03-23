# TestClaude 团队配置

## 📁 目录结构
```
teams/testclaude/
├── AGENTS.md      # 团队能力和工作流程
├── SOUL.md        # 团队使命和价值观
├── TOOLS.md       # 本地工具配置
└── README.md      # 本文件
```

## 🚀 快速开始

### 1. 验证 GitHub 配置
```bash
cd /home/administrator/.openclaw-zero/workspace
gh auth status
```

### 2. 测试开发流程
```bash
# 创建 Issue
gh issue create --repo joytyj11/testclaude --title "测试 Issue"

# 创建 PR
git checkout -b test/pr
git commit --allow-empty -m "test PR"
git push origin test/pr
gh pr create --repo joytyj11/testclaude --title "测试 PR" --body "测试"
```

### 3. 运行测试套件
```bash
# 天气功能测试
python3 weather.py 北京

# 浏览器测试
browser start profile=openclaw
```

## 📊 能力矩阵

| 能力 | 状态 | 备注 |
|------|------|------|
| GitHub Issues | ✅ | 可创建/查看/关闭 |
| GitHub PRs | ✅ | 可创建/审核/合并 |
| Feishu 消息 | ✅ | 群聊收发 |
| Feishu 文档 | ⚠️ | 只读，需写权限 |
| 子代理 | ✅ | 可分配任务 |
| 浏览器自动化 | ✅ | 需手动启动 |
| 网络搜索 | ❌ | 需配置 API |
| 图像识别 | ✅ | 多模态支持 |
| PDF 分析 | ✅ | 文本/图像提取 |

## 🔧 配置优先级

### P0 (立即配置)
- [ ] 网络搜索 API
- [ ] 子代理白名单

### P1 (本周完成)
- [ ] Feishu 写入权限
- [ ] MEMORY.md 初始化

### P2 (长期优化)
- [ ] TTS 语音服务
- [ ] 节点设备配对
- [ ] CI/CD 自动化

## 📝 使用示例

### 需求管理
```bash
# 创建新需求
gh issue create --repo joytyj11/testclaude \
  --title "新功能: XXX" \
  --label enhancement \
  --assignee @me
```

### 代码审查
```bash
# 查看待审 PR
gh pr list --repo joytyj11/testclaude --state open

# 查看 PR 详情
gh pr view 2 --repo joytyj11/testclaude

# 添加评论
gh pr review 2 --comment "LGTM!"
```

### 自动化测试
```bash
# 启动子代理执行测试
sessions_spawn task="运行测试套件并生成报告" runtime="subagent"
```

---

**维护者**: TestClaude Team  
**最后更新**: 2026-03-23
