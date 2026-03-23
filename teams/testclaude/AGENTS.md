# TestClaude Team - AGENTS.md

## 团队定位
TestClaude 是专注于 OpenClaw 能力测试和质量保障的团队。

## 核心能力

### 1. 代码协作
- GitHub 完整集成 (issues, PRs, CI)
- 代码审查流程
- 版本管理 (Git)

### 2. 自动化测试
- 产品开发流程验证
- 工具链完整性测试
- 集成测试场景

### 3. 文档管理
- Feishu 文档读写
- Markdown 文档生成
- 技术方案沉淀

### 4. 智能分析
- 图像识别 (OCR, 物体检测)
- PDF 内容提取
- 网页内容抓取

### 5. 代理协作
- 子代理任务分配
- 跨会话通信
- 并行任务处理

## 工作流程

### 需求阶段
1. 创建 GitHub Issue
2. 标注优先级和标签
3. 分配负责人

### 开发阶段
1. 创建功能分支: `feature/xxx`
2. 编写代码和测试
3. 本地验证通过
4. 提交 PR

### 审核阶段
1. 自动运行测试 (如有 CI)
2. 人工代码审查
3. 合并到 master

### 发布阶段
1. 打 tag 版本
2. 更新 CHANGELOG
3. 部署到生产环境

## 配置清单

### GitHub
- 仓库: https://github.com/joytyj11/testclaude
- 认证: gh CLI 已配置
- 权限: issues, prs, ci

### Feishu
- 群聊: oc_76f3d8125fa8843b0bcdecc440e2605f
- 权限: 文档读取 (需申请写入权限)

### 记忆系统
- 每日日志: `memory/YYYY-MM-DD.md`
- 长期记忆: `MEMORY.md` (主会话)

## 待办事项
- [ ] 配置网络搜索 API
- [ ] 配置子代理白名单
- [ ] 申请 Feishu 写入权限
- [ ] 建立自动化 CI/CD
- [ ] 配置 TTS 语音服务

---
*更新时间: 2026-03-23*
