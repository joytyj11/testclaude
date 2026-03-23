#!/usr/bin/env python3
"""
飞书群聊管理脚本 - 为 testclaude 团队提供群聊管理功能

参照 feishu-multi-agent/scripts/manage_binding.py 和 create_agent.py 设计

功能:
  1. 创建飞书群聊
  2. 添加/移除成员
  3. 管理 binding 配置
  4. 自动配置 openclaw.json
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# 配置路径
OPENCLAW_CONFIG = "/home/administrator/.openclaw/openclaw.json"
BACKUP_DIR = "/home/administrator/.openclaw/config-backups"
TEAM_WORKSPACE = "/home/administrator/.openclaw-zero/workspace/teams/testclaude"


def get_tenant_token(app_id, app_secret):
    """获取飞书 tenant_access_token"""
    try:
        result = subprocess.run(
            ["curl", "-s", "-X", "POST",
             "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
             "-H", "Content-Type: application/json",
             "-d", json.dumps({"app_id": app_id, "app_secret": app_secret})],
            capture_output=True, text=True, timeout=10
        )
        data = json.loads(result.stdout)
        if "tenant_access_token" in data:
            return data["tenant_access_token"]
        else:
            print(f"❌ 获取 token 失败: {data.get('msg', 'unknown')}")
            return None
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return None


def create_feishu_chat(app_id, app_secret, chat_name, user_open_ids=None):
    """创建飞书群聊并可选添加成员"""
    token = get_tenant_token(app_id, app_secret)
    if not token:
        return None

    # 创建群聊
    create_result = subprocess.run(
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
        data = json.loads(create_result.stdout)
        if data.get("code") != 0:
            print(f"❌ 创建群聊失败: {data.get('msg')}")
            return None

        chat_id = data["data"]["chat_id"]
        print(f"✅ 群聊创建成功: {chat_name} ({chat_id})")

        # 添加成员
        if user_open_ids:
            add_result = subprocess.run(
                ["curl", "-s", "-X", "POST",
                 f"https://open.feishu.cn/open-apis/im/v1/chats/{chat_id}/members",
                 "-H", f"Authorization: Bearer {token}",
                 "-H", "Content-Type: application/json",
                 "-d", json.dumps({"id_list": user_open_ids})],
                capture_output=True, text=True, timeout=10
            )
            add_data = json.loads(add_result.stdout)
            if add_data.get("code") == 0:
                print(f"✅ 已添加 {len(user_open_ids)} 个成员")
            else:
                print(f"⚠️ 添加成员失败: {add_data.get('msg')}")

        return chat_id

    except Exception as e:
        print(f"❌ 解析响应失败: {e}")
        return None


def add_member_to_chat(app_id, app_secret, chat_id, user_open_id):
    """添加成员到群聊"""
    token = get_tenant_token(app_id, app_secret)
    if not token:
        return False

    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         f"https://open.feishu.cn/open-apis/im/v1/chats/{chat_id}/members",
         "-H", f"Authorization: Bearer {token}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"id_list": [user_open_id]})],
        capture_output=True, text=True, timeout=10
    )

    try:
        data = json.loads(result.stdout)
        if data.get("code") == 0:
            print(f"✅ 成员 {user_open_id} 已添加")
            return True
        else:
            print(f"❌ 添加失败: {data.get('msg')}")
            return False
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return False


def remove_member_from_chat(app_id, app_secret, chat_id, user_open_id):
    """从群聊移除成员"""
    token = get_tenant_token(app_id, app_secret)
    if not token:
        return False

    result = subprocess.run(
        ["curl", "-s", "-X", "DELETE",
         f"https://open.feishu.cn/open-apis/im/v1/chats/{chat_id}/members",
         "-H", f"Authorization: Bearer {token}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"id_list": [user_open_id]})],
        capture_output=True, text=True, timeout=10
    )

    try:
        data = json.loads(result.stdout)
        if data.get("code") == 0:
            print(f"✅ 成员 {user_open_id} 已移除")
            return True
        else:
            print(f"❌ 移除失败: {data.get('msg')}")
            return False
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return False


def load_openclaw_config():
    """加载 OpenClaw 配置"""
    if not Path(OPENCLAW_CONFIG).exists():
        print(f"⚠️ 配置文件不存在: {OPENCLAW_CONFIG}")
        return None
    with open(OPENCLAW_CONFIG, "r", encoding="utf-8") as f:
        return json.load(f)


def save_openclaw_config(config, reason="feishu_chat_manager"):
    """安全保存配置"""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(BACKUP_DIR, f"{reason}_{ts}.json")
    shutil.copy2(OPENCLAW_CONFIG, backup_path)
    print(f"📦 配置备份: {backup_path}")

    with open(OPENCLAW_CONFIG, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print(f"✅ 配置已写入")
    return True


def add_binding_to_config(agent_id, chat_id, account_id="default"):
    """添加 binding 到配置"""
    config = load_openclaw_config()
    if not config:
        return False

    # 初始化必要字段
    if "bindings" not in config:
        config["bindings"] = []
    if "channels" not in config:
        config["channels"] = {}
    if "feishu" not in config["channels"]:
        config["channels"]["feishu"] = {}
    if "groups" not in config["channels"]["feishu"]:
        config["channels"]["feishu"]["groups"] = {}

    # 检查是否已存在
    for binding in config["bindings"]:
        peer = binding.get("match", {}).get("peer", {})
        if peer.get("id") == chat_id:
            print(f"⚠️ Binding 已存在: {binding.get('agentId')} → {chat_id}")
            return False

    # 添加 binding
    binding = {
        "agentId": agent_id,
        "match": {
            "channel": "feishu",
            "accountId": account_id,
            "peer": {
                "kind": "group",
                "id": chat_id
            }
        }
    }
    config["bindings"].append(binding)

    # 添加 groups 配置
    config["channels"]["feishu"]["groups"][chat_id] = {
        "enabled": True,
        "requireMention": False
    }

    print(f"✅ Binding 添加: {agent_id} → group:{chat_id}")
    return save_openclaw_config(config, f"add_binding_{agent_id}_{chat_id}")


def remove_binding_from_config(chat_id):
    """从配置中移除 binding"""
    config = load_openclaw_config()
    if not config:
        return False

    original_count = len(config.get("bindings", []))
    new_bindings = [b for b in config.get("bindings", [])
                    if b.get("match", {}).get("peer", {}).get("id") != chat_id]
    config["bindings"] = new_bindings

    # 移除 groups 配置
    if "channels" in config and "feishu" in config["channels"] and "groups" in config["channels"]["feishu"]:
        if chat_id in config["channels"]["feishu"]["groups"]:
            del config["channels"]["feishu"]["groups"][chat_id]

    removed = original_count - len(new_bindings)
    if removed > 0:
        print(f"✅ 已移除 {removed} 个 binding 引用")
        return save_openclaw_config(config, f"remove_binding_{chat_id}")
    else:
        print(f"⚠️ 未找到匹配的 binding: {chat_id}")
        return False


def list_bindings():
    """列出当前所有 binding"""
    config = load_openclaw_config()
    if not config:
        return

    bindings = config.get("bindings", [])
    if not bindings:
        print("📭 暂无 binding 配置")
        return

    print(f"\n{'Agent':<15} {'Peer ID':<35} {'Account'}")
    print("-" * 60)
    for binding in bindings:
        agent = binding.get("agentId", "-")
        peer = binding.get("match", {}).get("peer", {})
        peer_id = peer.get("id", "-")
        account = binding.get("match", {}).get("accountId", "default")
        print(f"{agent:<15} {peer_id:<35} {account}")
    print(f"\n总计: {len(bindings)} bindings")


def main():
    parser = argparse.ArgumentParser(description="testclaude 团队 - 飞书群聊管理工具")
    parser.add_argument("--create-chat", help="创建群聊 (群聊名称)")
    parser.add_argument("--add-member", nargs=2, metavar=("CHAT_ID", "USER_OPEN_ID"), help="添加成员")
    parser.add_argument("--remove-member", nargs=2, metavar=("CHAT_ID", "USER_OPEN_ID"), help="移除成员")
    parser.add_argument("--bind", nargs=2, metavar=("AGENT_ID", "CHAT_ID"), help="绑定 agent 到群聊")
    parser.add_argument("--unbind", metavar="CHAT_ID", help="解绑群聊")
    parser.add_argument("--list", action="store_true", help="列出所有 binding")
    parser.add_argument("--app-id", help="飞书 App ID")
    parser.add_argument("--app-secret", help="飞书 App Secret")
    parser.add_argument("--user-open-ids", nargs="+", help="用户 open_id 列表")
    parser.add_argument("--account-id", default="default", help="飞书账号 ID")

    args = parser.parse_args()

    if args.create_chat:
        if not args.app_id or not args.app_secret:
            print("❌ 创建群聊需要提供 --app-id 和 --app-secret")
            return
        chat_id = create_feishu_chat(args.app_id, args.app_secret,
                                      args.create_chat, args.user_open_ids)
        if chat_id:
            print(f"\n💡 群聊 ID: {chat_id}")
            print(f"   可使用以下命令绑定 agent:")
            print(f"   python3 feishu_chat_manager.py --bind orchestrator-agent {chat_id}")

    elif args.add_member:
        if not args.app_id or not args.app_secret:
            print("❌ 添加成员需要提供 --app-id 和 --app-secret")
            return
        chat_id, user_id = args.add_member
        add_member_to_chat(args.app_id, args.app_secret, chat_id, user_id)

    elif args.remove_member:
        if not args.app_id or not args.app_secret:
            print("❌ 移除成员需要提供 --app-id 和 --app-secret")
            return
        chat_id, user_id = args.remove_member
        remove_member_from_chat(args.app_id, args.app_secret, chat_id, user_id)

    elif args.bind:
        agent_id, chat_id = args.bind
        add_binding_to_config(agent_id, chat_id, args.account_id)
        print(f"\n💡 配置已更新，请运行以下命令重启 gateway:")
        print(f"   openclaw gateway restart")

    elif args.unbind:
        remove_binding_from_config(args.unbind)
        print(f"\n💡 配置已更新，请运行以下命令重启 gateway:")
        print(f"   openclaw gateway restart")

    elif args.list:
        list_bindings()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
