# 编排 Agent 自动飞书群聊

## 快速开始

### 1. 配置飞书应用凭证

在编排 agent 的环境变量中设置：

```bash
# 编辑编排 agent 的配置文件
vi ~/.openclaw/workspace-orchestrator-agent/.env

# 添加
FEISHU_APP_ID=cli_xxxxxx
FEISHU_APP_SECRET=xxxxxx
```

### 2. 测试自动创建群聊

```python
# 在 Python 环境中测试
from integration_example import AutoFeishuChatManager

manager = AutoFeishuChatManager()
result = manager.handle_task("让 coder 和 reviewer 一起修复登录 bug，开个群")
print(result)
```

### 3. 集成到编排 agent

将 `integration_example.py` 中的逻辑添加到编排 agent 的 SKILL.md 或直接集成到 agent 的主循环中。

## 工作流程

```
用户: "让 coder 和 reviewer 一起修复登录 bug，开个群"
    ↓
编排 agent 接收
    ↓
AutoFeishuChatManager 检测到关键词
    ↓
调用 feishu_chat_manager.py 创建群聊
    ↓
获取 chat_id (oc_xxxxx)
    ↓
绑定群聊到编排 agent
    ↓
重启 gateway
    ↓
在群里发送任务详情
    ↓
启动编码 agent 处理任务
    ↓
结果同步到群里
```

## 配置映射

### 用户名到 open_id 的映射

创建配置文件 `~/.openclaw/workspace-orchestrator-agent/user_mapping.json`：

```json
{
  "coder": "ou_123456789",
  "reviewer": "ou_987654321",
  "tester": "ou_111111111"
}
```

然后在 `extract_participants` 中使用：

```python
def extract_participants(self, task_desc):
    with open("user_mapping.json") as f:
        mapping = json.load(f)
    
    open_ids = []
    for name in re.findall(r'@(\w+)', task_desc):
        if name in mapping:
            open_ids.append(mapping[name])
    return open_ids
```

## 高级功能

### 自动添加任务看板

创建群聊后，自动创建飞书多维表格记录任务：

```python
def create_task_tracker(chat_id, task_desc):
    # 调用飞书 Bitable API
    # 创建任务跟踪表
    pass
```

### 定期进度汇报

设置 cron 任务，定期在群里发送进度：

```python
def setup_progress_report(chat_id, interval_hours=24):
    # 添加 cron 任务
    pass
```

### 任务完成后自动归档

任务完成后自动修改群名、归档群聊：

```python
def archive_chat(chat_id):
    # 修改群名添加 [已完成] 前缀
    pass
```

## 故障排查

| 问题 | 检查 |
|------|------|
| 创建群聊失败 | 1. app_id/app_secret 是否正确<br>2. 飞书应用是否有权限 |
| 绑定失败 | 1. openclaw.json 是否可写<br>2. binding 格式是否正确 |
| 收不到消息 | 1. gateway 是否重启<br>2. 群聊是否已绑定 |
| 无法拉人 | 1. open_id 是否正确<br>2. 用户是否在租户内 |

## 相关文件

- `scripts/feishu_chat_manager.py` - 底层群聊管理脚本
- `integration_example.py` - 集成示例代码
- `SKILL.md` - 详细使用说明
