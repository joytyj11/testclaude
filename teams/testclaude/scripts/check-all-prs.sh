#!/bin/bash

# check-all-prs.sh - 检查所有活跃任务的 PR 状态
# 用法: ./check-all-prs.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="$SCRIPT_DIR/../swarm/active-tasks.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Checking All PR Statuses ===${NC}"

# 读取所有有 PR 的任务
PR_TASKS=$(jq -r '.tasks[] | select(.prUrl != null) | "\(.id)|\(.prUrl)"' "$REGISTRY_FILE" 2>/dev/null)

if [ -z "$PR_TASKS" ]; then
    echo "No PRs found in active tasks"
    exit 0
fi

READY_COUNT=0
FAILED_COUNT=0
CONFLICT_COUNT=0

while IFS='|' read -r task_id pr_url; do
    if [ -z "$task_id" ]; then
        continue
    fi
    
    echo ""
    echo -e "${BLUE}Task: $task_id${NC}"
    
    # 提取 PR 号
    PR_NUMBER=$(echo "$pr_url" | grep -oP 'pull/\K\d+')
    
    if [ -n "$PR_NUMBER" ]; then
        # 检查 PR 状态
        "$SCRIPT_DIR/check-pr-status.sh" "$PR_NUMBER" 2>&1
        EXIT_CODE=$?
        
        case $EXIT_CODE in
            0)
                echo -e "${GREEN}  → PR ready for merge${NC}"
                READY_COUNT=$((READY_COUNT + 1))
                ;;
            10)
                echo -e "${RED}  → CI checks failed${NC}"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                ;;
            11)
                echo -e "${YELLOW}  → Merge conflicts${NC}"
                CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
                ;;
            12)
                echo -e "${GREEN}  → Already merged${NC}"
                ;;
            *)
                echo -e "${YELLOW}  → Status unknown${NC}"
                ;;
        esac
    fi
done <<< "$PR_TASKS"

# 汇总
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo "Ready to merge: $READY_COUNT"
echo "CI failed: $FAILED_COUNT"
echo "Merge conflicts: $CONFLICT_COUNT"

# 返回码
if [ $FAILED_COUNT -gt 0 ]; then
    exit 10
elif [ $CONFLICT_COUNT -gt 0 ]; then
    exit 11
else
    exit 0
fi
