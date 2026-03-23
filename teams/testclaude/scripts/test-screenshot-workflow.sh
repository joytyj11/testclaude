#!/bin/bash
# test-screenshot-workflow.sh - 完整测试 Screenshot 项目的所有 agent 流程

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "\n${GREEN}=== $* ===${NC}\n"; }

# Configuration
TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
PROJECT_DIR="/home/administrator/openclaw-zero-token/projects/Screenshot"
TEST_RESULTS_DIR="$TEAM_DIR/swarm/test-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEST_ID="screenshot-test-$TIMESTAMP"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

log_step "开始测试 Screenshot 项目 - $TEST_ID"

# Step 1: 项目准备
log_step "Step 1: 项目环境检查"
cd "$PROJECT_DIR"

log_info "检查项目结构..."
if [ ! -f "package.json" ]; then
  log_error "package.json 不存在"
  exit 1
fi
log_success "项目结构正确"

log_info "安装依赖..."
npm install 2>&1 | tail -5
log_success "依赖安装完成"

# Step 2: 运行单元测试
log_step "Step 2: 运行单元测试"

log_info "执行测试用例..."
npm test -- --json --outputFile="$TEST_RESULTS_DIR/$TEST_ID-test-results.json" 2>&1 | tee "$TEST_RESULTS_DIR/$TEST_ID-test-output.log"
TEST_EXIT_CODE=${PIPESTATUS[0]}

if [ $TEST_EXIT_CODE -eq 0 ]; then
  log_success "所有测试通过"
  TEST_STATUS="passed"
else
  log_error "部分测试失败"
  TEST_STATUS="failed"
fi

# 提取测试统计
if [ -f "$TEST_RESULTS_DIR/$TEST_ID-test-results.json" ]; then
  TOTAL_TESTS=$(jq '.numTotalTests' "$TEST_RESULTS_DIR/$TEST_ID-test-results.json" 2>/dev/null || echo "0")
  PASSED_TESTS=$(jq '.numPassedTests' "$TEST_RESULTS_DIR/$TEST_ID-test-results.json" 2>/dev/null || echo "0")
  FAILED_TESTS=$(jq '.numFailedTests' "$TEST_RESULTS_DIR/$TEST_ID-test-results.json" 2>/dev/null || echo "0")
  
  log_info "测试统计: 总计 $TOTAL_TESTS, 通过 $PASSED_TESTS, 失败 $FAILED_TESTS"
fi

# Step 3: 运行测试覆盖率
log_step "Step 3: 测试覆盖率分析"

npm run test:coverage -- --coverageDirectory="$TEST_RESULTS_DIR/$TEST_ID-coverage" 2>&1 | tail -10

if [ -f "coverage/index.html" ]; then
  log_success "覆盖率报告已生成"
  cp -r coverage/* "$TEST_RESULTS_DIR/$TEST_ID-coverage/" 2>/dev/null || true
fi

# 提取覆盖率（如果有）
if [ -f "coverage/coverage-summary.json" ]; then
  COVERAGE_LINES=$(jq '.total.lines.pct' coverage/coverage-summary.json 2>/dev/null || echo "0")
  COVERAGE_STATEMENTS=$(jq '.total.statements.pct' coverage/coverage-summary.json 2>/dev/null || echo "0")
  log_info "代码覆盖率: 行 $COVERAGE_LINES%, 语句 $COVERAGE_STATEMENTS%"
fi

# Step 4: Lint 检查
log_step "Step 4: 代码质量检查"

if command -v eslint &> /dev/null; then
  npx eslint src/ --format json --output-file="$TEST_RESULTS_DIR/$TEST_ID-lint.json" 2>&1 || true
  log_success "Lint 检查完成"
else
  log_warning "ESLint 未安装，跳过"
fi

# Step 5: 安全扫描
log_step "Step 5: 依赖安全扫描"

npm audit --json > "$TEST_RESULTS_DIR/$TEST_ID-audit.json" 2>&1 || true

if [ -f "$TEST_RESULTS_DIR/$TEST_ID-audit.json" ]; then
  VULN_COUNT=$(jq '.metadata.vulnerabilities.total' "$TEST_RESULTS_DIR/$TEST_ID-audit.json" 2>/dev/null || echo "0")
  if [ "$VULN_COUNT" -gt 0 ]; then
    log_warning "发现 $VULN_COUNT 个漏洞"
  else
    log_success "无安全漏洞"
  fi
fi

# Step 6: 生成测试报告
log_step "Step 6: 生成测试报告"

REPORT_FILE="$TEST_RESULTS_DIR/$TEST_ID-report.md"

cat > "$REPORT_FILE" << EOF
# Screenshot 项目测试报告

**测试 ID**: $TEST_ID  
**时间**: $(date)  
**状态**: $TEST_STATUS

## 测试统计

| 指标 | 数值 |
|------|------|
| 总测试数 | $TOTAL_TESTS |
| 通过数 | $PASSED_TESTS |
| 失败数 | $FAILED_TESTS |
| 通过率 | $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")% |
| 代码覆盖率(行) | ${COVERAGE_LINES:-N/A}% |

## 测试用例详情

$(cat "$TEST_RESULTS_DIR/$TEST_ID-test-output.log" | grep -E "(✓|✗)" | head -20 || echo "无详细输出")

## 安全扫描

- 漏洞数量: ${VULN_COUNT:-0}

## 文件输出

- 测试结果: $TEST_RESULTS_DIR/$TEST_ID-test-results.json
- 覆盖率报告: $TEST_RESULTS_DIR/$TEST_ID-coverage/
- 安全审计: $TEST_RESULTS_DIR/$TEST_ID-audit.json

## 建议

$(if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ 所有测试通过，代码质量良好"
else
  echo "⚠️ 存在失败的测试，请检查并修复"
fi)

EOF

log_success "测试报告已生成: $REPORT_FILE"

# Step 7: 发送通知到外部频道
log_step "Step 7: 发送测试结果通知"

if [ -f "$TEAM_DIR/scripts/channel-notify.sh" ]; then
  # 构建通知消息
  NOTIFY_MESSAGE="Screenshot 项目测试完成\n"
  NOTIFY_MESSAGE="${NOTIFY_MESSAGE}状态: $TEST_STATUS\n"
  NOTIFY_MESSAGE="${NOTIFY_MESSAGE}测试: $PASSED_TESTS/$TOTAL_TESTS 通过\n"
  NOTIFY_MESSAGE="${NOTIFY_MESSAGE}覆盖率: ${COVERAGE_LINES:-N/A}%\n"
  NOTIFY_MESSAGE="${NOTIFY_MESSAGE}漏洞: ${VULN_COUNT:-0}\n"
  NOTIFY_MESSAGE="${NOTIFY_MESSAGE}报告: $REPORT_FILE"
  
  if [ "$TEST_STATUS" = "passed" ]; then
    "$TEAM_DIR/scripts/channel-notify.sh" all "$NOTIFY_MESSAGE" \
      --title "✅ Screenshot 测试通过" 2>/dev/null || true
  else
    "$TEAM_DIR/scripts/channel-notify.sh" all "$NOTIFY_MESSAGE" \
      --title "❌ Screenshot 测试失败" 2>/dev/null || true
  fi
  
  log_success "通知已发送"
fi

# Step 8: 更新任务注册表
log_step "Step 8: 更新任务状态"

REGISTRY="$TEAM_DIR/swarm/active-tasks.json"
if [ -f "$REGISTRY" ]; then
  jq ".tasks += [{
    id: \"$TEST_ID\",
    type: \"screenshot-test\",
    description: \"Screenshot 项目完整测试\",
    status: \"$TEST_STATUS\",
    startTime: \"$(date -Iseconds)\",
    results: {
      total: $TOTAL_TESTS,
      passed: $PASSED_TESTS,
      failed: $FAILED_TESTS,
      coverage: ${COVERAGE_LINES:-0},
      vulnerabilities: ${VULN_COUNT:-0}
    },
    report: \"$REPORT_FILE\"
  }]" "$REGISTRY" > "$REGISTRY.tmp" 2>/dev/null && mv "$REGISTRY.tmp" "$REGISTRY"
  log_success "任务已记录到注册表"
fi

# Step 9: 运行任务状态监控
log_step "Step 9: 触发状态监控通知"

if [ -f "$TEAM_DIR/scripts/task-status-monitor.sh" ]; then
  "$TEAM_DIR/scripts/task-status-monitor.sh" check 2>/dev/null || true
fi

# 最终总结
log_step "测试完成总结"

echo ""
echo "📊 测试结果摘要:"
echo "   ✅ 测试通过率: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")% ($PASSED_TESTS/$TOTAL_TESTS)"
echo "   📈 代码覆盖率: ${COVERAGE_LINES:-N/A}%"
echo "   🔒 安全漏洞: ${VULN_COUNT:-0}"
echo "   📁 报告位置: $REPORT_FILE"
echo ""

if [ $TEST_EXIT_CODE -eq 0 ]; then
  log_success "所有测试通过！Screenshot 项目质量良好。"
  exit 0
else
  log_error "存在失败的测试，请查看报告了解详情。"
  exit 1
fi
