#!/bin/bash

# check-pr-status.sh - 检查 PR 的 CI 状态
# 用法: ./check-pr-status.sh <pr-number> [repo]

set -e

PR_NUMBER="$1"
REPO="${2:-testuser/Screenshot}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Checking PR #$PR_NUMBER CI Status ===${NC}"

# 检查 gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI not installed${NC}"
    exit 1
fi

# 获取 PR 状态
PR_DATA=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json state,statusCheckRollup,commits,mergeable 2>/dev/null)

if [ -z "$PR_DATA" ]; then
    echo -e "${RED}Failed to get PR #$PR_NUMBER status${NC}"
    exit 1
fi

# 提取状态
PR_STATE=$(echo "$PR_DATA" | jq -r '.state')
MERGEABLE=$(echo "$PR_DATA" | jq -r '.mergeable')

echo "PR State: $PR_STATE"
echo "Mergeable: $MERGEABLE"

# 检查 CI 状态
CI_STATUSES=$(echo "$PR_DATA" | jq -r '.statusCheckRollup[]? | "\(.context): \(.state)"' 2>/dev/null)

if [ -n "$CI_STATUSES" ]; then
    echo ""
    echo -e "${BLUE}CI Checks:${NC}"
    echo "$CI_STATUSES"
fi

# 判断 CI 是否通过
CI_PASSED=true
FAILED_CHECKS=""

if [ -n "$CI_STATUSES" ]; then
    while IFS= read -r line; do
        if [[ "$line" == *": FAILURE"* ]] || [[ "$line" == *": ERROR"* ]]; then
            CI_PASSED=false
            FAILED_CHECKS="$FAILED_CHECKS\n$line"
        fi
    done <<< "$CI_STATUSES"
fi

# 输出结果
echo ""
if [ "$PR_STATE" = "OPEN" ] && [ "$MERGEABLE" = "MERGEABLE" ] && [ "$CI_PASSED" = true ]; then
    echo -e "${GREEN}✓ PR is ready to merge (CI passed)${NC}"
    exit 0
elif [ "$PR_STATE" = "OPEN" ] && [ "$CI_PASSED" = false ]; then
    echo -e "${RED}✗ CI checks failed:${NC}"
    echo -e "$FAILED_CHECKS"
    exit 10
elif [ "$PR_STATE" = "OPEN" ] && [ "$MERGEABLE" != "MERGEABLE" ]; then
    echo -e "${YELLOW}⚠ PR has merge conflicts${NC}"
    exit 11
elif [ "$PR_STATE" = "MERGED" ]; then
    echo -e "${GREEN}✓ PR already merged${NC}"
    exit 12
else
    echo -e "${YELLOW}⚠ PR state: $PR_STATE${NC}"
    exit 1
fi
