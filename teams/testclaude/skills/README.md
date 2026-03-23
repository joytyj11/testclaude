# TestClaude Skills

## 可用技能

### 1. github-review
- **位置**: `skills/github-review/`
- **触发**: 提及 PR、"review"、PR 链接
- **能力**: 自动审查代码规范、测试覆盖率、安全问题
- **调用**: 自动激活或 `sessions_spawn task="审查 PR #2"`

### 2. feishu-notify
- **位置**: `skills/feishu-notify/`
- **触发**: 需要发送通知、测试完成、PR 合并
- **能力**: 发送文本/卡片消息、@提及
- **调用**: 自动或 `./scripts/notify.sh`

### 3. auto-test
- **位置**: `skills/auto-test/`
- **触发**: 代码提交、PR 创建
- **能力**: 运行测试、收集覆盖率、生成报告
- **调用**: 自动或 `./scripts/test-all-fixes.sh`

## 技能开发

新技能请创建目录并添加 `SKILL.md`：

```bash
mkdir -p skills/my-skill
touch skills/my-skill/SKILL.md
```

## 技能格式

参考 `skills/github-review/SKILL.md` 模板。
