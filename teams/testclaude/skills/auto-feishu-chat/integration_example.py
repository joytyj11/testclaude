#!/usr/bin/env python3
"""
编排 agent 集成示例 - 自动创建飞书群聊

将此代码集成到编排 agent 的主逻辑中
"""

import os
import subprocess
import re
from pathlib import Path


class AutoFeishuChatManager:
    """编排 agent 的自动飞书群聊管理器"""
    
    def __init__(self, app_id=None, app_secret=None):
        self.app_id = app_id or os.getenv("FEISHU_APP_ID")
        self.app_secret = app_secret or os.getenv("FEISHU_APP_SECRET")
        self.script_path = Path("/home/administrator/.openclaw-zero/workspace/teams/testclaude/scripts/feishu_chat_manager.py")
        
        if not self.script_path.exists():
            print(f"⚠️ 脚本不存在: {self.script_path}")
    
    def should_create_chat(self, task_desc, context=None):
        """判断是否需要创建群聊"""
        if not self.app_id or not self.app_secret:
            return False
        
        # 关键词触发
        chat_keywords = ["拉群", "开群", "建群", "创建群聊", "协作群", "长期", "多人", "一起"]
        for kw in chat_keywords:
            if kw in task_desc:
                return True
        
        # 检查是否是多人协作
        if "和" in task_desc and any(word in task_desc for word in ["一起", "共同", "合作"]):
            return True
        
        # 检查是否是长期任务
        if any(word in task_desc for word in ["长期", "持续", "迭代", "跟踪"]):
            return True
        
        return False
    
    def extract_participants(self, task_desc):
        """从任务描述中提取参与人的 open_id
        
        简化版：这里需要实际查询用户映射
        实际使用时需要：
        1. 识别提到的用户名（如 @coder @reviewer）
        2. 通过飞书 API 查询 open_id
        3. 返回 open_id 列表
        
        当前返回空列表（只拉 bot 自己）
        """
        # 示例：匹配 @username 格式
        mentions = re.findall(r'@(\w+)', task_desc)
        
        # 这里需要映射到真实的 open_id
        # 简化版：返回空
        if mentions:
            print(f"📝 检测到参与人: {mentions}")
            print("⚠️ 需要配置用户名到 open_id 的映射")
        
        return []  # 实际应该返回 open_id 列表
    
    def create_chat(self, chat_name, participants=None):
        """创建群聊并返回 chat_id"""
        if not self.script_path.exists():
            print(f"❌ 脚本不存在: {self.script_path}")
            return None
        
        cmd = [
            "python3", str(self.script_path),
            "--create-chat", chat_name,
            "--app-id", self.app_id,
            "--app-secret", self.app_secret
        ]
        
        if participants:
            cmd.extend(["--user-open-ids"] + participants)
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            # 解析 chat_id
            for line in result.stdout.split('\n'):
                if "群聊 ID:" in line:
                    chat_id = line.split()[-1]
                    print(f"✅ 群聊创建成功: {chat_name} ({chat_id})")
                    return chat_id
            
            print(f"❌ 创建群聊失败: {result.stderr}")
            return None
            
        except subprocess.TimeoutExpired:
            print("❌ 创建群聊超时")
            return None
        except Exception as e:
            print(f"❌ 创建群聊异常: {e}")
            return None
    
    def bind_chat(self, chat_id, agent_id="orchestrator-agent"):
        """绑定群聊到编排 agent"""
        if not self.script_path.exists():
            return False
        
        try:
            result = subprocess.run(
                ["python3", str(self.script_path), "--bind", agent_id, chat_id],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                print(f"✅ 群聊 {chat_id} 已绑定到 {agent_id}")
                return True
            else:
                print(f"❌ 绑定失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 绑定异常: {e}")
            return False
    
    def restart_gateway(self):
        """重启 gateway 使配置生效"""
        try:
            result = subprocess.run(
                ["openclaw", "gateway", "restart"],
                capture_output=True, text=True, timeout=10
            )
            print("🔄 Gateway 重启中...")
            return result.returncode == 0
        except Exception as e:
            print(f"⚠️ 重启 gateway 失败: {e}")
            return False
    
    def handle_task(self, task_desc, context=None):
        """处理任务的主入口
        
        Returns:
            dict: {
                "created": bool,
                "chat_id": str or None,
                "chat_name": str or None,
                "participants": list
            }
        """
        if not self.should_create_chat(task_desc, context):
            return {"created": False, "chat_id": None}
        
        # 生成群名（限制长度）
        chat_name = f"任务-{task_desc[:50]}"
        if len(chat_name) > 50:
            chat_name = chat_name[:47] + "..."
        
        # 提取参与人
        participants = self.extract_participants(task_desc)
        
        # 创建群聊
        chat_id = self.create_chat(chat_name, participants)
        if not chat_id:
            return {"created": False, "chat_id": None}
        
        # 绑定群聊
        if not self.bind_chat(chat_id):
            return {"created": True, "chat_id": chat_id, "bind_success": False}
        
        # 可选：重启 gateway
        # self.restart_gateway()
        
        return {
            "created": True,
            "chat_id": chat_id,
            "chat_name": chat_name,
            "participants": participants,
            "bind_success": True
        }


# ============================================================
# 集成示例：在编排 agent 的 SKILL.md 中如何调用
# ============================================================

"""
## 在编排 agent 的 SKILL.md 中添加以下逻辑：

当你收到用户任务时：

1. 检查是否需要创建飞书群聊
2. 如果需要，调用 AutoFeishuChatManager
3. 继续正常任务处理

示例代码：

```python
from integration_example import AutoFeishuChatManager

# 初始化
chat_manager = AutoFeishuChatManager(
    app_id=os.getenv("FEISHU_APP_ID"),
    app_secret=os.getenv("FEISHU_APP_SECRET")
)

# 在任务处理前
def process_task(task_desc, context):
    # 尝试自动创建群聊
    chat_info = chat_manager.handle_task(task_desc, context)
    
    if chat_info["created"]:
        # 在群里发个消息
        message = f"📢 新任务已创建\n\n任务: {task_desc}\n\n正在处理中..."
        # 使用飞书 API 发送消息到 chat_info["chat_id"]
        # 或者通过编排 agent 的 message 工具发送
        
    # 继续原有任务处理流程
    # ...
```
"""


# ============================================================
# 测试代码
# ============================================================

if __name__ == "__main__":
    # 测试示例
    manager = AutoFeishuChatManager()
    
    test_cases = [
        "让 coder 和 reviewer 一起修复登录 bug，开个群",
        "开始一个长期项目，持续优化 API 性能",
        "审查 PR #123，需要创建审查群",
        "修复一个简单 bug"  # 不应该创建群聊
    ]
    
    for task in test_cases:
        should = manager.should_create_chat(task)
        print(f"\n任务: {task}")
        print(f"  需要创建群聊: {should}")
        
        if should and manager.app_id:
            # 实际创建需要真实的 app_id
            result = manager.handle_task(task)
            print(f"  结果: {result}")
