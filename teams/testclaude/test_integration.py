#!/usr/bin/env python3
"""
测试编排 agent 与飞书群聊的完整集成
"""

import json
import subprocess
import time
import os

# 群聊 ID
CHAT_ID = "oc_312b28899d56a63a496bb7a0d18bbcf7"
APP_ID = "cli_a93f531068f8dbd2"
APP_SECRET = "kzwoPiONIzb5PrjJ66LvgflvFCDmDXZf"

def test_binding():
    """验证 binding 配置"""
    print("=" * 50)
    print("1. 验证 Binding 配置")
    print("=" * 50)
    
    result = subprocess.run(
        ["python3", "scripts/feishu_chat_manager.py", "--list"],
        cwd="/home/administrator/.openclaw-zero/workspace/teams/testclaude",
        capture_output=True, text=True
    )
    print(result.stdout)
    
    if CHAT_ID in result.stdout:
        print(f"✅ 群聊 {CHAT_ID} 已正确绑定")
        return True
    else:
        print(f"⚠️ 未找到群聊 {CHAT_ID} 的绑定")
        return False

def test_send_message():
    """测试发送消息到飞书群聊"""
    print("\n" + "=" * 50)
    print("2. 测试发送消息到飞书群聊")
    print("=" * 50)
    
    # 获取 token
    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"app_id": APP_ID, "app_secret": APP_SECRET})],
        capture_output=True, text=True
    )
    token_data = json.loads(result.stdout)
    token = token_data.get("tenant_access_token")
    
    if not token:
        print("❌ 无法获取 token")
        return False
    
    # 发送测试消息
    message = {
        "receive_id": CHAT_ID,
        "msg_type": "text",
        "content": json.dumps({
            "text": "🎉 测试消息！编排 agent 已成功绑定此群聊。\n\n现在可以通过此群聊发送任务给编排 agent，例如：\n- \"让 coder 修复登录 bug\"\n- \"开始长期项目优化 API\"\n- \"开个群讨论架构设计\""
        })
    }
    
    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         f"https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id",
         "-H", f"Authorization: Bearer {token}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps(message)],
        capture_output=True, text=True
    )
    
    try:
        data = json.loads(result.stdout)
        if data.get("code") == 0:
            print("✅ 测试消息已发送到飞书群聊")
            print(f"   消息 ID: {data['data']['message_id']}")
            return True
        else:
            print(f"❌ 发送失败: {data.get('msg')}")
            return False
    except:
        print(f"❌ 解析失败: {result.stdout}")
        return False

def main():
    print("🚀 testclaude 团队 - 飞书集成测试\n")
    
    # 测试 binding
    test_binding()
    
    # 测试发送消息
    test_send_message()
    
    print("\n" + "=" * 50)
    print("✅ 测试完成！")
    print("=" * 50)
    print("\n📢 下一步:")
    print(f"   1. 在飞书客户端查看群聊 '{CHAT_ID}' 是否收到测试消息")
    print("   2. 在群聊中发送任务给编排 agent")
    print("   3. 查看编排 agent 是否自动响应")

if __name__ == "__main__":
    main()
