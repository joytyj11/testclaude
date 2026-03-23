#!/bin/bash
# github.sh - GitHub API 操作库
# 提供 GitHub 相关的功能函数

# 检查 gh CLI 是否可用
check_gh() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        return 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub. Run 'gh auth login'"
        return 1
    fi
    
    return 0
}

# 获取 PR 信息
get_pr_info() {
    local repo="$1"
    local pr_number="$2"
    
    check_gh || return 1
    
    gh pr view "$pr_number" --repo "$repo" --json number,title,state,headRefName,baseRefName,author,createdAt,url 2>/dev/null
}

# 获取 PR 状态
get_pr_status() {
    local repo="$1"
    local pr_number="$2"
    
    gh pr view "$pr_number" --repo "$repo" --json state -q '.state' 2>/dev/null
}

# 创建 PR
create_pr() {
    local repo="$1"
    local title="$2"
    local body="$3"
    local head="$4"
    local base="${5:-main}"
    
    check_gh || return 1
    
    gh pr create --repo "$repo" \
        --title "$title" \
        --body "$body" \
        --head "$head" \
        --base "$base" \
        --fill 2>/dev/null
}

# 获取 CI 状态
get_ci_status() {
    local repo="$1"
    local pr_number="$2"
    
    # 获取 PR 的最新 commit
    local head_sha=$(gh pr view "$pr_number" --repo "$repo" --json headRefOid -q '.headRefOid' 2>/dev/null)
    
    if [ -z "$head_sha" ]; then
        echo "unknown"
        return
    fi
    
    # 获取 check runs
    local checks=$(gh api "repos/$repo/commits/$head_sha/check-runs" --jq '.check_runs[] | {status: .status, conclusion: .conclusion}' 2>/dev/null)
    
    if [ -z "$checks" ]; then
        echo "no-checks"
        return
    fi
    
    # 检查状态
    local any_failed=false
    local any_pending=false
    local any_in_progress=false
    
    while IFS= read -r check; do
        local status=$(echo "$check" | jq -r '.status')
        local conclusion=$(echo "$check" | jq -r '.conclusion')
        
        if [ "$status" = "completed" ]; then
            if [ "$conclusion" != "success" ] && [ "$conclusion" != "skipped" ] && [ "$conclusion" != "neutral" ]; then
                any_failed=true
            fi
        else
            any_pending=true
            if [ "$status" = "in_progress" ]; then
                any_in_progress=true
            fi
        fi
    done <<< "$checks"
    
    if [ "$any_failed" = true ]; then
        echo "failed"
    elif [ "$any_in_progress" = true ]; then
        echo "in_progress"
    elif [ "$any_pending" = true ]; then
        echo "pending"
    else
        echo "success"
    fi
}

# 添加 PR 评论
add_pr_comment() {
    local repo="$1"
    local pr_number="$2"
    local comment="$3"
    
    check_gh || return 1
    
    gh pr comment "$pr_number" --repo "$repo" --body "$comment" 2>/dev/null
}

# 审查 PR
review_pr() {
    local repo="$1"
    local pr_number="$2"
    local review_type="$3"  # APPROVE, REQUEST_CHANGES, COMMENT
    local body="$4"
    
    check_gh || return 1
    
    gh pr review "$pr_number" --repo "$repo" --"${review_type,,}" --body "$body" 2>/dev/null
}

# 合并 PR
merge_pr() {
    local repo="$1"
    local pr_number="$2"
    local merge_method="${3:-merge}"  # merge, squash, rebase
    
    check_gh || return 1
    
    gh pr merge "$pr_number" --repo "$repo" --"$merge_method" --delete-branch 2>/dev/null
}

# 获取仓库信息
get_repo_details() {
    local repo="$1"
    
    check_gh || return 1
    
    gh api "repos/$repo" --jq '{name: .name, owner: .owner.login, description: .description, default_branch: .default_branch, stars: .stargazers_count, forks: .forks_count}' 2>/dev/null
}

# 列出 PR
get_prs() {
    local repo="$1"
    local state="${2:-open}"
    
    check_gh || return 1
    
    gh pr list --repo "$repo" --state "$state" --json number,title,author,createdAt,url 2>/dev/null
}

# 获取最新 commit 信息
get_latest_commit() {
    local repo="$1"
    local branch="${2:-main}"
    
    check_gh || return 1
    
    gh api "repos/$repo/commits/$branch" --jq '{sha: .sha, message: .commit.message, author: .commit.author.name, date: .commit.author.date}' 2>/dev/null
}

# 导出函数
export -f check_gh get_pr_info get_pr_status create_pr
export -f get_ci_status add_pr_comment review_pr merge_pr
export -f get_repo_details get_prs get_latest_commit
