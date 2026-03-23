# GitHub Webhook 快速入门指南

## ✅ 已完成的工作

为 testclaude 团队编排 agent 增加了以下能力：

1. **GitHub Webhook 监听器** (`scripts/github-webhook-listener.sh`)
   - 监听 PR、Push、CI 事件
   - 验证 webhook 签名
   - 自动触发相应的处理流程

2. **CI 等待脚本** (`scripts/wait-for-ci.sh`)
   - 轮询 GitHub API 等待 CI 完成
   - 支持超时配置
   - 自动更新任务状态

3. **增强的通知系统** (`scripts/notify.sh`)
   - 支持 Discord/Slack/自定义 webhook
   - 自动降级到本地队列
   - 彩色编码的通知（绿色=成功，红色=失败）

## 🚀 快速启动（5分钟）

### 步骤 1: 配置 GitHub Webhook

```bash
# 1. 生成 webhook secret
openssl rand -hex 32
# 输出类似: a1b2c3d4e5f6...

# 2. 复制到剪贴板，然后在 GitHub 仓库设置中添加 webhook
# Settings → Webhooks → Add webhook
# Payload URL: http://YOUR_SERVER_IP:8080
# Secret: 上面生成的密钥
# Content type: application/json
# Events: Pull requests, Push, Check suite, Check run, Status
```

### 步骤 2: 配置环境变量

```bash
cd ~/.openclaw-zero/workspace/teams/testclaude

# 复制示例配置
cp .env.example .env

# 编辑 .env 文件
nano .env
```

添加你的配置：
```bash
GITHUB_WEBHOOK_SECRET=上面生成的密钥

# 可选：配置通知渠道
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your-webhook
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your-webhook
```

### 步骤 3: 配置 GitHub CLI

```bash
# 如果还没有配置
gh auth login
# 选择: GitHub.com, HTTPS, Login with a web browser
# 然后按提示完成认证

# 验证配置
gh auth status
```

### 步骤 4: 启动 Webhook 监听器

**测试模式（前台运行）：**
```bash
cd ~/.openclaw-zero/workspace/teams/testclaude
./scripts/github-webhook-listener.sh --port 8080
```

**生产模式（systemd 服务）：**
```bash
# 编辑服务文件，填入 webhook secret
nano scripts/github-webhook.service
# 修改 GITHUB_WEBHOOK_SECRET=你的密钥

# 安装服务
sudo cp scripts/github-webhook.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable github-webhook
sudo systemctl start github-webhook

# 查看状态
sudo systemctl status github-webhook
```

## 🧪 测试 Webhook

### 方法 1: 使用 GitHub 测试功能
1. 在 GitHub webhook 设置页面
2. 点击 "Recent Deliveries"
3. 点击 "Redeliver" 重新发送一个事件

### 方法 2: 手动发送测试请求
```bash
# 设置变量
SECRET="你的webhook密钥"
PAYLOAD='{"action":"opened","pull_request":{"number":1,"title":"Test PR","head":{"ref":"feature/test"}},"repository":{"full_name":"test/repo"}}'

# 计算签名
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print "sha256="$2}')

# 发送请求
curl -X POST http://localhost:8080 \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: $SIGNATURE" \
  -d "$PAYLOAD"
```

## 🔄 工作流程示例

### 场景：自动化 PR 处理

1. **开发者推送代码并创建 PR**
   ```
   GitHub → Webhook → github-webhook-listener.sh
   ```

2. **系统自动响应**
   - 检测到 PR 创建事件
   - 触发 `wait-for-ci.sh` 后台运行
   - 发送通知："PR #123 已创建，等待 CI..."

3. **CI 运行中**
   - `wait-for-ci.sh` 每 30 秒检查一次状态
   - 记录进度到日志

4. **CI 通过**
   - 检测到所有检查完成且成功
   - 更新任务注册表
   - 发送通知："✅ CI 通过！准备审查"
   - 自动触发 `review-pr.sh`

5. **PR 合并**
   - 检测到合并事件
   - 触发 `cleanup-agents.sh`
   - 发送通知："🔀 PR #123 已合并"

### 场景：CI 失败自动重试

1. CI 失败 → `wait-for-ci.sh` 检测到失败状态
2. 提取失败日志（最后 50 行）
3. 触发 `respawn-agent.sh --ci-failure`
4. 创建增强的提示文件（包含失败上下文）
5. 重新启动 agent
6. 发送通知："❌ CI 失败，正在重试..."

## 📊 监控和日志

### 查看实时日志
```bash
# Webhook 监听器日志（systemd）
sudo journalctl -u github-webhook -f

# 手动运行时的日志
tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/webhook-*.log

# CI 等待日志
tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/ci-wait-*.log

# 通知日志
tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/notify-*.log
```

### 检查任务状态
```bash
# 查看活跃任务
cat ~/.openclaw-zero/workspace/teams/testclaude/swarm/active-tasks.json | jq '.tasks[] | {id, repo, branch, ci_status, pr}'

# 查看待发送通知
cat ~/.openclaw-zero/workspace/teams/testclaude/swarm/notifications/pending.json

# 查看 agent 状态
./scripts/check-agents.sh
```

## 🔧 配置选项

### Webhook 监听器
- `--port`: 监听端口（默认 8080）
- `--secret`: GitHub webhook 密钥（也可从环境变量读取）

### CI 等待脚本
- `--timeout`: 超时时间（秒），默认 3600（1小时）
- 可通过修改脚本中的 `POLL_INTERVAL` 调整轮询间隔

### 通知渠道优先级
1. Discord（如果配置了 `DISCORD_WEBHOOK_URL`）
2. Slack（如果配置了 `SLACK_WEBHOOK_URL`）
3. 自定义 webhook（如果配置了 `CUSTOM_WEBHOOK_URL`）
4. 本地队列（fallback，保存在 `pending.json`）

## 🐛 故障排除

### 问题：Webhook 收不到请求
```bash
# 检查服务是否运行
sudo systemctl status github-webhook

# 检查端口是否监听
netstat -tlnp | grep 8080

# 检查防火墙
sudo ufw status

# 从外部测试连接
curl http://YOUR_SERVER_IP:8080
```

### 问题：CI 状态检测失败
```bash
# 验证 GitHub CLI 认证
gh auth status

# 手动测试 API
gh pr view 123 --repo owner/repo --json statusCheckRollup

# 检查 PR 的 CI 配置
gh pr checks 123 --repo owner/repo
```

### 问题：通知发送失败
```bash
# 检查环境变量
echo $DISCORD_WEBHOOK_URL

# 测试 Discord webhook
curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_DISCORD_WEBHOOK_URL

# 查看通知日志
tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/notify-*.log
```

## 📝 集成到现有工作流

### 在 orchestrator 中使用

更新 `orchestrator-config.json` 的 `systemPrompt`，添加以下说明：

```markdown
### GitHub Webhook 集成

系统已集成 GitHub webhook 监听器，可以自动响应 PR 事件：

- 当 PR 创建时，自动启动 `wait-for-ci.sh` 等待 CI 完成
- CI 通过后自动触发审查
- CI 失败时自动重启 agent（带失败上下文）

监听器运行在端口 8080，作为 systemd 服务自动启动。
```

### 在 cron 中添加监控

```bash
# 每 5 分钟检查一次 CI 状态
*/5 * * * * /home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/check-agents.sh

# 每 10 分钟处理一次待发送通知
*/10 * * * * /home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/notify.sh
```

## 🎯 下一步

1. **配置通知渠道**：设置 Discord/Slack webhook 接收实时通知
2. **自定义 CI 检查**：修改 `wait-for-ci.sh` 添加自定义检查逻辑
3. **扩展 webhook 处理**：添加对其他 GitHub 事件的支持（如 issue、release）
4. **添加仪表板**：创建一个简单的 Web UI 显示 CI 状态

## 📚 相关文档

- [完整设置文档](GITHUB_WEBHOOK_SETUP.md)
- [Orchestrator 配置](orchestrator-config.json)
- [团队配置](team-config.json)

---

**状态**: ✅ 所有脚本已创建并测试通过  
**下一步**: 配置 GitHub webhook 并启动监听器
