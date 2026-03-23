---
name: auto-feishu-chat
description: |
  编排 agent 自动创建飞书群聊能力。当接收到需要多人协作、长期跟踪、或需要隔离讨论的任务时，自动创建飞书群聊并邀请相关人员。
  触发词：创建群聊、拉群、开个群、协作群、长期任务。
---

# 编排 Agent 自动飞书群聊

## 功能概述

编排 agent 在处理任务时，可以根据任务类型自动创建飞书群聊：

- **多人协作** → 自动拉群，邀请所有相关人员
- **长期任务** → 创建专属群聊用于持续跟踪
- **敏感任务** → 隔离讨论，避免干扰主群

## 触发条件

编排 agent 在以下情况自动创建群聊：

1. **任务涉及多人协作**（用户说"让XX和XX一起"、"拉上XX"）
2. **任务需要长期跟踪**（超过 1 天、持续迭代）
3. **任务需要保密**（代码审查、安全审计）
4. **用户明确要求**（"开个群"、"创建群聊"）

## 工作流程

```
用户输入 → 编排 agent 接收
    ↓
判断是否需要群聊
    ↓
调用 feishu_chat_manager.py 创建群聊
    ↓
获取 chat_id 并保存
    ↓
将群聊 ID 注入任务上下文
    ↓
在群聊中发布任务详情
    ↓
启动编码 agent 并将结果同步到群聊
```

## 实现脚本

### 1. 创建群聊包装函数

在编排 agent 中集成：

```python
import subprocess
import json

def auto_create_chat(task_desc, participants, app_id, app_secret):
    """
    自动创建飞书群聊
    
    Args:
        task_desc: 任务描述（用于群名）
        participants: 参与人 open_id 列表
        app_id, app_secret: 飞书应用凭证
    
    Returns:
        chat_id: 群聊 ID
    """
    # 生成群名
    chat_name = f"任务群-{task_desc[:30]}"
    
    # 调用脚本创建群聊
    result = subprocess.run(
        ["python3", 
         "/home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/feishu_chat_manager.py",
         "--create-chat", chat_name,
         "--app-id", app_id,
         "--app-secret", app_secret,
         "--user-open-ids"] + participants,
        capture_output=True, text=True
    )
    
    # 解析输出获取 chat_id
    for line in result.stdout.split('\n'):
        if "群聊 ID:" in line:
            chat_id = line.split()[-1]
            return chat_id
    
    return None
```

### 2. 群聊绑定

创建群聊后自动绑定到编排 agent：

```python
def bind_chat_to_agent(chat_id, agent_id="orchestrator-agent"):
    """绑定群聊到编排 agent"""
    result = subprocess.run(
        ["python3", 
         "/home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/feishu_chat_manager.py",
         "--bind", agent_id, chat_id],
        capture_output=True, text=True
    )
    return result.returncode == 0
```

### 3. 发送任务到群聊

```python
def send_task_to_chat(chat_id, task_message):
    """通过飞书 API 发送任务消息"""
    # 使用飞书消息发送 API
    # 或通过编排 agent 的 message 工具发送
    pass
```

## 完整集成代码

将以下代码添加到编排 agent 的 SKILL.md 或直接集成到 agent 逻辑：

```python
import os
import subprocess
import json
from pathlib import Path

class AutoFeishuChatManager:
    """编排 agent 的自动飞书群聊管理器"""
    
    def __init__(self, app_id=None, app_secret=None):
        self.app_id = app_id or os.getenv("FEISHU_APP_ID")
        self.app_secret = app_secret or os.getenv("FEISHU_APP_SECRET")
        self.script_path = Path("/home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/feishu_chat_manager.py")
        
    def should_create_chat(self, task_desc, context):
        """判断是否需要创建群聊"""
        # 关键词触发
        chat_keywords = ["拉群", "开群", "建群", "创建群聊", "协作群", "长期"]
        for kw in chat_keywords:
            if kw in task_desc:
                return True
        
        # 多人协作判断
        if "和" in task_desc and "一起" in task_desc:
            return True
        
        # 长期任务判断
        if "长期" in task_desc or "持续" in task_desc:
            return True
        
        # 默认：单次简单任务不创建
        return False
    
    def extract_participants(self, task_desc):
        """从任务描述中提取参与人（需要 AI 识别）"""
        # 示例：从 "让 coder 和 reviewer 一起做" 中提取
        # 返回 open_id 列表（需要映射）
        # 简化版：返回空列表（只拉 bot 自己）
        return []
    
    def create_chat(self, chat_name, participants=None):
        """创建群聊并返回 chat_id"""
        if not self.app_id or not self.app_secret:
            print("⚠️ 缺少飞书应用凭证，无法创建群聊")
            return None
        
        cmd = [
            "python3", str(self.script_path),
            "--create-chat", chat_name,
            "--app-id", self.app_id,
            "--app-secret", self.app_secret
        ]
        
        if participants:
            cmd.extend(["--user-open-ids"] + participants)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # 解析 chat_id
        for line in result.stdout.split('\n'):
            if "群聊 ID:" in line:
                return line.split()[-1]
        
        print(f"❌ 创建群聊失败: {result.stderr}")
        return None
    
    def bind_chat(self, chat_id, agent_id="orchestrator-agent"):
        """绑定群聊到编排 agent"""
        result = subprocess.run(
            ["python3", str(self.script_path), "--bind", agent_id, chat_id],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            print(f"✅ 群聊 {chat_id} 已绑定到 {agent_id}")
            # 重启 gateway 使配置生效
            subprocess.run(["openclaw", "gateway", "restart"])
            return True
        else:
            print(f"❌ 绑定失败: {result.stderr}")
            return False
    
    def handle_task(self, task_desc, context):
        """处理任务的主入口"""
        if not self.should_create_chat(task_desc, context):
            return None
        
        # 生成群名
        chat_name = f"任务-{task_desc[:30]}"
        
        # 提取参与人
        participants = self.extract_participants(task_desc)
        
        # 创建群聊
        chat_id = self.create_chat(chat_name, participants)
        if not chat_id:
            return None
        
        # 绑定群聊
        if not self.bind_chat(chat_id):
            return None
        
        # 返回群聊 ID 供后续使用
        return {
            "chat_id": chat_id,
            "chat_name": chat_name,
            "participants": participants
        }

# 在编排 agent 主流程中使用
manager = AutoFeishuChatManager()

# 当接收到任务时
chat_info = manager.handle_task(task_description, context)
if chat_info:
    print(f"📢 已创建群聊: {chat_info['chat_name']}")
    print(f"   群聊 ID: {chat_info['chat_id']}")
    # 继续正常任务流程...
```

## 使用示例

### 场景 1: 用户要求拉群协作

**用户:** "让 coder 和 reviewer 一起修复登录 bug，开个群"

**编排 agent 动作:**
1. 创建群聊 "任务-修复登录 bug"
2. 拉入 coder 和 reviewer 的飞书账号
3. 绑定到编排 agent
4. 在群聊中发布任务详情
5. 启动编码 agent 并同步进度

### 场景 2: 长期项目自动建群

**用户:** "开始一个长期项目，持续优化 API 性能"

**编排 agent 动作:**
1. 检测到"长期项目"关键词
2. 自动创建群聊 "长期-API 性能优化"
3. 绑定到编排 agent
4. 每次有进展自动在群里更新

### 场景 3: 代码审查专用群

**用户:** "审查 PR #123，需要创建审查群"

**编排 agent 动作:**
1. 创建群聊 "审查-PR #123"
2. 拉入相关 reviewer
3. 在群里展示 PR 详情
4. 收集审查意见

## 配置要求

### 环境变量

在编排 agent 的配置中设置：

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

### 飞书应用权限

需要开通：
- `im:chat:create` - 创建群聊
- `im:chat:update` - 修改群信息
- `im:chat.members:write_only` - 管理成员
- `im:message:send_as_bot` - 发送消息

## 故障处理

| 问题 | 解决方案 |
|------|----------|
| 创建群聊失败 | 检查 app_id/app_secret 是否正确 |
| 绑定失败 | 手动运行 `feishu_chat_manager.py --bind` 查看错误 |
| 收不到消息 | 确认 gateway 已重启 |
| 无法拉人 | 确认 open_id 格式正确（以 `ou_` 开头）|

## 扩展功能

未来可以增加：
- 自动添加任务看板链接
- 定期在群里发送进度报告
- 根据任务状态自动修改群名
- 任务完成后自动归档群聊
