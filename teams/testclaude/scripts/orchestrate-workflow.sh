#!/bin/bash
# orchestrate-workflow.sh - Main workflow orchestrator for multi-agent coordination
# Usage: ./orchestrate-workflow.sh <workflow-type> <task-description> [options]

set -euo pipefail

# --- Configuration ---
TEAM_DIR="$HOME/.openclaw-zero/workspace/teams/testclaude"
SCRIPTS_DIR="$TEAM_DIR/scripts"
SWARM_DIR="$TEAM_DIR/swarm"
LOG_DIR="$SWARM_DIR/logs"
REGISTRY="$SWARM_DIR/active-tasks.json"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Parse arguments ---
WORKFLOW="${1:-}"
TASK_DESC="${2:-}"
shift 2 2>/dev/null || true

# Parse additional options
REPO=""
BRANCH=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 <workflow-type> <task-description> [--repo REPO] [--branch BRANCH]"
      echo ""
      echo "Workflow Types:"
      echo "  feature-development  - Complete feature development workflow"
      echo "  bug-fix             - Bug fix workflow"
      echo "  code-review         - Code review workflow"
      echo "  ci-cd-pipeline      - CI/CD pipeline setup"
      echo "  documentation-update - Documentation update"
      echo "  security-audit      - Security audit workflow"
      echo ""
      echo "Examples:"
      echo "  $0 feature-development 'Add user authentication' --repo owner/repo"
      echo "  $0 bug-fix 'Fix login bug' --repo owner/repo --branch fix/login"
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Validation ---
if [ -z "$WORKFLOW" ] || [ -z "$TASK_DESC" ]; then
  log_error "Workflow type and task description are required"
  exit 1
fi

# --- Create task ID ---
TASK_ID="${WORKFLOW}-$(date +%Y%m%d-%H%M%S)"
log_info "Starting workflow: $WORKFLOW"
log_info "Task ID: $TASK_ID"
log_info "Description: $TASK_DESC"

# --- Function to execute feature development workflow ---
execute_feature_development() {
  log_info "=== Feature Development Workflow ==="
  
  # Step 1: Generate task specification
  log_info "Step 1: Generating task specification..."
  SPEC_FILE="$SWARM_DIR/specs/${TASK_ID}.md"
  mkdir -p "$(dirname "$SPEC_FILE")"
  
  cat > "$SPEC_FILE" << EOF
# Task Specification: $TASK_DESC

## Overview
$TASK_DESC

## Requirements
- [ ] Implement core functionality
- [ ] Add unit tests
- [ ] Update documentation
- [ ] Security review
- [ ] CI/CD integration

## Success Criteria
- All tests pass
- Code coverage >= 80%
- No critical security issues
- Documentation updated

## Timeline
Started: $(date)
EOF
  
  log_success "Specification created: $SPEC_FILE"
  
  # Step 2: Generate coding prompt
  log_info "Step 2: Generating coding agent prompt..."
  if [ -n "$REPO" ] && [ -f "$SCRIPTS_DIR/generate-prompt.sh" ]; then
    PROMPT_FILE="$SWARM_DIR/prompts/${TASK_ID}-coding.txt"
    "$SCRIPTS_DIR/generate-prompt.sh" "$REPO" "$TASK_DESC" \
      --type feature \
      --scope full \
      --output "$PROMPT_FILE"
    log_success "Coding prompt generated: $PROMPT_FILE"
  else
    log_warning "No repo specified, skipping prompt generation"
    PROMPT_FILE=""
  fi
  
  # Step 3: Spawn coding agent
  if [ -n "$PROMPT_FILE" ] && [ -f "$SCRIPTS_DIR/spawn-agent.sh" ]; then
    log_info "Step 3: Spawning coding agent..."
    BRANCH_NAME="${BRANCH:-feature/$(echo "$TASK_DESC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)}"
    "$SCRIPTS_DIR/spawn-agent.sh" "$REPO" "$BRANCH_NAME" "$TASK_ID" "$PROMPT_FILE"
    log_success "Coding agent spawned (branch: $BRANCH_NAME)"
  else
    log_error "Cannot spawn coding agent: missing repo or script"
    return 1
  fi
  
  # Step 4: Wait for PR creation (will be handled by webhook)
  log_info "Step 4: Waiting for PR creation and CI..."
  log_info "The system will automatically:"
  log_info "  - Monitor CI status via webhook"
  log_info "  - Trigger code review when CI passes"
  log_info "  - Run security scan"
  log_info "  - Update documentation"
  
  # Register task in registry
  jq ".tasks += [{
    id: \"$TASK_ID\",
    type: \"feature-development\",
    description: \"$TASK_DESC\",
    repo: \"$REPO\",
    branch: \"$BRANCH_NAME\",
    status: \"in_progress\",
    startTime: \"$(date -Iseconds)\",
    spec: \"$SPEC_FILE\",
    prompt: \"$PROMPT_FILE\"
  }]" "$REGISTRY" > "$REGISTRY.tmp" 2>/dev/null && mv "$REGISTRY.tmp" "$REGISTRY"
  
  log_success "Feature development workflow started"
}

# --- Function to execute bug fix workflow ---
execute_bug_fix() {
  log_info "=== Bug Fix Workflow ==="
  
  # Step 1: Analyze bug
  log_info "Step 1: Analyzing bug..."
  ANALYSIS_FILE="$SWARM_DIR/analysis/${TASK_ID}.md"
  mkdir -p "$(dirname "$ANALYSIS_FILE")"
  
  cat > "$ANALYSIS_FILE" << EOF
# Bug Analysis: $TASK_DESC

## Root Cause Analysis
[To be filled by coding agent]

## Fix Approach
[To be determined]

## Test Cases
- [ ] Reproduce bug
- [ ] Verify fix
- [ ] Regression tests
EOF
  
  # Step 2: Generate bug fix prompt
  if [ -n "$REPO" ]; then
    PROMPT_FILE="$SWARM_DIR/prompts/${TASK_ID}-bugfix.txt"
    "$SCRIPTS_DIR/generate-prompt.sh" "$REPO" "Fix: $TASK_DESC" \
      --type bugfix \
      --scope full \
      --output "$PROMPT_FILE"
  fi
  
  # Step 3: Spawn coding agent
  if [ -n "$PROMPT_FILE" ]; then
    BRANCH_NAME="${BRANCH:-fix/$(echo "$TASK_DESC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)}"
    "$SCRIPTS_DIR/spawn-agent.sh" "$REPO" "$BRANCH_NAME" "$TASK_ID" "$PROMPT_FILE"
  fi
  
  log_success "Bug fix workflow started"
}

# --- Function to execute code review workflow ---
execute_code_review() {
  log_info "=== Code Review Workflow ==="
  
  if [ -z "$REPO" ] || [ -z "$BRANCH" ]; then
    log_error "Code review requires --repo and --branch"
    return 1
  fi
  
  log_info "Reviewing $REPO branch $BRANCH"
  
  # Use existing review script
  if [ -f "$SCRIPTS_DIR/review-pr.sh" ]; then
    "$SCRIPTS_DIR/review-pr.sh" "$REPO" "$BRANCH"
  else
    log_error "Review script not found"
    return 1
  fi
  
  log_success "Code review completed"
}

# --- Function to execute security audit ---
execute_security_audit() {
  log_info "=== Security Audit Workflow ==="
  
  if [ -z "$REPO" ]; then
    log_error "Security audit requires --repo"
    return 1
  fi
  
  log_info "Running security scan on $REPO"
  
  # Run security scans
  if command -v npm &> /dev/null; then
    log_info "Running npm audit..."
    npm audit --json > "$SWARM_DIR/audit/${TASK_ID}-npm.json" 2>/dev/null || true
  fi
  
  if command -v gh &> /dev/null; then
    log_info "Checking GitHub security alerts..."
    gh api "repos/$REPO/security-advisories" > "$SWARM_DIR/audit/${TASK_ID}-ghsa.json" 2>/dev/null || true
  fi
  
  # Send notification
  if [ -f "$SCRIPTS_DIR/notify.sh" ]; then
    "$SCRIPTS_DIR/notify.sh" "security-audit" "$REPO" "" "Security audit completed for $REPO"
  fi
  
  log_success "Security audit completed"
}

# --- Function to execute CI/CD pipeline workflow ---
execute_ci_cd_pipeline() {
  log_info "=== CI/CD Pipeline Workflow ==="
  
  if [ -z "$REPO" ]; then
    log_error "CI/CD setup requires --repo"
    return 1
  fi
  
  # Clone repo and check existing workflows
  WORK_DIR="/tmp/ci-setup-$$"
  git clone "https://github.com/$REPO.git" "$WORK_DIR" 2>/dev/null || {
    log_error "Failed to clone repository"
    return 1
  }
  
  cd "$WORK_DIR"
  
  # Check if GitHub Actions workflows exist
  if [ -d ".github/workflows" ]; then
    log_info "Existing workflows found:"
    ls -la .github/workflows/
  else
    log_info "No workflows found, creating default CI/CD pipeline..."
    mkdir -p .github/workflows
    
    # Create default CI workflow
    cat > .github/workflows/ci.yml << 'EOF'
name: CI

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
    
    git add .github/workflows/ci.yml
    git commit -m "ci: Add CI/CD pipeline"
    git push origin "$BRANCH" 2>/dev/null || log_warning "Push failed, need manual review"
  fi
  
  cd -
  rm -rf "$WORK_DIR"
  
  log_success "CI/CD pipeline configured"
}

# --- Main execution ---
case "$WORKFLOW" in
  feature-development)
    execute_feature_development
    ;;
  bug-fix)
    execute_bug_fix
    ;;
  code-review)
    execute_code_review
    ;;
  ci-cd-pipeline)
    execute_ci_cd_pipeline
    ;;
  documentation-update)
    log_info "Documentation update workflow - coming soon"
    ;;
  security-audit)
    execute_security_audit
    ;;
  *)
    log_error "Unknown workflow: $WORKFLOW"
    log_info "Available workflows: feature-development, bug-fix, code-review, ci-cd-pipeline, documentation-update, security-audit"
    exit 1
    ;;
esac

log_success "Workflow execution completed"
