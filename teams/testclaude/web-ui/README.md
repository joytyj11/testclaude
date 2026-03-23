# TestClaude Manager - OpenClaw 界面管理工具

TestClaude 团队开发的轻量级 OpenClaw 管理界面。

## 功能特性

- 🚀 **Gateway 状态监控** - 实时查看 OpenClaw Gateway 运行状态
- 🤖 **Agent 管理** - 查看所有 Agent 列表和状态
- 📊 **统计仪表板** - 活跃 Agents、会话数、系统负载
- 🔄 **快速操作** - 一键启动/重启 Gateway
- 🎨 **现代 UI** - 响应式设计，支持暗色模式

## 快速开始

### 1. 安装依赖
```bash
cd /home/administrator/.openclaw-zero/workspace/teams/testclaude/web-ui
npm install
```

### 2. 启动开发服务器
```bash
npm run dev
```

访问 http://localhost:3001

### 3. 构建生产版本
```bash
npm run build
npm run start
```

## 项目结构

```
web-ui/
├── app/
│   ├── layout.tsx          # 根布局
│   ├── page.tsx            # 主页面
│   ├── globals.css         # 全局样式
│   └── api/                # API 路由
│       ├── status/         # 状态查询
│       └── gateway/restart/# Gateway 重启
├── package.json
├── tailwind.config.ts
└── README.md
```

## API 端点

- `GET /api/status` - 获取 Gateway 和 Agent 状态
- `POST /api/gateway/restart` - 重启 Gateway

## 技术栈

- Next.js 14 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- Heroicons
- React Hot Toast

## 后续扩展

- [ ] Agent 聊天界面
- [ ] 任务队列管理
- [ ] 日志流式查看
- [ ] 性能图表分析
- [ ] 配置管理界面

## 相关文档

- [TestClaude 团队能力](../TEAM_CAPABILITIES.md)
- [统一开发流程](../DEV_FLOW.md)
- [OpenClaw 文档](https://docs.openclaw.ai)

---

**开发**: TestClaude Team  
**版本**: v1.0.0
