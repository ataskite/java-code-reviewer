#!/bin/bash
# 阶段二：Git 分支探测与选择 - 步骤A
# 用途：检测 Git 仓库的分支信息

set -e

PROJECT_DIR="${1:?请输入项目路径}"

if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "IS_GIT_REPO=true"
  CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
  echo "CURRENT_BRANCH=$CURRENT_BRANCH"
  echo ""

  # 列出本地分支，按最近提交时间排序（最多10个）
  echo "=== 最近活跃分支 ==="
  git -C "$PROJECT_DIR" for-each-ref --sort=-committerdate \
    --format='BRANCH: %(refname:short) | %(committerdate:short) | %(subject)' refs/heads/ | head -10

  # 如果本地分支不足5个，补充远程分支
  LOCAL_COUNT=$(git -C "$PROJECT_DIR" for-each-ref refs/heads/ | wc -l | tr -d ' ')
  if [ "$LOCAL_COUNT" -lt 5 ]; then
    echo ""
    echo "=== 远程分支（补充） ==="
    git -C "$PROJECT_DIR" for-each-ref --sort=-committerdate \
      --format='BRANCH_REMOTE: %(refname:short) | %(committerdate:short) | %(subject)' refs/remotes/ | grep -v '/HEAD' | head -10
  fi
else
  echo "IS_GIT_REPO=false"
fi
