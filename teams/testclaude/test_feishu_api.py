#!/usr/bin/env python3
"""
测试飞书 API - 验证凭证是否有效
"""

import json
import subprocess
import sys

# 飞书凭证
APP_ID = "cli_a93f531068f8dbd2"
APP_SECRET = "kzwoPiONIzb5PrjJ66LvgflvFCDmDXZf"

def test_get_token():
    """测试获取 token"""
    print("🔑 测试获取 tenant_access_token...")
    
    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"app_id": APP_ID, "app_secret": APP_SECRET})],
        capture_output=True, text=True, timeout=10
    )
    
    try:
        data = json.loads(result.stdout)
        if "tenant_access_token" in data:
            token = data["tenant_access_token"]
            print(f"✅ Token 获取成功: {token[:20]}...")
            return token
        else:
            print(f"❌ 获取 token 失败: {data.get('msg', 'unknown error')}")
            print(f"完整响应: {result.stdout}")
            return None
    except json.JSONDecodeError as e:
        print(f"❌ 解析响应失败: {e}")
        print(f"原始响应: {result.stdout}")
        return None

def test_create_chat(token):
    """测试创建群聊"""
    print("\n💬 测试创建测试群聊...")
    
    chat_name = f"testclaude-测试群-{__import__('time').time()}"
    
    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "https://open.feishu.cn/open-apis/im/v1/chats",
         "-H", f"Authorization: Bearer {token}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({
             "name": chat_name,
             "chat_mode": "group",
             "chat_type": "private"
         })],
        capture_output=True, text=True, timeout=10
    )
    
    try:
        data = json.loads(result.stdout)
        if data.get("code") == 0:
            chat_id = data["data"]["chat_id"]
            print(f"✅ 群聊创建成功!")
            print(f"   群名: {chat_name}")
            print(f"   群ID: {chat_id}")
            return chat_id
        else:
            print(f"❌ 创建群聊失败: {data.get('msg')}")
            print(f"完整响应: {result.stdout}")
            return None
    except json.JSONDecodeError as e:
        print(f"❌ 解析响应失败: {e}")
        print(f"原始响应: {result.stdout}")
        return None

def main():
    print("=" * 50)
    print("飞书 API 测试")
    print("=" * 50)
    
    # 测试获取 token
    token = test_get_token()
    if not token:
        print("\n⚠️ 无法获取 token，请检查 app_id 和 app_secret")
        return
    
    # 测试创建群聊
    chat_id = test_create_chat(token)
    if chat_id:
        print(f"\n✅ 测试成功！群聊 ID: {chat_id}")
        print(f"\n💡 下一步:")
        print(f"   1. 在飞书客户端查看是否创建了群聊")
        print(f"   2. 使用以下命令绑定 agent:")
        print(f"      python3 scripts/feishu_chat_manager.py --bind orchestrator-agent {chat_id}")
    else:
        print("\n❌ 测试失败，请检查权限配置")
        print("\n需要开通的权限:")
        print("   - im:chat:create")
        print("   - im:chat:update")
        print("   - im:chat.members:write_only")

if __name__ == "__main__":
    main()
