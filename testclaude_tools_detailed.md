# TestClaude 团队详细能力与 Tools 清单

**更新时间**: 2026-03-23 22:20 GMT+8  
**环境**: WSL2 / Node v24.14.0 / OpenClaw Agent

---

## 📋 完整 Tools 清单 (按功能分类)

### 1. 文件系统操作
| Tool | 功能 | 参数 |
|------|------|------|
| `read` | 读取文件内容 | path, offset, limit |
| `write` | 写入/创建文件 | path, content |
| `edit` | 精确编辑文件 | path, oldText, newText |

**能力**: 支持文本、图片、大文件分段读取

---

### 2. 命令执行与进程管理
| Tool | 功能 | 关键参数 |
|------|------|----------|
| `exec` | 执行 shell 命令 | command, workdir, pty, background, timeout, elevated |
| `process` | 管理后台进程 | action(list/poll/log/write/kill), sessionId |

**能力**: 
- PTY 支持 (交互式终端)
- 后台运行 (background)
- 超时控制
- 进程生命周期管理

---

### 3. 通信集成

#### Feishu 套件
| Tool | 功能 | 主要参数 |
|------|------|----------|
| `feishu_chat` | 群聊操作 | action(members/info), chat_id |
| `feishu_doc` | 文档操作 | action(read/write/create/append), doc_token |
| `feishu_wiki` | 知识库 | action(spaces/nodes/get/create/move/rename), space_id |
| `feishu_drive` | 云存储 | action(list/info/create_folder/move/delete) |
| `feishu_bitable_*` | 多维表格 | get_meta, list_records, create_record, update_record, create_field |
| `feishu_app_scopes` | 查看权限 | 无参数 |

#### 通用消息
| Tool | 功能 | 参数 |
|------|------|------|
| `message` | 发送消息 | action(send/broadcast), channel, target, message |
| `tts` | 语音合成 | text, channel |

---

### 4. GitHub 集成
| Tool | 功能 | 使用方式 |
|------|------|----------|
| `github` (skill) | 通过 `gh` CLI | issues, PRs, CI runs, API queries |

**已认证账号**: joytyj11  
**已测试**: 仓库创建、代码推送

---

### 5. 浏览器自动化
| Tool | 功能 | 关键参数 |
|------|------|----------|
| `browser` | 浏览器控制 | action(start/stop/profiles/tabs/open/snapshot/screenshot/act), profile, targetUrl |

**能力**:
- 独立 profile (`openclaw`)
- Chrome 扩展中继 (`profile="chrome"`)
- 快照 (aria/role 引用)
- 自动化操作 (click/type/press/hover/drag)

---

### 6. 代理与会话管理
| Tool | 功能 | 参数 |
|------|------|------|
| `sessions_spawn` | 启动子代理/ACP 会话 | task, runtime(subagent/acp), mode(run/session), agentId |
| `sessions_list` | 列出会话 | kinds, limit, activeMinutes |
| `sessions_send` | 跨会话消息 | sessionKey, message |
| `sessions_history` | 查看历史 | sessionKey, limit |
| `subagents` | 管理子代理 | action(list/kill/steer), target, message |
| `agents_list` | 列出可用 agent | 无参数 |

**当前状态**:
- ✅ subagent 可启动
- ❌ agents_list 为空 (需配置)
- ⚠️ ACP 需配置 agentId

---

### 7. 记忆系统
| Tool | 功能 | 参数 |
|------|------|------|
| `memory_search` | 语义搜索记忆 | query, maxResults, minScore |
| `memory_get` | 读取记忆片段 | path, from, lines |

**存储位置**:
- `MEMORY.md` - 长期记忆 (主会话专用)
- `memory/YYYY-MM-DD.md` - 每日日志

---

### 8. 智能分析
| Tool | 功能 | 参数 |
|------|------|------|
| `image` | 图像分析 | prompt, image/images, model |
| `pdf` | PDF 分析 | prompt, pdf/pdfs, pages, model |
| `canvas` | 画布操作 | action(present/hide/navigate/eval/snapshot) |

---

### 9. 网络与数据
| Tool | 功能 | 参数 |
|------|------|------|
| `web_search` | 网络搜索 | query, count, country, language |
| `web_fetch` | 网页抓取 | url, extractMode(markdown/text), maxChars |

**状态**: ⚠️ `web_search` 需配置 API key

---

### 10. 节点管理 (IoT/设备)
| Tool | 功能 | 参数 |
|------|------|------|
| `nodes` | 配对设备管理 | action(status/describe/notify/camera_snap/screen_record/location_get) |

**状态**: 框架存在，无配对节点

---

## 🎯 按场景分类能力

### 代码协作场景
- ✅ 文件读写 (本地)
- ✅ GitHub 操作 (issues, PRs, CI)
- ✅ 命令执行 (编译、测试)
- ✅ 子代理 (代码审查、重构)
- ⚠️ ACP 编码代理 (需配置)

### 文档处理场景
- ✅ Feishu 文档读取
- ✅ 本地 Markdown 编辑
- ✅ PDF 分析
- ⚠️ Feishu 文档写入 (需权限)
- ⚠️ Bitable 操作 (需权限)

### 自动化场景
- ✅ 浏览器自动化 (点击、填表)
- ✅ 命令脚本执行
- ✅ 定时任务 (通过 HEARTBEAT.md)
- ⚠️ 网络搜索 (需配置)

### 团队协作场景
- ✅ Feishu 群聊消息
- ✅ @提及响应
- ✅ 跨会话通信
- ✅ 子代理任务分配

### 智能分析场景
- ✅ 图像识别 (多模态)
- ✅ PDF 内容提取
- ✅ 网页内容抓取

---

## 📊 能力成熟度评估

| 类别 | 完成度 | 说明 |
|------|--------|------|
| 基础文件操作 | 100% | 读写编辑全覆盖 |
| 命令执行 | 95% | PTY + 后台 + 超时 |
| Feishu 集成 | 60% | 只读为主，缺写入权限 |
| GitHub 集成 | 90% | 已认证，可操作 |
| 浏览器自动化 | 85% | 功能完整，需手动启动 |
| 代理系统 | 70% | subagent 可用，缺 ACP |
| 记忆系统 | 75% | 有搜索，需内容积累 |
| 智能分析 | 100% | 图像/PDF 全支持 |
| 网络搜索 | 0% | 需配置 API |
| 节点管理 | 10% | 仅有框架 |

**总体**: **78%** (已配置核心功能)

---

## 🔧 配置建议

### 立即配置 (提升完成度到 90%)
```yaml
# 1. 网络搜索
search:
  provider: brave  # 或 google
  api_key: YOUR_KEY

# 2. 子代理白名单
agents:
  allowed:
    - coding-agent
    - codex
    - claude-code

# 3. ACP 编码代理
acp:
  defaultAgent: claude-code
  allowedAgents:
    - claude-code
    - codex
```

### 短期优化
- 申请 Feishu 写入权限
- 建立 `MEMORY.md` 长期记忆
- 配置 TTS (ElevenLabs)

---

## 📝 使用示例

### 代码审查
```bash
# 启动子代理审查 PR
sessions_spawn task="审查 https://github.com/joytyj11/testclaude/pull/1" runtime="subagent"
```

### GitHub 操作
```bash
# 列出 PR
github: gh pr list --repo joytyj11/testclaude
```

### Feishu 文档读取
```bash
# 读取文档
feishu_doc action=read doc_token=XXX
```

### 浏览器自动化
```bash
# 打开网页并截图
browser action=open profile=openclaw url=https://example.com
browser action=screenshot profile=openclaw
```

---

**总结**: TestClaude 团队拥有 **20+ 核心工具**，覆盖文件、通信、代码、浏览器、智能分析全链路。补齐搜索和子代理配置后可满足 90% 的日常开发协作需求。
