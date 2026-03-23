#!/bin/bash
# test-feishu.sh - 测试飞书 API 连接

set -euo pipefail

TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
CONFIG_FILE="$TEAM_DIR/.env"

# 加载配置
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo "=========================================="
echo "飞书 API 连接测试"
echo "=========================================="
echo ""

# 1. 检查配置
echo "1. 检查配置..."
if [ -n "$FEISHU_APP_ID" ]; then
    echo "   ✅ FEISHU_APP_ID: ${FEISHU_APP_ID:0:10}..."
else
    echo "   ❌ FEISHU_APP_ID 未配置"
fi

if [ -n "$FEISHU_APP_SECRET" ]; then
    echo "   ✅ FEISHU_APP_SECRET: 已配置 (长度: ${#FEISHU_APP_SECRET})"
else
    echo "   ❌ FEISHU_APP_SECRET 未配置"
fi

if [ -n "$FEISHU_WEBHOOK_URL" ]; then
    echo "   ✅ FEISHU_WEBHOOK_URL: ${FEISHU_WEBHOOK_URL:0:30}..."
else
    echo "   ⚠️  FEISHU_WEBHOOK_URL 未配置 (可选)"
fi
echo ""

# 2. 测试获取 access token
echo "2. 测试获取 access token..."
if [ -n "$FEISHU_APP_ID" ] && [ -n "$FEISHU_APP_SECRET" ]; then
    response=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "{\"app_id\":\"$FEISHU_APP_ID\",\"app_secret\":\"$FEISHU_APP_SECRET\"}")
    
    code=$(echo "$response" | jq -r '.code // 999')
    
    if [ "$code" = "0" ]; then
        token=$(echo "$response" | jq -r '.tenant_access_token')
        echo "   ✅ 获取 token 成功"
        echo "   Token: ${token:0:20}..."
    else
        msg=$(echo "$response" | jq -r '.msg // "Unknown error"')
        echo "   ❌ 获取 token 失败: $msg"
        echo "   完整响应: $response"
    fi
else
    echo "   ⚠️  跳过 (缺少 App ID/Secret)"
fi
echo ""

# 3. 测试 webhook 模式
echo "3. 测试 webhook 模式..."
if [ -n "$FEISHU_WEBHOOK_URL" ]; then
    test_msg="Test message from TestClaude at $(date '+%H:%M:%S')"
    payload=$(jq -n --arg msg "$test_msg" '{msg_type: "text", content: {text: $msg}}')
    
    response=$(curl -s -X POST "$FEISHU_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    if echo "$response" | jq -e '.code == 0' > /dev/null 2>&1; then
        echo "   ✅ Webhook 发送成功"
    else
        echo "   ⚠️  Webhook 响应: $response"
    fi
else
    echo "   ⚠️  跳过 (缺少 webhook URL)"
fi
echo ""

# 4. 测试创建群聊（需要 token）
echo "4. 测试创建群聊..."
if [ -n "$FEISHU_APP_ID" ] && [ -n "$FEISHU_APP_SECRET" ]; then
    # 重新获取 token
    token_response=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "{\"app_id\":\"$FEISHU_APP_ID\",\"app_secret\":\"$FEISHU_APP_SECRET\"}")
    
    token=$(echo "$token_response" | jq -r '.tenant_access_token')
    
    if [ "$token" != "null" ] && [ -n "$token" ]; then
        # 创建测试群聊
        test_group_name="TestClaude-Test-$(date +%H%M%S)"
        create_response=$(curl -s -X POST "https://open.feishu.cn/open-apis/chat/v4/create" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json; charset=utf-8" \
            -d "{\"name\":\"$test_group_name\",\"description\":\"API test group\"}")
        
        create_code=$(echo "$create_response" | jq -r '.code // 999')
        
        if [ "$create_code" = "0" ]; then
            chat_id=$(echo "$create_response" | jq -r '.data.chat_id')
            echo "   ✅ 创建群聊成功"
            echo "   群聊名称: $test_group_name"
            echo "   群聊 ID: $chat_id"
            
            # 保存群聊 ID
            echo ""
            echo "   可以将以下配置添加到 .env:"
            echo "   FEISHU_GROUP_ID=$chat_id"
        else
            create_msg=$(echo "$create_response" | jq -r '.msg // "Unknown error"')
            echo "   ⚠️  创建群聊失败: $create_msg"
            echo "   可能需要应用具有创建群聊的权限"
        fi
    fi
else
    echo "   ⚠️  跳过 (需要 App ID/Secret)"
fi
echo ""

# 5. 发送 Agent 测试消息
echo "5. 发送 Agent 测试消息..."
if [ -f "$TEAM_DIR/scripts/feishu-chat.sh" ]; then
    # 测试发送 Agent 消息（会使用配置的 webhook 或 API）
    echo "   发送测试消息..."
    "$TEAM_DIR/scripts/feishu-chat.sh" agent "test-orchestrator" "test-coding" "test" '{"message":"API test successful"}' 2>&1 | head -5
    echo "   ✅ 消息已发送"
else
    echo "   ❌ feishu-chat.sh 不存在"
fi
echo ""

echo "=========================================="
echo "测试完成"
echo "=========================================="
