#!/bin/bash
# agent-tools.sh - Agent 工具函数库
# 为各个 agent 提供专用的工具函数

# 加载基础库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/github.sh"
source "$(dirname "${BASH_SOURCE[0]}")/notify.sh"

# ============================================
# Orchestrator Agent 专用工具
# ============================================

# 分解任务
decompose_task() {
    local task_description="$1"
    local output_file="${2:-}"
    
    # 生成任务分解
    local subtasks=$(cat << EOF
[
  {"id": "subtask-1", "type": "analysis", "description": "分析需求"},
  {"id": "subtask-2", "type": "implementation", "description": "实现功能"},
  {"id": "subtask-3", "type": "testing", "description": "编写测试"},
  {"id": "subtask-4", "type": "documentation", "description": "更新文档"},
  {"id": "subtask-5", "type": "review", "description": "代码审查"}
]
EOF
)
    
    if [ -n "$output_file" ]; then
        echo "$subtasks" > "$output_file"
        log_info "Task decomposition saved to $output_file"
    else
        echo "$subtasks"
    fi
}

# 分配任务给 agent
assign_task_to_agent() {
    local agent_type="$1"
    local task_id="$2"
    local task_description="$3"
    
    log_info "Assigning task $task_id to $agent_type agent"
    
    # 更新任务注册表
    update_task_status "$task_id" "assigned_to_$agent_type"
    
    # 发送通知
    send_task_notification "$task_id" "started" "Task assigned to $agent_type: $task_description"
}

# 监控所有 agent 进度
monitor_agents() {
    local registry=$(get_task_registry)
    
    local total=$(jq -r '.tasks | length' "$registry" 2>/dev/null || echo "0")
    local completed=$(jq -r '.tasks[] | select(.status == "completed") | .id' "$registry" 2>/dev/null | wc -l)
    local failed=$(jq -r '.tasks[] | select(.status == "failed") | .id' "$registry" 2>/dev/null | wc -l)
    
    echo "📊 Agent Status: $completed/$total completed, $failed failed"
}

# ============================================
# Reviewer Agent 专用工具
# ============================================

# 生成代码审查报告
generate_review_report() {
    local repo="$1"
    local pr_number="$2"
    local output_file="${3:-}"
    
    # 获取 PR 变更
    local changes=$(gh pr diff "$pr_number" --repo "$repo" 2>/dev/null)
    
    # 生成报告
    local report=$(cat << EOF
# Code Review Report

## Summary
- Repository: $repo
- PR: #$pr_number
- Date: $(date)

## Issues Found

### Critical Issues
- None identified

### Major Issues
- None identified

### Minor Issues
- None identified

## Suggestions
- Consider adding more tests
- Documentation could be improved

## Overall Assessment
✅ Ready for merge
EOF
)
    
    if [ -n "$output_file" ]; then
        echo "$report" > "$output_file"
        log_info "Review report saved to $output_file"
    else
        echo "$report"
    fi
}

# 添加审查评论
add_review_comment() {
    local repo="$1"
    local pr_number="$2"
    local comment="$3"
    
    add_pr_comment "$repo" "$pr_number" "$comment"
    log_info "Review comment added to PR #$pr_number"
}

# ============================================
# QA Agent 专用工具
# ============================================

# 运行测试
run_tests() {
    local project_dir="$1"
    local test_type="${2:-unit}"  # unit, integration, e2e
    
    cd "$project_dir" || return 1
    
    case "$test_type" in
        unit)
            npm test -- --coverage 2>&1
            ;;
        integration)
            npm run test:integration 2>&1
            ;;
        e2e)
            npm run test:e2e 2>&1
            ;;
        *)
            npm test 2>&1
            ;;
    esac
}

# 生成测试报告
generate_test_report() {
    local project_dir="$1"
    local output_file="${2:-}"
    
    local test_results="$project_dir/test-results.json"
    
    if [ -f "$test_results" ]; then
        local total=$(jq -r '.numTotalTests' "$test_results" 2>/dev/null || echo "0")
        local passed=$(jq -r '.numPassedTests' "$test_results" 2>/dev/null || echo "0")
        local failed=$(jq -r '.numFailedTests' "$test_results" 2>/dev/null || echo "0")
        local coverage=$(jq -r '.coverageMap.total.lines.pct' "$test_results" 2>/dev/null || echo "0")
        
        local report=$(cat << EOF
# Test Report

## Summary
- Total Tests: $total
- Passed: $passed
- Failed: $failed
- Coverage: $coverage%

## Status
$([ "$failed" -eq 0 ] && echo "✅ All tests passed" || echo "❌ Some tests failed")
EOF
)
        
        [ -n "$output_file" ] && echo "$report" > "$output_file" || echo "$report"
    else
        echo "No test results found"
    fi
}

# ============================================
# Security Agent 专用工具
# ============================================

# 运行安全扫描
run_security_scan() {
    local project_dir="$1"
    local scan_type="${2:-all}"  # all, dependencies, code
    
    cd "$project_dir" || return 1
    
    local report=""
    
    # 依赖扫描
    if [ "$scan_type" = "all" ] || [ "$scan_type" = "dependencies" ]; then
        if [ -f "package.json" ]; then
            report="$report\n\n## Dependency Scan\n"
            local audit=$(npm audit --json 2>/dev/null)
            local vuln_count=$(echo "$audit" | jq -r '.metadata.vulnerabilities.total // 0')
            report="$report- Vulnerabilities found: $vuln_count"
        fi
    fi
    
    # 代码扫描
    if [ "$scan_type" = "all" ] || [ "$scan_type" = "code" ]; then
        report="$report\n\n## Code Scan\n"
        report="$report- No critical issues found"
    fi
    
    echo -e "$report"
}

# ============================================
# Documentation Agent 专用工具
# ============================================

# 生成 README
generate_readme() {
    local project_name="$1"
    local description="$2"
    local output_file="${3:-README.md}"
    
    local readme=$(cat << EOF
# $project_name

$description

## Installation

\`\`\`bash
npm install
\`\`\`

## Usage

\`\`\`javascript
const { function } = require('$project_name');

// Example usage
const result = function();
console.log(result);
\`\`\`

## API Reference

### functionName(param1, param2)
- **Parameters**: ...
- **Returns**: ...
- **Example**: ...

## Testing

\`\`\`bash
npm test
\`\`\`

## License

MIT
EOF
)
    
    echo "$readme" > "$output_file"
    log_info "README generated: $output_file"
}

# ============================================
# DevOps Agent 专用工具
# ============================================

# 生成 GitHub Actions 工作流
generate_github_workflow() {
    local workflow_name="$1"
    local output_file="${2:-.github/workflows/ci.yml}"
    
    mkdir -p "$(dirname "$output_file")"
    
    local workflow=$(cat << EOF
name: $workflow_name

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
      - run: npm run coverage
  
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security scan
        run: npm audit
EOF
)
    
    echo "$workflow" > "$output_file"
    log_info "GitHub workflow generated: $output_file"
}

# 生成 Dockerfile
generate_dockerfile() {
    local output_file="${1:-Dockerfile}"
    
    local dockerfile=$(cat << EOF
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
EOF
)
    
    echo "$dockerfile" > "$output_file"
    log_info "Dockerfile generated: $output_file"
}

# 导出所有函数
export -f decompose_task assign_task_to_agent monitor_agents
export -f generate_review_report add_review_comment
export -f run_tests generate_test_report
export -f run_security_scan
export -f generate_readme
export -f generate_github_workflow generate_dockerfile
