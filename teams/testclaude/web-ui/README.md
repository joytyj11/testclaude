# testclaude 团队Web监控面板

## 简介

这是一个用于监控testclaude团队任务执行情况和agent间A2A通信的Web界面。可以实时查看：

- 📊 **任务统计**：活跃任务、待审查、卡住、失败任务数量
- 📋 **活跃任务列表**：每个任务的详细信息（仓库、分支、状态、进度）
- 💬 **A2A通信记录**：编排agent和编码agent之间的实时对话
- 📈 **任务执行日志**：系统日志和事件记录

## 使用方法

### 方式1：直接打开HTML文件

```bash
# 在浏览器中打开文件
firefox /home/administrator/.openclaw-zero/workspace/teams/testclaude/web-ui/index.html
# 或
chromium-browser /home/administrator/.openclaw-zero/workspace/teams/testclaude/web-ui/index.html
```

### 方式2：使用简单的HTTP服务器

```bash
# 进入web-ui目录
cd /home/administrator/.openclaw-zero/workspace/teams/testclaude/web-ui

# 启动Python HTTP服务器
python3 -m http.server 8080

# 然后在浏览器中访问
# http://localhost:8080
```

### 方式3：使用Node.js http-server

```bash
# 安装http-server（如果未安装）
npm install -g http-server

# 启动服务
cd /home/administrator/.openclaw-zero/workspace/teams/testclaude/web-ui
http-server -p 8080
```

## 功能特点

### 1. 实时监控
- 页面每30秒自动刷新数据
- 模拟实时消息更新（每15秒添加一条模拟消息）
- 显示最后更新时间戳

### 2. 任务状态可视化
- 不同状态使用不同颜色标识
- 进度条显示任务完成百分比
- 统计卡片汇总整体情况

### 3. A2A通信记录
- 区分编排agent和编码agent的消息
- 显示发送时间戳
- 保留最近50条消息

### 4. 日志查看
- 按时间倒序显示
- 日志级别颜色区分（info/warn/error）

## 后续开发计划

### 需要集成的实际数据源

```javascript
// 计划从以下文件读取真实数据
const TASKS_FILE = '/home/administrator/.openclaw-zero/workspace/teams/testclaude/swarm/active-tasks.json';
const LOGS_DIR = '/home/administrator/.openclaw-zero/workspace/teams/testclaude/swarm/logs/';

// 需要创建后端API来提供数据
// 例如：使用Express.js创建REST API
```

### 建议的API接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/tasks` | GET | 获取所有活跃任务 |
| `/api/tasks/:id` | GET | 获取单个任务详情 |
| `/api/messages` | GET | 获取A2A通信记录 |
| `/api/logs` | GET | 获取最近日志 |
| `/api/stats` | GET | 获取统计信息 |

### WebSocket实时更新

对于真正的实时监控，建议添加WebSocket支持：

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    updateUI(data);
};
```

## 当前版本

- **版本**: v0.1.0 (模拟数据版)
- **功能**: UI界面和模拟数据显示
- **下一步**: 连接真实数据源

## 截图预览

（当前为模拟数据界面）

面板包含三个主要区域：
1. 顶部统计卡片
2. 左侧任务列表 / 右侧通信记录
3. 底部日志面板

## 自定义配置

如果需要修改刷新间隔或消息更新频率，可以编辑`index.html`中的：

```javascript
// 自动刷新间隔（毫秒）
setInterval(refreshData, 30000);  // 改为需要的值

// 模拟消息更新间隔
setInterval(() => { ... }, 15000); // 改为需要的值
```

## 问题反馈

如遇到问题或需要功能改进，请联系团队管理员。