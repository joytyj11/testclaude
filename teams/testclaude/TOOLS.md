# TestClaude Team - TOOLS.md

## 本地工具配置

### GitHub
```bash
# 已配置账号
gh auth status
# 账号: joytyj11
# Token 权限: gist, read:org, repo

# 主要仓库
REPO="joytyj11/testclaude"
```

### Feishu
```yaml
# 群聊配置
chat_id: "oc_76f3d8125fa8843b0bcdecc440e2605f"

# 权限状态
- docx:document:readonly ✅
- docx:document:write ❌ (需申请)
- bitable:app:create ❌ (需申请)
- drive:file:write ❌ (需申请)
```

### 常用命令

#### GitHub 操作
```bash
# 创建 Issue
gh issue create --repo $REPO --title "标题" --body "内容"

# 创建 PR
gh pr create --repo $REPO --title "标题" --body "内容" --base master

# 查看 PR
gh pr view 2 --repo $REPO --json title,state,mergeable

# 合并 PR
gh pr merge 2 --repo $REPO --squash
```

#### Git 操作
```bash
# 创建分支
git checkout -b feature/xxx

# 提交代码
git add . && git commit -m "feat: xxx"

# 推送分支
git push origin feature/xxx

# 同步主分支
git checkout master && git pull
```

#### 测试命令
```bash
# 天气查询测试
python3 weather.py 北京

# 浏览器自动化测试
browser start profile=openclaw
browser open profile=openclaw url=https://example.com

# 子代理测试
sessions_spawn task="测试任务" runtime="subagent"
```

## 环境变量
```bash
# GitHub Token (可选，gh CLI 已处理)
GH_TOKEN=gho_xxx

# 搜索 API (待配置)
SEARCH_API_KEY=xxx

# TTS API (待配置)
ELEVENLABS_API_KEY=xxx
```

## 测试脚本
```python
# test_weather.py
import subprocess

def test_weather():
    result = subprocess.run(
        ["python3", "weather.py", "上海"],
        capture_output=True,
        text=True
    )
    assert "上海" in result.stdout
    print("✅ 天气测试通过")

if __name__ == "__main__":
    test_weather()
```

---
*更新: 2026-03-23*
