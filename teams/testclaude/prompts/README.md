# Prompts 目录

## 📁 目录结构

```
prompts/
├── README.md           # 本文件
├── archive/            # 归档的旧 prompt 文件
│   ├── redesign.txt
│   ├── redesign-deepseek-*.txt
│   └── ...
├── redesign.txt        # 最新的 redesign prompt
├── redesign-deepseek.txt
├── redesign-with-files.txt
├── test-screenshot-task.txt
└── ...
```

## 📝 用途

此目录用于存放 `generate-prompt.sh` 生成的任务提示文件。每个 prompt 文件包含：

- 项目元数据（仓库、分支、技术栈）
- 项目文档和结构分析
- 最近变更记录
- 任务具体要求
- 代码规范和约定

## 🚀 使用方式

### 生成新 prompt
```bash
cd /home/administrator/.openclaw-zero/workspace/teams/testclaude
./scripts/generate-prompt.sh Screenshot "任务描述" --type feature --output ./prompts/task-name.txt
```

### 查看已有 prompt
```bash
# 列出所有 prompt
ls -la prompts/

# 查看特定 prompt
cat prompts/redesign.txt
```

### 使用 prompt 启动任务
```bash
./scripts/spawn-agent.sh Screenshot feature/branch task-id ./prompts/task-name.txt
```

## 📊 命名规范

建议使用以下命名格式：
- `{task-type}-{description}.txt` - 例如 `feature-screenshot-format.txt`
- `{repo}-{timestamp}.txt` - 例如 `Screenshot-1732000000.txt`

## 🗂️ 归档管理

- **活跃 prompt**：存放在 `prompts/` 根目录
- **已使用的 prompt**：移到 `archive/` 目录
- **定期清理**：建议每周清理一次 archive 目录

## 🔧 配置说明

脚本已配置默认使用此目录：
- `generate-prompt.sh` 默认输出到 `prompts/`
- `spawn-agent.sh` 支持相对路径自动转换

---
*最后更新: 2026-03-20*
